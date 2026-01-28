import { z } from 'zod';

export const imprimirComandaSchema = z.object({
  ordenId: z.number().int().positive(),
  esReimpresion: z.boolean().optional().default(false)
});

export type ImprimirComandaInput = z.infer<typeof imprimirComandaSchema>;

