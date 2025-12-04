import { z } from 'zod';

export const usuarioBaseSchema = z.object({
  nombre: z.string().min(3),
  username: z.string().min(3),
  telefono: z.string().min(3).max(40).optional().nullable(),
  activo: z.boolean().optional().default(true),
  roles: z.array(z.number().int().positive()).optional().default([])
});

export const crearUsuarioSchema = usuarioBaseSchema.extend({
  password: z.string().min(6)
});

export const actualizarUsuarioSchema = z
  .object({
    nombre: z.string().min(3).optional(),
    telefono: z.string().min(3).max(40).optional().nullable(),
    activo: z.boolean().optional(),
    password: z.string().min(6).optional(),
    roles: z.array(z.number().int().positive()).optional()
  })
  .refine(
    (value) =>
      value.nombre !== undefined ||
      value.telefono !== undefined ||
      value.activo !== undefined ||
      value.password !== undefined ||
      value.roles !== undefined,
    {
      message: 'Debe proporcionar al menos un campo para actualizar'
    }
  );

export const asignarRolesSchema = z.object({
  roles: z.array(z.number().int().positive())
});

export type CrearUsuarioInput = z.infer<typeof crearUsuarioSchema>;
export type ActualizarUsuarioInput = z.infer<typeof actualizarUsuarioSchema>;
export type AsignarRolesInput = z.infer<typeof asignarRolesSchema>;

