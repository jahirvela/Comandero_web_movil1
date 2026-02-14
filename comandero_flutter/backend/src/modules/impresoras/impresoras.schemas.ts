import { z } from 'zod';

const tipoImpresora = z.enum(['usb', 'tcp', 'bluetooth', 'simulation']);
const paperWidth = z.union([z.literal(57), z.literal(58), z.literal(72), z.literal(80)]);

export const crearImpresoraSchema = z.object({
  nombre: z.string().min(1).max(100),
  tipo: tipoImpresora,
  device: z.string().max(255).nullable().optional(),
  host: z.string().max(255).nullable().optional(),
  port: z.number().int().min(1).max(65535).nullable().optional(),
  paperWidth: paperWidth.optional().default(80),
  imprimeTicket: z.boolean().optional().default(true),
  imprimeComanda: z.boolean().optional().default(false),
  orden: z.number().int().optional().default(0),
  marcaModelo: z.string().max(120).nullable().optional(),
});

export const actualizarImpresoraSchema = z.object({
  nombre: z.string().min(1).max(100).optional(),
  tipo: tipoImpresora.optional(),
  device: z.string().max(255).nullable().optional(),
  host: z.string().max(255).nullable().optional(),
  port: z.number().int().min(1).max(65535).nullable().optional(),
  paperWidth: paperWidth.optional(),
  imprimeTicket: z.boolean().optional(),
  imprimeComanda: z.boolean().optional(),
  orden: z.number().int().optional(),
  activo: z.boolean().optional(),
  marcaModelo: z.string().max(120).nullable().optional(),
});

export type CrearImpresoraBody = z.infer<typeof crearImpresoraSchema>;
export type ActualizarImpresoraBody = z.infer<typeof actualizarImpresoraSchema>;
