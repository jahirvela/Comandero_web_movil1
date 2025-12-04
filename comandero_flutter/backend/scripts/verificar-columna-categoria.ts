import { pool } from '../src/db/pool.js';

async function verificarYAgregarColumnaCategoria() {
  try {
    // Verificar si la columna existe
    const [columns] = await pool.query<Array<{ COLUMN_NAME: string }>>(
      `
      SELECT COLUMN_NAME
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'inventario_item'
        AND COLUMN_NAME = 'categoria'
      `
    );

    if (columns.length === 0) {
      // La columna no existe, agregarla
      console.log('Columna categoria no existe. Agregándola...');
      await pool.execute(
        `
        ALTER TABLE inventario_item
        ADD COLUMN categoria VARCHAR(64) NOT NULL DEFAULT 'Otros'
        `
      );
      console.log('✓ Columna categoria agregada exitosamente');
    } else {
      console.log('✓ La columna categoria ya existe');
    }
  } catch (error: any) {
    console.error('Error al verificar/agregar columna categoria:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

verificarYAgregarColumnaCategoria()
  .then(() => {
    console.log('Proceso completado');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });

