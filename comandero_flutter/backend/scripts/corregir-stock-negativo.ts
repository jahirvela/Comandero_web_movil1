/**
 * Script para corregir valores negativos en el inventario
 * Establece en 0 cualquier cantidad_actual que sea negativa
 */

import { pool } from '../src/db/pool.js';
import { ResultSetHeader } from 'mysql2';

async function corregirStockNegativo() {
  try {
    console.log('🔍 Buscando items de inventario con stock negativo...');
    
    // Buscar items con stock negativo
    const [itemsNegativos] = await pool.query<Array<{ id: number; nombre: string; cantidad_actual: number }>>(
      `SELECT id, nombre, cantidad_actual 
       FROM inventario_item 
       WHERE cantidad_actual < 0`
    );
    
    if (itemsNegativos.length === 0) {
      console.log('✅ No se encontraron items con stock negativo.');
      return;
    }
    
    console.log(`⚠️ Encontrados ${itemsNegativos.length} item(s) con stock negativo:`);
    itemsNegativos.forEach(item => {
      console.log(`   - ${item.nombre} (ID: ${item.id}): ${item.cantidad_actual}`);
    });
    
    // Corregir todos los valores negativos a 0
    const [result] = await pool.execute<ResultSetHeader>(
      `UPDATE inventario_item 
       SET cantidad_actual = 0, actualizado_en = NOW()
       WHERE cantidad_actual < 0`
    );
    
    console.log(`\n✅ Se corrigieron ${result.affectedRows} item(s) de inventario.`);
    console.log('   Todos los valores negativos fueron establecidos en 0.\n');
    
  } catch (error: any) {
    console.error('❌ Error al corregir stock negativo:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

// Ejecutar el script
corregirStockNegativo()
  .then(() => {
    console.log('✅ Script completado exitosamente');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error en el script:', error);
    process.exit(1);
  });

