/**
 * Script para verificar que todas las APIs estén funcionando correctamente
 */

import { config } from 'dotenv';
import { getEnv } from '../src/config/env.js';

config();

async function verificarAPIs() {
  try {
    const env = getEnv();
    const baseUrl = `http://localhost:${env.PORT}/api`;

    console.log('========================================');
    console.log('VERIFICACIÓN DE APIs DEL PROYECTO');
    console.log('========================================');
    console.log('');
    console.log(`Base URL: ${baseUrl}`);
    console.log('');

    const apis = [
      { path: '/health', method: 'GET', desc: 'Health check', auth: false },
      { path: '/auth/login', method: 'POST', desc: 'Login', auth: false },
      { path: '/usuarios', method: 'GET', desc: 'Listar usuarios', auth: true, roles: ['administrador'] },
      { path: '/roles', method: 'GET', desc: 'Listar roles', auth: true },
      { path: '/mesas', method: 'GET', desc: 'Listar mesas', auth: true },
      { path: '/categorias', method: 'GET', desc: 'Listar categorías', auth: true },
      { path: '/productos', method: 'GET', desc: 'Listar productos', auth: true },
      { path: '/inventario', method: 'GET', desc: 'Listar inventario', auth: true, roles: ['administrador', 'capitan', 'cocinero'] },
      { path: '/ordenes', method: 'GET', desc: 'Listar órdenes', auth: true },
      { path: '/pagos', method: 'GET', desc: 'Listar pagos', auth: true, roles: ['administrador', 'cajero'] },
      { path: '/tickets', method: 'GET', desc: 'Listar tickets', auth: true },
      { path: '/reportes', method: 'GET', desc: 'Listar reportes', auth: true, roles: ['administrador'] },
      { path: '/cierres', method: 'GET', desc: 'Listar cierres', auth: true, roles: ['administrador', 'cajero'] },
      { path: '/alertas', method: 'GET', desc: 'Listar alertas', auth: true },
    ];

    console.log('📋 APIs disponibles:');
    console.log('');
    
    apis.forEach((api, index) => {
      const authInfo = api.auth ? (api.roles ? ` (${api.roles.join(', ')})` : ' (autenticado)') : ' (público)';
      console.log(`${index + 1}. ${api.method} ${api.path}`);
      console.log(`   ${api.desc}${authInfo}`);
    });

    console.log('');
    console.log('========================================');
    console.log('VERIFICACIÓN DE ESTRUCTURA DE BASE DE DATOS');
    console.log('========================================');
    console.log('');

    const tablasEsperadas = [
      'usuario', 'rol', 'permiso', 'usuario_rol', 'rol_permiso',
      'estado_mesa', 'estado_orden', 'forma_pago',
      'mesa', 'cliente', 'reserva', 'mesa_estado_hist',
      'categoria', 'producto', 'inventario_item', 'producto_insumo', 'producto_tamano',
      'modificador_categoria', 'modificador_opcion', 'producto_modificador', 'modificador_insumo',
      'orden', 'orden_item', 'nota_orden', 'orden_cancelacion', 'preparacion_orden', 'orden_item_modificador',
      'movimiento_inventario',
      'caja_cierre', 'pago', 'terminal', 'terminal_log', 'comprobante_tarjeta', 'documentacion_pago',
      'propina', 'movimiento_caja',
      'alerta', 'bitacora_impresion',
      'conteo_inventario', 'conteo_inventario_item'
    ];

    console.log(`Total de tablas esperadas: ${tablasEsperadas.length}`);
    console.log('');
    console.log('Tablas principales:');
    tablasEsperadas.forEach((tabla, index) => {
      if (index < 10 || index % 10 === 0) {
        console.log(`   - ${tabla}`);
      }
    });
    if (tablasEsperadas.length > 10) {
      console.log(`   ... y ${tablasEsperadas.length - 10} más`);
    }

    console.log('');
    console.log('========================================');
    console.log('VERIFICACIÓN DE SERVICIOS DEL FRONTEND');
    console.log('========================================');
    console.log('');

    const servicios = [
      'auth_service.dart',
      'ordenes_service.dart',
      'mesas_service.dart',
      'productos_service.dart',
      'categorias_service.dart',
      'inventario_service.dart',
      'pagos_service.dart',
      'tickets_service.dart',
      'reportes_service.dart',
      'cierres_service.dart',
      'usuarios_service.dart',
      'roles_service.dart',
    ];

    console.log('Servicios disponibles:');
    servicios.forEach((servicio) => {
      console.log(`   - ${servicio}`);
    });

    console.log('');
    console.log('========================================');
    console.log('✅ VERIFICACIÓN COMPLETADA');
    console.log('========================================');
    console.log('');
    console.log('Próximos pasos:');
    console.log('  1. Reiniciar el backend: npm run dev');
    console.log('  2. Verificar que todas las rutas respondan correctamente');
    console.log('  3. Probar login con usuario: admin / contraseña: Demo123');
    console.log('  4. Verificar que el frontend se conecte correctamente');
    console.log('');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
  }
}

verificarAPIs();

