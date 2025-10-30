import 'package:flutter/material.dart';
import '../models/captain_model.dart';

class CaptainController extends ChangeNotifier {
  // Estado de las alertas
  List<CaptainAlert> _alerts = [];

  // Estado de las órdenes activas
  List<CaptainOrder> _activeOrders = [];

  // Estado de las mesas
  List<CaptainTable> _tables = [];

  // Estadísticas del día
  CaptainStats _stats = CaptainStats(
    todaySales: 0,
    variation: '+0%',
    avgTicket: 0,
    totalOrders: 0,
    activeTables: 0,
    pendingOrders: 0,
    urgentOrders: 0,
  );

  // Filtros
  String _selectedTableStatus = 'todas';
  String _selectedOrderStatus = 'todas';
  String _selectedPriority = 'todas';

  // Getters
  List<CaptainAlert> get alerts => _alerts;
  List<CaptainOrder> get activeOrders => _activeOrders;
  List<CaptainTable> get tables => _tables;
  CaptainStats get stats => _stats;
  String get selectedTableStatus => _selectedTableStatus;
  String get selectedOrderStatus => _selectedOrderStatus;
  String get selectedPriority => _selectedPriority;

  // Obtener alertas filtradas
  List<CaptainAlert> get filteredAlerts {
    return _alerts.where((alert) {
      final priorityMatch =
          _selectedPriority == 'todas' || alert.priority == _selectedPriority;
      return priorityMatch;
    }).toList();
  }

  // Obtener órdenes filtradas
  List<CaptainOrder> get filteredOrders {
    return _activeOrders.where((order) {
      final statusMatch =
          _selectedOrderStatus == 'todas' ||
          order.status == _selectedOrderStatus;
      return statusMatch;
    }).toList();
  }

  // Obtener mesas filtradas
  List<CaptainTable> get filteredTables {
    return _tables.where((table) {
      final statusMatch =
          _selectedTableStatus == 'todas' ||
          table.status == _selectedTableStatus;
      return statusMatch;
    }).toList();
  }

  CaptainController() {
    _initializeData();
  }

