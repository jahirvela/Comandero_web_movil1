import { config } from 'dotenv';
import { pool } from '../src/db/pool.js';
import { getEnv } from '../src/config/env.js';

config();

interface ProductoRow {
  id: number;
  nombre: string;
  descripcion: string | null;
  precio: number;
  categoria_id: number | null;
  disponible: number;
  sku: string | null;
  inventariable: number;
  creado_en: Date;
  actualizado_en: Date;
  categoria_nombre?: string;
}

async function verificarProductos() {
  try {
    const env = getEnv();

    console.log('========================================');
    console.log('PRODUCTOS EN LA BASE DE DATOS');
    console.log('========================================\n');

    // Verificar productos en tabla producto
    const [productos] = await pool.query<ProductoRow[]>(
      `
      SELECT 
        p.id,
        p.nombre,
        p.descripcion,
        p.precio,
        p.categoria_id,
        p.disponible,
        p.sku,
        p.inventariable,
        p.creado_en,
        p.actualizado_en,
        c.nombre AS categoria_nombre
      FROM producto p
      LEFT JOIN categoria c ON c.id = p.categoria_id
      ORDER BY p.id
      `
    );

    if (productos.length === 0) {
      console.log('⚠️  No se encontraron productos en la tabla "producto"');
    } else {
      console.log(`✅ Se encontraron ${productos.length} producto(s):\n`);
      
      // Agrupar por categoría
      const productosPorCategoria = new Map<string, ProductoRow[]>();
      
      productos.forEach((producto) => {
        const categoria = producto.categoria_nombre || 'Sin categoría';
        if (!productosPorCategoria.has(categoria)) {
          productosPorCategoria.set(categoria, []);
        }
        productosPorCategoria.get(categoria)!.push(producto);
      });

      // Mostrar productos agrupados por categoría
      productosPorCategoria.forEach((productosCategoria, categoria) => {
        console.log(`\n📁 ${categoria.toUpperCase()} (${productosCategoria.length} producto(s))`);
        console.log('─'.repeat(60));
        
        productosCategoria.forEach((producto) => {
          console.log(`\n   🍽️  ID: ${producto.id}`);
          console.log(`      Nombre: ${producto.nombre}`);
          if (producto.descripcion) {
            console.log(`      Descripción: ${producto.descripcion}`);
          }
          console.log(`      Precio: $${Number(producto.precio).toFixed(2)}`);
          console.log(`      Disponible: ${producto.disponible ? '✅ Sí' : '❌ No'}`);
          if (producto.sku) {
            console.log(`      SKU: ${producto.sku}`);
          }
          console.log(`      Inventariable: ${producto.inventariable ? 'Sí' : 'No'}`);
          console.log(`      Creado: ${new Date(producto.creado_en).toLocaleDateString()}`);
        });
      });

      // Resumen
      console.log('\n' + '='.repeat(60));
      console.log('📊 RESUMEN');
      console.log('='.repeat(60));
      console.log(`   Total de productos: ${productos.length}`);
      console.log(`   Productos disponibles: ${productos.filter(p => p.disponible).length}`);
      console.log(`   Productos no disponibles: ${productos.filter(p => !p.disponible).length}`);
      console.log(`   Categorías: ${productosPorCategoria.size}`);
      
      // Mostrar precios
      const precios = productos.map(p => Number(p.precio)).filter(p => !isNaN(p));
      if (precios.length > 0) {
        const precioMin = Math.min(...precios);
        const precioMax = Math.max(...precios);
        const precioPromedio = precios.reduce((a, b) => a + b, 0) / precios.length;
        console.log(`   Precio mínimo: $${precioMin.toFixed(2)}`);
        console.log(`   Precio máximo: $${precioMax.toFixed(2)}`);
        console.log(`   Precio promedio: $${precioPromedio.toFixed(2)}`);
      }
    }

    // Verificar también en tabla productos (plural) por si hay datos ahí
    try {
      const [productosPlural] = await pool.query<any[]>(
        'SELECT COUNT(*) as total FROM productos'
      );
      
      if (productosPlural.length > 0 && productosPlural[0].total > 0) {
        console.log('\n⚠️  NOTA: También existe la tabla "productos" (plural)');
        console.log(`   Productos en tabla "productos": ${productosPlural[0].total}`);
        console.log('   Considera migrar estos datos a la tabla "producto" (singular)');
      }
    } catch (error: any) {
      // La tabla productos no existe, está bien
    }

    console.log('\n========================================');
    console.log('✅ VERIFICACIÓN COMPLETADA');
    console.log('========================================');

  } catch (error: any) {
    console.error('❌ Error durante la verificación:', error.message);
    if (error.code) {
      console.error('   Código:', error.code);
    }
    throw error;
  } finally {
    await pool.end();
  }
}

verificarProductos().catch(console.error);

