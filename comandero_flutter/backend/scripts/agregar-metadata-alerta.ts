/**
 * Script para agregar la columna metadata a la tabla alerta
 * Ejecuta la migración SQL para agregar soporte de prioridad en alertas
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';

config();

async function agregarMetadataColumna() {
  let connection: mysql.Connection | null = null;

  try {
    // Obtener configuración de la base de datos desde variables de entorno
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

    // Verificar si la columna ya existe
    console.log('\n🔍 Verificando si la columna metadata ya existe...');
    const [columns]: any = await connection.execute(`
      SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'alerta'
        AND COLUMN_NAME = 'metadata'
    `, [dbConfig.database]);

    if (columns.length > 0) {
      console.log('✅ La columna metadata ya existe en la tabla alerta');
      console.log(`   Tipo: ${columns[0].COLUMN_TYPE}`);
      console.log(`   Nullable: ${columns[0].IS_NULLABLE}`);
      console.log(`   Comentario: ${columns[0].COLUMN_COMMENT || '(sin comentario)'}`);
      return;
    }

    // Agregar la columna
    console.log('\n📝 Agregando columna metadata a la tabla alerta...');
    await connection.execute(`
      ALTER TABLE alerta
      ADD COLUMN metadata JSON NULL
      COMMENT 'Metadata adicional de la alerta (prioridad, estación, etc.)'
      AFTER creado_en
    `);

    console.log('✅ Columna metadata agregada exitosamente');

    // Verificar que se agregó correctamente
    console.log('\n🔍 Verificando la nueva columna...');
    const [newColumns]: any = await connection.execute(`
      SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'alerta'
        AND COLUMN_NAME = 'metadata'
    `, [dbConfig.database]);

    if (newColumns.length > 0) {
      console.log('✅ Verificación exitosa:');
      console.log(`   Nombre: ${newColumns[0].COLUMN_NAME}`);
      console.log(`   Tipo: ${newColumns[0].COLUMN_TYPE}`);
      console.log(`   Nullable: ${newColumns[0].IS_NULLABLE}`);
      console.log(`   Comentario: ${newColumns[0].COLUMN_COMMENT || '(sin comentario)'}`);
    }

    console.log('\n🎉 Migración completada exitosamente');
    console.log('   La tabla alerta ahora soporta metadata JSON para guardar prioridad y otros datos adicionales.');

  } catch (error: any) {
    console.error('\n❌ Error al ejecutar la migración:');
    if (error.code === 'ER_DUP_FIELDNAME') {
      console.error('   La columna metadata ya existe en la tabla alerta.');
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

