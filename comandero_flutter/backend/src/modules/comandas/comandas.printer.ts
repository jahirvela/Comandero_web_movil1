import { getEnv } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import { getCharsPerLine, type PaperWidth } from '../../config/printers.config.js';
import { createPrinter, createPrinterFromConfig } from '../tickets/tickets.printer.js';
import { formatMxLocale, nowMx } from '../../config/time.js';
import type { OrdenDetalle } from '../../types/ordenes.js';

/** Parte un texto en líneas por ancho máximo (corte por espacios cuando sea posible). */
function wrap(text: string, maxLen: number): string[] {
  if (maxLen < 1) return [];
  const t = (text || '').trim().replace(/\s+/g, ' ');
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
}

/**
 * Genera el contenido de la comanda en formato ESC/POS (cocina).
 * Nombre del producto completo (wrap); notas organizadas con wrap; número de orden visible; sin fecha/hora al final.
 * @param paperWidth 57, 58, 72 u 80 mm. Por defecto 80.
 */
export const generarContenidoComanda = (orden: OrdenDetalle, paperWidth: PaperWidth = 80): string => {
  const w = getCharsPerLine(paperWidth);
  const descMaxLen = Math.max(16, w - 6);
  let contenido = '';

  const ESC = '\x1B';
  const centrar = `${ESC}a1`;
  const izquierda = `${ESC}a0`;
  const negrita = `${ESC}E1`;
  const negritaOff = `${ESC}E0`;
  const cortar = `${ESC}i`;
  const imprimirYAvanzar = (n: number) => `${ESC}d${String.fromCharCode(n)}`;

  const folio = `ORD-${String(orden.id).padStart(6, '0')}`;
  const prefCant = (c: string) => c + '  ';
  const prefCont = '     ';

  contenido += `${'='.repeat(w)}\n`;
  contenido += centrar;
  contenido += negrita;
  contenido += 'COMANDA\n';
  contenido += negritaOff;
  contenido += izquierda;
  contenido += `${'='.repeat(w)}\n`;
  contenido += `Folio: ${folio}\n`;
  contenido += `Fecha: ${formatMxLocale(nowMx(), { dateStyle: 'short', timeStyle: 'short' })}\n`;

  if (orden.mesaCodigo) {
    contenido += `Mesa: ${orden.mesaCodigo}\n`;
  } else {
    contenido += `${'-'.repeat(w)}\n`;
    contenido += centrar;
    contenido += negrita;
    contenido += 'PEDIDO PARA LLEVAR\n';
    contenido += negritaOff;
    contenido += izquierda;
    contenido += `${'-'.repeat(w)}\n`;
    const nombreCliente = (orden.clienteNombre || '').trim() || 'Cliente';
    const lineasCliente = wrap(nombreCliente, w - 9);
    for (let i = 0; i < lineasCliente.length; i++) {
      contenido += i === 0 ? `Cliente:  ${lineasCliente[i]}\n` : `         ${lineasCliente[i]}\n`;
    }
    if (orden.clienteTelefono && orden.clienteTelefono.trim()) {
      const tel = orden.clienteTelefono.trim();
      const lineasTel = wrap(tel, w - 5);
      for (let i = 0; i < lineasTel.length; i++) {
        contenido += i === 0 ? `Tel:     ${lineasTel[i]}\n` : `         ${lineasTel[i]}\n`;
      }
    }
    contenido += `${'-'.repeat(w)}\n`;
  }

  if (orden.creadoPorNombre) contenido += `Mesero: ${orden.creadoPorNombre}\n`;

  contenido += `${'-'.repeat(w)}\n`;
  contenido += negrita;
  contenido += 'CANT  PRODUCTO\n';
  contenido += negritaOff;
  contenido += `${'-'.repeat(w)}\n`;

  for (const item of orden.items) {
    const cantidad = String(item.cantidad).padStart(3);
    const nombreProducto = item.productoNombre || 'Producto';
    const tamano = item.productoTamanoEtiqueta;
    const descripcion = tamano ? `${nombreProducto} (${tamano})` : nombreProducto;
    const lineasNombre = wrap(descripcion, descMaxLen);

    for (let i = 0; i < lineasNombre.length; i++) {
      const pref = i === 0 ? prefCant(cantidad) : prefCont;
      contenido += `${pref}${lineasNombre[i]}\n`;
    }

    if (item.modificadores && item.modificadores.length > 0) {
      for (const mod of item.modificadores) {
        contenido += `${prefCont}+ ${mod.modificadorOpcionNombre}\n`;
      }
    }

    if (item.nota && item.nota.trim()) {
      const lineasNota = wrap(item.nota.trim(), descMaxLen - 6);
      for (let i = 0; i < lineasNota.length; i++) {
        contenido += i === 0 ? `${prefCont}NOTA: ${lineasNota[i]}\n` : `${prefCont}      ${lineasNota[i]}\n`;
      }
    }
  }

  contenido += `${'-'.repeat(w)}\n`;
  if (orden.notas && orden.notas.length > 0) {
    contenido += negrita;
    contenido += 'NOTAS GENERALES:\n';
    contenido += negritaOff;
    for (const nota of orden.notas) {
      const texto = (nota.contenido || '').trim();
      if (!texto) continue;
      const lineasNota = wrap(texto, w - 2);
      for (const linea of lineasNota) {
        contenido += `- ${linea}\n`;
      }
    }
    contenido += `${'-'.repeat(w)}\n`;
  }

  contenido += centrar;
  contenido += negrita;
  contenido += `${folio}\n`;
  contenido += negritaOff;
  contenido += izquierda;
  contenido += imprimirYAvanzar(4);
  contenido += cortar;
  contenido += '\n';

  return contenido;
};

