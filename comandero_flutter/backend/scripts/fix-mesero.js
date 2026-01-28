// Script simple para habilitar usuario mesero
// Ejecutar: node scripts/fix-mesero.js

import dotenv from 'dotenv';
import mysql from 'mysql2/promise';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '../.env') });

async function fixMesero() {
  let conn = null;
  try {
    console.log('Conectando a MySQL...');
    conn = await mysql.createConnection({
      host: process.env.DATABASE_HOST || '127.0.0.1',
      port: parseInt(process.env.DATABASE_PORT || '3306', 10),
      user: process.env.DATABASE_USER || 'root',
      password: process.env.DATABASE_PASSWORD || '',
      database: process.env.DATABASE_NAME || 'comandero',
      connectTimeout: 5000
    });
    
    console.log('Conectado. Habilitando usuario mesero...');
    const [result] = await conn.execute(
      'UPDATE usuario SET activo = 1, actualizado_en = NOW() WHERE username = ?',
      ['mesero']
    );
    
    console.log('Filas afectadas:', result.affectedRows);
    
    if (result.affectedRows > 0) {
      const [rows] = await conn.execute(
        'SELECT id, username, activo FROM usuario WHERE username = ?',
        ['mesero']
      );
      console.log('Resultado:', rows[0]);
      console.log('✅ Usuario mesero habilitado');
    } else {
      console.log('⚠️ Usuario no encontrado o ya estaba habilitado');
    }
    
    await conn.end();
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    if (conn) await conn.end();
    process.exit(1);
  }
}

fixMesero();
