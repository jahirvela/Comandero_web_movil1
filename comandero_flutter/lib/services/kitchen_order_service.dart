import '../models/order_model.dart';
import '../models/product_model.dart';
import '../controllers/mesero_controller.dart';
import '../controllers/cocinero_controller.dart';

/// Servicio compartido para comunicar pedidos entre Mesero y Cocinero
/// Simula comunicación en tiempo real que luego se conectará con backend
class KitchenOrderService {
  static final KitchenOrderService _instance = KitchenOrderService._internal();
  factory KitchenOrderService() => _instance;
  KitchenOrderService._internal();

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
    if (_cocineroController == null) return;

    // Convertir CartItems a OrderItems
    final orderItems = cartItems.map((cartItem) {
      final quantity = cartItem.customizations['quantity'] as int? ?? 1;
      final kitchenNotes = cartItem.customizations['kitchenNotes'] as String? ?? '';
      
      // Determinar estación según categoría del producto
      final station = _mapCategoryToStation(cartItem.product.category);
      
      // Combinar notas del producto con notas de customización
      final notes = kitchenNotes.isNotEmpty
          ? kitchenNotes
          : (cartItem.customizations['sauce'] != null
              ? 'Salsa: ${cartItem.customizations['sauce']}'
              : '');

      return OrderItem(
        id: int.tryParse(cartItem.id) ?? DateTime.now().millisecondsSinceEpoch,
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

    // Agregar pedido al controller de cocinero
    _cocineroController!.addOrder(order);
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

