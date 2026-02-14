import { getEnv } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import type { PrinterConfigEntry } from '../../config/printers.config.js';
import { getCharsPerLine, getPrintersConfigSync, getTicketColumnWidths, type PaperWidth } from '../../config/printers.config.js';
import type { TicketData } from './tickets.repository.js';
import { promises as fs } from 'fs';
import path from 'path';
import { nowMx, formatMxLocale } from '../../config/time.js';

/**
 * Convierte string UTF-16 a buffer CP850 para impresoras térmicas (México/LATAM).
 * Sin dependencias externas. Mapea acentos, ñ y signos españoles.
 */
function stringToCp850(s: string): Buffer {
  // Unicode -> CP850 (tabla oficial: ¡=0xAD, ¿=0xA8; acentos y ñ)
  const map: Record<number, number> = {
    0xa1: 0xad, 0xbf: 0xa8, 0xc1: 0xb5, 0xc9: 0x90, 0xcd: 0xd6, 0xd1: 0xa5, 0xd3: 0xe0, 0xda: 0xe9, 0xdc: 0x9a,
    0xe1: 0xa0, 0xe9: 0x82, 0xed: 0xa1, 0xf1: 0xa4, 0xf3: 0xa2, 0xfa: 0xa3, 0xfc: 0x81,
  };
  const out = Buffer.allocUnsafe(s.length);
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c <= 0x7f) out[i] = c;
    else if (c in map) out[i] = map[c] as number;
    else if (c <= 0xff) out[i] = c;
    else out[i] = 0x3f;
  }
  return out;
}

/**
 * Impresión térmica ESC/POS (compatible con cualquier impresora térmica:
 * 58mm, 80mm, USB, red, etc. Ej: ZKP5803, POS-80, Epson TM-T20)
 *
 * Soporta: simulación (archivo), archivo, TCP, USB.
 */

export interface Printer {
  print(content: string): Promise<void>;
  close(): Promise<void>;
}

class SimulationPrinter implements Printer {
  private outputPath: string;

  constructor(outputPath: string) {
    this.outputPath = outputPath;
  }

  async print(content: string): Promise<void> {
    try {
      // Asegurar que el directorio existe
      await fs.mkdir(this.outputPath, { recursive: true });

      // Generar nombre de archivo con timestamp en zona CDMX
      const timestamp = nowMx().toFormat('yyyy-MM-dd-HH-mm-ss');
      const filename = `ticket-${timestamp}.txt`;
      const filepath = path.join(this.outputPath, filename);

      // Guardar el ticket
      await fs.writeFile(filepath, content, 'utf-8');
      logger.info({ filepath }, 'Ticket guardado en modo simulación');
    } catch (error) {
      logger.error({ err: error }, 'Error al guardar ticket en simulación');
      throw error;
    }
  }

  async close(): Promise<void> {
    // No hay nada que cerrar en simulación
  }
}

class FilePrinter implements Printer {
  private filepath: string;

  constructor(filepath: string) {
    this.filepath = filepath;
  }

  async print(content: string): Promise<void> {
    try {
      await fs.writeFile(this.filepath, content, 'utf-8');
      logger.info({ filepath: this.filepath }, 'Ticket guardado en archivo');
    } catch (error) {
      logger.error({ err: error }, 'Error al guardar ticket en archivo');
      throw error;
    }
  }

  async close(): Promise<void> {
    // No hay nada que cerrar
  }
}

class NetworkPrinter implements Printer {
  private host: string;
  private port: number;

  constructor(host: string, port: number) {
    this.host = host;
    this.port = port;
  }

