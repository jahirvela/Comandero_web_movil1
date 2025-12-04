import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';
import * as path from 'path';
import { config } from 'dotenv';
import { getEnv } from '../src/config/env.js';
import { crearBackup } from './backup-database.js';

const execAsync = promisify(exec);

config();

/**
 * Restaura un backup de la base de datos
 */
export async function restaurarBackup(backupPath: string, crearBackupAntes: boolean = true): Promise<void> {
  const env = getEnv();

  console.log('========================================');
  console.log('RESTAURANDO BACKUP DE BASE DE DATOS');
  console.log('========================================\n');

  // Verificar que el archivo existe
  if (!fs.existsSync(backupPath)) {
    throw new Error(`El archivo de backup no existe: ${backupPath}`);
  }

  // Verificar si es un archivo comprimido
  const isCompressed = backupPath.endsWith('.gz');
  const isSQL = backupPath.endsWith('.sql');

  if (!isSQL && !isCompressed) {
    throw new Error('El archivo debe ser un .sql o .sql.gz');
  }

  console.log(`📄 Archivo de backup: ${backupPath}`);
  console.log(`📊 Base de datos destino: ${env.DATABASE_NAME}`);
  console.log('');

  // Crear backup antes de restaurar (por seguridad)
  if (crearBackupAntes) {
    console.log('🔄 Creando backup de seguridad antes de restaurar...\n');
    try {
      await crearBackup({
        filename: `backup_pre_restore_${new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)}`
      });
      console.log('\n✅ Backup de seguridad creado\n');
    } catch (error: any) {
      console.error('⚠️  No se pudo crear backup de seguridad:', error.message);
      console.error('   Continuando con la restauración...\n');
    }
  }

  try {
    // Descomprimir si es necesario
    let sqlContent: string;
    let tempSqlPath: string | null = null;

    if (isCompressed) {
      console.log('📦 Descomprimiendo backup...');
      tempSqlPath = path.join(path.dirname(backupPath), `temp_${path.basename(backupPath, '.gz')}`);
      
      // Usar gunzip o gzip -d según el sistema
      const decompressCmd = process.platform === 'win32' 
        ? `gzip -d -c "${backupPath}" > "${tempSqlPath}"`
        : `gunzip -c "${backupPath}" > "${tempSqlPath}"`;
      
      await execAsync(decompressCmd, { shell: true });
      sqlContent = fs.readFileSync(tempSqlPath, 'utf-8');
      console.log('✅ Backup descomprimido\n');
    } else {
      sqlContent = fs.readFileSync(backupPath, 'utf-8');
    }

    console.log('🔄 Restaurando base de datos...');
    console.log('   Esto puede tomar varios minutos...\n');

    // Construir comando mysql
    const mysqlCmd = 'mysql';
    const mysqlOptions = [
      `--host=${env.DATABASE_HOST}`,
      `--port=${env.DATABASE_PORT}`,
      `--user=${env.DATABASE_USER}`,
      `--password=${env.DATABASE_PASSWORD}`,
      env.DATABASE_NAME
    ];

    const sqlFile = isCompressed ? tempSqlPath! : backupPath;
    const fullCommand = `${mysqlCmd} ${mysqlOptions.join(' ')} < "${sqlFile}"`;

    await execAsync(fullCommand, {
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer
      shell: true
    });

    // Limpiar archivo temporal si existe
    if (tempSqlPath && fs.existsSync(tempSqlPath)) {
      fs.unlinkSync(tempSqlPath);
    }

    console.log('\n========================================');
    console.log('✅ BACKUP RESTAURADO EXITOSAMENTE');
    console.log('========================================');
    console.log(`\n📊 Base de datos: ${env.DATABASE_NAME}`);
    console.log(`📄 Backup restaurado: ${path.basename(backupPath)}`);
    console.log('\n💡 Verifica que todos los datos se restauraron correctamente.');

  } catch (error: any) {
    console.error('\n❌ Error al restaurar backup:', error.message);
    
    // Verificar si mysql está instalado
    if (error.message.includes('mysql') || error.message.includes('not found')) {
      console.error('\n⚠️  mysql no está instalado o no está en el PATH.');
      console.error('   En Windows, mysql viene con MySQL Server.');
      console.error('   Asegúrate de que MySQL está instalado y en el PATH del sistema.');
    }
    
    throw error;
  }
}

// Si se ejecuta directamente
if (import.meta.url === `file://${process.argv[1]}`) {
  const backupPath = process.argv[2];
  
  if (!backupPath) {
    console.error('❌ Debes especificar la ruta del archivo de backup');
    console.error('   Uso: npm run restore:backup -- "ruta/al/backup.sql"');
    process.exit(1);
  }

  restaurarBackup(backupPath)
    .then(() => {
      console.log('\n✅ Restauración completada');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Error:', error);
      process.exit(1);
    });
}

