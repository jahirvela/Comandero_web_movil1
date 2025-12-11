import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/ordenes_service.dart';
import '../utils/date_utils.dart' as date_utils;

/// Repositorio para compartir las cuentas abiertas entre Mesero y Cajero.
/// Ahora carga órdenes pendientes desde el backend y las convierte en bills.
class BillRepository extends ChangeNotifier {
  final OrdenesService _ordenesService = OrdenesService();

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

  void removeBillsForTable(int tableNumber) {
    _bills.removeWhere((bill) => bill.tableNumber == tableNumber);
    notifyListeners();
  }

  // Cargar bills desde el backend (órdenes pendientes de pago)
  Future<void> loadBills() async {
    try {
      // Obtener órdenes del backend
      final ordenes = await _ordenesService.getOrdenes();

      // PRIMERO: Eliminar bills de órdenes que ya están pagadas/cerradas
      // CRÍTICO: NO eliminar bills pendientes que fueron creados vía cuenta.enviada
      // porque estas cuentas aún no están pagadas, solo fueron enviadas al cajero.
      // Las bills solo deben eliminarse cuando se procesa el pago o se cancela explícitamente la orden.
      _bills.removeWhere((bill) {
        // CRÍTICO: NUNCA eliminar bills pendientes durante loadBills()
        // Solo eliminar si están explícitamente canceladas
        if (bill.status == BillStatus.pending) {
          // Bill pendiente, NO eliminar aquí
          // Solo eliminar si la orden fue explícitamente cancelada
          if (bill.ordenId == null) return false;
          
          final ordenData = ordenes.firstWhere(
            (o) => o['id'] == bill.ordenId,
            orElse: () => <String, dynamic>{},
          );
          
          if (ordenData.isEmpty) {
            // Orden no existe en backend, pero mantener el bill (puede ser nueva)
            return false;
          }
          
          final estadoNombre =
              (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';
          
          // SOLO eliminar si fue explícitamente cancelada
          // NO eliminar si está "pagada" porque eso puede ser solo el estado cuando se envía la cuenta
          if (estadoNombre.contains('cancel')) {
            print('🗑️ BillRepository: Eliminando bill pendiente ${bill.id} - Orden ${bill.ordenId} cancelada');
            return true; // Orden cancelada, eliminar bill
          }
          
          // Mantener el bill en cualquier otro caso
          return false;
        }
        
        // Para bills que NO están pendientes (ya procesadas), sí pueden eliminarse
        // si la orden ya no existe o está cancelada
        if (bill.ordenId == null) return false;
        
        final ordenData = ordenes.firstWhere(
          (o) => o['id'] == bill.ordenId,
          orElse: () => <String, dynamic>{},
        );
        if (ordenData.isEmpty) {
          return true; // Orden no existe, eliminar bill no pendiente
        }
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';
        if (estadoNombre.contains('cancel')) {
          return true; // Orden cancelada
        }
        return false;
      });

      // Filtrar órdenes que no estén pagadas ni canceladas
      // Convertir órdenes a bills
      final nuevasBills = <BillModel>[];

      // CRÍTICO: Crear un set de todos los ordenIds que ya están en bills agrupados (requestedByWaiter: true)
      // Esto evita crear bills individuales para órdenes que ya están agrupadas
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
          
          // También verificar el ordenId directo si existe (para compatibilidad con bills no agrupados)
          if (bill.ordenId != null) {
            ordenIdsEnBillsAgrupados.add(bill.ordenId!);
          }
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

      for (final ordenData in ordenes) {
        final ordenId = ordenData['id'] as int;
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // Solo crear bills para órdenes que estén listas y no pagadas
        // (excluir órdenes canceladas y pagadas)
        if (estadoNombre.contains('cancel') ||
            estadoNombre.contains('pagada') ||
            estadoNombre.contains('cerrada') ||
            estadoNombre.contains('cobrada')) {
          continue;
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
          return BillItem(
            name: itemJson['productoNombre'] as String? ?? 'Producto',
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
