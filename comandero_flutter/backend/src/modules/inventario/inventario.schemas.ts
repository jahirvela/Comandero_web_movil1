import { z } from 'zod';

export const crearInsumoSchema = z.object({
  nombre: z.string().min(2),
  categoria: z.string().min(2).max(64),
  unidad: z.string().min(1).max(32),
  cantidadActual: z.coerce.number().nonnegative().default(0),
  stockMinimo: z.coerce.number().nonnegative().default(0),
  stockMaximo: z.coerce.number().nonnegative().optional().nullable(),
  costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
  proveedor: z.string().max(120).optional().nullable(),
  activo: z.boolean().optional().default(true)
});

export const actualizarInsumoSchema = z
  .object({
    nombre: z.string().min(2).optional(),
    categoria: z.string().min(2).max(64).optional(),
    unidad: z.string().min(1).max(32).optional(),
    cantidadActual: z.coerce.number().nonnegative().optional(),
    stockMinimo: z.coerce.number().nonnegative().optional(),
    stockMaximo: z.coerce.number().nonnegative().optional().nullable(),
    costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
    proveedor: z.string().max(120).optional().nullable(),
    activo: z.boolean().optional()
  })
  .refine(
    (value) =>
      value.nombre !== undefined ||
      value.categoria !== undefined ||
      value.unidad !== undefined ||
      value.cantidadActual !== undefined ||
      value.stockMinimo !== undefined ||
      value.stockMaximo !== undefined ||
      value.costoUnitario !== undefined ||
      value.proveedor !== undefined ||
      value.activo !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export const crearMovimientoSchema = z.object({
  inventarioItemId: z.number().int().positive(),
  tipo: z.enum(['entrada', 'salida', 'ajuste']),
  cantidad: z.coerce.number().positive(),
  costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
  motivo: z.string().max(160).optional().nullable(),
  origen: z.enum(['compra', 'consumo', 'ajuste', 'devolucion']).optional().nullable(),
  referenciaOrdenId: z.number().int().positive().optional().nullable()
});

export type CrearInsumoInput = z.infer<typeof crearInsumoSchema>;
export type ActualizarInsumoInput = z.infer<typeof actualizarInsumoSchema>;
export type CrearMovimientoInput = z.infer<typeof crearMovimientoSchema>;

