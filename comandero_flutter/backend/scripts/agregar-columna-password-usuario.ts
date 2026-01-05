import mysql from 'mysql2/promise';
import { config } from 'dotenv';

config();

async function agregarPasswordColumna() {
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
    console.log('\n🔍 Verificando si la columna password ya existe...');
    const [columns]: any = await connection.execute(`
      SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'usuario'
        AND COLUMN_NAME = 'password'
    `, [dbConfig.database]);

    if (columns.length > 0) {
      console.log('✅ La columna password ya existe en la tabla usuario');
      console.log(`   Tipo: ${columns[0].COLUMN_TYPE}`);
      console.log(`   Nullable: ${columns[0].IS_NULLABLE}`);
      console.log(`   Comentario: ${columns[0].COLUMN_COMMENT || '(sin comentario)'}`);
      return;
    }

    // Agregar la columna
    console.log('\n📝 Agregando columna password a la tabla usuario...');
    await connection.execute(`
      ALTER TABLE usuario
      ADD COLUMN password VARCHAR(255) NULL
      COMMENT 'Contraseña en texto plano (solo para visualización del administrador)'
      AFTER password_hash
    `);

    console.log('✅ Columna password agregada exitosamente');

    // Verificar que se agregó correctamente
    console.log('\n🔍 Verificando la nueva columna...');
    const [newColumns]: any = await connection.execute(`
      SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = 'usuario'
        AND COLUMN_NAME = 'password'
    `, [dbConfig.database]);

    if (newColumns.length > 0) {
      console.log('✅ Verificación exitosa:');
      console.log(`   Columna: ${newColumns[0].COLUMN_NAME}`);
      console.log(`   Tipo: ${newColumns[0].COLUMN_TYPE}`);
      console.log(`   Nullable: ${newColumns[0].IS_NULLABLE}`);
      console.log(`   Comentario: ${newColumns[0].COLUMN_COMMENT || '(sin comentario)'}`);
    }

    console.log('\n✅ Script completado exitosamente');
  } catch (error: any) {
    console.error('❌ Error al agregar columna password:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

agregarPasswordColumna();

