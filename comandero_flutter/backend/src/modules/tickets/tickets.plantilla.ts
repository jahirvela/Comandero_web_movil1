import type { TicketData } from './tickets.repository.js';
import type { PlantillaImpresion } from '../configuracion/plantilla-impresion.repository.js';
import { getCharsPerLine, getTicketColumnWidths, type PaperWidth } from '../../config/printers.config.js';
import { formatMxLocale, nowMx } from '../../config/time.js';

const ESC = '\x1B';
const init = `${ESC}@`;
const centrar = `${ESC}a1`;
const izquierda = `${ESC}a0`;
const negrita = `${ESC}E1`;
const negritaOff = `${ESC}E0`;
const cortar = `${ESC}i`;
const imprimirYAvanzar = (n: number) => `${ESC}d${String.fromCharCode(n)}`;

const norm = (s: string) => (s || '').normalize('NFC').replace(/\s+/g, ' ').trim();

function wrap(text: string, maxLen: number): string[] {
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
}

/** Genera el bloque de ítems para el ticket (respeta ancho de papel y columnas). */
function generarBloqueItems(
  data: TicketData,
  paperWidth: PaperWidth,
  plantillaLineaItem: string | null
): string {
  const w = getCharsPerLine(paperWidth);
  const { totalColLen, descColLen } = getTicketColumnWidths(paperWidth);
  const moneda = 'MXN ';
  const colCantWidth = 6;
  const prefCant = (c: string) => c + ' '.repeat(Math.max(0, colCantWidth - c.length));
  const prefCont = ' '.repeat(colCantWidth);
  let out = '';

  for (const item of data.items) {
    const nombre = norm(item.productoNombre) || 'Producto';
    const tamano = item.productoTamanoEtiqueta ? norm(item.productoTamanoEtiqueta) : null;
    const cantidad = String(item.cantidad).padStart(4);
    const total = item.totalLinea.toFixed(2).padStart(totalColLen);
    const lineasNombre = wrap(nombre, descColLen);

    if (plantillaLineaItem) {
      const linea = plantillaLineaItem
        .replace(/\{\{CANT\}\}/g, cantidad)
        .replace(/\{\{DESCRIPCION\}\}/g, nombre)
        .replace(/\{\{TOTAL\}\}/g, total)
        .replace(/\{\{TAMANO\}\}/g, tamano || '')
        .replace(/\{\{MONEDA\}\}/g, moneda);
      out += linea + '\n';
      if (item.modificadores.length > 0) {
        for (const mod of item.modificadores) {
          out += `  + ${norm(mod.nombre)}${mod.precioUnitario > 0 ? ` (+${moneda}${mod.precioUnitario.toFixed(2)})` : ''}\n`;
        }
      }
      if (item.nota) out += `  Nota: ${norm(item.nota)}\n`;
      continue;
    }

    if (tamano) {
      for (let i = 0; i < lineasNombre.length; i++) {
        const pref = i === 0 ? prefCant(cantidad) : prefCont;
        out += `${pref}${lineasNombre[i]}\n`;
      }
      out += `${prefCont}${('Tam: ' + tamano).padEnd(descColLen)}${moneda}${total}\n`;
    } else {
      for (let i = 0; i < lineasNombre.length; i++) {
        const pref = i === 0 ? prefCant(cantidad) : prefCont;
        const isLast = i === lineasNombre.length - 1;
        const totalStr = isLast ? `${' '.repeat(Math.max(0, descColLen - lineasNombre[i].length))}${moneda}${total}` : '';
        out += `${pref}${lineasNombre[i]}${totalStr}\n`;
      }
    }
    if (item.modificadores.length > 0) {
      for (const mod of item.modificadores) {
        out += `  + ${norm(mod.nombre)}${mod.precioUnitario > 0 ? ` (+${moneda}${mod.precioUnitario.toFixed(2)})` : ''}\n`;
      }
    }
    if (item.nota) out += `  Nota: ${norm(item.nota)}\n`;
  }
  return out;
}

/** Reemplaza marcadores de formato por códigos ESC/POS. */
function aplicarFormato(linea: string): string {
  return linea
    .replace(/\[CENTRAR\]/g, centrar)
    .replace(/\[\/CENTRAR\]/g, izquierda)
    .replace(/\[NEGRITA\]/g, negrita)
    .replace(/\[\/NEGRITA\]/g, negritaOff);
}

const FORMAT_MARKERS = /\[\/?CENTRAR\]|\[\/?NEGRITA\]/g;

/**
 * Si la línea (tras reemplazo de placeholders) supera el ancho del papel,
 * la parte visible se divide en varias líneas respetando el formato [CENTRAR]/[NEGRITA].
 */
function wrapLineToWidth(linea: string, w: number): string[] {
  const visible = linea.replace(FORMAT_MARKERS, '').replace(/\s+/g, ' ').trim();
  if (visible.length <= w) return [linea];
  const openTags = (linea.match(/\[(?:CENTRAR|NEGRITA)\]/g) || []).join('');
  const closeTags = (linea.match(/\[\/(?:CENTRAR|NEGRITA)\]/g) || []).join('');
  const segments = wrap(visible, w);
  return segments.map((seg) => openTags + seg + closeTags);
}