/**
 * Imprime la comanda en todas las impresoras configuradas para "comanda".
 * Si hay varias, imprime en cada una; si ninguna está configurada o todas fallan,
 * se intenta una impresora por defecto (legacy) o simulación.
 */
export const imprimirComanda = async (
  orden: OrdenDetalle,
  esReimpresion: boolean = false
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  const { getImpresorasAsPrinterConfig } = await import('../impresoras/impresoras.repository.js');
  const { getPrinterConfigsForDocument } = await import('../../config/printers.config.js');
  let configs = await getImpresorasAsPrinterConfig('comanda');
  if (configs.length === 0) configs = getPrinterConfigsForDocument('comanda');
  const tipoImpresion = esReimpresion ? 'reimpresión manual' : 'impresión automática';
  const rutas: string[] = [];
  let successCount = 0;

  for (const config of configs) {
    try {
      const contenido = generarContenidoComanda(orden, config.paperWidth ?? 80);
      const printer = createPrinterFromConfig(config);
      await printer.print(contenido);
      await printer.close();
      successCount++;
      logger.info({ ordenId: orden.id, printerId: config.id, tipoImpresion }, 'Comanda impresa');
      if (config.type === 'simulation' && config.device) {
        rutas.push(`./${config.device}/comanda-${orden.id}-${nowMx().toFormat('yyyy-MM-dd-HH-mm-ss')}.txt`);
      }
    } catch (err: unknown) {
      logger.warn({ err, ordenId: orden.id, printerId: config.id }, 'Error al imprimir comanda en impresora');
    }
  }

  if (configs.length > 0) {
    return {
      exito: successCount > 0,
      mensaje: successCount > 0 ? `Comanda impresa (${tipoImpresion})` : 'No se pudo imprimir en ninguna impresora configurada',
      rutaArchivo: rutas[0],
    };
  }

  if (configs.length === 0) {
    try {
      const contenido = generarContenidoComanda(orden);
      const printer = createPrinter();
      await printer.print(contenido);
      await printer.close();
      logger.info({ ordenId: orden.id, tipoImpresion }, 'Comanda impresa (impresora por defecto)');
      if (getEnv().PRINTER_TYPE === 'simulation') {
        rutas.push(`./${getEnv().PRINTER_SIMULATION_PATH}/comanda-${orden.id}-${nowMx().toFormat('yyyy-MM-dd-HH-mm-ss')}.txt`);
      }
      return { exito: true, mensaje: `Comanda impresa (${tipoImpresion})`, rutaArchivo: rutas[0] };
    } catch (error: unknown) {
      logger.error({ err: error, ordenId: orden.id }, 'Error al imprimir comanda');
      return {
        exito: false,
        mensaje: `Error al imprimir comanda: ${error instanceof Error ? error.message : 'Error desconocido'}`,
      };
    }
  }

  return { exito: false, mensaje: 'No hay impresoras configuradas para comanda' };
};

