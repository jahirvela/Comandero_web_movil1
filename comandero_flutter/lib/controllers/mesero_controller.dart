import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../models/product_model.dart';
import '../services/kitchen_order_service.dart';

class MeseroController extends ChangeNotifier {
  // Estado de las mesas
  List<TableModel> _tables = [];
  TableModel? _selectedTable;

  // Estado del carrito por mesa
  final Map<String, List<CartItem>> _tableOrders = {};

  // Historial de pedidos por mesa (pedidos enviados a cocina)
  final Map<String, List<Map<String, dynamic>>> _tableOrderHistory = {};

  // Estado de la vista actual
  String _currentView = 'floor';

  // Getters
  List<TableModel> get tables => _tables;
  TableModel? get selectedTable => _selectedTable;
  String get currentView => _currentView;

  // Obtener carrito de la mesa actual
  List<CartItem> getCurrentCart() {
    if (_selectedTable == null) return [];
    return _tableOrders[_selectedTable!.id.toString()] ?? [];
  }

  // Obtener total de artículos en todos los carritos
  int get totalCartItems {
    return _tableOrders.values.fold(0, (total, items) => total + items.length);
  }

  MeseroController() {
    _initializeTables();
  }

  void _initializeTables() {
    _tables = [
      TableModel(
        id: 1,
        number: 1,
        status: TableStatus.libre,
        seats: 4,
        position: TablePosition(x: 1, y: 1),
      ),
      TableModel(
        id: 2,
        number: 2,
        status: TableStatus.ocupada,
        seats: 2,
        customers: 2,
        position: TablePosition(x: 2, y: 1),
      ),
      TableModel(
        id: 3,
        number: 3,
        status: TableStatus.reservada,
        seats: 6,
        reservation: 'Familia López - 14:30',
        position: TablePosition(x: 3, y: 1),
      ),
      TableModel(
        id: 4,
        number: 4,
        status: TableStatus.enLimpieza,
        seats: 4,
        position: TablePosition(x: 1, y: 2),
      ),
      TableModel(
        id: 5,
        number: 5,
        status: TableStatus.libre,
        seats: 2,
        position: TablePosition(x: 2, y: 2),
      ),
      TableModel(
        id: 6,
        number: 6,
        status: TableStatus.ocupada,
        seats: 8,
        customers: 6,
        position: TablePosition(x: 3, y: 2),
      ),
      TableModel(
        id: 7,
        number: 7,
        status: TableStatus.libre,
        seats: 4,
        position: TablePosition(x: 1, y: 3),
      ),
      TableModel(
        id: 8,
        number: 8,
        status: TableStatus.ocupada,
        seats: 4,
        customers: 4,
        orderValue: 180,
        position: TablePosition(x: 2, y: 3),
      ),
      TableModel(
        id: 9,
        number: 9,
        status: TableStatus.libre,
        seats: 2,
        position: TablePosition(x: 3, y: 3),
      ),
    ];
    notifyListeners();
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Seleccionar mesa
  void selectTable(TableModel table) {
    _selectedTable = table;
    setCurrentView('table');
    notifyListeners();
  }

  // Cambiar estado de mesa
  void changeTableStatus(int tableId, String newStatus) {
    _tables = _tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: newStatus,
          customers:
              (newStatus == TableStatus.libre ||
                  newStatus == TableStatus.enLimpieza)
              ? null
              : table.customers,
          orderValue:
              (newStatus == TableStatus.libre ||
                  newStatus == TableStatus.enLimpieza)
              ? null
              : table.orderValue,
        );
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Agregar producto al carrito
  void addToCart(ProductModel product, {Map<String, dynamic>? customizations}) {
    if (_selectedTable == null) return;

    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      product: product,
      customizations: customizations ?? {},
      tableId: _selectedTable!.id.toString(),
    );

    final tableId = _selectedTable!.id.toString();
    _tableOrders[tableId] = [...(_tableOrders[tableId] ?? []), cartItem];
    notifyListeners();
  }

  // Remover producto del carrito
  void removeFromCart(String itemId) {
    if (_selectedTable == null) return;

    final tableId = _selectedTable!.id.toString();
    if (_tableOrders[tableId] != null) {
      _tableOrders[tableId] = _tableOrders[tableId]!
          .where((item) => item.id != itemId)
          .toList();
      notifyListeners();
    }
  }

  // Limpiar carrito de la mesa actual
  void clearCart() {
    if (_selectedTable == null) return;

    final tableId = _selectedTable!.id.toString();
    _tableOrders[tableId] = [];
    notifyListeners();
  }

  // Enviar pedido a cocina (método legacy, usar sendOrderToKitchen)
  void sendToKitchen({
    bool isTakeaway = false,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
  }) {
    sendOrderToKitchen(
      isTakeaway: isTakeaway,
      customerName: customerName,
      customerPhone: customerPhone,
      pickupTime: pickupTime,
    );
  }

  // Calcular total del carrito actual
  double calculateTotal() {
    final cart = getCurrentCart();
    return cart.fold(0.0, (total, item) => total + item.product.price);
  }

