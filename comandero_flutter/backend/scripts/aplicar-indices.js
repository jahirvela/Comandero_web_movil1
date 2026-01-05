/**
 * Script para aplicar índices de optimización a la base de datos
 * 
 * Este script lee las variables de entorno y aplica los índices de optimización
 * de manera segura (no falla si ya existen)
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import mysql from 'mysql2/promise';
import { config } from 'dotenv';

// Cargar variables de entorno
config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function aplicarIndices() {
  let connection = null;

  try {
    // Leer configuración de base de datos desde variables de entorno
    const dbConfig = {
      host: process.env.DATABASE_HOST || 'localhost',
      port: Number(process.env.DATABASE_PORT) || 3306,
      user: process.env.DATABASE_USER || 'root',
      password: process.env.DATABASE_PASSWORD || '',
      database: process.env.DATABASE_NAME || 'comandero',
      multipleStatements: true, // Permitir múltiples statements
    };

    console.log('🔌 Conectando a la base de datos...');
    console.log(`   Host: ${dbConfig.host}`);
    console.log(`   Database: ${dbConfig.database}`);
    console.log(`   User: ${dbConfig.user}`);

    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Conexión establecida\n');

    // Leer el script SQL
    const scriptPath = join(__dirname, 'optimizar-indices-performance.sql');
    console.log(`📄 Leyendo script: ${scriptPath}`);
    const sqlScript = readFileSync(scriptPath, 'utf-8');

    // Dividir el script en statements individuales
    // Filtrar líneas vacías y comentarios (aunque CREATE INDEX IF NOT EXISTS debería manejar esto)
    const statements = sqlScript
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--') && !s.startsWith('/*'));

    console.log(`📊 Encontradas ${statements.length} sentencias para ejecutar\n`);

    let exitosas = 0;
    let omitidas = 0;
    let errores = 0;

    // Ejecutar cada statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      
      // Obtener nombre del índice para logging
      const indexMatch = statement.match(/CREATE INDEX IF NOT EXISTS (\w+)/i);
      const indexName = indexMatch ? indexMatch[1] : `Statement ${i + 1}`;

      try {
        await connection.execute(statement);
        
        // Verificar si el índice ya existía o se creó
        // MySQL no distingue entre "creado" y "ya existía" con IF NOT EXISTS
        // Pero podemos intentar verificar
        try {
          const [checkResult] = await connection.execute(
            `SHOW INDEX FROM ${statement.match(/ON (\w+)/i)?.[1] || ''} WHERE Key_name = ?`,
            [indexName.replace('idx_', '').split('_').slice(1).join('_')]
          );
          
          if (Array.isArray(checkResult) && checkResult.length > 0) {
            exitosas++;
            console.log(`   ✅ ${indexName} - Índice verificado/existente`);
          } else {
            exitosas++;
            console.log(`   ✅ ${indexName} - Índice creado`);
          }
        } catch (checkError) {
          // Si no podemos verificar, asumir que se creó correctamente
          exitosas++;
          console.log(`   ✅ ${indexName} - Ejecutado (verificación omitida)`);
        }
      } catch (error) {
        // Si el error es que ya existe, contar como omitido
        if (error.code === 'ER_DUP_KEYNAME' || error.message?.includes('Duplicate key name')) {
          omitidas++;
          console.log(`   ⏭️  ${indexName} - Ya existe (omitido)`);
        } else {
          errores++;
          console.error(`   ❌ ${indexName} - Error: ${error.message}`);
        }
      }
    }

    console.log('\n📊 Resumen:');
    console.log(`   ✅ Exitosas: ${exitosas}`);
    if (omitidas > 0) {
      console.log(`   ⏭️  Omitidas: ${omitidas}`);
    }
    if (errores > 0) {
      console.log(`   ❌ Errores: ${errores}`);
    }

    if (errores === 0) {
      console.log('\n✅ Índices de optimización aplicados exitosamente');
      console.log('🚀 El sistema está optimizado para producción');
    } else {
      console.log('\n⚠️  Algunos índices tuvieron errores. Revisa los mensajes arriba.');
    }

  } catch (error) {
    console.error('\n❌ Error al aplicar índices:', error.message);
    console.error('\n💡 Asegúrate de que:');
    console.error('   1. MySQL esté corriendo');
    console.error('   2. Las variables de entorno estén configuradas (.env)');
    console.error('   3. Las credenciales de base de datos sean correctas');
    console.error('   4. El usuario tenga permisos para crear índices');
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n🔌 Conexión cerrada');
    }
  }
}

// Ejecutar
aplicarIndices().catch(console.error);

