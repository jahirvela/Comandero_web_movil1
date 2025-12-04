/**
 * Eliminar el usuario admin que se creó (ID: 2)
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function eliminarUsuario() {
  const env = getEnv();
  const conn = await mysql.createConnection({
    host: env.DATABASE_HOST,
    port: env.DATABASE_PORT,
    user: env.DATABASE_USER,
    password: env.DATABASE_PASSWORD,
    database: env.DATABASE_NAME,
  });

  console.log('Eliminando usuario ID: 2 (admin)...');
  
  await conn.query('DELETE FROM usuarios WHERE id = 2');
  
  console.log('✅ Usuario eliminado');
  
  const [users] = await conn.query('SELECT id, nombre, correo FROM usuarios');
  console.log('\nUsuarios restantes:');
  (users as any[]).forEach((u: any) => {
    console.log(`  - ID: ${u.id}, Nombre: ${u.nombre}, Correo: ${u.correo}`);
  });

  await conn.end();
}

eliminarUsuario();