  // Obtener estadísticas de ocupación
  Map<String, int> getOccupancyStats() {
    return {
      'libre': _tables.where((t) => t.status == TableStatus.libre).length,
      'ocupada': _tables.where((t) => t.status == TableStatus.ocupada).length,
      'en-limpieza': _tables
          .where((t) => t.status == TableStatus.enLimpieza)
          .length,
      'reservada': _tables
          .where((t) => t.status == TableStatus.reservada)
          .length,
    };
  }

  // Calcular porcentaje de ocupación
  double getOccupancyRate() {
    final occupiedTables = _tables
        .where((t) => t.status != TableStatus.libre)
        .length;
    return (occupiedTables / _tables.length) * 100;
  }

  // Actualizar número de comensales en una mesa
  void updateTableCustomers(int tableId, int customers) {
    _tables = _tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          customers: customers > 0 ? customers : null,
        );
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Obtener historial de pedidos de una mesa
  List<Map<String, dynamic>> getTableOrderHistory(int tableId) {
    return _tableOrderHistory[tableId.toString()] ?? [];
  }

  // Limpiar historial de una mesa
  void clearTableHistory(int tableId) {
    _tableOrderHistory[tableId.toString()] = [];
    notifyListeners();
  }

  // Restaurar historial demo
  void restoreDemoHistory(int tableId) {
    final demoHistory = [
      {
        'id': 'ORD-034',
        'items': ['3x Taco Barbacoa'],
        'status': 'Listo',
        'time': '14:20',
        'date': DateTime.now().toString(),
      },
      {
        'id': 'ORD-029',
        'items': ['1x Mix Barbacoa', '2x Agua Horchata'],
        'status': 'En preparación',
        'time': '13:45',
        'date': DateTime.now().toString(),
      },
      {
        'id': 'ORD-025',
        'items': ['2x Quesadilla Barbacoa'],
        'status': 'Entregado',
        'time': '13:15',
        'date': DateTime.now().toString(),
      },
    ];
    _tableOrderHistory[tableId.toString()] = demoHistory;
    notifyListeners();
  }

  // Enviar cuenta al cajero
  void sendToCashier(int tableId) {
    final cart = _tableOrders[tableId.toString()] ?? [];
    if (cart.isEmpty) return;

    final total = cart.fold(0.0, (sum, item) => sum + item.product.price);
    
    // Actualizar valor de orden en la mesa
    _tables = _tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(orderValue: total);
      }
      return table;
    }).toList();

    // Agregar al historial como "Enviado al Cajero"
    final orderId = 'ACC-${DateTime.now().millisecondsSinceEpoch}';
    final order = {
      'id': orderId,
      'items': cart.map((item) {
        final qty = item.customizations['quantity'] as int? ?? 1;
        return '${qty}x ${item.product.name}';
      }).toList(),
      'status': 'Enviado al Cajero',
      'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'date': DateTime.now().toString(),
      'total': total,
    };

    final history = _tableOrderHistory[tableId.toString()] ?? [];
    _tableOrderHistory[tableId.toString()] = [order, ...history];

    notifyListeners();
  }

  // Mejorar sendToKitchen para agregar al historial y enviar a cocina
  void sendOrderToKitchen({
    bool isTakeaway = false,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
  }) {
    if (_selectedTable == null) return;

    final currentCart = getCurrentCart();
    if (currentCart.isEmpty) return;

    final tableId = _selectedTable!.id.toString();
    
    // Crear ID de orden único
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    
    // Crear pedido para historial
    final order = {
      'id': orderId,
      'items': currentCart.map((item) {
        final qty = item.customizations['quantity'] as int? ?? 1;
        return '${qty}x ${item.product.name}';
      }).toList(),
      'status': 'Enviado',
      'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'date': DateTime.now().toString(),
      'isTakeaway': isTakeaway,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupTime': pickupTime,
    };

    // Agregar al historial
    final history = _tableOrderHistory[tableId] ?? [];
    _tableOrderHistory[tableId] = [order, ...history];

    // Enviar pedido a cocina a través del servicio
    final service = KitchenOrderService();
    service.sendOrderToKitchen(
      orderId: orderId,
      cartItems: currentCart,
      tableNumber: isTakeaway ? null : _selectedTable!.number,
      waiterName: 'Mesero', // TODO: Obtener del AuthController cuando esté disponible
      isTakeaway: isTakeaway,
      customerName: customerName,
      customerPhone: customerPhone,
      pickupTime: pickupTime,
    );

    // Limpiar carrito
    clearCart();

    notifyListeners();
  }

  // Actualizar estado de pedido (cuando cocinero lo tiene listo)
  void updateOrderStatus(String orderId, String newStatus) {
    _tableOrderHistory.forEach((tableId, orders) {
      for (var order in orders) {
        if (order['id'] == orderId) {
          order['status'] = newStatus;
          notifyListeners();
          return;
        }
      }
    });
  }
}
