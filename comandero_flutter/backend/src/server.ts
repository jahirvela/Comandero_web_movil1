import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { createServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import swaggerUi from 'swagger-ui-express';
import { apiRateLimiter } from './config/rate-limit.js';
import { corsOptions } from './config/cors.js';
import { getEnv } from './config/env.js';
import { logger } from './config/logger.js';
import { swaggerDocument } from './config/swagger.js';
import apiRouter from './routes/index.js';
import { errorHandler } from './middlewares/error-handler.js';
import { notFoundHandler } from './middlewares/not-found.js';
import { initRealtime } from './realtime/socket.js';
import { nowMxISO } from './config/time.js';
import { loadPrintersConfig } from './config/printers.config.js';

const env = getEnv();

// Cargar configuración de impresoras (archivo opcional) para que esté lista al primer uso
loadPrintersConfig()
  .then((printers) => {
    if (printers.length > 0) logger.info({ count: printers.length }, 'Impresoras cargadas');
  })
  .catch(() => {});

const app = express();
const httpServer = createServer(app);

// Configuración de Socket.IO optimizada para redes móviles
export const io = new SocketServer(httpServer, {
  cors: {
    origin: env.CORS_ORIGIN,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true
  },
  // Configuración para redes móviles (más tolerante a latencia y cortes)
  pingTimeout: 60000, // 60 segundos (más largo para móvil)
  pingInterval: 25000, // 25 segundos
  transports: ['websocket', 'polling'], // Permitir polling como fallback
  allowEIO3: true, // Compatibilidad con versiones anteriores
  // Timeouts más largos para conexiones móviles
  connectTimeout: 45000, // 45 segundos
  upgradeTimeout: 30000 // 30 segundos
});

initRealtime(io);

// Configuración de Helmet para producción (seguridad HTTP)
app.use(helmet({
  contentSecurityPolicy: env.NODE_ENV === 'production' ? {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  } : false, // Desactivar CSP en desarrollo para Swagger
  crossOriginEmbedderPolicy: false, // Necesario para Socket.IO
}));
app.use(cors(corsOptions));
app.use(express.json({ limit: '1mb' }));
app.use(apiRateLimiter);

app.get('/', (_req, res) => {
  res.json({
    name: 'Comandix API',
    version: '0.1.0',
    uptime: process.uptime(),
    timestamp: nowMxISO()
  });
});

app.use('/api', apiRouter);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.use(notFoundHandler);
app.use(errorHandler);

const port = env.PORT;

if (env.NODE_ENV !== 'test') {
  httpServer.listen(port, () => {
    logger.info(`Comandix API escuchando en http://0.0.0.0:${port}`);
    logger.info(`Swagger UI disponible en http://localhost:${port}/docs`);
  });

  // Cierre con Ctrl+C (SIGINT) o SIGTERM: cerrar servidor y Socket.IO para que el proceso termine
  const gracefulShutdown = (signal: string) => {
    logger.info({ signal }, 'Cerrando servidor...');
    httpServer.close(() => {
      logger.info('Servidor HTTP cerrado');
      io.close(() => {
        logger.info('Socket.IO cerrado');
        process.exit(0);
      });
    });
    // Si en 5 s no cerró, forzar salida (p. ej. si el terminal no envía bien la señal)
    setTimeout(() => {
      logger.warn('Forzando salida del proceso');
      process.exit(1);
    }, 5000);
  };
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

  // Manejo de errores al iniciar el servidor
  httpServer.on('error', (err: NodeJS.ErrnoException) => {
    if (err.code === 'EADDRINUSE') {
      logger.error(`❌ El puerto ${port} ya está en uso`);
      logger.error(`   Para liberar el puerto, ejecuta:`);
      logger.error(`   cd scripts && .\\liberar-puerto-3000.ps1`);
      logger.error(`   O cierra el proceso que está usando el puerto ${port}`);
      logger.error(`   Para ver qué proceso usa el puerto: netstat -ano | findstr :${port}`);
      process.exit(1);
    } else {
      logger.error({ err }, 'Error al iniciar el servidor');
      process.exit(1);
    }
  });
}

export { app, httpServer };

