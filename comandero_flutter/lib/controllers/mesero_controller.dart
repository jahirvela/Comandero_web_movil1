import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../models/product_model.dart';

class MeseroController extends ChangeNotifier {
  // Estado de las mesas
  List<TableModel> _tables = [];
  TableModel? _selectedTable;

  // Estado del carrito por mesa
  final Map<String, List<CartItem>> _tableOrders = {};

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

  // Enviar pedido a cocina
  void sendToKitchen({
    bool isTakeaway = false,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
  }) {
    if (_selectedTable == null) return;

    final currentCart = getCurrentCart();
    if (currentCart.isEmpty) return;

    // Aquí se enviaría el pedido a cocina
    // Por ahora solo limpiamos el carrito
    clearCart();

    // Mostrar mensaje de confirmación
    if (isTakeaway) {
      // Mostrar toast para takeaway
    } else {
      // Mostrar toast para pedido normal
    }
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
}
