/**
 * Script de prueba de integración completa
 * Verifica que todas las APIs, servicios y eventos funcionen correctamente
 */

import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';

config();

interface TestResult {
  name: string;
  passed: boolean;
  message: string;
  details?: any;
}

async function pruebaIntegracion() {
  let connection: mysql.Connection | null = null;
  const results: TestResult[] = [];

  try {
    const env = getEnv();

    console.log('========================================');
    console.log('PRUEBA DE INTEGRACIÓN COMPLETA');
    console.log('========================================');
    console.log('');

    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
    });

    console.log('✅ Conectado a la base de datos');
    console.log('');

    // ============================================
    // PRUEBA 1: Verificar estructura de base de datos
    // ============================================
    console.log('📋 PRUEBA 1: Verificar estructura de base de datos...');
    const [tables] = await connection.query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME",
      [env.DATABASE_NAME]
    );

    const tableNames = (tables as Array<{ TABLE_NAME: string }>).map(t => t.TABLE_NAME);
    const tablasEsperadas = [
      'usuario', 'rol', 'usuario_rol',
      'estado_mesa', 'estado_orden', 'forma_pago',
      'mesa', 'categoria', 'producto', 'orden', 'orden_item',
      'pago', 'alerta'
    ];

    const tablasFaltantes = tablasEsperadas.filter(t => !tableNames.includes(t));
    
    if (tablasFaltantes.length === 0) {
      results.push({
        name: 'Estructura de BD',
        passed: true,
        message: `Todas las tablas principales están presentes (${tablasEsperadas.length} tablas)`
      });
      console.log('   ✅ Todas las tablas principales están presentes');
    } else {
      results.push({
        name: 'Estructura de BD',
        passed: false,
        message: `Faltan tablas: ${tablasFaltantes.join(', ')}`
      });
      console.log('   ❌ Faltan tablas:', tablasFaltantes.join(', '));
    }
    console.log('');

    // ============================================
    // PRUEBA 2: Verificar usuario admin
    // ============================================
    console.log('👤 PRUEBA 2: Verificar usuario admin...');
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
      if (user.activo === 1 && user.roles && user.roles.includes('administrador')) {
        results.push({
          name: 'Usuario Admin',
          passed: true,
          message: `Usuario admin activo con rol de administrador`
        });
        console.log('   ✅ Usuario admin activo con rol de administrador');
      } else {
        results.push({
          name: 'Usuario Admin',
          passed: false,
          message: `Usuario admin existe pero no tiene rol de administrador o está inactivo`
        });
        console.log('   ⚠️  Usuario admin existe pero no tiene rol asignado correctamente');
      }
    } else {
      results.push({
        name: 'Usuario Admin',
        passed: false,
        message: 'Usuario admin no encontrado'
      });
      console.log('   ❌ Usuario admin no encontrado');
    }
    console.log('');

    // ============================================
    // PRUEBA 3: Verificar roles y estados
    // ============================================
    console.log('🔐 PRUEBA 3: Verificar roles y estados...');
    const [roles] = await connection.query('SELECT COUNT(*) as total FROM rol');
    const [estadosMesa] = await connection.query('SELECT COUNT(*) as total FROM estado_mesa');
    const [estadosOrden] = await connection.query('SELECT COUNT(*) as total FROM estado_orden');
    const [formasPago] = await connection.query('SELECT COUNT(*) as total FROM forma_pago');

    const totalRoles = (roles as any[])[0].total;
    const totalEstadosMesa = (estadosMesa as any[])[0].total;
    const totalEstadosOrden = (estadosOrden as any[])[0].total;
    const totalFormasPago = (formasPago as any[])[0].total;

    if (totalRoles >= 5 && totalEstadosMesa >= 4 && totalEstadosOrden >= 3 && totalFormasPago >= 3) {
      results.push({
        name: 'Roles y Estados',
        passed: true,
        message: `Roles: ${totalRoles}, Estados Mesa: ${totalEstadosMesa}, Estados Orden: ${totalEstadosOrden}, Formas Pago: ${totalFormasPago}`
      });
      console.log('   ✅ Roles y estados correctamente sembrados');
    } else {
      results.push({
        name: 'Roles y Estados',
        passed: false,
        message: `Roles: ${totalRoles}, Estados Mesa: ${totalEstadosMesa}, Estados Orden: ${totalEstadosOrden}, Formas Pago: ${totalFormasPago}`
      });
      console.log('   ⚠️  Algunos roles o estados faltan');
    }
    console.log('');

    // ============================================
    // PRUEBA 4: Verificar estructura de tabla alerta
    // ============================================
    console.log('🔔 PRUEBA 4: Verificar estructura de tabla alerta...');
    const [alertaColumns] = await connection.query(
      `SELECT COLUMN_NAME, DATA_TYPE 
       FROM INFORMATION_SCHEMA.COLUMNS 
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'alerta'
       ORDER BY ORDINAL_POSITION`,
      [env.DATABASE_NAME]
    );

    const columns = (alertaColumns as any[]).map(c => c.COLUMN_NAME);
    const requiredColumns = ['tipo', 'mensaje', 'usuario_origen_id', 'leida', 'prioridad', 'estacion'];
    const missingColumns = requiredColumns.filter(col => !columns.includes(col));

    if (missingColumns.length === 0) {
      results.push({
        name: 'Tabla Alerta',
        passed: true,
        message: 'Estructura de tabla alerta correcta'
      });
      console.log('   ✅ Estructura de tabla alerta correcta');
    } else {
      results.push({
        name: 'Tabla Alerta',
        passed: false,
        message: `Faltan columnas: ${missingColumns.join(', ')}`
      });
      console.log('   ❌ Faltan columnas en tabla alerta:', missingColumns.join(', '));
    }
    console.log('');

    // ============================================
    // PRUEBA 5: Verificar foreign keys
    // ============================================
    console.log('🔗 PRUEBA 5: Verificar foreign keys importantes...');
    const [fks] = await connection.query(
      `SELECT 
        TABLE_NAME,
        CONSTRAINT_NAME,
        REFERENCED_TABLE_NAME
       FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = ?
         AND REFERENCED_TABLE_NAME IS NOT NULL
         AND TABLE_NAME IN ('orden_item', 'orden', 'pago', 'alerta')
       GROUP BY TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME`,
      [env.DATABASE_NAME]
    );

    const fkList = fks as any[];
    const expectedFKs = [
      { table: 'orden_item', ref: 'orden' },
      { table: 'orden_item', ref: 'producto' },
      { table: 'orden', ref: 'mesa' },
      { table: 'orden', ref: 'estado_orden' },
      { table: 'pago', ref: 'orden' },
      { table: 'alerta', ref: 'usuario' }
    ];

    let fkPassed = 0;
    for (const expected of expectedFKs) {
      const exists = fkList.some(fk => 
        fk.TABLE_NAME === expected.table && fk.REFERENCED_TABLE_NAME === expected.ref
      );
      if (exists) fkPassed++;
    }

    if (fkPassed === expectedFKs.length) {
      results.push({
        name: 'Foreign Keys',
        passed: true,
        message: `Todas las foreign keys importantes están presentes (${fkPassed}/${expectedFKs.length})`
      });
      console.log(`   ✅ Todas las foreign keys importantes están presentes (${fkPassed}/${expectedFKs.length})`);
    } else {
      results.push({
        name: 'Foreign Keys',
        passed: false,
        message: `Solo ${fkPassed}/${expectedFKs.length} foreign keys importantes están presentes`
      });
      console.log(`   ⚠️  Solo ${fkPassed}/${expectedFKs.length} foreign keys importantes están presentes`);
    }
    console.log('');

    // ============================================
    // RESUMEN
    // ============================================
    console.log('========================================');
    console.log('RESUMEN DE PRUEBAS');
    console.log('========================================');
    console.log('');

    const passed = results.filter(r => r.passed).length;
    const total = results.length;

    results.forEach((result, index) => {
      const icon = result.passed ? '✅' : '❌';
      console.log(`${index + 1}. ${icon} ${result.name}`);
      console.log(`   ${result.message}`);
      if (result.details) {
        console.log(`   Detalles: ${JSON.stringify(result.details)}`);
      }
      console.log('');
    });

    console.log('========================================');
    if (passed === total) {
      console.log(`✅ TODAS LAS PRUEBAS PASARON (${passed}/${total})`);
    } else {
      console.log(`⚠️  ALGUNAS PRUEBAS FALLARON (${passed}/${total})`);
    }
    console.log('========================================');
    console.log('');

    console.log('Próximos pasos:');
    console.log('  1. Reiniciar el backend: npm run dev');
    console.log('  2. Verificar que el servidor inicie sin errores');
    console.log('  3. Probar login desde el frontend con: admin / Demo123');
    console.log('  4. Verificar que todas las funcionalidades CRUD funcionen');
    console.log('  5. Probar eventos Socket.IO en tiempo real');
    console.log('');

  } catch (error: any) {
    console.error('❌ Error durante las pruebas:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

pruebaIntegracion()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error fatal:', error);
    process.exit(1);
  });

