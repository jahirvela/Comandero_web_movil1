import mysql from 'mysql2/promise';
import type { ResultSetHeader } from 'mysql2';
import { getEnv } from '../config/env.js';
import { logger } from '../config/logger.js';

const env = getEnv();

const rawPool = mysql.createPool({
  host: env.DATABASE_HOST,
  port: env.DATABASE_PORT,
  user: env.DATABASE_USER,
  password: env.DATABASE_PASSWORD,
  database: env.DATABASE_NAME,
  connectionLimit: env.DATABASE_CONNECTION_LIMIT,
  namedPlaceholders: true,
  dateStrings: false,
  timezone: 'Z', // Leer fechas de MySQL como UTC (coherente con session time_zone UTC)
  connectTimeout: 60000,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
});

const UTC_SESSION = "SET time_zone = '+00:00'";

const RETRYABLE_DB_ERRORS = new Set([
  'ECONNRESET',
  'PROTOCOL_CONNECTION_LOST',
  'ETIMEDOUT',
  'EPIPE',
]);

const isReadOnlySql = (sql: string): boolean => {
  const normalized = sql.trim().toLowerCase();
  return (
    normalized.startsWith('select') ||
    normalized.startsWith('show') ||
    normalized.startsWith('describe') ||
    normalized.startsWith('explain')
  );
};

/**
 * Pool que fuerza cada conexión a usar UTC.
 * Así NOW() y CURRENT_TIMESTAMP en MySQL guardan hora UTC y la hora se muestra
 * correctamente en la app (backend convierte UTC → America/Mexico_City).
 */
export const pool = {
  getConnection: async (): Promise<mysql.PoolConnection> => {
    const conn = await rawPool.getConnection();
    try {
      await conn.query(UTC_SESSION);
    } catch (e) {
      conn.release();
      throw e;
    }
    return conn;
  },
  query: async <T extends mysql.RowDataPacket[] | ResultSetHeader>(
    sql: string,
    values?: any
  ): Promise<[T, mysql.FieldPacket[]]> => {
    const run = async (): Promise<[T, mysql.FieldPacket[]]> => {
      const conn = await rawPool.getConnection();
      try {
        await conn.query(UTC_SESSION);
        return conn.query(sql, values) as Promise<[T, mysql.FieldPacket[]]>;
      } finally {
        conn.release();
      }
    };
    try {
      return await run();
    } catch (error: any) {
      const canRetry =
        isReadOnlySql(sql) && RETRYABLE_DB_ERRORS.has(String(error?.code ?? ''));
      if (!canRetry) throw error;
      logger.warn({ err: error, code: error?.code }, 'Reintentando query de lectura por error transitorio de conexión MySQL');
      return run();
    }
  },
  execute: async <T extends mysql.RowDataPacket[] | ResultSetHeader>(
    sql: string,
    values?: any
  ): Promise<[T, mysql.FieldPacket[]]> => {
    const conn = await rawPool.getConnection();
    try {
      await conn.query(UTC_SESSION);
      return conn.execute(sql, values) as Promise<[T, mysql.FieldPacket[]]>;
    } finally {
      conn.release();
    }
  },
  /** Cierra el pool (p. ej. scripts one-shot). */
  end: () => rawPool.end()
};

// Intentar conectar con reintentos
const testConnection = async (retries = 3, delay = 2000) => {
  for (let i = 0; i < retries; i++) {
    try {
      const conn = await pool.getConnection();
      conn.release();
      logger.info('Conexión MySQL inicial establecida correctamente');
      return;
    } catch (error: any) {
      logger.warn(
        {
          err: error,
          attempt: i + 1,
          maxRetries: retries,
        },
        `Intento ${i + 1} de conexión a MySQL falló`
      );
      
      if (i < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        const errorMessage = error?.message || 'Error desconocido';
        const errorCode = error?.code || 'UNKNOWN';
        
        logger.error(
          {
            err: error,
            errorCode,
            errorMessage,
            host: env.DATABASE_HOST,
            port: env.DATABASE_PORT,
            database: env.DATABASE_NAME,
            user: env.DATABASE_USER,
          },
          `Error al establecer la conexión inicial con MySQL después de ${retries} reintentos.`
        );
        
        // Mensaje más específico según el tipo de error
        if (errorCode === 'ETIMEDOUT' || errorCode === 'ECONNREFUSED') {
          const esLocal =
            env.DATABASE_HOST === '127.0.0.1' ||
            env.DATABASE_HOST === 'localhost';
          logger.error(
            {
              host: env.DATABASE_HOST,
              port: env.DATABASE_PORT,
            },
            esLocal
              ? `No hay MySQL escuchando en ${env.DATABASE_HOST}:${env.DATABASE_PORT}. Inicia MySQL/XAMPP en esta PC, o en backend/.env usa los datos de tu servidor (p. ej. copia DATABASE_* desde .env.remote).`
              : `No se pudo conectar a MySQL en ${env.DATABASE_HOST}:${env.DATABASE_PORT}. Comprueba red, firewall del servidor y que MySQL acepte conexiones remotas.`
          );
        } else if (errorCode === 'ER_ACCESS_DENIED_ERROR' || errorCode === 'ER_NOT_SUPPORTED_AUTH_MODE') {
          logger.error(
            {
              user: env.DATABASE_USER,
            },
            `Error de autenticación. Verifica que el usuario '${env.DATABASE_USER}' y la contraseña sean correctos.`
          );
        } else if (errorCode === 'ER_BAD_DB_ERROR') {
          logger.error(
            {
              database: env.DATABASE_NAME,
            },
            `La base de datos '${env.DATABASE_NAME}' no existe. Verifica que la base de datos esté creada.`
          );
        }
      }
    }
  }
};

const dropCategoriaUniqueIndex = async () => {
  try {
    const [rows] = await pool.query<mysql.RowDataPacket[]>(
      `
      SELECT INDEX_NAME
      FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'categoria'
        AND NON_UNIQUE = 0
        AND INDEX_NAME <> 'PRIMARY'
      `
    );

    for (const row of rows) {
      const indexName = row.INDEX_NAME as string;
      await pool.query(`DROP INDEX \`${indexName}\` ON categoria`);
      logger.info({ indexName }, 'Índice UNIQUE eliminado de categoria');
    }
  } catch (error) {
    logger.warn({ err: error }, 'No se pudo eliminar índice UNIQUE de categoria');
  }
};

const initPool = async () => {
  await testConnection();
  await dropCategoriaUniqueIndex();
};

initPool();

export const withTransaction = async <T>(fn: (connection: mysql.PoolConnection) => Promise<T>) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const result = await fn(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

