import { z } from 'zod';

const cajonTipoConexionSchema = z.enum(['via_impresora', 'red', 'usb']);

export const actualizarConfiguracionCajonSchema = z.object({
  habilitado: z.boolean().optional(),
  impresoraId: z.number().int().positive().nullable().optional(),
  abrirEnEfectivo: z.boolean().optional(),
  abrirEnTarjeta: z.boolean().optional(),
  tipoConexion: cajonTipoConexionSchema.optional(),
  marca: z.string().max(80).nullable().optional(),
  modelo: z.string().max(80).nullable().optional(),
  host: z.string().max(255).nullable().optional(),
  port: z.number().int().min(1).max(65535).nullable().optional(),
  device: z.string().max(255).nullable().optional(),
});

export const actualizarConfiguracionSchema = z.object({
  ivaHabilitado: z.boolean().optional(),
  cajon: actualizarConfiguracionCajonSchema.optional(),
});

export type ActualizarConfiguracionBody = z.infer<typeof actualizarConfiguracionSchema>;
export type ActualizarConfiguracionCajonBody = z.infer<typeof actualizarConfiguracionCajonSchema>;
