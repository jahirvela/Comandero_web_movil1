/**
 * Script para limpiar completamente las tablas relacionadas con orden
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function limpiarTablasOrden() {
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

    console.log('Limpiando tablas relacionadas con orden...');
    console.log('');

    // Desactivar foreign key checks
    await connection.query('SET FOREIGN_KEY_CHECKS = 0');

    // Obtener todas las foreign keys que referencian orden_item
    const [fkInfo] = await connection.query(
      `SELECT 
        CONSTRAINT_NAME,
        TABLE_NAME
       FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = ?
         AND REFERENCED_TABLE_NAME = 'orden_item'`,
      [env.DATABASE_NAME]
    );

    const fkList = fkInfo as any[];
    console.log(`Encontradas ${fkList.length} foreign keys a orden_item`);
    
    // Eliminar foreign keys
    for (const fk of fkList) {
      try {
        await connection.query(`ALTER TABLE ${fk.TABLE_NAME} DROP FOREIGN KEY ${fk.CONSTRAINT_NAME}`);
        console.log(`   ✅ Eliminada FK ${fk.CONSTRAINT_NAME} de ${fk.TABLE_NAME}`);
      } catch (error: any) {
        console.log(`   ⚠️  No se pudo eliminar ${fk.CONSTRAINT_NAME}: ${error.message}`);
      }
    }

    // Eliminar tablas en orden inverso de dependencias
    const tablasAEliminar = [
      'orden_item_modificador',
      'preparacion_orden',
      'orden_item',
      'orden_cancelacion',
      'nota_orden',
      'pago',
      'propina',
      'movimiento_inventario',
      'orden'
    ];

    for (const tabla of tablasAEliminar) {
      try {
        await connection.query(`DROP TABLE IF EXISTS ${tabla}`);
        console.log(`   ✅ Eliminada tabla ${tabla}`);
      } catch (error: any) {
        console.log(`   ⚠️  Error al eliminar ${tabla}: ${error.message}`);
      }
    }

    // Reactivar foreign key checks
    await connection.query('SET FOREIGN_KEY_CHECKS = 1');

    console.log('');
    console.log('✅ Limpieza completada');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

limpiarTablasOrden();

