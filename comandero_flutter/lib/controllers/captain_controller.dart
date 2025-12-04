import 'package:flutter/material.dart';
import '../models/captain_model.dart';
import '../services/mesas_service.dart';
import '../services/socket_service.dart';
// import '../services/ordenes_service.dart'; // Reservado para futuras funcionalidades

class CaptainController extends ChangeNotifier {
  final MesasService _mesasService = MesasService();
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

  // Cargar mesas desde el backend
  Future<void> loadTables() async {
    try {
      final mesas = await _mesasService.getMesas();
      // Filtrar mesas inactivas (activo = false) - el backend marca como inactivo en lugar de eliminar
      final mesasActivas = mesas.where((m) {
        final data = m as Map<String, dynamic>;
        return (data['activo'] as bool?) ?? true; // Solo incluir mesas activas
      }).toList();
      
      _tables = mesasActivas.map((m) {
        final data = m as Map<String, dynamic>;
        final codigo = data['codigo'] as String;
        final numero = int.tryParse(codigo) ?? 0;
        final estadoNombre = (data['estadoNombre'] as String?)?.toLowerCase() ?? 'libre';
        
        // Mapear estado del backend a estado del frontend
        String status = CaptainTableStatus.disponible;
        final estadoLower = estadoNombre.toLowerCase().trim();
        
        // Verificar primero coincidencias exactas
        if (estadoLower == 'libre' || estadoLower == 'disponible') {
          status = CaptainTableStatus.disponible;
        } else if (estadoLower == 'ocupada' || estadoLower == 'ocupado') {
          status = CaptainTableStatus.ocupada;
        } else if (estadoLower == 'reservada' || estadoLower == 'reservado') {
          status = CaptainTableStatus.reservada;
        } else if (estadoLower == 'en limpieza' || 
                   estadoLower == 'en-limpieza' || 
                   estadoLower == 'limpieza') {
          status = CaptainTableStatus.servicio;
        } 
        // Luego verificar coincidencias parciales
        else if (estadoLower.contains('ocupad')) {
          status = CaptainTableStatus.ocupada;
        } else if (estadoLower.contains('cuenta')) {
          status = CaptainTableStatus.cuenta;
        } else if (estadoLower.contains('reservad')) {
          status = CaptainTableStatus.reservada;
        } else if (estadoLower.contains('limpieza')) {
          status = CaptainTableStatus.servicio;
        }
        
        return CaptainTable(
          number: numero,
          status: status,
          hasActiveOrder: status == CaptainTableStatus.ocupada || status == CaptainTableStatus.cuenta,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error al cargar mesas: $e');
      // Si falla, mantener lista vacía
      _tables = [];
      notifyListeners();
    }
  }

  CaptainController() {
    _initializeData();
    _setupSocketListeners();
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    final socketService = SocketService();
    
    // Escuchar nuevas órdenes creadas (solo si tienen mesa)
    socketService.onOrderCreated((data) {
      try {
        final mesaId = data['mesaId'] as int?;
        if (mesaId != null) {
          // Recargar mesas cuando se crea una orden con mesa
          loadTables();
          
          // Agregar alerta
          _alerts.add(CaptainAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'order_delayed',
            title: 'Nueva Orden',
            message: 'Nueva orden en mesa $mesaId',
            tableNumber: mesaId,
            orderNumber: data['id']?.toString() ?? '',
            minutes: 0,
            priority: 'medium',
            timestamp: DateTime.now(),
          ));
          notifyListeners();
        }
      } catch (e) {
        print('Error al procesar nueva orden en capitán: $e');
      }
    });

    // Escuchar actualizaciones de órdenes
    socketService.onOrderUpdated((data) {
      try {
        final mesaId = data['mesaId'] as int?;
        if (mesaId != null) {
          // Recargar mesas cuando se actualiza una orden
          loadTables();
        }
      } catch (e) {
        print('Error al procesar actualización de orden en capitán: $e');
      }
    });

    // Escuchar alertas de demora
    socketService.onAlertaDemora((data) {
      try {
        _alerts.add(CaptainAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'order_delayed',
          title: data['ordenId']?.toString() ?? 'Orden',
          message: data['mensaje'] ?? 'Orden con demora',
          tableNumber: data['mesaNumero'] as int? ?? 0,
          orderNumber: data['ordenId']?.toString() ?? '',
          minutes: data['minutos'] as int? ?? 0,
          priority: 'high',
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de demora: $e');
      }
    });

    // Escuchar alertas de cancelación
    socketService.onAlertaCancelacion((data) {
      try {
        _alerts.add(CaptainAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'service_issue', // Cambiar a service_issue para cancelaciones
          title: 'Orden Cancelada',
          message: data['mensaje'] ?? 'Una orden ha sido cancelada',
          tableNumber: data['mesaNumero'] as int? ?? 0,
          orderNumber: data['ordenId']?.toString() ?? '',
          minutes: 0,
          priority: 'high',
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cancelación: $e');
      }
    });

    // Escuchar alertas de modificación
    socketService.onAlertaModificacion((data) {
      try {
        _alerts.add(CaptainAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'service_issue',
          title: 'Orden Modificada',
          message: data['mensaje'] ?? 'Una orden ha sido modificada',
          tableNumber: data['mesaNumero'] as int? ?? 0,
          orderNumber: data['ordenId']?.toString() ?? '',
          minutes: 0,
          priority: 'medium',
          timestamp: DateTime.now(),
        ));
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de modificación: $e');
      }
    });

    // Escuchar alertas de mesa
    socketService.onAlertaMesa((data) {
      try {
        // Recargar mesas cuando hay cambios
        loadTables();
      } catch (e) {
        print('Error al procesar alerta de mesa: $e');
      }
    });

    // Escuchar eventos de mesas
    socketService.onTableCreated((data) {
      try {
        // Recargar mesas cuando se crea una nueva
        loadTables();
        notifyListeners();
      } catch (e) {
        print('Error al procesar mesa creada en capitán: $e');
      }
    });

    socketService.onTableUpdated((data) {
      try {
        print('📢 Capitán: Mesa actualizada recibida vía socket - Mesa ID: ${data['id']}, Estado: ${data['estadoNombre']}');
        // Recargar mesas cuando se actualiza una mesa (desde otro rol)
        // Esto asegura que los cambios del admin o mesero se reflejen en capitán
        loadTables();
        notifyListeners();
      } catch (e) {
        print('Error al procesar mesa actualizada en capitán: $e');
      }
    });

    socketService.onTableDeleted((data) {
      try {
        final mesaId = data['id'] as int?;
        final mesaNumero = data['numero'] as int?;
        print('📢 Capitán: Mesa eliminada recibida vía socket - Mesa ID: $mesaId, Número: $mesaNumero');
        
        // Eliminar la mesa de la lista local inmediatamente
        if (mesaNumero != null) {
          _tables.removeWhere((t) => t.number == mesaNumero);
          notifyListeners();
          print('✅ Capitán: Mesa $mesaNumero eliminada de la lista local');
        }
        
        // Recargar mesas desde el backend para asegurar sincronización completa
        loadTables();
      } catch (e) {
        print('❌ Error al procesar mesa eliminada en capitán: $e');
        // Si hay error, recargar desde el backend
        loadTables();
      }
    });

    // Escuchar eventos de pagos (para estadísticas)
    socketService.onPaymentCreated((data) {
      try {
        // Actualizar estadísticas cuando se crea un pago
        _initializeData(); // Recargar datos
        notifyListeners();
      } catch (e) {
        print('Error al procesar pago creado en capitán: $e');
      }
    });
  }

  void _initializeData() {
    // Cargar mesas desde el backend
    loadTables();
    
    // Datos de ejemplo solo para alertas y órdenes que no vienen del backend todavía
    // (estos se pueden mantener como fallback o eliminar cuando todo esté integrado)
    /*
    // Inicializar alertas de ejemplo según las imágenes
    _alerts = [
      CaptainAlert(
        id: 'alert_001',
        type: AlertType.orderDelayed,
        title: 'Orden ORD-001',
        message: 'Mesa 5 • tardó 25 min más de lo esperado',
        tableNumber: 5,
        orderNumber: 'ORD-001',
        minutes: 25,
        priority: AlertPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      CaptainAlert(
        id: 'alert_002',
        type: AlertType.tableDelayed,
        title: 'Mesa 3',
        message: 'Cuenta pendiente • 45 min sin cobrar',
        tableNumber: 3,
        minutes: 45,
        priority: AlertPriority.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];

    // Inicializar órdenes activas de ejemplo según las imágenes
    _activeOrders = [
      CaptainOrder(
        id: 'ORD-001',
        tableNumber: 5,
        status: CaptainOrderStatus.preparando,
        orderTime: DateTime.now().subtract(const Duration(minutes: 25)),
        elapsedMinutes: 25,
        waiter: 'Juan Martínez',
        total: 157.55,
        items: [
          CaptainOrderItem(
            name: 'Taco de Barbacoa',
            quantity: 3,
            station: 'Tacos',
            status: 'preparando',
            notes: 'Sin cebolla',
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
        waiter: 'María García',
        total: 145.95,
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
        waiter: 'María García',
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 45)),
        currentTotal: 145.95,
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
    */
    // Fin del comentario de datos de ejemplo
    // Las mesas ahora se cargan desde el backend a través de loadTables()
    // Las alertas y órdenes seguirán usando datos de ejemplo hasta que se integren completamente

    // Inicializar estadísticas (estas también se pueden integrar con el backend más adelante)
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
  Future<void> updateTableStatus(int tableNumber, String newStatus) async {
    try {
      // Verificar que la mesa existe
      if (!_tables.any((t) => t.number == tableNumber)) {
        throw Exception('Mesa no encontrada: $tableNumber');
      }
      
      // Obtener estados de mesa disponibles
      final estados = await _mesasService.getEstadosMesa();
      
      // Mapear estado del frontend al ID del backend
      int? estadoMesaId;
      final statusLower = newStatus.toLowerCase();
      
      if (statusLower.contains('libre') || statusLower.contains('disponible')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('libre') ||
                 (e['nombre'] as String).toLowerCase().contains('disponible'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 1},
        );
        estadoMesaId = estado['id'] as int;
      } else if (statusLower.contains('ocupada') || statusLower.contains('ocupado')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('ocupada') ||
                 (e['nombre'] as String).toLowerCase().contains('ocupado'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 2},
        );
        estadoMesaId = estado['id'] as int;
      } else if (statusLower.contains('limpieza')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('limpieza'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 3},
        );
        estadoMesaId = estado['id'] as int;
      } else if (statusLower.contains('reservada') || statusLower.contains('reservado')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('reservada') ||
                 (e['nombre'] as String).toLowerCase().contains('reservado'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 4},
        );
        estadoMesaId = estado['id'] as int;
      } else if (statusLower.contains('cuenta')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('cuenta'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 5},
        );
        estadoMesaId = estado['id'] as int;
      }
      
      if (estadoMesaId == null) {
        throw Exception('Estado de mesa no encontrado: $newStatus');
      }
      
      // Verificar que la mesa existe localmente
      if (!_tables.any((t) => t.number == tableNumber)) {
        throw Exception('Mesa con número $tableNumber no encontrada');
      }
      
      // Necesitamos obtener el ID de la mesa desde el backend
      // El número de mesa corresponde al código en el backend
      // Buscamos la mesa por código para obtener su ID
      final mesas = await _mesasService.getMesas();
      final mesaBackend = mesas.firstWhere(
        (m) {
          final codigo = m['codigo'] as String?;
          final numero = codigo != null ? int.tryParse(codigo) : null;
          return numero == tableNumber;
        },
        orElse: () => throw Exception('Mesa con número $tableNumber no encontrada en el backend'),
      );
      
      final mesaId = mesaBackend['id'] as int;
      
      // Actualizar estado en BD
      await _mesasService.cambiarEstadoMesa(mesaId, estadoMesaId);
      
      // Recargar mesas desde el backend para asegurar sincronización
      await loadTables();
    } catch (e) {
      print('Error al actualizar estado de mesa: $e');
      rethrow;
    }
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

  // Obtener monto total de cuentas pendientes
  double getPendingBillsAmount() {
    // Simular cálculo de cuentas pendientes
    // En producción, esto vendría de las facturas pendientes
    return 303.50;
  }

  // Obtener lista de facturas pendientes
  List<Map<String, dynamic>> getPendingBills() {
    // Simular lista de facturas pendientes
    // En producción, esto vendría del módulo Cajero
    return [
      {
        'id': 'BILL-001',
        'tableNumber': 5,
        'total': 157.55,
        'waiter': 'Juan Martínez',
        'isTakeaway': false,
        'elapsedMinutes': 2917,
      },
      {
        'id': 'BILL-002',
        'tableNumber': null,
        'total': 145.95,
        'waiter': 'María García',
        'isTakeaway': true,
        'customerName': 'Roberto',
        'elapsedMinutes': 2927,
      },
    ];
  }

  // Eliminar alerta por ID de orden
  void removeAlertByOrderId(String orderId) {
    _alerts = _alerts.where((alert) => alert.orderNumber != orderId).toList();
    notifyListeners();
  }
}

