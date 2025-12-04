import { z } from 'zod';

export const loginSchema = z.object({
  username: z.string().min(3, 'El usuario es obligatorio'),
  password: z.string().min(4, 'La contraseña es obligatoria')
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(10, 'El token es obligatorio')
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;

