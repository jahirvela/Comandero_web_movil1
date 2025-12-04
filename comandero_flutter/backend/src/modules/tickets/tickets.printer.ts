import { getEnv } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import type { TicketData } from './tickets.repository.js';
import { promises as fs } from 'fs';
import path from 'path';
import { nowMx, formatMxLocale } from '../../config/time.js';

/**
 * Librería elegida: escpos (v3.0.0-alpha.6)
 * 
 * Razones:
 * 1. Soporte completo para comandos ESC/POS (estándar POS-80)
 * 2. Soporte para múltiples interfaces: USB, TCP/IP, archivo
 * 3. Soporte para códigos de barras (Code128, EAN, etc.)
 * 4. Activamente mantenida
 * 5. Compatible con impresoras térmicas comunes
 */

interface Printer {
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

      // El contenido ya viene formateado con comandos ESC/POS como string
      // Enviar directamente como buffer
      const buffer = Buffer.from(content, 'utf-8');
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

  constructor(device: string) {
    this.device = device;
  }

  async print(content: string): Promise<void> {
    try {
      // Usar escpos-usb para impresoras USB
      const escposUsb = await import('escpos-usb');
      
      const usbDevice = new escposUsb.USB();
      await usbDevice.open(this.device);

      // El contenido ya viene formateado con comandos ESC/POS como string
      // Enviar directamente como buffer
      const buffer = Buffer.from(content, 'utf-8');
      await usbDevice.write(buffer);
      
      await usbDevice.close();

      logger.info({ device: this.device }, 'Ticket enviado a impresora USB');
    } catch (error) {
      logger.error({ err: error, device: this.device }, 'Error al imprimir en USB');
      throw new Error(`No se pudo conectar a la impresora USB en ${this.device}`);
    }
  }

  async close(): Promise<void> {
    // La conexión se cierra automáticamente
  }
}

export const createPrinter = (): Printer => {
  const env = getEnv();

  if (env.PRINTER_TYPE === 'simulation') {
    return new SimulationPrinter(env.PRINTER_SIMULATION_PATH);
  }

  if (env.PRINTER_INTERFACE === 'file') {
    if (!env.PRINTER_DEVICE) {
      throw new Error('PRINTER_DEVICE es requerido para interfaz de archivo');
    }
    return new FilePrinter(env.PRINTER_DEVICE);
  }

  if (env.PRINTER_INTERFACE === 'tcp') {
    if (!env.PRINTER_HOST || !env.PRINTER_PORT) {
      throw new Error('PRINTER_HOST y PRINTER_PORT son requeridos para impresora de red');
    }
    return new NetworkPrinter(env.PRINTER_HOST, env.PRINTER_PORT);
  }

  if (env.PRINTER_INTERFACE === 'usb') {
    if (!env.PRINTER_DEVICE) {
      throw new Error('PRINTER_DEVICE es requerido para impresora USB');
    }
    return new USBPrinter(env.PRINTER_DEVICE);
  }

  throw new Error(`Configuración de impresora inválida: ${env.PRINTER_INTERFACE}`);
};

/**
 * Genera el contenido del ticket en formato texto plano compatible con POS-80
 */
