/**
 * Script para verificar productos en la base de datos
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificarProductos() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();
    
    console.log('========================================');
    console.log('VERIFICACIÓN DE PRODUCTOS');
    console.log('========================================');
    console.log('');
    console.log('📋 Configuración:');
    console.log(`   Base de datos: ${env.DATABASE_NAME}`);
    console.log('');

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
    });

    console.log('✅ Conectado a MySQL');
    console.log('');

    // Verificar si existe tabla "producto" o "productos"
    console.log('🔍 Buscando tablas de productos...');
    const [tables] = await connection.query("SHOW TABLES LIKE '%producto%'");
    const tableNames = (tables as any[]).map((t: any) => Object.values(t)[0] as string);
    
    if (tableNames.length === 0) {
      console.log('❌ No se encontraron tablas de productos');
    } else {
      console.log(`✅ Tablas encontradas: ${tableNames.join(', ')}`);
      console.log('');

      for (const tableName of tableNames) {
        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
        console.log(`📊 Tabla: ${tableName}`);
        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

        // Ver estructura
        try {
          const [columns] = await connection.query(`DESCRIBE ${tableName}`);
          console.log('Estructura:');
          (columns as any[]).forEach((col: any) => {
            console.log(`   - ${col.Field} (${col.Type})`);
          });
          console.log('');

          // Contar productos
          const [count] = await connection.query(`SELECT COUNT(*) as total FROM ${tableName}`);
          const total = (count as any[])[0].total;
          console.log(`📦 Total de productos: ${total}`);
          console.log('');

          if (total > 0) {
            // Obtener productos (limitar a 10 para no saturar)
            const [products] = await connection.query(`SELECT * FROM ${tableName} ORDER BY id DESC LIMIT 10`);
            console.log(`Mostrando los últimos ${Math.min(10, total)} productos:`);
            console.log('');

            (products as any[]).forEach((p: any, i: number) => {
              console.log(`Producto ${i + 1}:`);
              Object.keys(p).forEach(key => {
                const value = p[key];
                if (value !== null && value !== undefined) {
                  if (key.includes('fecha') || key.includes('creado') || key.includes('actualizado')) {
                    try {
                      console.log(`   ${key}: ${new Date(value).toLocaleString('es-ES')}`);
                    } catch {
                      console.log(`   ${key}: ${value}`);
                    }
                  } else {
                    console.log(`   ${key}: ${value}`);
                  }
                }
              });
              console.log('');
            });

            if (total > 10) {
              console.log(`... y ${total - 10} productos más`);
              console.log('');
            }
          } else {
            console.log('⚠️  No hay productos en esta tabla');
            console.log('');
          }
        } catch (error: any) {
          console.log(`❌ Error al leer la tabla: ${error.message}`);
          console.log('');
        }
      }
    }

    // Verificar también categorías si existen
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔍 Verificando categorías...');
    try {
      const [catTables] = await connection.query("SHOW TABLES LIKE '%categoria%'");
      const catTableNames = (catTables as any[]).map((t: any) => Object.values(t)[0] as string);
      
      if (catTableNames.length > 0) {
        for (const catTable of catTableNames) {
          const [catCount] = await connection.query(`SELECT COUNT(*) as total FROM ${catTable}`);
          const totalCats = (catCount as any[])[0].total;
          console.log(`📁 Tabla ${catTable}: ${totalCats} categorías`);
        }
      }
    } catch (e) {
      // Ignorar errores
    }

    console.log('');
    console.log('========================================');
    console.log('✅ Verificación completada');
    console.log('========================================');

  } catch (error: any) {
    console.error('');
    console.error('❌ Error:', error.message);
    if (error.code) {
      console.error(`   Código: ${error.code}`);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

verificarProductos();


