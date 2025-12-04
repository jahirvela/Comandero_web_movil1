/**
 * Script para analizar la estructura actual de la BD y compararla con el script SQL original
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import * as fs from 'fs';
import * as path from 'path';

config();

interface TableInfo {
  name: string;
  columns: Array<{ name: string; type: string; nullable: string }>;
}

async function analizarEstructura() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
    });

    console.log('========================================');
    console.log('ANÁLISIS DE ESTRUCTURA DE BASE DE DATOS');
    console.log('========================================');
    console.log('');

    // Obtener todas las tablas
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME",
      [env.DATABASE_NAME]
    );

    const tableNames = (tables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME);
    
    console.log(`📊 Total de tablas encontradas: ${tableNames.length}`);
    console.log('');

    const tablesInfo: TableInfo[] = [];

    // Analizar cada tabla
    for (const tableName of tableNames) {
      const [columns] = await connection.query(
        `SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_KEY, EXTRA
         FROM INFORMATION_SCHEMA.COLUMNS 
         WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
         ORDER BY ORDINAL_POSITION`,
        [env.DATABASE_NAME, tableName]
      );

      const [foreignKeys] = await connection.query(
        `SELECT 
          CONSTRAINT_NAME,
          COLUMN_NAME,
          REFERENCED_TABLE_NAME,
          REFERENCED_COLUMN_NAME
         FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
         WHERE TABLE_SCHEMA = ? 
           AND TABLE_NAME = ?
           AND REFERENCED_TABLE_NAME IS NOT NULL`,
        [env.DATABASE_NAME, tableName]
      );

      const [indexes] = await connection.query(
        `SELECT INDEX_NAME, COLUMN_NAME, NON_UNIQUE
         FROM INFORMATION_SCHEMA.STATISTICS
         WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
         ORDER BY INDEX_NAME, SEQ_IN_INDEX`,
        [env.DATABASE_NAME, tableName]
      );

      const cols = (columns as any[]).map((col: any) => ({
        name: col.COLUMN_NAME,
        type: `${col.DATA_TYPE}${col.COLUMN_KEY === 'PRI' ? ' PRIMARY KEY' : ''}${col.EXTRA.includes('auto_increment') ? ' AUTO_INCREMENT' : ''}`,
        nullable: col.IS_NULLABLE
      }));

      tablesInfo.push({
        name: tableName,
        columns: cols
      });

      console.log(`📋 Tabla: ${tableName}`);
      console.log(`   Columnas: ${cols.length}`);
      console.log(`   Foreign Keys: ${(foreignKeys as any[]).length}`);
      console.log(`   Índices: ${(indexes as any[]).length}`);
      console.log('');
    }

    // Guardar reporte en archivo
    const reportPath = path.join(process.cwd(), 'scripts', 'reporte-estructura-bd.json');
    fs.writeFileSync(reportPath, JSON.stringify({
      fecha: new Date().toISOString(),
      database: env.DATABASE_NAME,
      totalTablas: tableNames.length,
      tablas: tablesInfo.map(t => ({
        nombre: t.name,
        columnas: t.columns.map(c => ({
          nombre: c.name,
          tipo: c.type,
          nullable: c.nullable === 'YES'
        }))
      }))
    }, null, 2));

    console.log(`✅ Reporte guardado en: ${reportPath}`);
    console.log('');

    // Comparar con tablas esperadas del script SQL
    const tablasEsperadas = [
      'usuario', 'rol', 'permiso', 'usuario_rol', 'rol_permiso', 'usuario_password_hist',
      'estado_mesa', 'estado_orden', 'forma_pago',
      'mesa', 'cliente', 'reserva', 'mesa_estado_hist',
      'categoria', 'producto', 'inventario_item', 'producto_insumo', 'producto_tamano',
      'modificador_categoria', 'modificador_opcion', 'producto_modificador', 'modificador_insumo',
      'orden', 'orden_item', 'nota_orden', 'orden_cancelacion', 'preparacion_orden', 'orden_item_modificador',
      'movimiento_inventario',
      'caja_cierre', 'pago', 'terminal', 'terminal_log', 'comprobante_tarjeta', 'documentacion_pago',
      'propina', 'movimiento_caja',
      'alerta',
      'conteo_inventario', 'conteo_inventario_item'
    ];

    console.log('========================================');
    console.log('COMPARACIÓN CON ESTRUCTURA ESPERADA');
    console.log('========================================');
    console.log('');

    const tablasFaltantes = tablasEsperadas.filter(t => !tableNames.includes(t));
    const tablasExtras = tableNames.filter(t => !tablasEsperadas.includes(t));

    if (tablasFaltantes.length > 0) {
      console.log('⚠️  Tablas faltantes:');
      tablasFaltantes.forEach(t => console.log(`   - ${t}`));
      console.log('');
    } else {
      console.log('✅ Todas las tablas esperadas están presentes');
      console.log('');
    }

    if (tablasExtras.length > 0) {
      console.log('ℹ️  Tablas adicionales (no en script original):');
      tablasExtras.forEach(t => console.log(`   - ${t}`));
      console.log('');
    }

    console.log('========================================');
    console.log('✅ Análisis completado');
    console.log('========================================');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

analizarEstructura();

