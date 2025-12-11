import '../models/order_model.dart';
import '../models/product_model.dart';
import '../controllers/mesero_controller.dart';
import '../controllers/cocinero_controller.dart';
import 'socket_service.dart';

/// Servicio compartido para comunicar pedidos entre Mesero y Cocinero
/// Usa Socket.IO para comunicación en tiempo real
class KitchenOrderService {
  static final KitchenOrderService _instance = KitchenOrderService._internal();
  factory KitchenOrderService() => _instance;
  KitchenOrderService._internal();

  final SocketService _socketService = SocketService();
  CocineroController? _cocineroController;
  MeseroController? _meseroController;

  // Registrar controllers
  void registerCocineroController(CocineroController controller) {
    _cocineroController = controller;
  }

  void registerMeseroController(MeseroController controller) {
    _meseroController = controller;
  }

  // Enviar pedido desde Mesero a Cocinero
  void sendOrderToKitchen({
    required String orderId,
    required List<CartItem> cartItems,
    required int? tableNumber,
    required String waiterName,
    required bool isTakeaway,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
  }) {
    // Verificar que el controller esté disponible y no haya sido disposed
    if (_cocineroController == null) {
      print('⚠️ CocineroController no está registrado');
      return;
    }

    try {
      // Convertir CartItems a OrderItems
      final orderItems = cartItems.map((cartItem) {
        final quantity = cartItem.customizations['quantity'] as int? ?? 1;
        final kitchenNotes =
            cartItem.customizations['kitchenNotes'] as String? ?? '';

        // Determinar estación según categoría del producto
        final station = _mapCategoryToStation(cartItem.product.category);

        // Combinar notas del producto con notas de customización
        final notes = kitchenNotes.isNotEmpty
            ? kitchenNotes
            : (cartItem.customizations['sauce'] != null
                  ? 'Salsa: ${cartItem.customizations['sauce']}'
                  : '');

        return OrderItem(
          id:
              int.tryParse(cartItem.id) ??
              DateTime.now().millisecondsSinceEpoch,
          name: cartItem.product.name,
          quantity: quantity,
          station: station,
          notes: notes,
        );
      }).toList();

      // Crear OrderModel
      final order = OrderModel(
        id: orderId,
        tableNumber: tableNumber,
        items: orderItems,
        status: OrderStatus.pendiente,
        orderTime: DateTime.now(),
        estimatedTime: _calculateEstimatedTime(orderItems),
        waiter: waiterName,
        priority: OrderPriority.normal,
        isTakeaway: isTakeaway,
        customerName: customerName,
        customerPhone: customerPhone,
        pickupTime: pickupTime,
      );

      // Verificar nuevamente antes de usar el controller
      if (_cocineroController != null) {
        _cocineroController!.addOrder(order);
      } else {
        print('⚠️ CocineroController fue disposed antes de agregar la orden');
      }
    } catch (e) {
      print('⚠️ Error al enviar pedido a cocina: $e');
      // No lanzar la excepción para que el flujo continúe normalmente
    }
  }

  /// Enviar alerta a cocina vía Socket.IO (tiempo real)
  void sendAlertToKitchen({
    required String tableNumber,
    required String orderId,
    required String alertType,
    required String reason,
    String? details,
    String priority = 'Normal',
  }) {
    try {
      // Extraer ordenId numérico del string (ej: "ORD-000003" -> 3)
      int? ordenIdNumerico;
      final ordenIdMatch = RegExp(r'ORD-(\d+)').firstMatch(orderId);
      if (ordenIdMatch != null) {
        ordenIdNumerico = int.tryParse(ordenIdMatch.group(1) ?? '');
      } else {
        ordenIdNumerico = int.tryParse(orderId);
      }

      // Extraer mesaId del número de mesa
      final mesaId = int.tryParse(tableNumber);

      // Mapear prioridad al formato del backend
      String prioridadBackend = 'media';
      if (priority.toLowerCase() == 'urgente' ||
          priority.toLowerCase() == 'high') {
        prioridadBackend = 'urgente';
      } else if (priority.toLowerCase() == 'baja' ||
          priority.toLowerCase() == 'low') {
        prioridadBackend = 'baja';
      }

      // Construir mensaje completo
      final mensaje =
          '$alertType: $reason${details != null && details.isNotEmpty ? ' - $details' : ''}';

      // Preparar payload para Socket.IO
      final payload = {
        'tipo': alertType,
        'mensaje': mensaje,
        'ordenId': ordenIdNumerico,
        'mesaId': mesaId,
        'prioridad': prioridadBackend,
        'metadata': {
          'tableNumber': tableNumber,
          'orderId': orderId,
          'alertType': alertType,
          'reason': reason,
          if (details != null) 'details': details,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Enviar por Socket.IO para tiempo real
      _socketService.emitKitchenAlert(payload);
      print('📢 Alerta enviada a cocina vía Socket.IO: $alertType - $reason');

      // También agregar localmente si el controller está disponible (fallback)
      // NOTA: Este código usa el formato viejo de alertas. En el futuro debería
      // migrarse al nuevo sistema usando KitchenAlertsService.
      if (_cocineroController != null) {
        // Usar el tipo OldKitchenAlert que espera el controller
        // Necesitamos acceder al tipo desde el controller
        // Por ahora, comentamos esto porque el nuevo sistema de alertas
        // ya maneja esto automáticamente vía Socket.IO
        // TODO: Migrar este código al nuevo sistema de alertas
        /*
        final alert = OldKitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: tableNumber,
          orderId: orderId,
          type: alertType,
          reason: reason,
          details: details,
          priority: prioridadBackend,
          timestamp: DateTime.now(),
        );
        _cocineroController!.addAlert(alert);
        */
      }
    } catch (e) {
      print('⚠️ Error al enviar alerta a cocina: $e');
    }
  }

  // Notificar cuando pedido está listo (de Cocinero a Mesero)
  void notifyOrderReady({
    required String orderId,
    required bool isTakeaway,
    int? tableNumber,
    String? customerName,
  }) {
    if (_meseroController == null) return;

    // Actualizar estado del pedido en el historial del mesero
    _meseroController!.updateOrderStatus(
      orderId,
      isTakeaway ? 'Listo para Recoger' : 'Listo',
    );

    // TODO: En una implementación completa, aquí se enviaría una notificación
    // al mesero a través del sistema de notificaciones
  }

  // Mapear categoría de producto a estación de cocina
  String _mapCategoryToStation(int category) {
    switch (category) {
      case ProductCategory.tacos:
      case ProductCategory.platosEspeciales:
      case ProductCategory.acompanamientos:
      case ProductCategory.extras:
        return KitchenStation.tacos;
      case ProductCategory.consomes:
        return KitchenStation.consomes;
      case ProductCategory.bebidas:
        return KitchenStation.bebidas;
      default:
        return KitchenStation.tacos;
    }
  }

  // Calcular tiempo estimado según items
  int _calculateEstimatedTime(List<OrderItem> items) {
    int maxTime = 0;

    for (final item in items) {
      int itemTime;
      switch (item.station) {
        case KitchenStation.tacos:
          itemTime = 8; // 8-12 min
          break;
        case KitchenStation.consomes:
          itemTime = 10; // 10-15 min
          break;
        case KitchenStation.bebidas:
          itemTime = 2; // 2-3 min
          break;
        default:
          itemTime = 8;
      }
      maxTime = maxTime > itemTime ? maxTime : itemTime;
    }

    // Agregar tiempo extra si hay múltiples items
    if (items.length > 3) {
      maxTime += 5;
    }

    return maxTime;
  }
}
