/**
 * Script para verificar el usuario admin y sus roles
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificarUsuario() {
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
    console.log('Verificando usuario admin');
    console.log('========================================');
    console.log('');

    // Verificar usuario
    const [users] = await connection.query(
      'SELECT * FROM usuario WHERE username = ?',
      ['admin']
    );

    const userList = users as any[];

    if (userList.length === 0) {
      console.log('❌ No se encontró el usuario "admin"');
      return;
    }

    const user = userList[0];
    console.log('✅ Usuario encontrado:');
    console.log(`   ID: ${user.id}`);
    console.log(`   Nombre: ${user.nombre}`);
    console.log(`   Username: ${user.username}`);
    console.log(`   Activo: ${user.activo === 1 ? 'Sí' : 'No'}`);
    console.log(`   Password hash: ${user.password_hash ? 'Existe' : 'No existe'}`);
    console.log('');

    // Verificar si existen tablas de roles
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME IN ('rol', 'usuario_rol')",
      [env.DATABASE_NAME]
    );

    const tableNames = (tables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME);

    if (tableNames.includes('rol') && tableNames.includes('usuario_rol')) {
      console.log('✅ Tablas de roles existen');
      
      // Obtener roles del usuario
      const [roles] = await connection.query(
        `SELECT r.id, r.nombre 
         FROM usuario_rol ur
         JOIN rol r ON r.id = ur.rol_id
         WHERE ur.usuario_id = ?`,
        [user.id]
      );

      const rolesList = roles as Array<{ id: number; nombre: string }>;
      
      if (rolesList.length > 0) {
        console.log('Roles asignados:');
        rolesList.forEach((rol) => {
          console.log(`   - ${rol.nombre} (ID: ${rol.id})`);
        });
      } else {
        console.log('⚠️  El usuario no tiene roles asignados');
      }
    } else {
      console.log('⚠️  Tablas de roles no existen');
      console.log('   El usuario funcionará pero sin roles asignados');
    }

    console.log('');
    console.log('========================================');
    console.log('Estado del usuario:');
    console.log(`   Puede hacer login: ${user.activo === 1 ? 'Sí' : 'No'}`);
    console.log(`   Tiene password: ${user.password_hash ? 'Sí' : 'No'}`);
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

verificarUsuario();

