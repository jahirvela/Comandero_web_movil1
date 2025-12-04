import { z } from 'zod';

export const reporteVentasSchema = z.object({
  fechaInicio: z.coerce.date(),
  fechaFin: z.coerce.date()
});

export const reporteTopProductosSchema = z.object({
  fechaInicio: z.coerce.date(),
  fechaFin: z.coerce.date(),
  limite: z.coerce.number().int().positive().max(100).optional().default(10)
});

export const corteCajaSchema = z.object({
  fecha: z.coerce.date(),
  cajeroId: z.coerce.number().int().positive().optional()
});

export const reporteInventarioSchema = z.object({
  fechaInicio: z.coerce.date(),
  fechaFin: z.coerce.date()
});

