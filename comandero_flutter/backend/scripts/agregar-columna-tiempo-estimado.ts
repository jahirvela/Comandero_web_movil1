/**
 * Script para agregar la columna tiempo_estimado_preparacion a la tabla orden
 * Esta columna almacena el tiempo estimado de preparación configurado por el cocinero
 */

import { pool } from '../src/db/pool.js';

async function agregarColumnaTiempoEstimado() {
  try {
    console.log('🔍 Verificando si existe la columna tiempo_estimado_preparacion...');
    
    // Verificar si la columna existe
    const [columns] = await pool.query<Array<{ Field: string }>>(
      `SHOW COLUMNS FROM orden LIKE 'tiempo_estimado_preparacion'`
    );
    
    if (columns.length > 0) {
      console.log('✅ La columna tiempo_estimado_preparacion ya existe.');
      return;
    }
    
    console.log('📝 Agregando columna tiempo_estimado_preparacion...');
    
    // Agregar la columna
    await pool.execute(
      `ALTER TABLE orden 
       ADD COLUMN tiempo_estimado_preparacion INT NULL 
       COMMENT 'Tiempo estimado de preparación en minutos configurado por el cocinero' 
       AFTER estado_orden_id`
    );
    
    console.log('✅ Columna tiempo_estimado_preparacion agregada exitosamente.');
    
  } catch (error: any) {
    console.error('❌ Error al agregar columna tiempo_estimado_preparacion:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

// Ejecutar el script
agregarColumnaTiempoEstimado()
  .then(() => {
    console.log('✅ Script completado exitosamente');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error en el script:', error);
    process.exit(1);
  });