  async print(content: string): Promise<void> {
    try {
      // Usar escpos-network para impresoras de red
      const escposNetwork = await import('escpos-network');
      
      const device = new escposNetwork.Network(this.host, this.port);
      await device.open();

      // Convertir a CP850 para que acentos y ñ impriman bien en impresoras térmicas (red/USB/Bluetooth)
      const buffer = stringToCp850(content);
      await device.write(buffer);
      
      await device.close();

      logger.info({ host: this.host, port: this.port }, 'Ticket enviado a impresora de red');
    } catch (error) {
      logger.error({ err: error, host: this.host, port: this.port }, 'Error al imprimir en red');
      throw new Error(`No se pudo conectar a la impresora en ${this.host}:${this.port}`);
    }
  }

  async close(): Promise<void> {
    // La conexión se cierra automáticamente
  }
}

class USBPrinter implements Printer {
  private device: string;
  private platform: string;

  constructor(device: string) {
    this.device = device;
    this.platform = process.platform;
  }

  async print(content: string): Promise<void> {
    // En Windows: enviar datos RAW (ESC/POS) con script PowerShell + API Win32.
    // El comando "print /d:nombre" envia como documento y el driver no pasa los bytes raw.
    if (this.platform === 'win32') {
      if (!this.device) {
        throw new Error('En Windows se requiere PRINTER_DEVICE con el nombre exacto de la impresora (ej. ZKTECO).');
      }
      const { execFile } = await import('child_process');
      const { promisify } = await import('util');
      const execFileAsync = promisify(execFile);
      const { tmpdir } = await import('os');
      const tempFile = path.join(tmpdir(), `ticket-${nowMx().toMillis()}.bin`);
      const buffer = stringToCp850(content);
      await fs.writeFile(tempFile, buffer);
      const scriptPath = path.join(process.cwd(), 'scripts', 'print-raw-windows.ps1');
      try {
        await execFileAsync(
          'powershell',
          ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, '-PrinterName', this.device, '-FilePath', tempFile],
          { timeout: 15000, windowsHide: true }
        );
        logger.info({ device: this.device, method: 'windows-raw' }, 'Ticket enviado a impresora (RAW)');
      } catch (e: any) {
        await fs.unlink(tempFile).catch(() => {});
        const msg = e.stderr?.trim() || e.message || String(e);
        throw new Error(`No se pudo imprimir en "${this.device}". ${msg}`);
      }
      setTimeout(() => fs.unlink(tempFile).catch(() => {}), 3000);
      return;
    }
    // Linux/Mac: usar escpos-usb. CP850 para acentos y ñ como en Windows.
    const buffer = stringToCp850(content);
    const escposUsbMod = await import('escpos-usb');
    const USB = (escposUsbMod as any).default ?? (escposUsbMod as any).USB;
    if (typeof USB !== 'function') {
      throw new Error('escpos-usb: USB no es un constructor.');
    }
    const devices = USB.findPrinter();
    if (!devices || devices.length === 0) {
      throw new Error('No se encontró ninguna impresora USB térmica. Conecta la impresora y verifica que esté encendida.');
    }
    const usbDevice = new USB(devices[0]);
    await new Promise<void>((resolve, reject) => {
      usbDevice.open((err: Error | null) => (err ? reject(err) : resolve()));
    });
    try {
      await new Promise<void>((resolve, reject) => {
        usbDevice.write(buffer, (err: Error | null) => (err ? reject(err) : resolve()));
      });
      logger.info({ device: this.device, platform: this.platform }, 'Ticket enviado a impresora USB (escpos-usb)');
    } finally {
      await new Promise<void>((resolve, reject) => {
        usbDevice.close((err: Error | null) => (err ? reject(err) : resolve()));
      });
    }
  }

  async close(): Promise<void> {
    // La conexión se cierra automáticamente
  }
}

/**
 * Crea una instancia de impresora a partir de una entrada de configuración.
 * Usado cuando hay varias impresoras (config/printers.json) o por tipo de documento.
 */
