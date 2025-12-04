/**
 * Verificar bases de datos en diferentes puertos
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';

config();

async function verificarPuertos() {
  const puertos = [3306, 3307];
  const host = process.env.DATABASE_HOST || '127.0.0.1';
  const user = process.env.DATABASE_USER || 'root';
  const password = process.env.DATABASE_PASSWORD || '';

  console.log('========================================');
  console.log('VERIFICACIÓN EN MÚLTIPLES PUERTOS');
  console.log('========================================');
  console.log('');

  for (const port of puertos) {
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`🔍 Puerto: ${port}`);
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

    try {
      // Intentar conectar sin base de datos
      const conn = await mysql.createConnection({
        host,
        port,
        user,
        password,
        connectTimeout: 5000,
      });

      console.log(`✅ Conexión exitosa al puerto ${port}`);
      console.log('');

      // Listar bases de datos
      const [dbs] = await conn.query('SHOW DATABASES');
      const databases = (dbs as any[]).map((db: any) => Object.values(db)[0] as string)
        .filter(db => !['information_schema', 'performance_schema', 'mysql', 'sys'].includes(db));

      console.log(`📊 Bases de datos disponibles (${databases.length}):`);
      databases.forEach(db => console.log(`   - ${db}`));
      console.log('');

      // Verificar cada base de datos que pueda ser relevante
      for (const dbName of databases) {
        if (dbName.toLowerCase().includes('comand') || dbName.toLowerCase().includes('test')) {
          try {
            await conn.query(`USE ${dbName}`);
            console.log(`📋 Base de datos: ${dbName}`);

            // Buscar tabla usuario (singular)
            try {
              const [tables1] = await conn.query("SHOW TABLES LIKE 'usuario'");
              if ((tables1 as any[]).length > 0) {
                console.log('   ✅ Tabla "usuario" (singular) encontrada');
                const [users] = await conn.query('SELECT COUNT(*) as total FROM usuario');
                const total = (users as any[])[0].total;
                console.log(`      Total de usuarios: ${total}`);
                
                if (total > 0) {
                  const [userList] = await conn.query('SELECT id, nombre, username, activo FROM usuario LIMIT 5');
                  (userList as any[]).forEach((u: any) => {
                    console.log(`      - ID: ${u.id}, Nombre: ${u.nombre}, Username: ${u.username}, Activo: ${u.activo}`);
                  });
                }
              }
            } catch (e) {
              // Tabla no existe
            }

            // Buscar tabla usuarios (plural)
            try {
              const [tables2] = await conn.query("SHOW TABLES LIKE 'usuarios'");
              if ((tables2 as any[]).length > 0) {
                console.log('   ✅ Tabla "usuarios" (plural) encontrada');
                const [users] = await conn.query('SELECT COUNT(*) as total FROM usuarios');
                const total = (users as any[])[0].total;
                console.log(`      Total de usuarios: ${total}`);
                
                if (total > 0) {
                  const [userList] = await conn.query('SELECT id, nombre, correo, rol, activo FROM usuarios LIMIT 5');
                  (userList as any[]).forEach((u: any) => {
                    console.log(`      - ID: ${u.id}, Nombre: ${u.nombre}, Correo: ${u.correo}, Rol: ${u.rol}, Activo: ${u.activo}`);
                  });
                }
              }
            } catch (e) {
              // Tabla no existe
            }

            // Verificar tablas relacionadas
            try {
              const [tables3] = await conn.query("SHOW TABLES LIKE 'rol'");
              if ((tables3 as any[]).length > 0) {
                console.log('   ✅ Tabla "rol" encontrada');
              }
            } catch (e) {}

            try {
              const [tables4] = await conn.query("SHOW TABLES LIKE 'usuario_rol'");
              if ((tables4 as any[]).length > 0) {
                console.log('   ✅ Tabla "usuario_rol" encontrada');
              }
            } catch (e) {}

            console.log('');
          } catch (e: any) {
            console.log(`   ❌ Error al acceder a ${dbName}: ${e.message}`);
            console.log('');
          }
        }
      }

      await conn.end();
      console.log('');

    } catch (error: any) {
      console.log(`❌ No se pudo conectar al puerto ${port}`);
      if (error.code === 'ECONNREFUSED') {
        console.log(`   MySQL no está escuchando en el puerto ${port}`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`   Timeout al conectar al puerto ${port}`);
      } else {
        console.log(`   Error: ${error.message}`);
      }
      console.log('');
    }
  }

  console.log('========================================');
  console.log('✅ Verificación completada');
  console.log('========================================');
}

verificarPuertos();

