import { z } from 'zod';

export const lineaFormulacionSchema = z.object({
  componenteInventarioItemId: z.number().int().positive(),
  cantidad: z.coerce.number().positive(),
  unidad: z
    .string()
    .min(1)
    .max(32)
    .transform((s) => s.trim())
});

export const crearInsumoSchema = z
  .object({
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
    /** Unidad del contenido por pieza (ej. "kg", "L", "Piezas"). Solo tiene sentido con contenidoPorPieza. */
    unidadContenido: z.string().max(16).optional().nullable(),
    /** Producto compuesto con lista de materiales (BOM). Requiere al menos una línea si es true. */
    esFormulado: z.boolean().optional().default(false),
    lineasFormulacion: z.array(lineaFormulacionSchema).optional().default([])
  })
  .refine(
    (v) =>
      !v.esFormulado ||
      (Array.isArray(v.lineasFormulacion) && v.lineasFormulacion.length > 0),
    {
      message: 'Un producto formulado debe tener al menos una línea de formulación',
      path: ['lineasFormulacion']
    }
  )
  .refine(
    (v) =>
      v.esFormulado ||
      !v.lineasFormulacion ||
      v.lineasFormulacion.length === 0,
    {
      message: 'Solo los productos formulados pueden tener líneas de formulación',
      path: ['lineasFormulacion']
    }
  );

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
    unidadContenido: z.string().max(16).optional().nullable(),
    esFormulado: z.boolean().optional(),
    lineasFormulacion: z.array(lineaFormulacionSchema).optional()
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
      value.unidadContenido !== undefined ||
      value.esFormulado !== undefined ||
      value.lineasFormulacion !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  )
  .refine(
    (value) =>
      !(
        value.esFormulado === true &&
        value.lineasFormulacion !== undefined &&
        value.lineasFormulacion.length === 0
      ),
    {
      message:
        'No puedes marcar como formulado y enviar la lista de componentes vacía; use false o omita lineasFormulacion',
      path: ['lineasFormulacion']
    }
  );

export const crearMovimientoSchema = z
  .object({
    inventarioItemId: z.number().int().positive(),
    tipo: z.enum(['entrada', 'salida', 'ajuste']),
    cantidad: z.coerce.number().nonnegative(),
    costoUnitario: z.coerce.number().nonnegative().optional().nullable(),
    motivo: z.string().max(160).optional().nullable(),
    origen: z.enum(['compra', 'consumo', 'ajuste', 'devolucion']).optional().nullable(),
    referenciaOrdenId: z.number().int().positive().optional().nullable()
  })
  .superRefine((data, ctx) => {
    if (data.tipo === 'ajuste') return;
    if (data.cantidad <= 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'La cantidad debe ser mayor a 0 para entrada o salida',
        path: ['cantidad']
      });
    }
  });

export const crearCategoriaInventarioSchema = z.object({
  nombre: z.string().min(2, 'Mínimo 2 caracteres').max(64).trim()
});

export const renombrarCategoriaInventarioSchema = z.object({
  nuevoNombre: z.string().min(2, 'Mínimo 2 caracteres').max(64).trim()
});

export type CrearInsumoInput = z.infer<typeof crearInsumoSchema>;
export type ActualizarInsumoInput = z.infer<typeof actualizarInsumoSchema>;
export type CrearMovimientoInput = z.infer<typeof crearMovimientoSchema>;
export type CrearCategoriaInventarioInput = z.infer<typeof crearCategoriaInventarioSchema>;