export const createPrinterFromConfig = (config: PrinterConfigEntry): Printer => {
  const env = getEnv();
  if (config.type === 'simulation') {
    const path = config.device ?? env.PRINTER_SIMULATION_PATH;
    return new SimulationPrinter(path);
  }
  if (config.type === 'file') {
    if (!config.device) throw new Error(`Impresora ${config.id}: device es requerido para type=file`);
    return new FilePrinter(config.device);
  }
  if (config.type === 'tcp') {
    if (!config.host || !config.port) throw new Error(`Impresora ${config.id}: host y port requeridos para type=tcp`);
    return new NetworkPrinter(config.host, config.port);
  }
  if (config.type === 'usb') {
    if (!config.device) throw new Error(`Impresora ${config.id}: device es requerido para type=usb (nombre o puerto)`);
    return new USBPrinter(config.device);
  }
  throw new Error(`Impresora ${config.id}: tipo inválido ${(config as { type: string }).type}`);
};

/** Comando ESC/POS estándar para abrir cajón de dinero (pin 2). Compatible con la mayoría de impresoras térmicas. */
export const COMANDO_APERTURA_CAJON_ESC_POS = '\x1B\x70\x00\x19\x19';

/**
 * Envía la señal de apertura de cajón a la impresora indicada.
 * No lanza error; los fallos se registran en log.
 */
export async function enviarAperturaCajon(config: PrinterConfigEntry): Promise<void> {
  const printer = createPrinterFromConfig(config);
  try {
    await printer.print(COMANDO_APERTURA_CAJON_ESC_POS);
    logger.info({ printerId: config.id }, 'Señal de apertura de cajón enviada');
  } catch (err) {
    logger.warn({ err, printerId: config.id }, 'Error al enviar apertura de cajón');
  } finally {
    await printer.close();
  }
}

/**
 * Crea la impresora por defecto (una sola, desde .env o primera del config).
 * Mantiene compatibilidad con el flujo que usa una única impresora.
 */
export const createPrinter = (): Printer => {
  const configs = getPrintersConfigSync();
  const first = configs[0];
  if (!first) throw new Error('No hay ninguna impresora configurada');
  return createPrinterFromConfig(first);
};

/**
 * Genera el contenido del ticket en formato ESC/POS (cualquier impresora térmica).
 * @param paperWidth 57, 58, 72 u 80 mm. Por defecto 80.
 */
