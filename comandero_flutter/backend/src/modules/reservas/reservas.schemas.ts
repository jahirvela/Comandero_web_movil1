import { z } from 'zod';
import { parseMxToUtc } from '../../config/time.js';

export const crearReservaSchema = z.object({
  mesaId: z.number().int().positive(),
  nombreCliente: z.string().max(120).optional().nullable(),
  telefono: z.string().max(40).optional().nullable(),
  // Las fechas se reciben como strings y se interpretan como zona CDMX
  fechaHoraInicio: z.string().datetime(),
  fechaHoraFin: z.string().datetime().optional().nullable(),
  estado: z.enum(['pendiente', 'confirmada', 'cancelada', 'no_show']).optional().default('pendiente'),
});

export const actualizarReservaSchema = z.object({
  mesaId: z.number().int().positive().optional(),
  nombreCliente: z.string().max(120).optional().nullable(),
  telefono: z.string().max(40).optional().nullable(),
  fechaHoraInicio: z.string().datetime().optional(),
  fechaHoraFin: z.string().datetime().optional().nullable(),
  estado: z.enum(['pendiente', 'confirmada', 'cancelada', 'no_show']).optional(),
}).refine(
  (value) => Object.keys(value).length > 0,
  { message: 'Debe proporcionar al menos un campo para actualizar' }
);

export const listarReservasSchema = z.object({
  mesaId: z.coerce.number().int().positive().optional(),
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
  estado: z.enum(['pendiente', 'confirmada', 'cancelada', 'no_show']).optional(),
});

export type CrearReservaInput = z.infer<typeof crearReservaSchema>;
export type ActualizarReservaInput = z.infer<typeof actualizarReservaSchema>;
export type ListarReservasInput = z.infer<typeof listarReservasSchema>;

