import { z } from 'zod';
import { parseMxToUtc, nowMx } from '../../config/time.js';

export const listarCierresCajaSchema = z.object({
  // Las fechas de filtro se interpretan como zona CDMX y se convierten a UTC
  fechaInicio: z.string().optional().transform((val) => {
    if (!val) return undefined;
    const parsed = parseMxToUtc(val);
    return parsed?.toJSDate() ?? new Date(val);
  }),
  fechaFin: z.string().optional().transform((val) => {
    if (!val) return undefined;
    const parsed = parseMxToUtc(val);
    return parsed?.toJSDate() ?? new Date(val);
  }),
  cajeroId: z.coerce.number().int().positive().optional()
});

export const crearCierreCajaSchema = z.object({
  // La fecha del cierre se interpreta como zona CDMX
  fecha: z.string().optional().transform((val) => {
    if (!val) return nowMx().toJSDate();
    const parsed = parseMxToUtc(val);
    return parsed?.toJSDate() ?? new Date(val);
  }),
  efectivoInicial: z.coerce.number().nonnegative().default(0),
  efectivoFinal: z.coerce.number().nonnegative().optional().default(0),
  totalPagos: z.coerce.number().nonnegative().optional(),
  totalEfectivo: z.coerce.number().nonnegative().optional(),
  totalTarjeta: z.coerce.number().nonnegative().optional(),
  notas: z.string().max(255).nullable().optional(),
  otrosIngresos: z.coerce.number().nonnegative().optional().default(0),
  otrosIngresosTexto: z.string().max(255).nullable().optional(),
  notaCajero: z.string().max(500).nullable().optional(),
  efectivoContado: z.coerce.number().nonnegative().optional(),
  totalDeclarado: z.coerce.number().nonnegative().optional(),
});

export type CrearCierreCajaInput = z.infer<typeof crearCierreCajaSchema>;

export const actualizarEstadoCierreSchema = z.object({
  estado: z.enum(['pending', 'approved', 'rejected', 'clarification']),
  comentarioRevision: z.string().max(1000).nullable().optional(),
});

export type ActualizarEstadoCierreInput = z.infer<typeof actualizarEstadoCierreSchema>;