export const generarContenidoTicket = (
  data: TicketData,
  incluirCodigoBarras: boolean = true,
  paperWidth: PaperWidth = 80
): string => {
  const { orden, cajero, items, restaurante } = data;
  const w = getCharsPerLine(paperWidth);
  const { totalColLen, descColLen, labelLen: ticketLabelLen } = getTicketColumnWidths(paperWidth);
  const moneda = 'MXN ';

  let contenido = '';

  const ESC = '\x1B';
  const init = `${ESC}@`; // Inicializar impresora (limpia buffer y evita encabezados extra)
  const centrar = `${ESC}a1`;
  const izquierda = `${ESC}a0`;
  const negrita = `${ESC}E1`;
  const negritaOff = `${ESC}E0`;
  const cortar = `${ESC}i`;
  const imprimirYAvanzar = (n: number) => `${ESC}d${String.fromCharCode(n)}`;
  // Normalizar texto: un solo espacio entre palabras para que no se junten
  const norm = (s: string) => (s || '').normalize('NFC').replace(/\s+/g, ' ').trim();

  // Encabezado: nombre del restaurante (por defecto "Restaurante"), bien estructurado y visible
  const nombreRestaurante = (norm(restaurante.nombre) || 'Restaurante').trim() || 'Restaurante';
  contenido += init;
  contenido += centrar;
  contenido += negrita;
  contenido += `${nombreRestaurante}\n`;
  contenido += negritaOff;
  if (restaurante.direccion) contenido += `${norm(restaurante.direccion)}\n`;
  if (restaurante.telefono) contenido += `Tel: ${norm(restaurante.telefono)}\n`;
  if (restaurante.rfc) contenido += `RFC: ${norm(restaurante.rfc)}\n`;
  contenido += '\n';
  contenido += `${'='.repeat(w)}\n`;
  contenido += centrar;
  contenido += negrita;
  contenido += 'TICKET DE COBRO\n';
  contenido += negritaOff;
  contenido += `${'='.repeat(w)}\n`;
  contenido += izquierda;
  contenido += '\n';

  // Helper: partir texto en líneas por ancho (para nombres largos en cualquier ancho de papel)
  const wrap = (text: string, maxLen: number): string[] => {
    if (maxLen < 1) return [];
    const t = (text || '').trim();
    if (!t) return [];
    const lines: string[] = [];
    let rest = t;
    while (rest.length > 0) {
      if (rest.length <= maxLen) {
        lines.push(rest);
        break;
      }
      const chunk = rest.substring(0, maxLen);
      const lastSpace = chunk.lastIndexOf(' ');
      const cut = lastSpace > 0 ? lastSpace : maxLen;
      lines.push(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    return lines;
  };

  // Para llevar = sin mesa. Bloque compacto, sin espacios en blanco grandes.
  const isTakeaway = !orden.mesaCodigo;

  if (isTakeaway) {
    contenido += `${'-'.repeat(w)}\n`;
    contenido += centrar;
    contenido += negrita;
    contenido += 'PARA LLEVAR\n';
    contenido += negritaOff;
    contenido += izquierda;
    const nombreCliente = norm(orden.clienteNombre || '') || 'Cliente';
    const prefix = 'Cliente: ';
    const descColLenTakeaway = w - prefix.length;
    const lineasCliente = wrap(nombreCliente, descColLenTakeaway);
    for (let i = 0; i < lineasCliente.length; i++) {
      contenido += i === 0 ? `${prefix}${lineasCliente[i]}\n` : `${' '.repeat(prefix.length)}${lineasCliente[i]}\n`;
    }
    contenido += `${'-'.repeat(w)}\n`;
  }

  // Datos del ticket - fecha/hora de impresión en CDMX
  contenido += `Folio: ${norm(orden.folio)}\n`;
  contenido += `Fecha: ${formatMxLocale(nowMx(), { dateStyle: 'short', timeStyle: 'short' })}\n`;

  // Mesa (y opcionalmente cuenta dividida: "Cuenta de: [nombre]") — compacto, sin huecos
  if (!isTakeaway && orden.mesaCodigo) {
    contenido += `Mesa: ${norm(orden.mesaCodigo)}\n`;
  }
  if (!isTakeaway && orden.clienteNombre) {
    const nombreCuenta = norm(orden.clienteNombre);
    const prefixCuenta = 'Cuenta de: ';
    const anchoCuenta = w - prefixCuenta.length;
    const lineasCuenta = wrap(nombreCuenta, anchoCuenta);
    for (let i = 0; i < lineasCuenta.length; i++) {
      contenido += i === 0 ? `${prefixCuenta}${lineasCuenta[i]}\n` : `${' '.repeat(prefixCuenta.length)}${lineasCuenta[i]}\n`;
    }
  }
  if (cajero) contenido += `Impreso por: ${norm(cajero.nombre)}\n`;
  if (data.metodoPago) {
    const prefixMetodo = 'Método de pago: ';
    const valorMetodo = norm(data.metodoPago);
    const anchoValor = w - prefixMetodo.length;
    const lineasMetodo = wrap(valorMetodo, anchoValor);
    for (let i = 0; i < lineasMetodo.length; i++) {
      contenido += i === 0 ? `${prefixMetodo}${lineasMetodo[i]}\n` : `${' '.repeat(prefixMetodo.length)}${lineasMetodo[i]}\n`;
    }
  }

  contenido += `${'-'.repeat(w)}\n`;
  contenido += negrita;
  contenido += `CANT  DESCRIPCION${' '.repeat(Math.max(1, descColLen - 11))} TOTAL MXN\n`;
  contenido += negritaOff;
  contenido += `${'-'.repeat(w)}\n`;

  const colCantWidth = 6;
  const prefCant = (c: string) => c + ' '.repeat(Math.max(0, colCantWidth - c.length));
  const prefCont = ' '.repeat(colCantWidth);

  for (const item of items) {
    const nombre = norm(item.productoNombre) || 'Producto';
    const tamano = item.productoTamanoEtiqueta ? norm(item.productoTamanoEtiqueta) : null;
    const cantidad = String(item.cantidad).padStart(4);
    const total = item.totalLinea.toFixed(2).padStart(totalColLen);
    const lineasNombre = wrap(nombre, descColLen);

    if (tamano) {
      // Con tamaño: nombre completo (wrap, sin truncar con "..."), luego tamaño debajo y total
      for (let i = 0; i < lineasNombre.length; i++) {
        const pref = i === 0 ? prefCant(cantidad) : prefCont;
        contenido += `${pref}${lineasNombre[i]}\n`;
      }
      contenido += `${prefCont}${('Tam: ' + tamano).padEnd(descColLen)}${moneda}${total}\n`;
    } else {
      // Sin tamaño: nombre en varias líneas, total en la última
      for (let i = 0; i < lineasNombre.length; i++) {
        const pref = i === 0 ? prefCant(cantidad) : prefCont;
        const isLast = i === lineasNombre.length - 1;
        const totalStr = isLast ? `${' '.repeat(Math.max(0, descColLen - lineasNombre[i].length))}${moneda}${total}` : '';
        contenido += `${pref}${lineasNombre[i]}${totalStr}\n`;
      }
    }

    // Modificadores (sin línea extra si no hay)
    if (item.modificadores.length > 0) {
      for (const mod of item.modificadores) {
        const modNombre = `  + ${norm(mod.nombre)}`;
        const modPrecio = mod.precioUnitario > 0 ? ` (+${moneda}${mod.precioUnitario.toFixed(2)})` : '';
        contenido += `${modNombre}${modPrecio}\n`;
      }
    }

    if (item.nota) contenido += `  Nota: ${norm(item.nota)}\n`;
  }

  // Garantizar al menos un espacio entre etiqueta y valor para que las palabras no se junten
  const pad = (n: number) => ' '.repeat(Math.max(1, n));
  contenido += `${'-'.repeat(w)}\n`;
  contenido += `Subtotal:${pad(ticketLabelLen - 8)}${moneda}${orden.subtotal.toFixed(2).padStart(totalColLen)}\n`;
  if (orden.descuentoTotal > 0) {
    contenido += `Descuento:${pad(ticketLabelLen - 9)}${moneda}${orden.descuentoTotal.toFixed(2).padStart(totalColLen)}\n`;
  }
  // IVA solo si el administrador lo tiene habilitado (se muestra la línea aunque sea 0.00)
  if (data.ivaHabilitado) {
    contenido += `IVA (16%):${pad(ticketLabelLen - 10)}${moneda}${orden.impuestoTotal.toFixed(2).padStart(totalColLen)}\n`;
  }
  contenido += negrita;
  contenido += `TOTAL:${pad(ticketLabelLen - 5)}${moneda}${orden.total.toFixed(2).padStart(totalColLen)}\n`;
  contenido += negritaOff;
  contenido += `${'='.repeat(w)}\n`;

  // Cierre: compacto, sin espaciado extra
  contenido += izquierda;
  const gracias = '¡Gracias por su preferencia!';
  const vuelva = 'Vuelva pronto';
  const espaciosGracias = ' '.repeat(Math.max(0, Math.floor((w - gracias.length) / 2)));
  const espaciosVuelva = ' '.repeat(Math.max(0, Math.floor((w - vuelva.length) / 2)));
  contenido += espaciosGracias + gracias + '\n';
  contenido += espaciosVuelva + vuelva + '\n';
  contenido += imprimirYAvanzar(3);
  contenido += cortar;
  contenido += '\n';
  return contenido;
};

