import { z } from 'zod';

export const imprimirTicketSchema = z.object({
  ordenId: z.coerce.number().int().positive(),
  ordenIds: z.array(z.coerce.number().int().positive()).optional(), // Para cuentas agrupadas
  incluirCodigoBarras: z.boolean().optional().default(true)
});

export type ImprimirTicketInput = z.infer<typeof imprimirTicketSchema>;

