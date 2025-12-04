/**
 * Módulo central de manejo de tiempo para Comandix
 * 
 * Zona horaria oficial del sistema: America/Mexico_City (CDMX)
 * La base de datos MySQL se maneja en UTC.
 * 
 * REGLAS:
 * - PROHIBIDO usar new Date() directamente en lógica de negocio
 * - Siempre usar las funciones de este módulo
 * - Las fechas de la BD vienen en UTC, convertir a CDMX antes de mostrar
 * - Al guardar fechas, convertir de CDMX a UTC
 */

import { DateTime, Duration, Settings } from 'luxon';

// Zona horaria oficial del sistema
export const APP_TIMEZONE = 'America/Mexico_City';

// Configurar Luxon para usar la zona horaria por defecto
Settings.defaultZone = APP_TIMEZONE;

/**
 * Obtiene la fecha/hora actual en zona horaria CDMX
 * @returns DateTime en zona horaria America/Mexico_City
 */
export function nowMx(): DateTime {
  return DateTime.now().setZone(APP_TIMEZONE);
}

/**
 * Convierte una fecha UTC a zona horaria CDMX
 * @param date - Fecha en UTC (puede ser Date, string ISO, o DateTime)
 * @returns DateTime en zona horaria America/Mexico_City
 */
export function utcToMx(date: Date | string | DateTime | null | undefined): DateTime | null {
  if (date === null || date === undefined) {
    return null;
  }
  
  if (date instanceof DateTime) {
    return date.setZone(APP_TIMEZONE);
  }
  
  if (date instanceof Date) {
    return DateTime.fromJSDate(date, { zone: 'utc' }).setZone(APP_TIMEZONE);
  }
  
  if (typeof date === 'string') {
    // Intentar parsear como ISO string (asumiendo UTC si no tiene zona)
    const parsed = DateTime.fromISO(date, { zone: 'utc' });
    if (parsed.isValid) {
      return parsed.setZone(APP_TIMEZONE);
    }
    // Intentar como SQL datetime
    const sqlParsed = DateTime.fromSQL(date, { zone: 'utc' });
    if (sqlParsed.isValid) {
      return sqlParsed.setZone(APP_TIMEZONE);
    }
  }
  
  return null;
}

/**
 * Convierte una fecha en zona horaria CDMX a UTC
 * @param date - Fecha en zona CDMX (puede ser Date, string ISO, o DateTime)
 * @returns DateTime en UTC
 */
export function mxToUtc(date: Date | string | DateTime | null | undefined): DateTime | null {
  if (date === null || date === undefined) {
    return null;
  }
  
  if (date instanceof DateTime) {
    return date.setZone('utc');
  }
  
  if (date instanceof Date) {
    // Asumimos que la fecha JS viene en la zona local (CDMX)
    return DateTime.fromJSDate(date, { zone: APP_TIMEZONE }).setZone('utc');
  }
  
  if (typeof date === 'string') {
    // Parsear asumiendo zona CDMX
    const parsed = DateTime.fromISO(date, { zone: APP_TIMEZONE });
    if (parsed.isValid) {
      return parsed.setZone('utc');
    }
    const sqlParsed = DateTime.fromSQL(date, { zone: APP_TIMEZONE });
    if (sqlParsed.isValid) {
      return sqlParsed.setZone('utc');
    }
  }
  
  return null;
}

/**
 * Obtiene un timestamp ISO string de la hora actual en CDMX
 * Útil para campos de timestamp en respuestas JSON
 */
export function nowMxISO(): string {
  return nowMx().toISO() ?? new Date().toISOString();
}

/**
 * Convierte una fecha UTC a ISO string en zona CDMX
 * @param date - Fecha en UTC
 * @returns ISO string representando la hora en CDMX
 */
export function utcToMxISO(date: Date | string | DateTime | null | undefined): string | null {
  const converted = utcToMx(date);
  return converted?.toISO() ?? null;
}

/**
 * Formatea una fecha UTC para mostrar en CDMX con formato legible
 * @param date - Fecha en UTC
 * @param format - Formato de Luxon (por defecto: 'dd/MM/yyyy HH:mm')
 * @returns String formateado en zona CDMX
 */
export function formatMx(
  date: Date | string | DateTime | null | undefined, 
  format: string = 'dd/MM/yyyy HH:mm'
): string {
  const converted = utcToMx(date);
  if (!converted) return '';
  return converted.toFormat(format);
}

/**
 * Formatea una fecha para formato de ticket/impresión
 * @param date - Fecha en UTC
 * @returns String formateado tipo "03/12/2025 14:30"
 */
export function formatMxTicket(date: Date | string | DateTime | null | undefined): string {
  return formatMx(date, 'dd/MM/yyyy HH:mm');
}

/**
 * Formatea una fecha en formato corto para reportes
 * @param date - Fecha en UTC
 * @returns String formateado tipo "03/12/2025"
 */
export function formatMxDate(date: Date | string | DateTime | null | undefined): string {
  return formatMx(date, 'dd/MM/yyyy');
}

/**
 * Formatea una fecha usando formato local ES-MX pero en zona CDMX
 * @param date - Fecha en UTC
 * @param options - Opciones de Intl.DateTimeFormat
 */
export function formatMxLocale(
  date: Date | string | DateTime | null | undefined,
  options: Intl.DateTimeFormatOptions = { dateStyle: 'short', timeStyle: 'short' }
): string {
  const converted = utcToMx(date);
  if (!converted) return '';
  // Luxon's toLocaleString acepta locale como parámetro opcional en el objeto options
  return converted.toJSDate().toLocaleString('es-MX', options);
}

