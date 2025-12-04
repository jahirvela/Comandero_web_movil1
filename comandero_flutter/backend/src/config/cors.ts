import type { CorsOptions } from 'cors';
import { getEnv } from './env.js';

const env = getEnv();

// Función para verificar si el origen está permitido
const originChecker = (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
  // Permitir requests sin origen (mismo origen, Postman, etc.)
  if (!origin) {
    return callback(null, true);
  }

  // Verificar si el origen está en la lista permitida
  const allowedOrigins = env.CORS_ORIGIN;
  
  // Si hay wildcard, permitir cualquier localhost
  const isLocalhostWildcard = allowedOrigins.some(originPattern => 
    originPattern.includes('localhost:*') || originPattern.includes('127.0.0.1:*')
  );
  
  if (isLocalhostWildcard) {
    // Permitir cualquier puerto de localhost
    if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
      return callback(null, true);
    }
  }

  // Verificar coincidencia exacta
  if (allowedOrigins.includes(origin)) {
    return callback(null, true);
  }

  // Por defecto, denegar
  callback(null, false);
};

export const corsOptions: CorsOptions = {
  origin: originChecker,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 204,
  preflightContinue: false,
};

