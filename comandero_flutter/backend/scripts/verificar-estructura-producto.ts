import { config } from 'dotenv';
import { pool } from '../src/db/pool.js';
import { getEnv } from '../src/config/env.js';

config();

async function verificarEstructura() {
  try {
    const env = getEnv();

    console.log('========================================');
    console.log('ESTRUCTURA DE TABLA PRODUCTO');
    console.log('========================================\n');

    // Obtener estructura de la tabla
    const [columnas] = await pool.query<any[]>(
      `
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        COLUMN_DEFAULT,
        COLUMN_KEY
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'producto'
      ORDER BY ORDINAL_POSITION
      `,
      [env.DATABASE_NAME]
    );

    console.log('📋 Columnas de la tabla "producto":\n');
    columnas.forEach((col) => {
      console.log(`   - ${col.COLUMN_NAME} (${col.DATA_TYPE})`);
    });

    // Ahora obtener productos con las columnas correctas
    console.log('\n========================================');
    console.log('PRODUCTOS EN LA BASE DE DATOS');
    console.log('========================================\n');

    const columnNames = columnas.map((c: any) => `p.${c.COLUMN_NAME}`).join(', ');
    
    const [productos] = await pool.query<any[]>(
      `
      SELECT 
        ${columnNames},
        c.nombre AS categoria_nombre
      FROM producto p
      LEFT JOIN categoria c ON c.id = p.categoria_id
      ORDER BY p.id
      `
    );

    if (productos.length === 0) {
      console.log('⚠️  No se encontraron productos en la tabla "producto"');
    } else {
      console.log(`✅ Se encontraron ${productos.length} producto(s):\n`);
      
      productos.forEach((producto, index) => {
        console.log(`\n${index + 1}. ${producto.nombre || 'Sin nombre'}`);
        console.log('   ' + '─'.repeat(50));
        Object.keys(producto).forEach((key) => {
          if (key !== 'categoria_nombre') {
            const value = producto[key];
            if (value !== null && value !== undefined) {
              console.log(`   ${key}: ${value}`);
            }
          }
        });
        if (producto.categoria_nombre) {
          console.log(`   Categoría: ${producto.categoria_nombre}`);
        }
      });
    }

    await pool.end();
  } catch (error: any) {
    console.error('❌ Error:', error.message);
    await pool.end();
    throw error;
  }
}

verificarEstructura().catch(console.error);

