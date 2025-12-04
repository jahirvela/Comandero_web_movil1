#!/usr/bin/env node

/**
 * Script para eliminar la restricción UNIQUE de fecha en caja_cierre
 * Esto permite múltiples cierres de caja el mismo día
 */

const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function fixCierreCajaUnique() {
  let connection;
  
  try {
    // Conectar a la base de datos
    connection = await mysql.createConnection({
      host: process.env.DATABASE_HOST || 'localhost',
      port: parseInt(process.env.DATABASE_PORT || '3306'),
      user: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME,
      multipleStatements: true
    });

    console.log('✅ Conectado a la base de datos');

    // Verificar si existe el índice
    const [indexes] = await connection.execute(
      `SELECT COUNT(*) as count FROM information_schema.statistics 
       WHERE table_schema = ? 
       AND table_name = 'caja_cierre' 
       AND index_name = 'ux_caja_fecha'`,
      [process.env.DATABASE_NAME]
    );

    if (indexes[0].count > 0) {
      console.log('🔍 Encontrada restricción UNIQUE ux_caja_fecha, eliminándola...');
      
      // Eliminar la restricción UNIQUE
      await connection.execute('ALTER TABLE caja_cierre DROP INDEX ux_caja_fecha');
      
      console.log('✅ Restricción UNIQUE eliminada correctamente');
    } else {
      console.log('ℹ️  La restricción UNIQUE ux_caja_fecha no existe');
    }

    // Verificar si existe el índice normal
    const [normalIndexes] = await connection.execute(
      `SELECT COUNT(*) as count FROM information_schema.statistics 
       WHERE table_schema = ? 
       AND table_name = 'caja_cierre' 
       AND index_name = 'ix_caja_fecha'`,
      [process.env.DATABASE_NAME]
    );

    if (normalIndexes[0].count === 0) {
      console.log('🔍 Agregando índice normal en fecha para mejorar consultas...');
      
      // Agregar índice normal (no único)
      await connection.execute('ALTER TABLE caja_cierre ADD INDEX ix_caja_fecha (fecha)');
      
      console.log('✅ Índice normal agregado correctamente');
    } else {
      console.log('ℹ️  El índice normal ix_caja_fecha ya existe');
    }

    // Mostrar índices actuales
    const [currentIndexes] = await connection.execute('SHOW INDEX FROM caja_cierre');
    console.log('\n📋 Índices actuales en caja_cierre:');
    currentIndexes.forEach(idx => {
      console.log(`   - ${idx.Key_name} (${idx.Column_name}) ${idx.Non_unique === 0 ? '[UNIQUE]' : '[INDEX]'}`);
    });

    console.log('\n✅ Migración completada exitosamente');
    console.log('🎉 Ahora puedes crear múltiples cierres de caja el mismo día');

  } catch (error) {
    console.error('❌ Error al ejecutar la migración:', error.message);
    if (error.code) {
      console.error(`   Código de error: ${error.code}`);
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
fixCierreCajaUnique();

