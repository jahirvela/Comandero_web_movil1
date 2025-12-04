/**
 * Script para ejecutar la migración completa de la base de datos
 * Basado en el script SQL original del proyecto
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import * as fs from 'fs';
import * as path from 'path';
import { crearBackupNode } from './backup-database-node.js';

config();

async function ejecutarMigracion() {
  let connection: mysql.Connection | null = null;

  try {
    const env = getEnv();

    console.log('========================================');
    console.log('MIGRACIÓN COMPLETA DE BASE DE DATOS');
    console.log('========================================');
    console.log('');

    // Crear backup automático antes de la migración
    console.log('💾 Creando backup automático antes de la migración...\n');
    try {
      const backupPath = await crearBackupNode({
        filename: `backup_pre_migracion_${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}`
      });
      console.log(`\n✅ Backup de seguridad creado: ${backupPath}\n`);
    } catch (error: any) {
      console.error('⚠️  ADVERTENCIA: No se pudo crear el backup automático:', error.message);
      console.error('   La migración continuará, pero se recomienda crear un backup manual antes.');
      console.error('   Ejecuta: npm run backup:database\n');
      
      // En modo no interactivo o si el usuario quiere continuar, seguir adelante
      console.log('⚠️  Continuando con la migración sin backup automático...\n');
    }

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
      multipleStatements: true // Permitir múltiples statements
    });

    console.log('✅ Conectado a la base de datos');
    console.log('');

    // Leer el archivo SQL de migración
    const sqlPath = path.join(process.cwd(), 'scripts', 'migracion-segura-bd.sql');
    
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`No se encontró el archivo de migración: ${sqlPath}`);
    }

    const sqlContent = fs.readFileSync(sqlPath, 'utf-8');
    
    console.log('📄 Leyendo script de migración...');
    console.log(`   Archivo: ${sqlPath}`);
    console.log(`   Tamaño: ${(sqlContent.length / 1024).toFixed(2)} KB`);
    console.log('');

    // Ejecutar la migración
    console.log('🚀 Ejecutando migración...');
    console.log('   Esto puede tomar varios minutos...');
    console.log('');

    await connection.query(sqlContent);

    console.log('✅ Migración ejecutada exitosamente');
    console.log('');

    // Verificar que las tablas se crearon correctamente
    console.log('🔍 Verificando tablas creadas...');
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME",
      [env.DATABASE_NAME]
    );

    const tableNames = (tables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME);
    console.log(`   Total de tablas: ${tableNames.length}`);
    console.log('');

    // Verificar usuario admin y su rol
    console.log('👤 Verificando usuario admin...');
    const [users] = await connection.query(
      `SELECT u.id, u.username, u.nombre, u.activo,
              GROUP_CONCAT(r.nombre ORDER BY r.nombre SEPARATOR ', ') AS roles
       FROM usuario u
       LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
       LEFT JOIN rol r ON r.id = ur.rol_id
       WHERE u.username = 'admin'
       GROUP BY u.id`,
      []
    );

    const userList = users as any[];
    if (userList.length > 0) {
      const user = userList[0];
      console.log(`   ✅ Usuario encontrado: ${user.username}`);
      console.log(`   Nombre: ${user.nombre}`);
      console.log(`   Activo: ${user.activo === 1 ? 'Sí' : 'No'}`);
      console.log(`   Roles: ${user.roles || 'Sin roles asignados'}`);
    } else {
      console.log('   ⚠️  Usuario admin no encontrado');
    }
    console.log('');

    // Verificar roles creados
    console.log('🔐 Verificando roles...');
    const [roles] = await connection.query('SELECT id, nombre FROM rol ORDER BY id');
    const rolesList = roles as Array<{ id: number; nombre: string }>;
    console.log(`   Total de roles: ${rolesList.length}`);
    rolesList.forEach((rol) => {
      console.log(`   - ${rol.nombre} (ID: ${rol.id})`);
    });
    console.log('');

    // Verificar estados creados
    console.log('📋 Verificando estados...');
    const [estadosMesa] = await connection.query('SELECT COUNT(*) as total FROM estado_mesa');
    const [estadosOrden] = await connection.query('SELECT COUNT(*) as total FROM estado_orden');
    const [formasPago] = await connection.query('SELECT COUNT(*) as total FROM forma_pago');
    
    console.log(`   Estados de mesa: ${(estadosMesa as any[])[0].total}`);
    console.log(`   Estados de orden: ${(estadosOrden as any[])[0].total}`);
    console.log(`   Formas de pago: ${(formasPago as any[])[0].total}`);
    console.log('');

    console.log('========================================');
    console.log('✅ MIGRACIÓN COMPLETADA EXITOSAMENTE');
    console.log('========================================');
    console.log('');
    console.log('Próximos pasos:');
    console.log('  1. Verificar que el backend pueda conectarse correctamente');
    console.log('  2. Probar el login con usuario: admin / contraseña: Demo123');
    console.log('  3. Verificar que todas las funcionalidades CRUD funcionen');
    console.log('');

  } catch (error: any) {
    console.error('❌ Error durante la migración:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    if (error.sqlMessage) {
      console.error('   SQL:', error.sqlMessage);
    }
    if (error.sqlState) {
      console.error('   Estado SQL:', error.sqlState);
    }
    console.error('');
    console.error('⚠️  Si hay errores, revisa:');
    console.error('   - Que la base de datos esté corriendo');
    console.error('   - Que las credenciales en .env sean correctas');
    console.error('   - Que no haya conflictos con tablas existentes');
    throw error;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

ejecutarMigracion()
  .then(() => {
    console.log('✅ Script finalizado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error fatal:', error);
    process.exit(1);
  });

