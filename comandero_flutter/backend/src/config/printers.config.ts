/**
 * Configuración flexible de impresoras térmicas
 *
 * Soporta:
 * - 1 impresora para todo (comanda + ticket)
 * - Varias impresoras: una para cocina (comanda), una para caja (ticket)
 * - Cualquier combinación por tipo de documento
 *
 * Tipos de documento: "comanda" (cocina) | "ticket" (cliente/cobro)
 * Interfaces: simulation | file | tcp | usb
 * Ancho de papel: 57 | 58 | 72 | 80 mm - estándar ESC/POS
 */

import path from 'path';
import { promises as fs } from 'fs';
import { getEnv } from './env.js';
import { logger } from './logger.js';

export type DocumentType = 'comanda' | 'ticket';

/** Anchos de papel soportados (mm). */
export type PaperWidth = 57 | 58 | 72 | 80;

export interface PrinterConfigEntry {
  /** Identificador único (para logs y fallbacks) */
  id: string;
  /** Nombre legible (opcional) */
  name?: string;
  /** simulation = guardar en archivos; file = escribir en ruta fija; tcp = red; usb = USB */
  type: 'simulation' | 'file' | 'tcp' | 'usb';
  /** Tipos de documento que imprime esta impresora */
  documents: DocumentType[];
  /** Ancho de papel en mm (57, 58, 72 u 80). Por defecto 80. */
  paperWidth?: PaperWidth;
  /** Para type=simulation: carpeta; type=file: ruta del archivo; type=usb: nombre/puerto (ej. "Thermal Receipt Printer" o "USB001") */
  device?: string;
  /** Para type=tcp */
  host?: string;
  /** Para type=tcp */
  port?: number;
}

const DEFAULT_PAPER_WIDTH: PaperWidth = 80;

/**
 * Caracteres por línea según ancho de papel (estándar ESC/POS).
 * 57mm ~28-30, 58mm ~32, 72mm ~40, 80mm ~48.
 */
const CHAR_WIDTH_MAP: Record<PaperWidth, number> = {
  57: 28,
  58: 32,
  72: 40,
  80: 48,
};

/** Ancho en caracteres según papel (para alinear contenido). Valores no soportados → 80 mm. */
export function getCharsPerLine(paperWidth: PaperWidth | number = DEFAULT_PAPER_WIDTH): number {
  const w = paperWidth as PaperWidth;
  return CHAR_WIDTH_MAP[w] ?? CHAR_WIDTH_MAP[80];
}

/** Normaliza un valor a PaperWidth; si no es válido devuelve 80. */
export function normalizePaperWidth(n: number | undefined | null): PaperWidth {
  if (n === 57 || n === 58 || n === 72 || n === 80) return n;
  return 80;
}

/**
 * Anchos de columnas para ticket según papel.
 * Layout: [CANT  ](6) + [DESCRIPCION](descColLen) + [ TOTAL MXN](10) = w.
 * Item:    [CANT  ](6) + [desc](descColLen) + [MXN ](4) + [total](totalColLen) = w.
 * Totals:  [Label](labelLen) + [MXN ](4) + [amount](totalColLen) = w.
 * De ahí: descColLen = w - 16, totalColLen = 6, labelLen = w - 10.
 */
export function getTicketColumnWidths(paperWidth: PaperWidth | number): { totalColLen: number; descColLen: number; labelLen: number } {
  const w = normalizePaperWidth(paperWidth);
  const totalColLen = 6; // montos hasta 999.99
  const descColLen = w - 16; // 6 + descColLen + 10 = w (header)
  const labelLen = w - 10;   // labelLen + 4 + totalColLen = w (totals)
  return { totalColLen, descColLen, labelLen };
}

/** Longitud sugerida para descripción en comanda según papel. */
export function getComandaDescLen(paperWidth: PaperWidth | number): number {
  const w = normalizePaperWidth(paperWidth);
  const map: Record<PaperWidth, number> = {
    57: 16,
    58: 20,
    72: 28,
    80: 36,
  };
  return map[w];
}

let cachedPrinters: PrinterConfigEntry[] | null = null;

/**
 * Carga la configuración de impresoras desde:
 * 1. Archivo JSON (PRINTERS_CONFIG_PATH o config/printers.json)
 * 2. Si no existe, una sola impresora desde variables de entorno (.env)
 */
export async function loadPrintersConfig(): Promise<PrinterConfigEntry[]> {
  if (cachedPrinters) return cachedPrinters;

  const env = getEnv();
  const configPath =
    (process.env.PRINTERS_CONFIG_PATH as string) ||
    path.join(process.cwd(), 'config', 'printers.json');

  try {
    const content = await fs.readFile(configPath, 'utf-8');
    const parsed = JSON.parse(content) as { printers?: PrinterConfigEntry[] };
    if (Array.isArray(parsed.printers) && parsed.printers.length > 0) {
      cachedPrinters = parsed.printers.map((p) => ({
        ...p,
        paperWidth: normalizePaperWidth(p.paperWidth),
      }));
      logger.info({ count: cachedPrinters.length, path: configPath }, 'Impresoras cargadas desde archivo');
      return cachedPrinters;
    }
  } catch (e: unknown) {
    const err = e as NodeJS.ErrnoException;
    if (err.code !== 'ENOENT') {
      logger.warn({ err: e, path: configPath }, 'No se pudo cargar printers.json, usando configuración .env');
    }
  }

  // Una sola impresora desde .env (comportamiento legacy)
  const paperWidth = normalizePaperWidth(env.PRINTER_PAPER_WIDTH);
  cachedPrinters = [
    {
      id: 'default',
      name: 'Impresora principal',
      type: (env.PRINTER_TYPE === 'simulation' ? 'simulation' : env.PRINTER_INTERFACE) as 'simulation' | 'usb' | 'tcp' | 'file',
      documents: ['comanda', 'ticket'],
      paperWidth,
      device: env.PRINTER_DEVICE || (env.PRINTER_TYPE === 'simulation' ? env.PRINTER_SIMULATION_PATH : undefined),
      host: env.PRINTER_HOST,
      port: env.PRINTER_PORT,
    },
  ];
  logger.info({ printer: cachedPrinters[0].id }, 'Impresora única desde .env');
  return cachedPrinters;
}

/** Síncrono: devuelve caché o config por env (para uso en createPrinter) */
export function getPrintersConfigSync(): PrinterConfigEntry[] {
  if (cachedPrinters) return cachedPrinters;
  const env = getEnv();
  const paperWidth = normalizePaperWidth(env.PRINTER_PAPER_WIDTH);
  return [
    {
      id: 'default',
      name: 'Impresora principal',
      type: (env.PRINTER_TYPE === 'simulation' ? 'simulation' : env.PRINTER_INTERFACE) as 'simulation' | 'usb' | 'tcp' | 'file',
      documents: ['comanda', 'ticket'],
      paperWidth,
      device: env.PRINTER_DEVICE || (env.PRINTER_TYPE === 'simulation' ? env.PRINTER_SIMULATION_PATH : undefined),
      host: env.PRINTER_HOST,
      port: env.PRINTER_PORT,
    },
  ];
}

/**
 * Devuelve las configuraciones de impresoras que imprimen el tipo de documento dado.
 * Debe llamarse después de loadPrintersConfig() en arranque, o usará .env.
 */
export function getPrinterConfigsForDocument(document: DocumentType): PrinterConfigEntry[] {
  const configs = getPrintersConfigSync();
  return configs.filter((c) => c.documents.includes(document));
}

export function clearPrintersCache(): void {
  cachedPrinters = null;
}