/** Reemplaza un valor que puede ser largo; si excede ancho, devuelve varias líneas (wrap). */
function reemplazarConWrap(
  templateLine: string,
  placeholder: string,
  valor: string,
  ancho: number
): string {
  const valorNorm = norm(valor);
  if (!valorNorm || valorNorm.length <= ancho) {
    return templateLine.replace(placeholder, valorNorm);
  }
  const lineas = wrap(valorNorm, ancho);
  return lineas.map((l) => templateLine.replace(placeholder, l)).join('\n');
}

/**
 * Genera el contenido del ticket de cobro a partir de una plantilla editable.
 * Placeholders: NOMBRE_RESTAURANTE, DIRECCION, TELEFONO, RFC, TITULO, FECHA, FOLIO, MESA, CLIENTE,
 * IMPRESO_POR, METODO_PAGO, ITEMS, SUBTOTAL, DESCUENTO, IVA, TOTAL, GRACIAS, VUELVA.
 * Marcadores: [CENTRAR], [/CENTRAR], [NEGRITA], [/NEGRITA].
 */
export function renderTicketConPlantilla(
  data: TicketData,
  plantilla: PlantillaImpresion,
  paperWidth: PaperWidth = 80
): string {
  const w = getCharsPerLine(paperWidth);
  const { totalColLen, labelLen: ticketLabelLen } = getTicketColumnWidths(paperWidth);
  const moneda = 'MXN ';
  const pad = (n: number) => ' '.repeat(Math.max(1, n));

  const orden = data.orden;
  const cajero = data.cajero;
  const restaurante = data.restaurante;

  const nombreRestaurante = (norm(restaurante.nombre) || 'Restaurante').trim() || 'Restaurante';
  const fechaStr = formatMxLocale(nowMx(), { dateStyle: 'short', timeStyle: 'short' });
  const itemsBlock = generarBloqueItems(data, paperWidth, plantilla.plantillaLineaItem);

  const ivaFormatted = orden.impuestoTotal.toFixed(2).padStart(totalColLen);
  const ivaLine = data.ivaHabilitado
    ? `IVA (16%):      ${moneda}${ivaFormatted}`
    : '';

  const valores: Record<string, string> = {
    SEPARADOR: '='.repeat(w),
    GUION: '-'.repeat(w),
    NOMBRE_RESTAURANTE: nombreRestaurante,
    DIRECCION: restaurante.direccion ? norm(restaurante.direccion) : '',
    TELEFONO: restaurante.telefono ? norm(restaurante.telefono) : '',
    RFC: restaurante.rfc ? norm(restaurante.rfc) : '',
    TITULO: 'TICKET DE COBRO',
    FECHA: fechaStr,
    FOLIO: norm(orden.folio),
    MESA: orden.mesaCodigo ? norm(orden.mesaCodigo) : '',
    CLIENTE: orden.clienteNombre ? norm(orden.clienteNombre) : '',
    IMPRESO_POR: cajero ? norm(cajero.nombre) : '',
    METODO_PAGO: data.metodoPago ? norm(data.metodoPago) : '',
    ITEMS: itemsBlock,
    MONEDA: moneda,
    SUBTOTAL: orden.subtotal.toFixed(2).padStart(totalColLen),
    DESCUENTO: orden.descuentoTotal.toFixed(2).padStart(totalColLen),
    IVA: orden.impuestoTotal.toFixed(2).padStart(totalColLen),
    IVA_LINE: ivaLine,
    TOTAL: orden.total.toFixed(2).padStart(totalColLen),
    GRACIAS: '¡Gracias por su preferencia!',
    VUELVA: 'Vuelva pronto',
  };

  let contenido = init + '\n';
  const lineas = plantilla.contenido.split(/\r?\n/);

  for (let i = 0; i < lineas.length; i++) {
    let linea = lineas[i];

    if (linea.includes('{{ITEMS}}')) {
      let conItems = linea.replace('{{ITEMS}}', itemsBlock);
      conItems = conItems.replace(/\{\{([^}]+)\}\}/g, (_m: string, key: string) => key.trim().replace(/_/g, ' '));
      contenido += aplicarFormato(conItems) + '\n';
      continue;
    }

    // Si no hay nombre de cliente, ocultar completamente la línea que lo contiene (evita "Cuenta de:" vacío).
    if (linea.includes('{{CLIENTE}}') && !valores.CLIENTE) {
      continue;
    }

    const placer = (key: string, val: string): string =>
      linea.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), val);

    let expanded: string[] = [];
    if (linea.includes('{{DIRECCION}}') && valores.DIRECCION.length > w) {
      expanded = wrap(valores.DIRECCION, w).map((l) => placer('DIRECCION', l));
    } else if (linea.includes('{{CLIENTE}}') && valores.CLIENTE.length > w) {
      expanded = wrap(valores.CLIENTE, w).map((l) => placer('CLIENTE', l));
    } else {
      let out = linea;
      for (const [key, valor] of Object.entries(valores)) {
        if (key === 'ITEMS') continue;
        out = out.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), valor);
      }
      expanded = [out];
    }

    for (const ln of expanded) {
      // Cualquier {{texto_con_guiones}} no definido se imprime como texto: sin llaves, guiones bajos → espacios (configurable desde la plantilla)
      const lnFinal = ln.replace(/\{\{([^}]+)\}\}/g, (_match, key: string) => key.trim().replace(/_/g, ' '));
      const lineasAAncho = wrapLineToWidth(lnFinal, w);
      for (const l of lineasAAncho) {
        contenido += aplicarFormato(l) + '\n';
      }
    }
  }

  contenido += imprimirYAvanzar(3);
  contenido += cortar;
  contenido += '\n';
  return contenido;
}
