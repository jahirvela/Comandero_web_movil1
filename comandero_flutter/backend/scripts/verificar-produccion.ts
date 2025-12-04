import { getEnv } from '../src/config/env.js';
import { pool } from '../src/db/pool.js';
import { logger } from '../src/config/logger.js';

/**
 * Script de verificación pre-deployment
 * Verifica que todo esté configurado correctamente para producción
 */

interface VerificationResult {
  name: string;
  status: 'ok' | 'error' | 'warning';
  message: string;
}

const results: VerificationResult[] = [];

function addResult(name: string, status: 'ok' | 'error' | 'warning', message: string) {
  results.push({ name, status, message });
  const icon = status === 'ok' ? '✅' : status === 'error' ? '❌' : '⚠️';
  console.log(`${icon} ${name}: ${message}`);
}

async function verifyEnvironment() {
  console.log('\n🔍 Verificando variables de entorno...\n');
  
  try {
    const env = getEnv();
    
    // Verificar NODE_ENV
    if (env.NODE_ENV === 'production') {
      addResult('NODE_ENV', 'ok', `Configurado como: ${env.NODE_ENV}`);
    } else {
      addResult('NODE_ENV', 'warning', `Actualmente: ${env.NODE_ENV}. Para producción debe ser 'production'`);
    }
    
    // Verificar JWT secrets
    if (env.JWT_ACCESS_SECRET.length >= 32) {
      addResult('JWT_ACCESS_SECRET', 'ok', 'Secreto tiene longitud suficiente');
    } else {
      addResult('JWT_ACCESS_SECRET', 'error', `Secreto muy corto (${env.JWT_ACCESS_SECRET.length} caracteres). Mínimo 32`);
    }
    
    if (env.JWT_REFRESH_SECRET.length >= 32) {
      addResult('JWT_REFRESH_SECRET', 'ok', 'Secreto tiene longitud suficiente');
    } else {
      addResult('JWT_REFRESH_SECRET', 'error', `Secreto muy corto (${env.JWT_REFRESH_SECRET.length} caracteres). Mínimo 32`);
    }
    
    // Verificar CORS
    if (env.CORS_ORIGIN.length > 0 && !env.CORS_ORIGIN.includes('localhost')) {
      addResult('CORS_ORIGIN', 'ok', `Configurado para: ${env.CORS_ORIGIN.join(', ')}`);
    } else {
      addResult('CORS_ORIGIN', 'warning', 'Incluye localhost. Asegúrate de incluir tu dominio de producción');
    }
    
    // Verificar LOG_LEVEL
    if (env.LOG_LEVEL === 'info' || env.LOG_LEVEL === 'warn') {
      addResult('LOG_LEVEL', 'ok', `Configurado como: ${env.LOG_LEVEL}`);
    } else {
      addResult('LOG_LEVEL', 'warning', `Actualmente: ${env.LOG_LEVEL}. Para producción se recomienda 'info' o 'warn'`);
    }
    
    // Verificar LOG_PRETTY
    if (!env.LOG_PRETTY) {
      addResult('LOG_PRETTY', 'ok', 'Desactivado (correcto para producción)');
    } else {
      addResult('LOG_PRETTY', 'warning', 'Activado. Se recomienda desactivar en producción');
    }
    
  } catch (error: any) {
    addResult('Variables de entorno', 'error', `Error al validar: ${error.message}`);
  }
}

async function verifyDatabase() {
  console.log('\n🗄️  Verificando conexión a base de datos...\n');
  
  try {
    const [rows] = await pool.query('SELECT 1 as test');
    if (Array.isArray(rows) && rows.length > 0) {
      addResult('Conexión a BD', 'ok', 'Conexión exitosa');
    } else {
      addResult('Conexión a BD', 'error', 'No se pudo conectar a la base de datos');
    }
    
    // Verificar que existan las tablas principales
    const [tables] = await pool.query<Array<{ Tables_in_comandero: string }>>(
      "SHOW TABLES LIKE 'usuario'"
    );
    
    if (Array.isArray(tables) && tables.length > 0) {
      addResult('Tablas principales', 'ok', 'Tablas principales existen');
    } else {
      addResult('Tablas principales', 'error', 'Faltan tablas principales. Ejecuta las migraciones');
    }
    
  } catch (error: any) {
    addResult('Conexión a BD', 'error', `Error: ${error.message}`);
  }
}

async function verifyBuild() {
  console.log('\n📦 Verificando build...\n');
  
  try {
    const fs = await import('fs');
    const path = await import('path');
    
    const distPath = path.join(process.cwd(), 'dist', 'server.js');
    
    if (fs.existsSync(distPath)) {
      addResult('Build', 'ok', 'Archivo dist/server.js existe');
    } else {
      addResult('Build', 'error', 'No se encontró dist/server.js. Ejecuta: npm run build');
    }
  } catch (error: any) {
    addResult('Build', 'error', `Error: ${error.message}`);
  }
}

async function main() {
  console.log('🚀 Verificación Pre-Deployment para Comandero Backend\n');
  console.log('=' .repeat(60));
  
  await verifyEnvironment();
  await verifyDatabase();
  await verifyBuild();
  
  console.log('\n' + '='.repeat(60));
  console.log('\n📊 Resumen de Verificación\n');
  
  const okCount = results.filter(r => r.status === 'ok').length;
  const warningCount = results.filter(r => r.status === 'warning').length;
  const errorCount = results.filter(r => r.status === 'error').length;
  
  console.log(`✅ Correctos: ${okCount}`);
  console.log(`⚠️  Advertencias: ${warningCount}`);
  console.log(`❌ Errores: ${errorCount}`);
  
  if (errorCount > 0) {
    console.log('\n❌ Hay errores que deben corregirse antes de desplegar');
    process.exit(1);
  } else if (warningCount > 0) {
    console.log('\n⚠️  Hay advertencias. Revisa antes de desplegar');
    process.exit(0);
  } else {
    console.log('\n✅ Todo está listo para producción');
    process.exit(0);
  }
}

main().catch((error) => {
  logger.error({ err: error }, 'Error en verificación');
  process.exit(1);
});

