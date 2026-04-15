import { config } from 'dotenv';
import mysql from 'mysql2/promise';
import { getEnv } from '../src/config/env.js';
import * as fs from 'fs';
import * as path from 'path';
import { createGzip } from 'zlib';
import { pipeline } from 'stream/promises';

config();

interface BackupOptions {
  outputDir?: string;
  filename?: string;
  compress?: boolean;
}

/**
 * Crea un backup completo de la base de datos usando Node.js directamente
 * No requiere mysqldump en el PATH
 */
export async function crearBackupNode(options: BackupOptions = {}): Promise<string> {
  const env = getEnv();
  const {
    outputDir = path.join(process.cwd(), 'backups'),
    filename,
    compress = true
  } = options;

  // Crear directorio de backups si no existe
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Generar nombre de archivo con timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const baseFilename = filename || `backup_${env.DATABASE_NAME}_${timestamp}`;
  const sqlFilename = `${baseFilename}.sql`;
  const sqlPath = path.join(outputDir, sqlFilename);
  const finalPath = compress ? `${sqlPath}.gz` : sqlPath;

  console.log('========================================');
  console.log('CREANDO BACKUP DE BASE DE DATOS');
  console.log('========================================\n');

  console.log(`📊 Base de datos: ${env.DATABASE_NAME}`);
  console.log(`📁 Directorio: ${outputDir}`);
  console.log(`📄 Archivo: ${path.basename(finalPath)}`);
  console.log('');

  let connection: mysql.Connection | null = null;
  const sqlContent: string[] = [];

  try {
    connection = await mysql.createConnection({
      host: env.DATABASE_HOST,
      port: env.DATABASE_PORT,
      user: env.DATABASE_USER,
      password: env.DATABASE_PASSWORD,
      database: env.DATABASE_NAME,
      multipleStatements: true
    });

    console.log('✅ Conectado a la base de datos');
    console.log('🔄 Generando backup...\n');

    // Agregar headers del dump
    sqlContent.push('-- ============================================');
    sqlContent.push('-- BACKUP DE BASE DE DATOS');
    sqlContent.push(`-- Base de datos: ${env.DATABASE_NAME}`);
    sqlContent.push(`-- Fecha: ${new Date().toISOString()}`);
    sqlContent.push('-- ============================================\n');
    sqlContent.push(`USE \`${env.DATABASE_NAME}\`;\n`);
    sqlContent.push('SET NAMES utf8mb4;\n');
    sqlContent.push('SET FOREIGN_KEY_CHECKS = 0;\n\n');

    // Obtener todas las tablas
    const [tables] = await connection.query<Array<{ TABLE_NAME: string }>>(
      `SELECT TABLE_NAME 
       FROM INFORMATION_SCHEMA.TABLES 
       WHERE TABLE_SCHEMA = ? 
       ORDER BY TABLE_NAME`,
      [env.DATABASE_NAME]
    );

    console.log(`📋 Encontradas ${tables.length} tablas\n`);

    // Para cada tabla, obtener estructura y datos
    for (const table of tables) {
      const tableName = table.TABLE_NAME;
      console.log(`   📄 Procesando tabla: ${tableName}...`);

      // Obtener estructura de la tabla (CREATE TABLE)
      const [createTable] = await connection.query<Array<{ 'Create Table': string }>>(
        `SHOW CREATE TABLE \`${tableName}\``
      );

      if (createTable.length > 0) {
        sqlContent.push(`\n-- ============================================`);
        sqlContent.push(`-- Estructura de tabla: ${tableName}`);
        sqlContent.push(`-- ============================================\n`);
        sqlContent.push(`DROP TABLE IF EXISTS \`${tableName}\`;\n`);
        sqlContent.push(`${createTable[0]['Create Table']};\n\n`);

        // Obtener datos de la tabla
        const [rows] = await connection.query<any[]>(
          `SELECT * FROM \`${tableName}\``
        );

        if (rows.length > 0) {
          sqlContent.push(`-- Datos de tabla: ${tableName}\n`);
          sqlContent.push(`LOCK TABLES \`${tableName}\` WRITE;\n`);

          // Insertar datos en lotes
          const batchSize = 100;
          for (let i = 0; i < rows.length; i += batchSize) {
            const batch = rows.slice(i, i + batchSize);
            const columns = Object.keys(batch[0]);
            const columnNames = columns.map(col => `\`${col}\``).join(', ');

            sqlContent.push(`INSERT INTO \`${tableName}\` (${columnNames}) VALUES\n`);

            const values = batch.map((row, idx) => {
              const rowValues = columns.map(col => {
                const value = row[col];
                if (value === null) return 'NULL';
                if (typeof value === 'string') {
                  // Escapar comillas y caracteres especiales
                  return `'${value.replace(/'/g, "''").replace(/\\/g, '\\\\')}'`;
                }
                if (value instanceof Date) {
                  return `'${value.toISOString().slice(0, 19).replace('T', ' ')}'`;
                }
                if (Buffer.isBuffer(value)) {
                  return `0x${value.toString('hex')}`;
                }
                return String(value);
              }).join(', ');
              return `(${rowValues})${idx < batch.length - 1 ? ',' : ';'}`;
            });

            sqlContent.push(values.join('\n'));
            sqlContent.push('\n');
          }

          sqlContent.push(`UNLOCK TABLES;\n\n`);
        } else {
          sqlContent.push(`-- Tabla ${tableName} está vacía\n\n`);
        }
      }
    }

    // Obtener stored procedures, functions y triggers
    console.log(`\n   🔧 Procesando procedimientos almacenados...`);
    const [procedures] = await connection.query<Array<{ ROUTINE_NAME: string; ROUTINE_DEFINITION: string; ROUTINE_TYPE: string }>>(
      `SELECT ROUTINE_NAME, ROUTINE_DEFINITION, ROUTINE_TYPE
       FROM INFORMATION_SCHEMA.ROUTINES
       WHERE ROUTINE_SCHEMA = ?`,
      [env.DATABASE_NAME]
    );

    if (procedures.length > 0) {
      sqlContent.push('-- ============================================');
      sqlContent.push('-- Procedimientos almacenados y funciones');
      sqlContent.push('-- ============================================\n');
      for (const proc of procedures) {
        sqlContent.push(`-- ${proc.ROUTINE_TYPE}: ${proc.ROUTINE_NAME}\n`);
        sqlContent.push(`${proc.ROUTINE_DEFINITION};\n\n`);
      }
    }

    // Restaurar foreign keys
    sqlContent.push('SET FOREIGN_KEY_CHECKS = 1;\n');

    // Escribir el archivo SQL
    const sqlText = sqlContent.join('\n');
    fs.writeFileSync(sqlPath, sqlText, 'utf-8');

    console.log(`✅ Backup SQL creado: ${sqlPath}`);

    // Comprimir si es necesario
    if (compress) {
      console.log('📦 Comprimiendo backup...');
      const readStream = fs.createReadStream(sqlPath);
      const writeStream = fs.createWriteStream(finalPath);
      const gzipStream = createGzip();

      await pipeline(readStream, gzipStream, writeStream);

      // Eliminar archivo SQL sin comprimir
      fs.unlinkSync(sqlPath);
      console.log(`✅ Backup comprimido creado: ${finalPath}`);
    }

    // Obtener tamaño del archivo
    const finalFile = compress ? finalPath : sqlPath;
    const stats = fs.statSync(finalFile);
    const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
    console.log(`📦 Tamaño del archivo: ${fileSizeMB} MB`);

    // Guardar metadata
    const finalFilename = path.basename(finalFile);
    const metadata = {
      timestamp: new Date().toISOString(),
      database: env.DATABASE_NAME,
      filename: finalFilename,
      size: stats.size,
      sizeMB: parseFloat(fileSizeMB),
      compressed: compress,
      tables: tables.length,
      includesData: true,
      includesStructure: true
    };

    const metadataPath = path.join(outputDir, `${baseFilename}.meta.json`);
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));

    console.log('\n========================================');
    console.log('✅ BACKUP COMPLETADO EXITOSAMENTE');
    console.log('========================================');
    console.log(`\n📄 Archivo: ${finalFilename}`);
    console.log(`📊 Tamaño: ${fileSizeMB} MB`);
    console.log(`📁 Ubicación: ${outputDir}`);
    console.log(`\n💡 Para restaurar este backup, ejecuta:`);
    console.log(`   npm run restore:backup -- "${finalFile}"`);

    return finalFile;
  } catch (error: any) {
    console.error('\n❌ Error al crear backup:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    throw error;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Si se ejecuta directamente
const isMainModule = import.meta.url === `file://${process.argv[1]}` || 
                     process.argv[1]?.endsWith('backup-database-node.ts') ||
                     process.argv[1]?.includes('backup-database-node');

const backupOutputDir = process.env.BACKUP_OUTPUT_DIR?.trim();

if (isMainModule || !process.env.npm_config_user_config) {
  crearBackupNode(backupOutputDir ? { outputDir: backupOutputDir } : {})
    .then((backupPath) => {
      console.log(`\n✅ Backup guardado en: ${backupPath}`);
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Error:', error);
      process.exit(1);
    });
}

