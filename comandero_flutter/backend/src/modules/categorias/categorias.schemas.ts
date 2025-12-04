import { z } from 'zod';

export const crearCategoriaSchema = z.object({
  nombre: z.string().min(2),
  descripcion: z.string().max(255).optional().nullable(),
  activo: z.boolean().optional().default(true)
});

export const actualizarCategoriaSchema = z
  .object({
    nombre: z.string().min(2).optional(),
    descripcion: z.string().max(255).optional().nullable(),
    activo: z.boolean().optional()
  })
  .refine(
    (value) =>
      value.nombre !== undefined ||
      value.descripcion !== undefined ||
      value.activo !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export type CrearCategoriaInput = z.infer<typeof crearCategoriaSchema>;
export type ActualizarCategoriaInput = z.infer<typeof actualizarCategoriaSchema>;

