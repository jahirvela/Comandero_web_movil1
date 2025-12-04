import { z } from 'zod';

export const rolBaseSchema = z.object({
  nombre: z.string().min(3),
  descripcion: z.string().max(255).optional().nullable(),
  permisos: z.array(z.number().int().positive()).optional().default([])
});

export const crearRolSchema = rolBaseSchema;

export const actualizarRolSchema = z
  .object({
    nombre: z.string().min(3).optional(),
    descripcion: z.string().max(255).optional().nullable(),
    permisos: z.array(z.number().int().positive()).optional()
  })
  .refine(
    (value) =>
      value.nombre !== undefined ||
      value.descripcion !== undefined ||
      value.permisos !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export type CrearRolInput = z.infer<typeof crearRolSchema>;
export type ActualizarRolInput = z.infer<typeof actualizarRolSchema>;

