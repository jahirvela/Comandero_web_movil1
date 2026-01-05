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

      // El contenido viene con comandos ESC/POS como string, convertir a buffer
      // Usar latin1 para preservar los bytes de los comandos ESC/POS
      const buffer = Buffer.from(content, 'latin1');
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
    try {
      // En Windows, si el dispositivo es un nombre de impresora, usar la API nativa
      // En Linux/Mac, usar escpos-usb directamente
      if (this.platform === 'win32') {
        // En Windows, intentar usar el nombre de la impresora directamente
        // Si el dispositivo parece un nombre de impresora (no una ruta), usar node-printer o similar
        // Por ahora, intentar con escpos-usb y si falla, usar alternativa
        
        try {
          // Intentar con escpos-usb primero
          const escposUsb = await import('escpos-usb');
          const usbDevice = new escposUsb.USB();
          await usbDevice.open(this.device);
          
          // El contenido viene con comandos ESC/POS como string, convertir a buffer
          const buffer = Buffer.from(content, 'latin1'); // Usar latin1 para preservar bytes ESC/POS
          await usbDevice.write(buffer);
          await usbDevice.close();
          
          logger.info({ device: this.device, platform: this.platform }, 'Ticket enviado a impresora USB (escpos-usb)');
        } catch (escposError: any) {
          // Si escpos-usb falla, intentar método alternativo para Windows
          logger.warn({ err: escposError, device: this.device }, 'escpos-usb falló, intentando método alternativo para Windows');
          
          // Para Windows: usar el nombre de la impresora directamente
          // Esto requiere que la impresora esté instalada en Windows
          const { exec } = await import('child_process');
          const { promisify } = await import('util');
          const execAsync = promisify(exec);
          
          // Guardar contenido temporalmente y enviarlo a la impresora por nombre
          const { tmpdir } = await import('os');
          const tempFile = path.join(tmpdir(), `ticket-${Date.now()}.txt`);
          await fs.writeFile(tempFile, content, 'latin1');
          
          // Usar comando de Windows para imprimir
          // Si el dispositivo es un nombre de impresora, usarlo directamente
          // Si es un path como LPT1, COM1, etc., usarlo también
          const printCommand = this.device.includes('\\') || this.device.includes(':')
            ? `copy /b "${tempFile}" "${this.device}"` // Para LPT1, COM1, etc.
            : `print /d:"${this.device}" "${tempFile}"`; // Para nombre de impresora
          
          try {
            await execAsync(printCommand, { timeout: 5000 });
            logger.info({ device: this.device, method: 'windows-native' }, 'Ticket enviado a impresora USB (método Windows nativo)');
          } catch (printError: any) {
            // Eliminar archivo temporal
            await fs.unlink(tempFile).catch(() => {});
            throw new Error(`No se pudo imprimir en Windows. Verifica que la impresora "${this.device}" esté instalada y disponible. Error: ${printError.message}`);
          }
          
          // Eliminar archivo temporal después de un breve delay
          setTimeout(() => fs.unlink(tempFile).catch(() => {}), 2000);
        }
      } else {
        // Linux/Mac: usar escpos-usb directamente
        const escposUsb = await import('escpos-usb');
        const usbDevice = new escposUsb.USB();
        await usbDevice.open(this.device);
        
        // El contenido viene con comandos ESC/POS como string, convertir a buffer
        const buffer = Buffer.from(content, 'latin1'); // Usar latin1 para preservar bytes ESC/POS
        await usbDevice.write(buffer);
        await usbDevice.close();
        
        logger.info({ device: this.device, platform: this.platform }, 'Ticket enviado a impresora USB (escpos-usb)');
      }
    } catch (error: any) {
      logger.error({ err: error, device: this.device, platform: this.platform }, 'Error al imprimir en USB');
      throw new Error(`No se pudo conectar a la impresora USB en ${this.device}: ${error.message}`);
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
    contenido += '\n';
    // Comando ESC/POS para código de barras Code128
    // ESC k m n d1...dk donde:
    // - m = 4 (Code128)
    // - n = longitud de los datos
    // - d = datos del código de barras
    const codigoLength = orden.folio.length;
    contenido += `${ESC}k${String.fromCharCode(4)}${String.fromCharCode(codigoLength)}${orden.folio}`;
    contenido += '\n\n'; // Espacio después del código
    contenido += `${orden.folio}\n`; // Texto debajo del código
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

