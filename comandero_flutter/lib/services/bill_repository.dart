import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/ordenes_service.dart';
import '../services/pagos_service.dart';
import '../utils/date_utils.dart' as date_utils;

List<int> _ordenIdsEnBill(BillModel bill) {
  if (bill.ordenIds != null && bill.ordenIds!.isNotEmpty) {
    return List<int>.from(bill.ordenIds!);
  }
  if (bill.ordenId != null) return [bill.ordenId!];
  return bill.ordenIdsFromBillIdInt;
}

/// Solo pagos con efecto en caja (excluye anulados / pendientes de aplicar).
bool _pagoCuentaParaSaldo(dynamic p) {
  if (p is! Map) return false;
  final e = (p['estado'] as String? ?? 'aplicado').toLowerCase().trim();
  return e == 'aplicado';
}

/// Suma de pagos con estado `aplicado` por orden (uso compartido cajero / repositorio).
Map<int, double> montoPagadoAplicadoPorOrden(List<dynamic> pagos) {
  final acum = <int, double>{};
  for (final p in pagos) {
    if (!_pagoCuentaParaSaldo(p)) continue;
    if (p is! Map) continue;
    final ordenId = (p['ordenId'] as num?)?.toInt();
    if (ordenId == null) continue;
    final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
    acum[ordenId] = (acum[ordenId] ?? 0) + monto;
  }
  return acum;
}

bool _ordenCancelada(Map<String, dynamic> ordenData) {
  final est =
      (ordenData['estadoNombre'] as String? ?? '').toLowerCase();
  return est.contains('cancel');
}

double _totalOrdenDesdeMap(Map<String, dynamic> ordenData) {
  return (ordenData['total'] as num?)?.toDouble() ?? 0.0;
}

/// Cuenta liquidada en caja: solo pagos **aplicados** que cubren el total.
/// No basta el nombre de estado `pagada` en BD: el cajero debe ver el bill hasta que existan pagos.
bool ordenLiquidadadaConPagos(
  Map<String, dynamic> ordenData,
  double pagadoAplicado,
) {
  if (_ordenCancelada(ordenData)) return false;
  final total = _totalOrdenDesdeMap(ordenData);
  if (total <= 0.009) {
    return pagadoAplicado > 0.009;
  }
  return pagadoAplicado + 0.009 >= total;
}

/// Repositorio para compartir las cuentas abiertas entre Mesero y Cajero.
/// Ahora carga órdenes pendientes desde el backend y las convierte en bills.
class BillRepository extends ChangeNotifier {
  final OrdenesService _ordenesService = OrdenesService();
  final PagosService _pagosService = PagosService();

  BillRepository() {
    // Cargar bills desde el backend de forma asíncrona
    // No esperar aquí para no bloquear la inicialización
    loadBills();
  }

  final List<BillModel> _bills = [];

  List<BillModel> get bills => List.unmodifiable(_bills);

  List<BillModel> get pendingBills =>
      _bills.where((bill) => bill.status == BillStatus.pending).toList();

  BillModel? getBill(String billId) {
    try {
      return _bills.firstWhere((bill) => bill.id == billId);
    } catch (e) {
      return null;
    }
  }

  void addBill(BillModel bill) {
    // Verificar que no exista ya
    if (!_bills.any((b) => b.id == bill.id)) {
      _bills.insert(0, bill);
      notifyListeners();
    }
  }

  void updateBill(String billId, BillModel Function(BillModel) updater) {
    final index = _bills.indexWhere((bill) => bill.id == billId);
    if (index == -1) return;

    _bills[index] = updater(_bills[index]);
    notifyListeners();
  }

  void removeBill(String billId) {
    _bills.removeWhere((bill) => bill.id == billId);
    notifyListeners();
  }

