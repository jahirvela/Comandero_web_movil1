import { z } from 'zod';

export const crearMesaSchema = z.object({
  codigo: z.string().min(1),
  nombre: z.string().min(1).optional().nullable(),
  capacidad: z.number().int().positive().max(500).optional().nullable(),
  ubicacion: z.string().max(120).optional().nullable(),
  estadoMesaId: z.number().int().positive().optional().nullable(),
  activo: z.boolean().optional().default(true)
});

export const actualizarMesaSchema = z
  .object({
    codigo: z.string().min(1).optional(),
    nombre: z.string().min(1).optional().nullable(),
    capacidad: z.number().int().positive().max(500).optional().nullable(),
    ubicacion: z.string().max(120).optional().nullable(),
    estadoMesaId: z.number().int().positive().optional().nullable(),
    activo: z.boolean().optional()
  })
  .refine(
    (value) =>
      value.codigo !== undefined ||
      value.nombre !== undefined ||
      value.capacidad !== undefined ||
      value.ubicacion !== undefined ||
      value.estadoMesaId !== undefined ||
      value.activo !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export const cambiarEstadoMesaSchema = z.object({
  estadoMesaId: z.number().int().positive(),
  nota: z.string().max(255).optional().nullable()
});

export type CrearMesaInput = z.infer<typeof crearMesaSchema>;
export type ActualizarMesaInput = z.infer<typeof actualizarMesaSchema>;
export type CambiarEstadoMesaInput = z.infer<typeof cambiarEstadoMesaSchema>;