export const generarContenidoTicket = (data: TicketData, incluirCodigoBarras: boolean = true): string => {
  const { orden, cajero, items, restaurante } = data;

  let contenido = '';

  // Comandos ESC/POS para centrar y formato
  const ESC = '\x1B';
  const centrar = `${ESC}a1`; // Centrar texto
  const izquierda = `${ESC}a0`; // Alinear izquierda
  const negrita = `${ESC}E1`; // Negrita ON
  const negritaOff = `${ESC}E0`; // Negrita OFF
  const dobleAltura = `${ESC}d1`; // Doble altura
  const alturaNormal = `${ESC}d0`; // Altura normal
  const cortar = `${ESC}i`; // Cortar papel

  // Encabezado del restaurante
  contenido += centrar;
  contenido += negrita;
  contenido += dobleAltura;
  contenido += `${restaurante.nombre}\n`;
  contenido += alturaNormal;
  contenido += negritaOff;

  if (restaurante.direccion) {
    contenido += `${restaurante.direccion}\n`;
  }
  if (restaurante.telefono) {
    contenido += `Tel: ${restaurante.telefono}\n`;
  }
  if (restaurante.rfc) {
    contenido += `RFC: ${restaurante.rfc}\n`;
  }

  contenido += `${'='.repeat(42)}\n`;
  contenido += izquierda;

  // Datos del ticket - usar formato CDMX
  contenido += `Folio: ${orden.folio}\n`;
  contenido += `Fecha: ${formatMxLocale(orden.fecha, { dateStyle: 'short', timeStyle: 'short' })}\n`;

  // Determinar si es pedido para llevar
  const isTakeaway = !orden.mesaCodigo && orden.clienteNombre;

  if (isTakeaway) {
    // Mostrar claramente que es PARA LLEVAR
    contenido += centrar;
    contenido += negrita;
    contenido += dobleAltura;
    contenido += '*** PARA LLEVAR ***\n';
    contenido += alturaNormal;
    contenido += negritaOff;
    contenido += izquierda;
  } else if (orden.mesaCodigo) {
    contenido += `Mesa: ${orden.mesaCodigo}\n`;
  }

  if (orden.clienteNombre) {
    contenido += `Cliente: ${orden.clienteNombre}\n`;
  }

  if (orden.clienteTelefono) {
    contenido += `Tel: ${orden.clienteTelefono}\n`;
  }

  if (cajero) {
    contenido += `Cajero: ${cajero.nombre}\n`;
  }

  contenido += `${'-'.repeat(42)}\n`;

  // Items de la orden
  contenido += negrita;
  contenido += 'CANT  DESCRIPCION              TOTAL\n';
  contenido += negritaOff;
  contenido += `${'-'.repeat(42)}\n`;

  for (const item of items) {
    const descripcion = item.productoTamanoEtiqueta
      ? `${item.productoNombre} (${item.productoTamanoEtiqueta})`
      : item.productoNombre;

    // Truncar descripción si es muy larga
    const descripcionCorta = descripcion.length > 25 ? descripcion.substring(0, 22) + '...' : descripcion;
    const cantidad = String(item.cantidad).padStart(3);
    const total = item.totalLinea.toFixed(2).padStart(8);

    contenido += `${cantidad}  ${descripcionCorta.padEnd(25)} ${total}\n`;

    // Mostrar modificadores si existen
    if (item.modificadores.length > 0) {
      for (const mod of item.modificadores) {
        const modNombre = `  + ${mod.nombre}`;
        const modPrecio = mod.precioUnitario > 0 ? ` (+$${mod.precioUnitario.toFixed(2)})` : '';
        contenido += `${modNombre}${modPrecio}\n`;
      }
    }

    // Mostrar nota si existe
    if (item.nota) {
      contenido += `  Nota: ${item.nota}\n`;
    }
  }

  contenido += `${'-'.repeat(42)}\n`;

  // Totales
  contenido += `Subtotal:                    $${orden.subtotal.toFixed(2).padStart(8)}\n`;

  if (orden.descuentoTotal > 0) {
    contenido += `Descuento:                   $${orden.descuentoTotal.toFixed(2).padStart(8)}\n`;
  }

  if (orden.impuestoTotal > 0) {
    contenido += `Impuesto:                   $${orden.impuestoTotal.toFixed(2).padStart(8)}\n`;
  }

  if (orden.propinaSugerida && orden.propinaSugerida > 0) {
    contenido += `Propina sugerida:           $${orden.propinaSugerida.toFixed(2).padStart(8)}\n`;
  }

  contenido += negrita;
  contenido += `TOTAL:                      $${orden.total.toFixed(2).padStart(8)}\n`;
  contenido += negritaOff;

  contenido += `${'='.repeat(42)}\n`;

  // Código de barras (Code128)
  if (incluirCodigoBarras) {
    contenido += centrar;
    contenido += `\n${ESC}k4${ESC}k${orden.folio.length}${orden.folio}\n`; // Code128
    contenido += `${orden.folio}\n`;
    contenido += izquierda;
  }

  // Mensaje final
  contenido += centrar;
  contenido += '\n¡Gracias por su preferencia!\n';
  contenido += 'Vuelva pronto\n\n';
  contenido += izquierda;

  // Cortar papel
  contenido += cortar;
  contenido += '\n'; // Avanzar papel

  return contenido;
};

