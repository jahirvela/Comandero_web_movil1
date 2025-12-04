/**
 * Buscar usuarios en TODAS las bases de datos
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function buscarEnTodasLasBases() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();
    
    console.log('========================================');
    console.log('BÚSQUEDA EN TODAS LAS BASES DE DATOS');
    console.log('========================================');
    console.log('');

    // Conectar sin especificar base de datos
    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
    });

    // Listar todas las bases de datos
    const [dbs] = await connection.query('SHOW DATABASES');
    const databases = (dbs as any[]).map((db: any) => Object.values(db)[0] as string)
      .filter(db => !['information_schema', 'performance_schema', 'mysql', 'sys'].includes(db));

    console.log(`🔍 Buscando en ${databases.length} bases de datos...`);
    console.log('');

    for (const dbName of databases) {
      try {
        await connection.query(`USE ${dbName}`);
        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
        console.log(`📊 Base de datos: ${dbName}`);
        console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

        // Buscar tabla "usuario" (singular)
        try {
          const [tables1] = await connection.query(`SHOW TABLES LIKE 'usuario'`);
          if ((tables1 as any[]).length > 0) {
            console.log('✅ Tabla "usuario" (singular) encontrada');
            const [users] = await connection.query('SELECT * FROM usuario');
            console.log(`   Total de usuarios: ${(users as any[]).length}`);
            if ((users as any[]).length > 0) {
              (users as any[]).forEach((u: any, i: number) => {
                console.log(`   Usuario ${i + 1}:`);
                Object.keys(u).forEach(key => {
                  if (key.toLowerCase().includes('password') || key.toLowerCase().includes('contraseña')) {
                    console.log(`     ${key}: [OCULTO]`);
                  } else {
                    console.log(`     ${key}: ${u[key]}`);
                  }
                });
              });
            }
          }
        } catch (e: any) {
          // Tabla no existe
        }

        // Buscar tabla "usuarios" (plural)
        try {
          const [tables2] = await connection.query(`SHOW TABLES LIKE 'usuarios'`);
          if ((tables2 as any[]).length > 0) {
            console.log('✅ Tabla "usuarios" (plural) encontrada');
            const [users] = await connection.query('SELECT * FROM usuarios');
            console.log(`   Total de usuarios: ${(users as any[]).length}`);
            if ((users as any[]).length > 0) {
              (users as any[]).forEach((u: any, i: number) => {
                console.log(`   Usuario ${i + 1}:`);
                Object.keys(u).forEach(key => {
                  if (key.toLowerCase().includes('password') || key.toLowerCase().includes('contraseña')) {
                    console.log(`     ${key}: [OCULTO]`);
                  } else {
                    console.log(`     ${key}: ${u[key]}`);
                  }
                });
              });
            }
          }
        } catch (e: any) {
          // Tabla no existe
        }

        // Verificar tablas relacionadas
        try {
          const [tables3] = await connection.query(`SHOW TABLES LIKE 'rol'`);
          if ((tables3 as any[]).length > 0) {
            console.log('✅ Tabla "rol" encontrada');
            const [roles] = await connection.query('SELECT * FROM rol');
            console.log(`   Total de roles: ${(roles as any[]).length}`);
          }
        } catch (e: any) {
          // Tabla no existe
        }

        try {
          const [tables4] = await connection.query(`SHOW TABLES LIKE 'usuario_rol'`);
          if ((tables4 as any[]).length > 0) {
            console.log('✅ Tabla "usuario_rol" encontrada');
            const [userRoles] = await connection.query('SELECT COUNT(*) as total FROM usuario_rol');
            console.log(`   Total de asignaciones: ${(userRoles as any[])[0].total}`);
          }
        } catch (e: any) {
          // Tabla no existe
        }

        console.log('');

      } catch (error: any) {
        console.log(`❌ Error al acceder a ${dbName}: ${error.message}`);
        console.log('');
      }
    }

    console.log('========================================');
    console.log('✅ Búsqueda completada');
    console.log('========================================');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

buscarEnTodasLasBases();