  /// Quita bills cuyo [tableNumber] coincide. **No usar** para “liberar mesa” en mesero:
  /// el cajero y gerente comparten este repositorio; las cuentas deben quitarse solo al
  /// cobrar (o cancelar orden), no al cerrar la mesa en la vista del mesero.
  void removeBillsForTable(int tableNumber) {
    _bills.removeWhere((bill) => bill.tableNumber == tableNumber);
    notifyListeners();
  }

  /// Evita carreras cuando [loadBills] se dispara en paralelo (p. ej. init cajero + post-frame refresh).
  Future<void>? _loadBillsInFlight;

  /// Cargar bills desde el backend (órdenes pendientes de pago)
  Future<void> loadBills() {
    if (_loadBillsInFlight != null) return _loadBillsInFlight!;
    _loadBillsInFlight = _loadBillsInternal().whenComplete(() {
      _loadBillsInFlight = null;
    });
    return _loadBillsInFlight!;
  }

  Future<void> _loadBillsInternal() async {
    try {
      // Para cajero: órdenes incluyendo "cerrada" (cuentas enviadas por mesero, por cobrar)
      final ordenesFut = _ordenesService.getOrdenesParaCajero();
      final pagosFut = _pagosService.getPagos();
      final ordenes = await ordenesFut;
      final pagos = await pagosFut;

      final pagadoPorOrden = montoPagadoAplicadoPorOrden(pagos);

      // Índice id -> orden (lista cajero + detalle para ids que no vienen en listado, p. ej. pagada)
      final idsNecesarios = <int>{};
      for (final bill in _bills) {
        idsNecesarios.addAll(_ordenIdsEnBill(bill));
      }
      for (final o in ordenes) {
        if (o is Map) {
          final id = (o['id'] as num?)?.toInt();
          if (id != null) idsNecesarios.add(id);
        }
      }

      final ordenPorId = <int, Map<String, dynamic>>{};
      for (final o in ordenes) {
        if (o is! Map) continue;
        final m = Map<String, dynamic>.from(o);
        final id = (m['id'] as num?)?.toInt();
        if (id != null) ordenPorId[id] = m;
      }
      for (final id in idsNecesarios) {
        if (ordenPorId.containsKey(id)) continue;
        final det = await _ordenesService.getOrden(id);
        if (det != null) ordenPorId[id] = det;
      }

      // Quitar cuentas pendientes solo si: cancelación, o TODAS las órdenes liquidadas
      // con pagos aplicados (misma regla que producción: no basta estado "pagada" en BD).
      _bills.removeWhere((bill) {
        if (bill.status == BillStatus.pending) {
          final ids = _ordenIdsEnBill(bill);
          if (ids.isEmpty) return false;

          for (final ordenId in ids) {
            final od = ordenPorId[ordenId];
            if (od != null && _ordenCancelada(od)) {
              print(
                '🗑️ BillRepository: Eliminando bill pendiente ${bill.id} - Orden $ordenId cancelada',
              );
              return true;
            }
          }

          final todasLiquidadasConPagos = ids.every((id) {
            final od = ordenPorId[id];
            if (od == null) return false;
            final pag = pagadoPorOrden[id] ?? 0;
            return ordenLiquidadadaConPagos(od, pag);
          });
          if (todasLiquidadasConPagos) {
            print(
              '🗑️ BillRepository: Eliminando bill pendiente ${bill.id} - Liquidadas con pagos aplicados',
            );
            return true;
          }
          return false;
        }

        // Bills no pendientes: limpiar solo si alguna orden asociada está cancelada
        final idsNp = _ordenIdsEnBill(bill);
        if (idsNp.isEmpty) return false;
        for (final ordenId in idsNp) {
          final od = ordenPorId[ordenId];
          if (od != null && _ordenCancelada(od)) return true;
        }
        return false;
      });

      // Filtrar órdenes que no estén pagadas ni canceladas
      // Convertir órdenes a bills
      final nuevasBills = <BillModel>[];

      // CRÍTICO: Crear un set de todos los ordenIds que ya están en bills agrupados (requestedByWaiter: true)
      // Esto evita crear bills individuales para órdenes que ya están agrupadas
      // IMPORTANTE: Solo considerar bills agrupados (BILL-MESA-* o BILL-TAKEAWAY-* con múltiples órdenes)
      // NO considerar bills individuales (BILL-ORD-*) como agrupados
      final ordenIdsEnBillsAgrupados = <int>{};
      for (final bill in _bills) {
        if (bill.requestedByWaiter == true) {
          // Este bill fue creado vía cuenta.enviada (puede ser agrupado)
          // Extraer ordenIds directamente del billId (más confiable)
          // Formato: BILL-MESA-11-65-67-68 o BILL-TAKEAWAY-CLIENTE-65-67
          
          // Método 1: Extraer desde el formato BILL-MESA-X-Y-Z
          if (bill.id.startsWith('BILL-MESA-')) {
            final parts = bill.id.split('-');
            // Los números después de "BILL-MESA-11" son los ordenIds
            // Ejemplo: BILL-MESA-11-65-67-68 -> parts = [BILL, MESA, 11, 65, 67, 68]
            // El índice 2 es el número de mesa, los índices 3+ son los ordenIds
            for (var i = 3; i < parts.length; i++) {
              final posibleOrdenId = int.tryParse(parts[i]);
              if (posibleOrdenId != null) {
                ordenIdsEnBillsAgrupados.add(posibleOrdenId);
              }
            }
          }
          // Método 2: Extraer desde el formato BILL-TAKEAWAY-CLIENTE-Y-Z o BILL-TAKEAWAY-NOMBRE-Y-Z
          else if (bill.id.startsWith('BILL-TAKEAWAY-')) {
            final parts = bill.id.split('-');
            // Los números después del nombre del cliente son los ordenIds
            // Ejemplo: BILL-TAKEAWAY-CLIENTE-65-67 -> parts = [BILL, TAKEAWAY, CLIENTE, 65, 67]
            // Ejemplo: BILL-TAKEAWAY-Juan-Perez-65-67 -> parts = [BILL, TAKEAWAY, Juan, Perez, 65, 67]
            // Los ordenIds siempre están al final del billId (después del nombre del cliente)
            // Recorrer desde el final hacia adelante para encontrar los números (ordenIds)
            final ordenIdsEncontrados = <int>[];
            for (var i = parts.length - 1; i >= 2; i--) {
              final posibleOrdenId = int.tryParse(parts[i]);
              if (posibleOrdenId != null) {
                // Encontramos un número, agregarlo (agregar al inicio porque recorremos al revés)
                ordenIdsEncontrados.insert(0, posibleOrdenId);
              } else {
                // Si encontramos un no-número, significa que ya pasamos todos los ordenIds
                break;
              }
            }
            // Agregar todos los ordenIds encontrados al set
            ordenIdsEnBillsAgrupados.addAll(ordenIdsEncontrados);
          }
          // NO agregar bills individuales (BILL-ORD-*) al set de agrupados
          // Los bills individuales pueden coexistir con bills agrupados
        }
      }

      if (ordenIdsEnBillsAgrupados.isNotEmpty) {
        print(
          '📋 BillRepository: Órdenes ya agrupadas (NO crear bills individuales): ${ordenIdsEnBillsAgrupados.toList()}',
        );
        
        // CRÍTICO: Eliminar bills individuales que están duplicados con bills agrupados
        // Esto asegura que solo se muestre el bill agrupado, no los individuales
        final billsAEliminar = <String>[];
        for (final bill in _bills) {
          // Si este bill es individual (BILL-ORD-*) y su ordenId está en un bill agrupado
          if (bill.id.startsWith('BILL-ORD-') && 
              bill.ordenId != null && 
              ordenIdsEnBillsAgrupados.contains(bill.ordenId!)) {
            billsAEliminar.add(bill.id);
            print(
              '🗑️ BillRepository: Eliminando bill individual duplicado: ${bill.id} (orden ${bill.ordenId} está en bill agrupado)',
            );
          }
        }
        // Eliminar los bills individuales duplicados
        for (final billId in billsAEliminar) {
          _bills.removeWhere((b) => b.id == billId);
        }
        if (billsAEliminar.isNotEmpty) {
          print(
            '✅ BillRepository: ${billsAEliminar.length} bills individuales eliminados (duplicados de bills agrupados)',
          );
        }
      }

      for (final raw in ordenes) {
        if (raw is! Map) continue;
        final ordenData = Map<String, dynamic>.from(raw);
        final ordenId = ordenData['id'] as int;
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // Excluir órdenes canceladas siempre
        if (estadoNombre.contains('cancel')) {
          continue;
        }

        // Solo crear bill si la orden fue enviada al cajero (cerrada/enviada/entregada/cobrada o pagada sin pagos).
        // NO agrupar por mesa: solo aparecen las cuentas que el mesero envía con "Cerrar cuenta" (evento en vivo).
        final esCerradaParaCobro = estadoNombre.contains('cerrada') ||
            estadoNombre.contains('enviada') ||
            estadoNombre.contains('entregada') ||
            estadoNombre.contains('cobrada');
        bool esPagadaSinPagos = false;

        if (!esCerradaParaCobro && !estadoNombre.contains('pagada')) {
          continue;
        }

        final pagadoAqui = pagadoPorOrden[ordenId] ?? 0;
        if (ordenLiquidadadaConPagos(ordenData, pagadoAqui)) {
          print(
            '⏭️ BillRepository: Saltando orden $ordenId - Liquidada con pagos aplicados',
          );
          continue;
        }

        // Para órdenes "pagadas" o cerradas, incluir si aún no están liquidadas al 100%
        if (estadoNombre.contains('pagada') || esCerradaParaCobro) {
          if (estadoNombre.contains('pagada')) {
            esPagadaSinPagos = true;
          }

          print(
            '✅ BillRepository: Incluyendo orden $ordenId - Estado: $estadoNombre${esPagadaSinPagos ? ' (pagada sin liquidar)' : ''}',
          );
        }

        // CRÍTICO: NO crear bill individual si esta orden ya está en un bill agrupado
        if (ordenIdsEnBillsAgrupados.contains(ordenId)) {
          print(
            '⏭️ BillRepository: Saltando orden $ordenId - Ya está en un bill agrupado',
          );
          continue;
        }

        // IMPORTANTE: Verificar si ya existe un bill para esta orden por ordenId O por billId
        final billId = 'BILL-ORD-$ordenId';
        if (_bills.any((b) => b.id == billId || b.ordenId == ordenId)) {
          continue; // Ya existe, no duplicar
        }

        // Obtener detalles completos de la orden
        final ordenDetalle = await _ordenesService.getOrden(ordenId);
        if (ordenDetalle == null) continue;

        // Crear billItems desde los items de la orden
        // IMPORTANTE: Calcular el total de cada item como precio * cantidad
        // para asegurar que los totales sean correctos
        final itemsData = ordenDetalle['items'] as List<dynamic>? ?? [];
        final billItems = itemsData.map((itemJson) {
          final cantidad = (itemJson['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario =
              (itemJson['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          // Calcular el total del item correctamente: precio * cantidad
          final totalItem = precioUnitario * cantidad;
          final productoNombre =
              itemJson['productoNombre'] as String? ?? 'Producto';

          // Tomar la etiqueta de tamaño desde cualquiera de los posibles campos
          final tamanoEtiqueta = (itemJson['productoTamanoEtiqueta'] ??
                  itemJson['tamanoEtiqueta'] ??
                  itemJson['tamanoNombre'] ??
                  itemJson['sizeName'] ??
                  itemJson['size'] ??
                  itemJson['tamaño'] ??
                  itemJson['productoTamano'] ??
                  itemJson['productoTamanioEtiqueta'])
              ?.toString();
          
          // Debug: imprimir información del item para verificar
          if (tamanoEtiqueta != null && tamanoEtiqueta.isNotEmpty) {
            print('📦 BillRepository: Producto "$productoNombre" tiene tamaño: "$tamanoEtiqueta"');
          } else {
            print('⚠️ BillRepository: Producto "$productoNombre" NO tiene tamaño. Campos disponibles: ${itemJson.keys.toList()}');
          }

          final nombreConTamano = _formatProductNameWithSize(
            productoNombre,
            tamanoEtiqueta,
          );
          final notaItem = itemJson['nota'] as String? ?? '';
          final tieneDescuento = notaItem.toLowerCase().contains('descuento aplicado');
          final nombreConDescuento = tieneDescuento
              ? '$nombreConTamano (Desc.)'
              : nombreConTamano;
          
          print('📦 BillRepository: Nombre final del producto: "$nombreConDescuento"');

          return BillItem(
            name: nombreConDescuento,
            quantity: cantidad,
            price: precioUnitario,
            total: totalItem,
          );
        }).toList();

        // Calcular el subtotal sumando los totales de cada item
        // NO usar el subtotal del backend porque puede estar mal
        final subtotalCalculado = billItems.fold<double>(
          0.0,
          (sum, item) => sum + item.total,
        );

        final descuento =
            (ordenDetalle['descuentoTotal'] as num?)?.toDouble() ?? 0.0;
        final impuesto =
            (ordenDetalle['impuestoTotal'] as num?)?.toDouble() ?? 0.0;

        // Calcular el total final: subtotal - descuento + impuesto
        final total = subtotalCalculado - descuento + impuesto;

        final mesaId = ordenDetalle['mesaId'] as int?;
        final mesaCodigo = ordenData['mesaCodigo'] as String?;
        final tableNumber = mesaCodigo != null
            ? int.tryParse(mesaCodigo)
            : null;

        final bill = BillModel(
          id: billId,
          tableNumber: tableNumber,
          mesaCodigo: mesaCodigo,
          ordenId: ordenId,
          items: billItems,
          subtotal: subtotalCalculado,
          tax: impuesto,
          total: total,
          discount: descuento,
          status: BillStatus.pending,
          createdAt: ordenDetalle['creadoEn'] != null
              ? date_utils.AppDateUtils.parseToLocal(ordenDetalle['creadoEn'])
              : date_utils.AppDateUtils.now(),
          waiterName:
              ordenDetalle['creadoPorNombre'] as String? ??
              ordenDetalle['creadoPorUsuarioNombre'] as String? ??
              'Mesero',
          requestedByWaiter: true,
          isTakeaway: mesaId == null,
          customerName: ordenDetalle['clienteNombre'] as String?,
        );

        nuevasBills.add(bill);
      }

      // Agregar nuevas bills (sin duplicar por billId)
      for (final bill in nuevasBills) {
        if (!_bills.any((b) => b.id == bill.id)) {
          _bills.add(bill);
        }
      }

      // Ordenar por fecha de creación (más recientes primero)
      _bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
    } catch (e) {
      print('Error al cargar bills desde el backend: $e');
      // Si falla, mantener las bills existentes
      notifyListeners();
    }
  }
}

String _formatProductNameWithSize(String name, String? size) {
  if (size == null || size.isEmpty || size.trim().isEmpty) {
    return name;
  }
  final cleanSize = size.trim();
  // Si el nombre ya incluye el tamaño en paréntesis, no agregarlo de nuevo
  if (name.contains('($cleanSize)')) {
    return name;
  }
  // Agregar el tamaño al nombre
  return '$name ($cleanSize)';
}
