/**
 * Script para agregar campos de estado a la tabla caja_cierre
 * Ejecutar: node scripts/add-estado-cierre-caja.cjs
 */

require('dotenv').config();
const mysql = require('mysql2/promise');

// Usar las mismas variables de entorno que el backend
const config = {
  host: process.env.DATABASE_HOST || process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || process.env.DB_PORT || '3306', 10),
  user: process.env.DATABASE_USER || process.env.DB_USER || 'root',
  password: process.env.DATABASE_PASSWORD || process.env.DB_PASSWORD || '',
  database: process.env.DATABASE_NAME || process.env.DB_NAME || 'comandero',
  multipleStatements: true,
};

console.log('📋 Configuración de conexión:');
console.log(`   Host: ${config.host}`);
console.log(`   Port: ${config.port}`);
console.log(`   Database: ${config.database}`);
console.log(`   User: ${config.user}`);

async function agregarCamposEstado() {
  let connection;
  
  try {
    console.log('🔌 Conectando a la base de datos...');
    connection = await mysql.createConnection(config);
    console.log('✅ Conectado a la base de datos');

    console.log('\n📝 Agregando campos de estado a caja_cierre...');
    
    // Agregar campo estado
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD COLUMN estado VARCHAR(20) NOT NULL DEFAULT 'pending'
        COMMENT 'Estado del cierre: pending, approved, rejected, clarification'
        AFTER notas
      `);
      console.log('✅ Campo "estado" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('⚠️  Campo "estado" ya existe');
      } else {
        throw error;
      }
    }

    // Agregar campo revisado_por_usuario_id
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD COLUMN revisado_por_usuario_id BIGINT UNSIGNED NULL
        COMMENT 'Usuario que revisó el cierre'
        AFTER estado
      `);
      console.log('✅ Campo "revisado_por_usuario_id" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('⚠️  Campo "revisado_por_usuario_id" ya existe');
      } else {
        throw error;
      }
    }

    // Agregar índice si no existe
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD INDEX ix_caja_revisado_por (revisado_por_usuario_id)
      `);
      console.log('✅ Índice "ix_caja_revisado_por" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_KEYNAME') {
        console.log('⚠️  Índice "ix_caja_revisado_por" ya existe');
      } else {
        throw error;
      }
    }

    // Agregar foreign key si no existe
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD CONSTRAINT fk_caja_revisado_por 
        FOREIGN KEY (revisado_por_usuario_id) 
        REFERENCES usuario(id) 
        ON UPDATE CASCADE
        ON DELETE SET NULL
      `);
      console.log('✅ Foreign key "fk_caja_revisado_por" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_KEY' || error.code === 'ER_DUP_KEYNAME') {
        console.log('⚠️  Foreign key "fk_caja_revisado_por" ya existe');
      } else {
        throw error;
      }
    }

    // Agregar campo revisado_en
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD COLUMN revisado_en TIMESTAMP NULL
        COMMENT 'Fecha y hora en que se revisó el cierre'
        AFTER revisado_por_usuario_id
      `);
      console.log('✅ Campo "revisado_en" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('⚠️  Campo "revisado_en" ya existe');
      } else {
        throw error;
      }
    }

    // Agregar campo comentario_revision
    try {
      await connection.execute(`
        ALTER TABLE caja_cierre
        ADD COLUMN comentario_revision TEXT NULL
        COMMENT 'Comentario del administrador al revisar (para rechazos o aclaraciones)'
        AFTER revisado_en
      `);
      console.log('✅ Campo "comentario_revision" agregado');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('⚠️  Campo "comentario_revision" ya existe');
      } else {
        throw error;
      }
    }

    // Actualizar cierres existentes que no tienen estado
    await connection.execute(`
      UPDATE caja_cierre
      SET estado = 'pending'
      WHERE estado IS NULL OR estado = ''
    `);
    console.log('✅ Estados de cierres existentes actualizados a "pending"');

    console.log('\n✅ Migración completada exitosamente');
    
  } catch (error) {
    console.error('\n❌ Error durante la migración:', error);
    throw error;
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión cerrada');
    }
  }
}

// Ejecutar la migración
agregarCamposEstado()
  .then(() => {
    console.log('\n✅ Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error fatal:', error);
    process.exit(1);
  });
