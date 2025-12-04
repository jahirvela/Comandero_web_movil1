import { config as loadEnv } from 'dotenv';
import { z } from 'zod';

loadEnv();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_HOST: z.string().min(1),
  DATABASE_PORT: z.coerce.number().int().positive().default(3306),
  DATABASE_USER: z.string().min(1),
  DATABASE_PASSWORD: z.string().min(1),
  DATABASE_NAME: z.string().min(1),
  DATABASE_CONNECTION_LIMIT: z.coerce.number().int().positive().default(10),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.string().min(2),
  JWT_REFRESH_EXPIRES_IN: z.string().min(2),
  CORS_ORIGIN: z
    .string()
    .min(1)
    .transform((value) => value.split(',').map((item) => item.trim())),
  API_BASE_URL: z.string().url().optional(), // URL pública del API (para Swagger)
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(1000), // Aumentado para producción
  RATE_LIMIT_LOGIN_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_LOGIN_MAX: z.coerce.number().int().positive().default(5), // Más restrictivo para login
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  LOG_PRETTY: z.coerce.boolean().default(false), // Desactivado por defecto (mejor para producción)
  // Configuración de impresora térmica
  PRINTER_TYPE: z.enum(['pos80', 'simulation']).default('simulation'),
  PRINTER_INTERFACE: z.enum(['usb', 'tcp', 'file']).default('file'),
  PRINTER_HOST: z.string().optional(),
  PRINTER_PORT: z.coerce.number().int().positive().optional(),
  PRINTER_DEVICE: z.string().optional(), // Para USB: ruta del dispositivo
  PRINTER_SIMULATION_PATH: z.string().default('./tickets')
});

type Env = z.infer<typeof envSchema>;

let cachedEnv: Env | null = null;

export const getEnv = (): Env => {
  if (cachedEnv) return cachedEnv;

  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('Error al validar variables de entorno:', parsed.error.flatten().fieldErrors);
    throw new Error('Configuración de entorno inválida. Revisa el archivo .env');
  }

  cachedEnv = parsed.data;
  return cachedEnv;
};

