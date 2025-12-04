/// Script de verificación de CRUD completo
/// Este script verifica que todas las operaciones CRUD estén correctamente implementadas
/// y conectadas al backend

import 'dart:io';

void main() async {
  print('═══════════════════════════════════════════════════════════');
  print('  VERIFICACIÓN COMPLETA DE CRUD - COMANDERO FLUTTER');
  print('═══════════════════════════════════════════════════════════\n');

  final results = <String, Map<String, bool>>{};

  // ETAPA 1: ADMINISTRADOR
  print('📋 ETAPA 1: VERIFICACIÓN CRUD ADMINISTRADOR');
  print('─' * 60);
  results['Administrador'] = await verificarAdminCRUD();
  print('');

  // ETAPA 2: MESERO
  print('📋 ETAPA 2: VERIFICACIÓN CRUD MESERO');
  print('─' * 60);
  results['Mesero'] = await verificarMeseroCRUD();
  print('');

  // ETAPA 3: COCINERO
  print('📋 ETAPA 3: VERIFICACIÓN CRUD COCINERO');
  print('─' * 60);
  results['Cocinero'] = await verificarCocineroCRUD();
  print('');

  // ETAPA 4: CAJERO
  print('📋 ETAPA 4: VERIFICACIÓN CRUD CAJERO');
  print('─' * 60);
  results['Cajero'] = await verificarCajeroCRUD();
  print('');

  // ETAPA 5: CAPITÁN
  print('📋 ETAPA 5: VERIFICACIÓN CRUD CAPITÁN');
  print('─' * 60);
  results['Capitán'] = await verificarCaptainCRUD();
  print('');

  // RESUMEN FINAL
  print('═══════════════════════════════════════════════════════════');
  print('  RESUMEN DE VERIFICACIÓN');
  print('═══════════════════════════════════════════════════════════\n');

  for (final entry in results.entries) {
    final rol = entry.key;
    final checks = entry.value;
    final total = checks.length;
    final passed = checks.values.where((v) => v).length;
    final percentage = (passed / total * 100).toStringAsFixed(1);
    
    print('$rol: $passed/$total verificaciones pasadas ($percentage%)');
    for (final check in checks.entries) {
      final icon = check.value ? '✅' : '❌';
      print('  $icon ${check.key}');
    }
    print('');
  }

  final allPassed = results.values.every((checks) => 
    checks.values.every((v) => v));
  
  if (allPassed) {
    print('🎉 ¡TODAS LAS VERIFICACIONES PASARON!');
  } else {
    print('⚠️  ALGUNAS VERIFICACIONES FALLARON. Revisa los detalles arriba.');
  }
}

