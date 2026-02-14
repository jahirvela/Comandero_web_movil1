import { z } from 'zod';

export const crearInsumoSchema = z.object({
  nombre: z.string().min(2),
  /** Código de barras único por línea de producto (ej. Café 5kg). Opcional. */
  codigoBarras: z.string().max(64).optional().nullable(),
  categoria: z.string().min(2).max(64),
  unidad: z.string().min(1).max(32),
  cantidadActual: z.coerce.number().nonnegative().default(0),
  stockMinimo: z.coerce.number().nonnegative().default(0),
  stockMaximo: z.coerce.number().nonnegative().optional().nullable(),
  costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
  proveedor: z.string().max(120).optional().nullable(),
  activo: z.boolean().optional().default(true),
  /** Cuando la unidad es pieza: cuánto pesa o contiene cada pieza (ej. 5 para envase 5 kg). Opcional. */
  contenidoPorPieza: z.coerce.number().positive().optional().nullable(),
  /** Unidad del contenido por pieza (ej. "kg", "L"). Solo tiene sentido con contenidoPorPieza. */
  unidadContenido: z.string().max(16).optional().nullable()
});

export const actualizarInsumoSchema = z
  .object({
    nombre: z.string().min(2).optional(),
    codigoBarras: z.string().max(64).optional().nullable(),
    categoria: z.string().min(2).max(64).optional(),
    unidad: z.string().min(1).max(32).optional(),
    cantidadActual: z.coerce.number().nonnegative().optional(),
    stockMinimo: z.coerce.number().nonnegative().optional(),
    stockMaximo: z.coerce.number().nonnegative().optional().nullable(),
    costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
    proveedor: z.string().max(120).optional().nullable(),
    activo: z.boolean().optional(),
    contenidoPorPieza: z.coerce.number().positive().optional().nullable(),
    unidadContenido: z.string().max(16).optional().nullable()
  })
  .refine(
    (value) =>
      value.nombre !== undefined ||
      value.codigoBarras !== undefined ||
      value.categoria !== undefined ||
      value.unidad !== undefined ||
      value.cantidadActual !== undefined ||
      value.stockMinimo !== undefined ||
      value.stockMaximo !== undefined ||
      value.costoUnitario !== undefined ||
      value.proveedor !== undefined ||
      value.activo !== undefined ||
      value.contenidoPorPieza !== undefined ||
      value.unidadContenido !== undefined,
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

export const crearCategoriaInventarioSchema = z.object({
  nombre: z.string().min(2, 'Mínimo 2 caracteres').max(64).trim()
});

export type CrearInsumoInput = z.infer<typeof crearInsumoSchema>;
export type ActualizarInsumoInput = z.infer<typeof actualizarInsumoSchema>;
export type CrearMovimientoInput = z.infer<typeof crearMovimientoSchema>;
export type CrearCategoriaInventarioInput = z.infer<typeof crearCategoriaInventarioSchema>;