  void _initializeData() {
    // Inicializar alertas de ejemplo
    _alerts = [
      CaptainAlert(
        id: 'alert_001',
        type: AlertType.tableDelayed,
        title: 'Mesa 5 - Tiempo de espera excedido',
        message: 'La mesa 5 lleva más de 45 minutos esperando su orden',
        tableNumber: 5,
        minutes: 45,
        priority: AlertPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      CaptainAlert(
        id: 'alert_002',
        type: AlertType.orderDelayed,
        title: 'Orden ORD-003 - Retraso en cocina',
        message: 'La orden ORD-003 lleva más de 30 minutos en preparación',
        orderNumber: 'ORD-003',
        minutes: 30,
        priority: AlertPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      CaptainAlert(
        id: 'alert_003',
        type: AlertType.serviceIssue,
        title: 'Mesa 3 - Problema de servicio',
        message: 'El cliente de la mesa 3 reporta problema con su orden',
        tableNumber: 3,
        minutes: 15,
        priority: AlertPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    // Inicializar órdenes activas de ejemplo
    _activeOrders = [
      CaptainOrder(
        id: 'ORD-001',
        tableNumber: 5,
        status: CaptainOrderStatus.preparando,
        orderTime: DateTime.now().subtract(const Duration(minutes: 25)),
        elapsedMinutes: 25,
        waiter: 'Juan Martínez',
        total: 159.0,
        items: [
          CaptainOrderItem(
            name: 'Taco de Barbacoa',
            quantity: 3,
            station: 'Tacos',
            status: 'preparando',
            notes: 'Sin cebolla',
          ),
          CaptainOrderItem(
            name: 'Consomé Grande',
            quantity: 1,
            station: 'Consomes',
            status: 'listo',
          ),
        ],
        priority: AlertPriority.medium,
        isUrgent: false,
      ),
      CaptainOrder(
        id: 'ORD-002',
        tableNumber: 3,
        status: CaptainOrderStatus.listo,
        orderTime: DateTime.now().subtract(const Duration(minutes: 40)),
        elapsedMinutes: 40,
        waiter: 'María López',
        total: 161.0,
        items: [
          CaptainOrderItem(
            name: 'Mix Barbacoa',
            quantity: 1,
            station: 'Consomes',
            status: 'listo',
            notes: 'Bien dorado',
          ),
        ],
        priority: AlertPriority.high,
        isUrgent: true,
      ),
    ];

    // Inicializar mesas de ejemplo
    _tables = [
      CaptainTable(
        number: 1,
        status: CaptainTableStatus.disponible,
        hasActiveOrder: false,
      ),
      CaptainTable(
        number: 2,
        status: CaptainTableStatus.ocupada,
        customers: 2,
        waiter: 'Juan Martínez',
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 30)),
        currentTotal: 89.0,
        hasActiveOrder: true,
      ),
      CaptainTable(
        number: 3,
        status: CaptainTableStatus.cuenta,
        customers: 4,
        waiter: 'María López',
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 45)),
        currentTotal: 161.0,
        hasActiveOrder: true,
        notes: 'Esperando pago',
      ),
      CaptainTable(
        number: 4,
        status: CaptainTableStatus.reservada,
        hasActiveOrder: false,
        notes: 'Reserva para 14:30 - Familia López',
      ),
      CaptainTable(
        number: 5,
        status: CaptainTableStatus.ocupada,
        customers: 3,
        waiter: 'Juan Martínez',
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 25)),
        currentTotal: 159.0,
        hasActiveOrder: true,
      ),
    ];

    // Inicializar estadísticas
    _stats = CaptainStats(
      todaySales: 3250.0,
      variation: '+12.5%',
      avgTicket: 135.42,
      totalOrders: 24,
      activeTables: 3,
      pendingOrders: 2,
      urgentOrders: 1,
    );

    notifyListeners();
  }

  // Cambiar filtro de estado de mesa
  void setSelectedTableStatus(String status) {
    _selectedTableStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de estado de orden
  void setSelectedOrderStatus(String status) {
    _selectedOrderStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de prioridad
  void setSelectedPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  // Marcar alerta como leída
  void markAlertAsRead(String alertId) {
    _alerts = _alerts.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();
    notifyListeners();
  }

  // Marcar todas las alertas como leídas
  void markAllAlertsAsRead() {
    _alerts = _alerts.map((alert) => alert.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  // Agregar nueva alerta
  void addAlert(CaptainAlert alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  // Actualizar estado de mesa
  void updateTableStatus(int tableNumber, String newStatus) {
    _tables = _tables.map((table) {
      if (table.number == tableNumber) {
        return table.copyWith(status: newStatus);
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Reasignar mesa a otro mesero
  void reassignTable(int tableNumber, String newWaiter) {
    _tables = _tables.map((table) {
      if (table.number == tableNumber) {
        return table.copyWith(waiter: newWaiter);
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Obtener alertas no leídas
  List<CaptainAlert> getUnreadAlerts() {
    return _alerts.where((alert) => !alert.isRead).toList();
  }

  // Obtener órdenes urgentes
  List<CaptainOrder> getUrgentOrders() {
    return _activeOrders.where((order) => order.isUrgent).toList();
  }

  // Obtener mesas ocupadas
  List<CaptainTable> getOccupiedTables() {
    return _tables
        .where((table) => table.status == CaptainTableStatus.ocupada)
        .toList();
  }

  // Obtener mesas con cuenta pendiente
  List<CaptainTable> getTablesWithPendingBill() {
    return _tables
        .where((table) => table.status == CaptainTableStatus.cuenta)
        .toList();
  }

  // Obtener color de estado de mesa
  Color getTableStatusColor(String status) {
    switch (status) {
      case CaptainTableStatus.disponible:
        return Colors.green;
      case CaptainTableStatus.ocupada:
        return Colors.red;
      case CaptainTableStatus.cuenta:
        return Colors.orange;
      case CaptainTableStatus.reservada:
        return Colors.blue;
      case CaptainTableStatus.servicio:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de estado de orden
  Color getOrderStatusColor(String status) {
    switch (status) {
      case CaptainOrderStatus.preparando:
        return Colors.yellow;
      case CaptainOrderStatus.listo:
        return Colors.green;
      case CaptainOrderStatus.entregado:
        return Colors.blue;
      case CaptainOrderStatus.cancelado:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de prioridad
  Color getPriorityColor(String priority) {
    switch (priority) {
      case AlertPriority.high:
        return Colors.red;
      case AlertPriority.medium:
        return Colors.orange;
      case AlertPriority.low:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Formatear tiempo transcurrido
  String formatElapsedTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  // Formatear moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Formatear fecha
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Obtener estadísticas de mesas
  Map<String, int> getTableStats() {
    final stats = <String, int>{};
    for (final table in _tables) {
      stats[table.status] = (stats[table.status] ?? 0) + 1;
    }
    return stats;
  }

  // Obtener estadísticas de órdenes
  Map<String, int> getOrderStats() {
    final stats = <String, int>{};
    for (final order in _activeOrders) {
      stats[order.status] = (stats[order.status] ?? 0) + 1;
    }
    return stats;
  }

  // Obtener estadísticas de alertas
  Map<String, int> getAlertStats() {
    final stats = <String, int>{};
    for (final alert in _alerts) {
      stats[alert.priority] = (stats[alert.priority] ?? 0) + 1;
    }
    return stats;
  }
}