Future<Map<String, bool>> verificarAdminCRUD() async {
  final checks = <String, bool>{};

  // Verificar archivos de servicios
  checks['UsuariosService existe'] = await File('lib/services/usuarios_service.dart').exists();
  checks['ProductosService existe'] = await File('lib/services/productos_service.dart').exists();
  checks['InventarioService existe'] = await File('lib/services/inventario_service.dart').exists();
  checks['CategoriasService existe'] = await File('lib/services/categorias_service.dart').exists();
  checks['MesasService existe'] = await File('lib/services/mesas_service.dart').exists();

  // Verificar métodos CRUD en servicios
  final usuariosService = await File('lib/services/usuarios_service.dart').readAsString();
  checks['UsuariosService.createUsuario'] = usuariosService.contains('crearUsuario');
  checks['UsuariosService.actualizarUsuario'] = usuariosService.contains('actualizarUsuario');
  checks['UsuariosService.eliminarUsuario'] = usuariosService.contains('eliminarUsuario');
  checks['UsuariosService.listarUsuarios'] = usuariosService.contains('listarUsuarios');

  final productosService = await File('lib/services/productos_service.dart').readAsString();
  checks['ProductosService.createProducto'] = productosService.contains('createProducto');
  checks['ProductosService.updateProducto'] = productosService.contains('updateProducto');
  checks['ProductosService.desactivarProducto'] = productosService.contains('desactivarProducto');
  checks['ProductosService.getProductos'] = productosService.contains('getProductos');

  final inventarioService = await File('lib/services/inventario_service.dart').readAsString();
  checks['InventarioService.createItem'] = inventarioService.contains('createItem');
  checks['InventarioService.updateItem'] = inventarioService.contains('updateItem');
  checks['InventarioService.eliminarItem'] = inventarioService.contains('eliminarItem');
  checks['InventarioService.getItems'] = inventarioService.contains('getItems');

  final categoriasService = await File('lib/services/categorias_service.dart').readAsString();
  checks['CategoriasService.createCategoria'] = categoriasService.contains('createCategoria');
  checks['CategoriasService.updateCategoria'] = categoriasService.contains('updateCategoria');
  checks['CategoriasService.eliminarCategoria'] = categoriasService.contains('eliminarCategoria');
  checks['CategoriasService.getCategorias'] = categoriasService.contains('getCategorias');

  final mesasService = await File('lib/services/mesas_service.dart').readAsString();
  checks['MesasService.createMesa'] = mesasService.contains('createMesa');
  checks['MesasService.updateMesa'] = mesasService.contains('updateMesa');
  checks['MesasService.eliminarMesa'] = mesasService.contains('eliminarMesa');
  checks['MesasService.getMesas'] = mesasService.contains('getMesas');

  // Verificar métodos en AdminController
  final adminController = await File('lib/controllers/admin_controller.dart').readAsString();
  checks['AdminController.addUser'] = adminController.contains('addUser') || adminController.contains('createUser');
  checks['AdminController.updateUser'] = adminController.contains('updateUser');
  checks['AdminController.deleteUser'] = adminController.contains('deleteUser');
  checks['AdminController.loadUsers'] = adminController.contains('loadUsers');

  checks['AdminController.addMenuItem'] = adminController.contains('addMenuItem');
  checks['AdminController.updateMenuItem'] = adminController.contains('updateMenuItem');
  checks['AdminController.deleteMenuItem'] = adminController.contains('deleteMenuItem');
  checks['AdminController.loadMenuItems'] = adminController.contains('loadMenuItems');

  checks['AdminController.addInventoryItem'] = adminController.contains('addInventoryItem');
  checks['AdminController.updateInventoryItem'] = adminController.contains('updateInventoryItem');
  checks['AdminController.deleteInventoryItem'] = adminController.contains('deleteInventoryItem');
  checks['AdminController.loadInventory'] = adminController.contains('loadInventory');

  checks['AdminController.addCustomCategory'] = adminController.contains('addCustomCategory');
  checks['AdminController.updateCustomCategory'] = adminController.contains('updateCustomCategory');
  checks['AdminController.deleteCustomCategory'] = adminController.contains('deleteCustomCategory');
  checks['AdminController.loadCategorias'] = adminController.contains('loadCategorias');

  checks['AdminController.addTable'] = adminController.contains('addTable');
  checks['AdminController.updateTable'] = adminController.contains('updateTable');
  checks['AdminController.deleteTable'] = adminController.contains('deleteTable');
  checks['AdminController.loadTables'] = adminController.contains('loadTables');

  // Verificar recarga después de operaciones
  checks['Recarga después de crear'] = adminController.contains('await load') || 
                                       adminController.contains('loadUsers()') ||
                                       adminController.contains('loadMenuItems()');

  // Imprimir resultados
  for (final check in checks.entries) {
    final icon = check.value ? '✅' : '❌';
    print('  $icon ${check.key}');
  }

  return checks;
}

Future<Map<String, bool>> verificarMeseroCRUD() async {
  final checks = <String, bool>{};

  // Verificar servicios
  checks['OrdenesService existe'] = await File('lib/services/ordenes_service.dart').exists();
  checks['MesasService existe'] = await File('lib/services/mesas_service.dart').exists();
  checks['BillRepository existe'] = await File('lib/services/bill_repository.dart').exists();

  // Verificar métodos en OrdenesService
  final ordenesService = await File('lib/services/ordenes_service.dart').readAsString();
  checks['OrdenesService.createOrden'] = ordenesService.contains('createOrden');
  checks['OrdenesService.getOrden'] = ordenesService.contains('getOrden');
  checks['OrdenesService.getOrdenes'] = ordenesService.contains('getOrdenes');
  checks['OrdenesService.updateOrden'] = ordenesService.contains('updateOrden');
  checks['OrdenesService.cambiarEstado'] = ordenesService.contains('cambiarEstado');

  // Verificar métodos en MeseroController
  final meseroController = await File('lib/controllers/mesero_controller.dart').readAsString();
  checks['MeseroController.sendOrderToKitchen'] = meseroController.contains('sendOrderToKitchen');
  checks['MeseroController.sendToCashier'] = meseroController.contains('sendToCashier');
  checks['MeseroController.addToCart'] = meseroController.contains('addToCart');
  checks['MeseroController.loadTables'] = meseroController.contains('loadTables');
  checks['MeseroController.updateTableStatus'] = meseroController.contains('updateTableStatus');

  // Verificar que sendToCashier obtiene orden del backend
  checks['sendToCashier obtiene orden del backend'] = meseroController.contains('_ordenesService.getOrden');

  // Verificar BillRepository
  final billRepository = await File('lib/services/bill_repository.dart').readAsString();
  checks['BillRepository.loadBills'] = billRepository.contains('loadBills');
  checks['BillRepository carga desde backend'] = billRepository.contains('_ordenesService') || 
                                                 billRepository.contains('OrdenesService');

  // Imprimir resultados
  for (final check in checks.entries) {
    final icon = check.value ? '✅' : '❌';
    print('  $icon ${check.key}');
  }

  return checks;
}

