import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { logger } from '../config/logger.js';
import { getEnv } from '../config/env.js';

interface ApiError extends Error {
  status?: number;
  details?: unknown;
}

export const errorHandler = (err: ApiError, _req: Request, res: Response, _next: NextFunction) => {
  const status = err.status ?? 500;
  const isZodError = err instanceof ZodError;
  const env = getEnv();
  const isProduction = env.NODE_ENV === 'production';

  if (isZodError) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Datos de entrada inválidos',
      details: err.flatten()
    });
  }

  // Manejar errores de MySQL específicos
  if ((err as any).code === 'ER_DUP_ENTRY') {
    const mysqlError = err as any;
    const message = err.message || 'Ya existe un registro con estos datos';
    
    logger.warn({ err: mysqlError }, 'Intento de crear registro duplicado');
    
    return res.status(409).json({
      error: 'duplicate_entry',
      message: message.includes('ux_producto_categoria_nombre') 
        ? 'Ya existe un producto con este nombre en esta categoría'
        : message.includes('ux_mesa_codigo')
          ? 'Ya existe una mesa con ese número'
          : message
    });
  }

  // Manejar errores de FK (registro referenciado) - por ejemplo al borrar usuario con historial
  if ((err as any).code === 'ER_ROW_IS_REFERENCED_2' ||
      (typeof err.message === 'string' && err.message.includes('foreign key constraint fails'))) {
    const mysqlError = err as any;
    logger.warn({ err: mysqlError }, 'Intento de eliminar registro con referencias');

    const rawMessage = err.message || 'No se puede eliminar porque existen registros relacionados';
    const isUsuarioMesaHist = rawMessage.includes('mesa_estado_hist') || rawMessage.includes('fk_meh_usuario');

    return res.status(409).json({
      error: 'reference_constraint',
      message: isUsuarioMesaHist
        ? 'No se puede eliminar este usuario porque está referenciado en el historial de mesas. Puedes desactivarlo (activo=0) en lugar de eliminarlo permanentemente.'
        : 'No se puede eliminar este registro porque tiene información relacionada en el sistema.'
    });
  }

  // Manejar errores de tabla no encontrada
  if ((err as any).code === 'ER_NO_SUCH_TABLE' || err.message?.includes("doesn't exist")) {
    const mysqlError = err as any;
    const tableMatch = err.message?.match(/Table ['`]([^'`]+)['`]/);
    const tableName = tableMatch ? tableMatch[1] : 'desconocida';
    
    logger.error({ err: mysqlError, tableName }, 'Tabla no encontrada en la base de datos');
    
    return res.status(500).json({
      error: 'database_error',
      message: `La tabla '${tableName}' no existe en la base de datos. ` +
               `Verifica que las migraciones se hayan ejecutado correctamente. ` +
               `Revisa la configuración de la base de datos en el archivo .env`,
      details: isProduction ? undefined : {
        table: tableName,
        database: env.DATABASE_NAME,
        originalError: err.message
      }
    });
  }

  // En producción, no exponer detalles del error
  if (isProduction) {
    logger.error({ err: { name: err.name, message: err.message, status } }, 'Error no controlado');
    
    return res.status(status).json({
      error: status >= 500 ? 'internal_error' : err.name || 'error',
      message: status >= 500 
        ? 'Ocurrió un error en el servidor. Por favor, intenta más tarde.' 
        : err.message || 'Ocurrió un error'
    });
  }

  // En desarrollo, mostrar más detalles
  logger.error({ err }, 'Error no controlado');

  return res.status(status).json({
    error: err.name || 'internal_error',
    message: err.message || 'Ocurrió un error inesperado',
    ...(err.details && { details: err.details }),
    ...(err.stack && { stack: err.stack })
  });
};

