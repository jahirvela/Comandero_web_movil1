import { z } from 'zod';
import { DateTime } from 'luxon';
import { parseMxToUtc } from '../../config/time.js';

export const crearPagoSchema = z.object({
  ordenId: z.coerce.number().int().positive(),
  formaPagoId: z.coerce.number().int().positive(),
  monto: z.coerce.number().positive(),
  referencia: z.string().max(120).nullable().optional(),
  estado: z.enum(['aplicado', 'anulado', 'pendiente']).optional().default('aplicado'),
  // Aceptar fecha como string datetime ISO y convertirla a formato SQL para MySQL
  fechaPago: z.union([
    z.string().datetime(),
    z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/), // Formato ISO básico
    z.string()
  ]).nullable().optional().transform((val) => {
    if (!val || typeof val !== 'string') {
      return null;
    }
    
    // El frontend envía la fecha en formato ISO con 'Z' (UTC) o sin timezone
    // Necesitamos parsearla correctamente y convertirla a formato SQL para MySQL
    let parsed: DateTime | null = null;
    
    // Si tiene 'Z' o timezone, parsear como UTC
    if (val.includes('Z') || val.includes('+') || val.match(/-\d{2}:\d{2}$/)) {
      // Parsear como UTC directamente
      parsed = DateTime.fromISO(val, { zone: 'utc' });
    } else {
      // Si no tiene timezone, asumir que viene en CDMX y convertir a UTC
      parsed = parseMxToUtc(val);
    }
    
    if (parsed && parsed.isValid) {
      // Convertir a formato SQL válido para MySQL (sin milisegundos, sin timezone)
      // MySQL espera formato 'YYYY-MM-DD HH:mm:ss' en UTC
      return parsed.toFormat('yyyy-MM-dd HH:mm:ss');
    }
    
    // Si no se puede parsear, retornar null para que use NOW() en la BD
    return null;
  })
}).passthrough(); // Permitir campos adicionales sin error

export const crearPropinaSchema = z.object({
  ordenId: z.number().int().positive(),
  monto: z.coerce.number().nonnegative()
});

export type CrearPagoInput = z.infer<typeof crearPagoSchema>;
export type CrearPropinaInput = z.infer<typeof crearPropinaSchema>;

