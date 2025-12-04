import rateLimit from 'express-rate-limit';
import { getEnv } from './env.js';

const env = getEnv();

// Configuración de rate limiting para producción
// En desarrollo: límites muy permisivos para pruebas
// En producción: usar valores del .env o defaults seguros
const isDevelopment = env.NODE_ENV === 'development';

// API general: límites según entorno
// Desarrollo: muy permisivo (10000/min)
// Producción: usar valor del .env o mínimo 1000/min (suficiente para uso normal)
const maxRequests = isDevelopment 
  ? 10000 
  : Math.max(env.RATE_LIMIT_MAX, 1000); // Mínimo 1000 en producción
const windowMs = isDevelopment ? 60000 : env.RATE_LIMIT_WINDOW_MS; // 1 minuto

export const apiRateLimiter = rateLimit({
  windowMs: windowMs,
  max: maxRequests,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'rate_limit_exceeded',
    message: 'Demasiadas solicitudes desde esta IP. Inténtalo más tarde.'
  }
});

// Rate limiter para login - más restrictivo para seguridad
// Desarrollo: permisivo (1000/min)
// Producción: usar valor del .env o mínimo 5/min (protección contra fuerza bruta)
const loginMaxRequests = isDevelopment 
  ? 1000 
  : Math.max(env.RATE_LIMIT_LOGIN_MAX, 5); // Mínimo 5 en producción
export const loginRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_LOGIN_WINDOW_MS,
  max: loginMaxRequests,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // No contar intentos exitosos
  message: {
    error: 'rate_limit_exceeded',
    message: 'Demasiados intentos de inicio de sesión. Inténtalo más tarde.'
  }
});

