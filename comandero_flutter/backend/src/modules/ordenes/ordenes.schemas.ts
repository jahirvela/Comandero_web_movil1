import { z } from 'zod';

export const ordenItemModificadorSchema = z.object({
  modificadorOpcionId: z.number().int().positive(),
  precioUnitario: z.coerce.number().nonnegative().optional().default(0)
});

export const ordenItemSchema = z.object({
  productoId: z.number().int().positive(),
  productoTamanoId: z.number().int().positive().optional().nullable(),
  cantidad: z.coerce.number().positive(),
  precioUnitario: z.coerce.number().positive(),
  nota: z.string().max(255).optional().nullable(),
  modificadores: z.array(ordenItemModificadorSchema).optional().default([])
});

export const crearOrdenSchema = z.object({
  mesaId: z.number().int().positive().optional().nullable(),
  reservaId: z.number().int().positive().optional().nullable(),
  clienteId: z.number().int().positive().optional().nullable(),
  clienteNombre: z.string().max(160).optional().nullable(),
  clienteTelefono: z.string().max(40).optional().nullable(),
  subtotal: z.coerce.number().nonnegative().optional(),
  descuentoTotal: z.coerce.number().nonnegative().optional().default(0),
  impuestoTotal: z.coerce.number().nonnegative().optional().default(0),
  propinaSugerida: z.coerce.number().nonnegative().optional().nullable(),
  estadoOrdenId: z.number().int().positive().optional(),
  items: z.array(ordenItemSchema).min(1),
  pickupTime: z.string().datetime().optional().nullable(),
  estimatedTime: z.coerce.number().int().positive().optional().nullable(),
});

export const actualizarOrdenSchema = z
  .object({
    mesaId: z.number().int().positive().optional().nullable(),
    reservaId: z.number().int().positive().optional().nullable(),
    clienteId: z.number().int().positive().optional().nullable(),
    clienteNombre: z.string().max(160).optional().nullable()
  })
  .refine(
    (value) =>
      value.mesaId !== undefined ||
      value.reservaId !== undefined ||
      value.clienteId !== undefined ||
      value.clienteNombre !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export const actualizarEstadoOrdenSchema = z.object({
  estadoOrdenId: z.number().int().positive(),
  /** Si es true, permite marcar como listo aunque falte stock (uso excepcional). */
  forzarSinStock: z.boolean().optional(),
});

export const agregarItemSchema = z.object({
  items: z.array(ordenItemSchema).min(1)
});

export type CrearOrdenInput = z.infer<typeof crearOrdenSchema>;
export type ActualizarOrdenInput = z.infer<typeof actualizarOrdenSchema>;
export type ActualizarEstadoOrdenInput = z.infer<typeof actualizarEstadoOrdenSchema>;
export type AgregarItemInput = z.infer<typeof agregarItemSchema>;
export type OrdenItemInput = z.infer<typeof ordenItemSchema>;

