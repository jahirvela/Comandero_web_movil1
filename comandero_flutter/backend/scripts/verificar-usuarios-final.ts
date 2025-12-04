/**
 * Verificar usuarios finales
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

async function verificar() {
  const env = getEnv();
  const conn = await mysql.createConnection({
    host: env.DATABASE_HOST,
    port: env.DATABASE_PORT,
    user: env.DATABASE_USER,
    password: env.DATABASE_PASSWORD,
    database: env.DATABASE_NAME,
  });

  const [users] = await conn.query('SELECT id, nombre, correo, rol, activo FROM usuarios');
  
  console.log('========================================');
  console.log('USUARIOS EN LA BASE DE DATOS');
  console.log('========================================');
  console.log('');
  
  (users as any[]).forEach((u: any) => {
    console.log(`Usuario ID: ${u.id}`);
    console.log(`  Nombre: ${u.nombre}`);
    console.log(`  Correo: ${u.correo}`);
    console.log(`  Rol: ${u.rol}`);
    console.log(`  Activo: ${u.activo ? 'Sí' : 'No'}`);
    console.log('');
  });

  await conn.end();
}

verificar();

