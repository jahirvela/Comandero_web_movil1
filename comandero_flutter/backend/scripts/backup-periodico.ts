import { config } from 'dotenv';
import { crearBackupNode } from './backup-database-node.js';
import * as fs from 'fs';
import * as path from 'path';

config();

/**
 * Script para crear backups periódicos
 * Puede ser ejecutado manualmente o programado con cron/task scheduler
 */
async function crearBackupPeriodico() {
  try {
    console.log('========================================');
    console.log('BACKUP PERIÓDICO AUTOMÁTICO');
    console.log('========================================\n');

    const timestamp = new Date();
    const fecha = timestamp.toISOString().split('T')[0]; // YYYY-MM-DD
    
    // Crear backup diario
    const backupPath = await crearBackupNode({
      filename: `backup_diario_${fecha}`,
      compress: true
    });

    // Limpiar backups antiguos (mantener solo los últimos 30 días)
    limpiarBackupsAntiguos(30);

    console.log('\n✅ Backup periódico completado');
    console.log(`📄 Archivo: ${path.basename(backupPath)}`);
    
    return backupPath;
  } catch (error: any) {
    console.error('\n❌ Error en backup periódico:', error.message);
    throw error;
  }
}

/**
 * Elimina backups más antiguos que el número de días especificado
 */
function limpiarBackupsAntiguos(diasARetener: number = 30) {
  const backupsDir = path.join(process.cwd(), 'backups');
  
  if (!fs.existsSync(backupsDir)) {
    return;
  }

  const archivos = fs.readdirSync(backupsDir);
  const ahora = Date.now();
  const milisegundosPorDia = 24 * 60 * 60 * 1000;
  const fechaLimite = ahora - (diasARetener * milisegundosPorDia);

  let eliminados = 0;
  let espacioLiberado = 0;

  archivos.forEach((archivo) => {
    // Solo procesar archivos .sql, .sql.gz y .meta.json
    if (!archivo.match(/\.(sql|gz|json)$/)) {
      return;
    }

    const archivoPath = path.join(backupsDir, archivo);
    const stats = fs.statSync(archivoPath);

    if (stats.mtimeMs < fechaLimite) {
      espacioLiberado += stats.size;
      fs.unlinkSync(archivoPath);
      eliminados++;
    }
  });

  if (eliminados > 0) {
    const espacioMB = (espacioLiberado / (1024 * 1024)).toFixed(2);
    console.log(`\n🧹 Limpieza de backups antiguos:`);
    console.log(`   Archivos eliminados: ${eliminados}`);
    console.log(`   Espacio liberado: ${espacioMB} MB`);
  }
}

// Si se ejecuta directamente
if (import.meta.url === `file://${process.argv[1]}`) {
  crearBackupPeriodico()
    .then(() => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Error:', error);
      process.exit(1);
    });
}

export { crearBackupPeriodico, limpiarBackupsAntiguos };

