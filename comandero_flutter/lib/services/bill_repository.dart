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
      // IMPORTANTE: NO limpiar bills existentes - preservar los que fueron recibidos por Socket.IO
      // Solo agregar nuevas bills desde órdenes activas que aún no tienen bill

      // Obtener órdenes del backend
      final ordenes = await _ordenesService.getOrdenes();

      // Filtrar órdenes que no estén pagadas ni canceladas
      // Convertir órdenes a bills
      final nuevasBills = <BillModel>[];

      for (final ordenData in ordenes) {
        final ordenId = ordenData['id'] as int;
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // Solo crear bills para órdenes que estén listas y no pagadas
        // (excluir órdenes canceladas y pagadas)
        if (estadoNombre.contains('cancel') ||
            estadoNombre.contains('pagada') ||
            estadoNombre.contains('cerrada')) {
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