/**
 * Calcula la diferencia de tiempo entre una fecha UTC y ahora en CDMX
 * @param date - Fecha en UTC
 * @returns Texto tipo "hace X minutos/horas" o null si la fecha es inválida
 */
export function timeAgoMx(date: Date | string | DateTime | null | undefined): string | null {
  const converted = utcToMx(date);
  if (!converted) return null;
  
  const now = nowMx();
  const diff = now.diff(converted, ['hours', 'minutes', 'seconds']);
  
  const totalMinutes = Math.floor(diff.as('minutes'));
  const totalHours = Math.floor(diff.as('hours'));
  const totalDays = Math.floor(diff.as('days'));
  
  if (totalMinutes < 0) {
    return 'en el futuro';
  }
  
  if (totalMinutes < 1) {
    return 'hace un momento';
  }
  
  if (totalMinutes < 60) {
    return `hace ${totalMinutes} ${totalMinutes === 1 ? 'minuto' : 'minutos'}`;
  }
  
  if (totalHours < 24) {
    return `hace ${totalHours} ${totalHours === 1 ? 'hora' : 'horas'}`;
  }
  
  return `hace ${totalDays} ${totalDays === 1 ? 'día' : 'días'}`;
}

/**
 * Calcula los minutos transcurridos desde una fecha UTC hasta ahora en CDMX
 * @param date - Fecha en UTC
 * @returns Minutos transcurridos (puede ser negativo si la fecha es futura)
 */
export function minutesSinceMx(date: Date | string | DateTime | null | undefined): number {
  const converted = utcToMx(date);
  if (!converted) return 0;
  
  const now = nowMx();
  return Math.floor(now.diff(converted, 'minutes').minutes);
}

/**
 * Obtiene el inicio del día actual en CDMX (00:00:00) como DateTime UTC
 * Útil para queries de "hoy"
 */
export function startOfTodayMxAsUtc(): DateTime {
  return nowMx().startOf('day').setZone('utc');
}

/**
 * Obtiene el fin del día actual en CDMX (23:59:59) como DateTime UTC
 */
export function endOfTodayMxAsUtc(): DateTime {
  return nowMx().endOf('day').setZone('utc');
}

/**
 * Obtiene el inicio del día de una fecha en CDMX como UTC
 * @param date - Fecha (será convertida a CDMX primero)
 */
export function startOfDayMxAsUtc(date: Date | string | DateTime | null | undefined): DateTime | null {
  const converted = utcToMx(date);
  if (!converted) return null;
  return converted.startOf('day').setZone('utc');
}

/**
 * Convierte una fecha a Date de JS manteniendo la representación correcta
 * @param date - Fecha en UTC de la BD
 * @returns Date de JavaScript
 */
export function utcToJsDate(date: Date | string | DateTime | null | undefined): Date | null {
  const converted = utcToMx(date);
  if (!converted) return null;
  return converted.toJSDate();
}

/**
 * Obtiene solo la parte de fecha (YYYY-MM-DD) en zona CDMX
 * Útil para comparaciones y agrupaciones por día
 */
export function getDateOnlyMx(date: Date | string | DateTime | null | undefined): string | null {
  const converted = utcToMx(date);
  if (!converted) return null;
  return converted.toFormat('yyyy-MM-dd');
}

/**
 * Parsea una fecha string en zona CDMX y devuelve como UTC
 * @param dateStr - String de fecha (puede ser ISO o SQL format)
 * @returns DateTime en UTC listo para guardar en BD
 */
export function parseMxToUtc(dateStr: string): DateTime | null {
  // Intentar ISO primero
  let parsed = DateTime.fromISO(dateStr, { zone: APP_TIMEZONE });
  if (parsed.isValid) {
    return parsed.setZone('utc');
  }
  
  // Intentar SQL format
  parsed = DateTime.fromSQL(dateStr, { zone: APP_TIMEZONE });
  if (parsed.isValid) {
    return parsed.setZone('utc');
  }
  
  // Intentar formato común dd/MM/yyyy HH:mm
  parsed = DateTime.fromFormat(dateStr, 'dd/MM/yyyy HH:mm', { zone: APP_TIMEZONE });
  if (parsed.isValid) {
    return parsed.setZone('utc');
  }
  
  // Intentar solo fecha dd/MM/yyyy
  parsed = DateTime.fromFormat(dateStr, 'dd/MM/yyyy', { zone: APP_TIMEZONE });
  if (parsed.isValid) {
    return parsed.setZone('utc');
  }
  
  return null;
}

/**
 * Crea un DateTime desde componentes en zona CDMX
 */
export function createMxDateTime(
  year: number,
  month: number,
  day: number,
  hour: number = 0,
  minute: number = 0,
  second: number = 0
): DateTime {
  return DateTime.fromObject(
    { year, month, day, hour, minute, second },
    { zone: APP_TIMEZONE }
  );
}

/**
 * Verifica si una fecha está en el mismo día que hoy (en zona CDMX)
 */
export function isTodayMx(date: Date | string | DateTime | null | undefined): boolean {
  const converted = utcToMx(date);
  if (!converted) return false;
  
  const today = nowMx();
  return converted.hasSame(today, 'day');
}

/**
 * Obtiene la fecha actual en CDMX como string YYYY-MM-DD
 */
export function todayMxString(): string {
  return nowMx().toFormat('yyyy-MM-dd');
}

// Re-exportar tipos útiles de Luxon
export { DateTime, Duration };