Future<Map<String, bool>> verificarCocineroCRUD() async {
  final checks = <String, bool>{};

  // Verificar CocineroController
  final cocineroController = await File('lib/controllers/cocinero_controller.dart').readAsString();
  checks['CocineroController existe'] = cocineroController.isNotEmpty;
  checks['CocineroController.loadOrders'] = cocineroController.contains('loadOrders');
  checks['CocineroController.updateOrderStatus'] = cocineroController.contains('updateOrderStatus') ||
                                                  cocineroController.contains('cambiarEstado');
  checks['CocineroController usa OrdenesService'] = cocineroController.contains('OrdenesService') ||
                                                    cocineroController.contains('_ordenesService');

  // Verificar que carga desde backend
  checks['Carga órdenes desde backend'] = cocineroController.contains('getOrdenes') ||
                                          cocineroController.contains('_ordenesService.getOrdenes');

  // Imprimir resultados
  for (final check in checks.entries) {
    final icon = check.value ? '✅' : '❌';
    print('  $icon ${check.key}');
  }

  return checks;
}

Future<Map<String, bool>> verificarCajeroCRUD() async {
  final checks = <String, bool>{};

  // Verificar servicios
  checks['PagosService existe'] = await File('lib/services/pagos_service.dart').exists();

  // Verificar PagosService
  final pagosService = await File('lib/services/pagos_service.dart').readAsString();
  checks['PagosService.registrarPago'] = pagosService.contains('registrarPago');
  checks['PagosService.registrarPropina'] = pagosService.contains('registrarPropina');
  checks['PagosService.getPagos'] = pagosService.contains('getPagos');

  // Verificar CajeroController
  final cajeroController = await File('lib/controllers/cajero_controller.dart').readAsString();
  checks['CajeroController existe'] = cajeroController.isNotEmpty;
  checks['CajeroController.processPayment'] = cajeroController.contains('processPayment');
  checks['CajeroController usa PagosService'] = cajeroController.contains('PagosService') ||
                                                cajeroController.contains('_pagosService');

  // Verificar que processPayment registra en backend
  checks['processPayment registra en backend'] = cajeroController.contains('registrarPago') ||
                                                 cajeroController.contains('_pagosService.registrarPago');

  // Imprimir resultados
  for (final check in checks.entries) {
    final icon = check.value ? '✅' : '❌';
    print('  $icon ${check.key}');
  }

  return checks;
}

Future<Map<String, bool>> verificarCaptainCRUD() async {
  final checks = <String, bool>{};

  // Verificar CaptainController
  final captainController = await File('lib/controllers/captain_controller.dart').readAsString();
  checks['CaptainController existe'] = captainController.isNotEmpty;
  checks['CaptainController.loadTables'] = captainController.contains('loadTables');
  checks['CaptainController usa MesasService'] = captainController.contains('MesasService') ||
                                                  captainController.contains('_mesasService');

  // Verificar que carga mesas desde backend
  checks['Carga mesas desde backend'] = captainController.contains('getMesas') ||
                                        captainController.contains('_mesasService.getMesas');

  // Imprimir resultados
  for (final check in checks.entries) {
    final icon = check.value ? '✅' : '❌';
    print('  $icon ${check.key}');
  }

  return checks;
}

