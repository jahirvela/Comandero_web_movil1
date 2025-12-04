import { pool } from '../src/config/database.js';

async function verificarEstados() {
  try {
    const [rows] = await pool.query<any[]>(
      `SELECT id, nombre FROM estado_orden ORDER BY id`
    );
    
    console.log('\n=== ESTADOS DE ORDEN EN LA BD ===');
    rows.forEach((row) => {
      console.log(`ID: ${row.id}, Nombre: "${row.nombre}"`);
    });
    
    // Verificar órdenes y sus estados
    const [ordenes] = await pool.query<any[]>(
      `SELECT o.id, o.creado_en, eo.nombre AS estado_nombre 
       FROM orden o 
       JOIN estado_orden eo ON eo.id = o.estado_orden_id 
       ORDER BY o.creado_en DESC 
       LIMIT 10`
    );
    
    console.log('\n=== ÚLTIMAS 10 ÓRDENES ===');
    ordenes.forEach((orden) => {
      const fecha = orden.creado_en instanceof Date 
        ? orden.creado_en.toISOString() 
        : new Date(orden.creado_en).toISOString();
      console.log(`Orden ${orden.id}: Estado="${orden.estado_nombre}", Creada=${fecha}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

verificarEstados();

