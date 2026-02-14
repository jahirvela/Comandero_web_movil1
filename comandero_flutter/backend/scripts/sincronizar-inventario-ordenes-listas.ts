/**
 * Sincroniza el inventario con las órdenes que ya estaban en "listo" o "listo para recoger"
 * pero no se les descontó por un bug anterior (origen 'receta_automatica' no válido en BD).
 * Ejecutar una vez para reflejar en inventario lo que ya fue marcado como listo.
 *
 * Uso: npm run sync:inventario-ordenes-listas
 */

import 'dotenv/config';
import { pool } from '../src/db/pool.js';
import { sincronizarInventarioOrdenesListas } from '../src/modules/inventario/inventario.service.js';

async function main() {
  console.log('📦 Sincronizando inventario con órdenes ya marcadas como listo/listo para recoger...\n');

  try {
    const result = await sincronizarInventarioOrdenesListas();

    console.log('\n✅ Resumen:');
    console.log(`   Órdenes procesadas (descuento aplicado): ${result.procesadas}`);
    console.log(`   Órdenes omitidas (ya tenían descuento):   ${result.omitidas}`);
    console.log(`   Errores:                                  ${result.errores}`);
    console.log('\n📦 Inventario actualizado. El descuento automático ya funciona al marcar "listo".\n');
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error('❌ Error:', msg);
    throw error;
  } finally {
    try {
      await pool.end();
    } catch {
      // ignorar error al cerrar pool
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
