/**
 * Script para asegurar columnas de la tabla alerta (metadata, leido_por_usuario_id, leido_en).
 * Ejecuta la migración para soporte de prioridad en alertas y marcar como leídas.
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';

config();

async function columnExists(connection: mysql.Connection, db: string, col: string): Promise<boolean> {
  const [rows]: any = await connection.execute(
    `SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'alerta' AND COLUMN_NAME = ?`,
    [db, col]
  );
  return rows.length > 0;
}

async function agregarMetadataColumna() {
  let connection: mysql.Connection | null = null;

  try {
    const dbConfig = {
      host: process.env.DATABASE_HOST || 'localhost',
      port: Number(process.env.DATABASE_PORT) || 3306,
      user: process.env.DATABASE_USER || 'root',
      password: process.env.DATABASE_PASSWORD || '',
      database: process.env.DATABASE_NAME || 'comandero',
    };

    console.log('🔌 Conectando a la base de datos...');
    console.log(`   Host: ${dbConfig.host}`);
    console.log(`   Database: ${dbConfig.database}`);
    console.log(`   User: ${dbConfig.user}`);

    connection = await mysql.createConnection(dbConfig);
    const db = dbConfig.database;

    // 1) Columna metadata (prioridad, estación, etc.)
    console.log('\n🔍 Tabla alerta: verificando columna metadata...');
    if (await columnExists(connection, db, 'metadata')) {
      console.log('✅ La columna metadata ya existe.');
    } else {
      console.log('📝 Agregando columna metadata...');
      await connection.execute(`
        ALTER TABLE alerta
        ADD COLUMN metadata JSON NULL
        COMMENT 'Metadata adicional (prioridad, estación, etc.)'
        AFTER creado_en
      `);
      console.log('✅ Columna metadata agregada.');
    }

    // 2) Columna leido_por_usuario_id (marcar alerta leída)
    console.log('\n🔍 Tabla alerta: verificando columna leido_por_usuario_id...');
    if (await columnExists(connection, db, 'leido_por_usuario_id')) {
      console.log('✅ La columna leido_por_usuario_id ya existe.');
    } else {
      console.log('📝 Agregando columna leido_por_usuario_id...');
      await connection.execute(`
        ALTER TABLE alerta
        ADD COLUMN leido_por_usuario_id BIGINT UNSIGNED NULL
        COMMENT 'Usuario que marcó la alerta como leída'
        AFTER leida
      `);
      console.log('✅ Columna leido_por_usuario_id agregada.');
    }

    // 3) Columna leido_en (fecha de lectura)
    console.log('\n🔍 Tabla alerta: verificando columna leido_en...');
    if (await columnExists(connection, db, 'leido_en')) {
      console.log('✅ La columna leido_en ya existe.');
    } else {
      console.log('📝 Agregando columna leido_en...');
      await connection.execute(`
        ALTER TABLE alerta
        ADD COLUMN leido_en TIMESTAMP NULL
        COMMENT 'Fecha/hora en que se marcó como leída'
        AFTER leido_por_usuario_id
      `);
      console.log('✅ Columna leido_en agregada.');
    }

    console.log('\n🎉 Migración de tabla alerta completada.');
    console.log('   Columnas necesarias para alertas (prioridad y marcar leídas) están listas.');

  } catch (error: any) {
    console.error('\n❌ Error al ejecutar la migración:');
    if (error.code === 'ER_DUP_FIELDNAME') {
      console.error('   Una de las columnas ya existe en la tabla alerta.');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('   Error de acceso: Verifica las credenciales de la base de datos.');
    } else if (error.code === 'ECONNREFUSED') {
      console.error('   No se pudo conectar: Verifica que MySQL esté ejecutándose.');
    } else {
      console.error(`   ${error.message}`);
      console.error(`   Código: ${error.code}`);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión cerrada');
    }
  }
}

// Ejecutar la migración
agregarMetadataColumna()
  .then(() => {
    console.log('\n✅ Script finalizado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error fatal:', error);
    process.exit(1);
  });

