import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';
import * as path from 'path';
import { config } from 'dotenv';
import { getEnv } from '../src/config/env.js';

const execAsync = promisify(exec);

config();

interface BackupOptions {
  outputDir?: string;
  filename?: string;
  compress?: boolean;
  includeData?: boolean;
  includeStructure?: boolean;
}

/**
 * Crea un backup completo de la base de datos
 */
export async function crearBackup(options: BackupOptions = {}): Promise<string> {
  const env = getEnv();
  const {
    outputDir = path.join(process.cwd(), 'backups'),
    filename,
    compress = true,
    includeData = true,
    includeStructure = true
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

  try {
    // Construir comando mysqldump
    let mysqldumpCmd = 'mysqldump';
    
    // Opciones básicas
    const dumpOptions = [
      `--host=${env.DATABASE_HOST}`,
      `--port=${env.DATABASE_PORT}`,
      `--user=${env.DATABASE_USER}`,
      `--password=${env.DATABASE_PASSWORD}`,
      '--single-transaction', // Para InnoDB, asegura consistencia
      '--routines', // Incluir stored procedures y functions
      '--triggers', // Incluir triggers
      '--events', // Incluir events
      '--add-drop-table', // Agregar DROP TABLE antes de CREATE TABLE
      '--add-locks', // Agregar locks para mejor rendimiento
      '--disable-keys', // Deshabilitar índices durante importación
    ];

    if (includeStructure && !includeData) {
      dumpOptions.push('--no-data'); // Solo estructura
    } else if (includeData && !includeStructure) {
      dumpOptions.push('--no-create-info'); // Solo datos
    }

    dumpOptions.push(env.DATABASE_NAME);

    const fullCommand = `${mysqldumpCmd} ${dumpOptions.join(' ')}`;

    console.log('🔄 Ejecutando mysqldump...');
    console.log('   Esto puede tomar varios minutos dependiendo del tamaño de la BD...\n');

    // Ejecutar mysqldump
    const { stdout, stderr } = await execAsync(fullCommand, {
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer
      encoding: 'buffer' as any
    });

    if (stderr && !stderr.toString().includes('Warning')) {
      console.error('⚠️  Advertencias de mysqldump:', stderr.toString());
    }

    // Escribir el dump a archivo
    if (compress) {
      // Primero escribir el SQL, luego comprimir
      fs.writeFileSync(sqlPath, stdout);
      
      // Comprimir con gzip
      try {
        if (process.platform === 'win32') {
          // Windows: usar gzip si está disponible (Git Bash, WSL, o instalado)
          await execAsync(`gzip -f "${sqlPath}"`, { shell: true });
        } else {
          // Linux/Mac
          await execAsync(`gzip -f "${sqlPath}"`);
        }
        console.log(`✅ Backup comprimido creado: ${finalPath}`);
      } catch (gzipError: any) {
        // Si gzip no está disponible, guardar sin comprimir
        console.warn('⚠️  gzip no está disponible, guardando sin comprimir');
        console.log(`✅ Backup creado: ${sqlPath}`);
        // No eliminar el archivo SQL si falla la compresión
      }
    } else {
      fs.writeFileSync(sqlPath, stdout);
      console.log(`✅ Backup creado: ${sqlPath}`);
    }

    // Obtener tamaño del archivo final
    const finalFile = compress && fs.existsSync(finalPath) ? finalPath : sqlPath;
    const stats = fs.statSync(finalFile);
    const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
    console.log(`📦 Tamaño del archivo: ${fileSizeMB} MB`);

    // Guardar metadata del backup
    const finalFilename = compress && fs.existsSync(finalPath) ? path.basename(finalPath) : path.basename(sqlPath);
    const metadata = {
      timestamp: new Date().toISOString(),
      database: env.DATABASE_NAME,
      filename: finalFilename,
      size: stats.size,
      sizeMB: parseFloat(fileSizeMB),
      compressed: compress && fs.existsSync(finalPath),
      includesData: includeData,
      includesStructure: includeStructure
    };

    const metadataPath = path.join(outputDir, `${baseFilename}.meta.json`);
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));

    const finalBackupPath = compress && fs.existsSync(finalPath) ? finalPath : sqlPath;
    
    console.log('\n========================================');
    console.log('✅ BACKUP COMPLETADO EXITOSAMENTE');
    console.log('========================================');
    console.log(`\n📄 Archivo: ${path.basename(finalBackupPath)}`);
    console.log(`📊 Tamaño: ${fileSizeMB} MB`);
    console.log(`📁 Ubicación: ${outputDir}`);
    console.log(`\n💡 Para restaurar este backup, ejecuta:`);
    console.log(`   npm run restore:backup -- "${finalBackupPath}"`);

    return finalBackupPath;
  } catch (error: any) {
    console.error('\n❌ Error al crear backup:', error.message);
    
    // Verificar si mysqldump está instalado
    if (error.message.includes('mysqldump') || error.message.includes('not found')) {
      console.error('\n⚠️  mysqldump no está instalado o no está en el PATH.');
      console.error('   En Windows, mysqldump viene con MySQL Server.');
      console.error('   Asegúrate de que MySQL está instalado y en el PATH del sistema.');
    }
    
    throw error;
  }
}

// Si se ejecuta directamente
if (import.meta.url === `file://${process.argv[1]}`) {
  crearBackup()
    .then((backupPath) => {
      console.log(`\n✅ Backup guardado en: ${backupPath}`);
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Error:', error);
      process.exit(1);
    });
}

