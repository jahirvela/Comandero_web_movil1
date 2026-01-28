import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/captain_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../services/mesas_service.dart';
import '../services/socket_service.dart';
import '../services/ordenes_service.dart';
import '../services/bill_repository.dart';
import '../services/kitchen_alerts_service.dart';
import '../config/api_config.dart';
import '../utils/date_utils.dart' as date_utils;

class CaptainController extends ChangeNotifier {
  final MesasService _mesasService = MesasService();
  final OrdenesService _ordenesService = OrdenesService();
  final BillRepository _billRepository = BillRepository();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  KitchenAlertsService? _kitchenAlertsService;
  
  // Estado de las alertas
  List<CaptainAlert> _alerts = [];

  // Estado de las órdenes activas
  List<OrderModel> _activeOrders = [];
  
  // Mapa auxiliar para almacenar información adicional de órdenes (items con precios, totales, etc.)
  final Map<String, Map<String, dynamic>> _orderAdditionalData = {};

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
  List<OrderModel> get activeOrders => _activeOrders;
  List<CaptainTable> get tables => _tables;
  CaptainStats get stats => _stats;
  String get selectedTableStatus => _selectedTableStatus;
  String get selectedOrderStatus => _selectedOrderStatus;
  String get selectedPriority => _selectedPriority;
  List<BillModel> get pendingBills => _billRepository.pendingBills;

  // Obtener alertas filtradas
  List<CaptainAlert> get filteredAlerts {
    return _alerts.where((alert) {
      final priorityMatch =
          _selectedPriority == 'todas' || alert.priority == _selectedPriority;
      return priorityMatch;
    }).toList();
  }

  // Obtener órdenes filtradas
  List<OrderModel> get filteredOrders {
    return _activeOrders.where((order) {
      final statusMatch =
          _selectedOrderStatus == 'todas' ||
          order.status.toLowerCase().contains(_selectedOrderStatus.toLowerCase());
      return statusMatch;
    }).toList();
  }
  
  // Obtener información adicional de una orden (items como texto, total, etc.)
  Map<String, dynamic>? getOrderAdditionalData(String orderId) {
    return _orderAdditionalData[orderId];
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
    // Configurar Socket.IO después de un delay para asegurar que esté conectado
    Future.delayed(const Duration(milliseconds: 2000), () {
      final socketService = SocketService();
      if (socketService.isConnected) {
        _setupSocketListeners();
        print('✅ Capitán: Listeners de Socket.IO configurados');
      } else {
        print('⚠️ Capitán: Socket.IO no está conectado aún, intentando conectar...');
        socketService.connect().then((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _setupSocketListeners();
            print('✅ Capitán: Listeners de Socket.IO configurados después de conectar');
          });
        }).catchError((e) {
          print('❌ Capitán: Error al conectar Socket.IO: $e');
        });
      }
    });
  }

  @override
  void dispose() {
    _kitchenAlertsService?.dispose();
    super.dispose();
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    final socketService = SocketService();
    
    // Verificar que Socket.IO esté conectado antes de configurar listeners
    if (!socketService.isConnected) {
      print('⚠️ Capitán: Socket.IO no está conectado, esperando conexión...');
      // Esperar hasta 5 segundos para que se conecte
      int attempts = 0;
      while (attempts < 10 && !socketService.isConnected) {
        Future.delayed(const Duration(milliseconds: 500), () {});
        attempts++;
      }
      if (!socketService.isConnected) {
        print('❌ Capitán: Socket.IO no se conectó después de esperar, intentando reconectar...');
        socketService.connect().catchError((e) {
          print('❌ Capitán: Error al reconectar Socket.IO: $e');
        });
        return; // Los listeners se configurarán cuando se conecte
      }
    }
    
    print('✅ Capitán: Socket.IO está conectado, configurando listeners...');
    print('📡 Capitán: URL de Socket.IO: ${ApiConfig.socketUrl}');
    
    // Cargar alertas pendientes desde BD al iniciar
    _loadPendingAlerts();
    
    // ============================================
    // NUEVO SISTEMA DE ALERTAS DE COCINA (igual que cocinero)
    // ============================================
    _kitchenAlertsService = KitchenAlertsService(socketService);
    
    _kitchenAlertsService!.listenNewAlerts((alert) {
      try {
        print('🔔 Capitán: Nueva alerta recibida (kitchen:alert:new) - OrderId: ${alert.orderId}');
        
        final alertId = alert.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Verificar si esta alerta ya fue descartada
        if (_dismissedAlertIds.contains(alertId)) {
          print('⚠️ Capitán: Alerta $alertId ignorada (ya fue descartada)');
          return;
        }
        
        final orderIdStr = 'ORD-${alert.orderId.toString().padLeft(6, '0')}';
        
        // Obtener número de mesa correcto desde la orden activa
        int? tableNumber;
        try {
          final order = _activeOrders.firstWhere(
            (o) => o.id == orderIdStr,
            orElse: () => _activeOrders.firstWhere(
              (o) => o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '') == alert.orderId.toString(),
              orElse: () => throw Exception('Orden no encontrada'),
            ),
          );
          tableNumber = order.tableNumber;
        } catch (e) {
          // Si no se encuentra la orden, usar tableId como fallback
          tableNumber = alert.tableId;
          print('⚠️ Capitán: No se encontró orden $orderIdStr, usando tableId: $tableNumber');
        }
        
        // Mapear prioridad
        String priority = 'medium';
        final alertPriorityLower = alert.priority.toLowerCase();
        if (alertPriorityLower == 'urgente' || alertPriorityLower == 'urgent') {
          priority = 'high';
        } else if (alertPriorityLower == 'high') {
          priority = 'high';
        }
        
        // Mapear tipo de alerta
        String alertType = 'order_delayed';
        if (alert.type.name == 'CANCEL_ORDER') {
          alertType = 'service_issue';
        } else if (alert.type.name == 'UPDATE_ORDER') {
          alertType = 'service_issue';
        }
        
        final captainAlert = CaptainAlert(
          id: alertId,
          type: alertType,
          title: alert.type.displayName,
          message: alert.message,
          tableNumber: tableNumber,
          orderNumber: orderIdStr,
          minutes: 0,
          priority: priority,
          timestamp: alert.createdAt ?? DateTime.now(),
        );
        
        // Mejorar lógica de detección de duplicados: verificar por ID, orden+tipo, o orden+mensaje similar
        final isDuplicate = _alerts.any((a) {
          // Mismo ID
          if (a.id == captainAlert.id) return true;
          // Misma orden, mismo tipo, y menos de 5 minutos de diferencia
          if (a.orderNumber == captainAlert.orderNumber && 
              a.type == captainAlert.type &&
              (captainAlert.timestamp.difference(a.timestamp).inMinutes.abs() < 5)) {
            return true;
          }
          // Misma orden y mensaje muy similar (para evitar duplicados por diferentes fuentes)
          if (a.orderNumber == captainAlert.orderNumber &&
              a.message == captainAlert.message &&
              (captainAlert.timestamp.difference(a.timestamp).inMinutes.abs() < 10)) {
            return true;
          }
          return false;
        });
        
        if (!isDuplicate) {
          _alerts.insert(0, captainAlert);
          notifyListeners();
          print('✅ Capitán: Alerta agregada - Tipo: ${alert.type.displayName}, Orden: $orderIdStr, Mesa: $tableNumber');
        } else {
          print('⚠️ Capitán: Alerta duplicada ignorada - Orden: $orderIdStr, Tipo: ${alert.type.displayName}');
        }
      } catch (e, stackTrace) {
        print('❌ Error al procesar alerta en capitán: $e');
        print('Stack trace: $stackTrace');
      }
    });
    
    // Escuchar nuevas órdenes creadas
    socketService.onOrderCreated((data) {
      try {
        _handleOrderCreated(data);
      } catch (e) {
        print('Error al procesar nueva orden en capitán: $e');
      }
    });

    // Escuchar actualizaciones de órdenes
    socketService.onOrderUpdated((data) {
      try {
        _handleOrderUpdated(data);
      } catch (e) {
        print('Error al procesar actualización de orden en capitán: $e');
      }
    });
    
    // Escuchar órdenes canceladas
    socketService.onOrderCancelled((data) {
      try {
        _handleOrderCancelled(data);
      } catch (e) {
        print('Error al procesar orden cancelada en capitán: $e');
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

    // Escuchar alertas de cancelación (evento legacy, ya manejado por kitchen:alert:new)
    socketService.onAlertaCancelacion((data) {
      try {
        final orderId = data['ordenId'] as int?;
        final mensaje = data['mensaje'] as String? ?? 'Una orden ha sido cancelada';
        
        // Ya debería haberse agregado por kitchen:alert:new, pero por si acaso
        final existingAlert = _alerts.any((a) => 
          a.orderNumber == 'ORD-${orderId?.toString().padLeft(6, '0') ?? ''}' &&
          a.message.contains('cancel')
        );
        
        if (!existingAlert && orderId != null) {
          _alerts.add(CaptainAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'service_issue',
            title: 'Orden Cancelada',
            message: mensaje,
            tableNumber: data['mesaNumero'] as int?,
            orderNumber: 'ORD-${orderId.toString().padLeft(6, '0')}',
            minutes: 0,
            priority: 'high',
            timestamp: DateTime.now(),
          ));
          notifyListeners();
        }
      } catch (e) {
        print('Error al procesar alerta de cancelación en capitán: $e');
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

    // Escuchar eventos de pagos (para estadísticas y actualizar cuentas por cobrar)
    socketService.onPaymentCreated((data) {
      try {
        // Remover la cuenta pagada de las cuentas pendientes
        final billId = data['billId'] as String?;
        if (billId != null) {
          _billRepository.removeBill(billId);
          _updateBillsList();
        }
        // Actualizar estadísticas cuando se crea un pago
        _updateStats();
        notifyListeners();
      } catch (e) {
        print('Error al procesar pago creado en capitán: $e');
      }
    });
    
    // Escuchar cuando se envía una cuenta desde el mesero
    socketService.on('cuenta.enviada', (data) {
      try {
        print('📄 Capitán: Cuenta recibida en tiempo real');
        // El BillRepository ya maneja esto automáticamente si está escuchando
        // Solo necesitamos actualizar nuestra lista local
        _updateBillsList();
        notifyListeners();
      } catch (e) {
        print('❌ Error al procesar cuenta enviada en capitán: $e');
      }
    });
  }
  
  // Actualizar lista de bills desde el repositorio
  void _updateBillsList() {
    // El repositorio ya tiene las bills actualizadas, solo notificamos
    notifyListeners();
  }

  void _initializeData() {
    // Cargar mesas desde el backend
    loadTables();
    
    // Cargar órdenes activas desde el backend
    loadActiveOrders();
    
    // Cargar cuentas por cobrar desde el repositorio
    _billRepository.addListener(_onBillsChanged);
    
    // Actualizar estadísticas
    _updateStats();
    
    notifyListeners();
    
    /* DATOS DE EJEMPLO (mantener comentado)
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
  List<OrderModel> getUrgentOrders() {
    return _activeOrders.where((order) {
      final priority = (order.priority ?? '').toLowerCase();
      return priority == 'alta' || priority == 'urgente' || priority == 'high';
    }).toList();
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
    final bills = _billRepository.pendingBills;
    return bills.fold(0.0, (sum, bill) => sum + bill.total);
  }

  // Obtener lista de facturas pendientes (formato para UI)
  List<Map<String, dynamic>> getPendingBills() {
    final bills = _billRepository.pendingBills;
    final now = DateTime.now();
    
    return bills.map((bill) {
      final elapsed = bill.createdAt != null 
          ? now.difference(bill.createdAt!).inMinutes 
          : 0;
      
      return {
        'id': bill.id,
        'tableNumber': bill.tableNumber,
        'total': bill.total,
        'waiter': bill.waiterName ?? 'Mesero',
        'isTakeaway': bill.isTakeaway ?? false,
        'customerName': bill.customerName,
        'elapsedMinutes': elapsed,
      };
    }).toList();
  }
  
  // Callback cuando cambian las bills
  void _onBillsChanged() {
    notifyListeners();
  }

  // Eliminar alerta por ID de orden
  void removeAlertByOrderId(String orderId) {
    _alerts = _alerts.where((alert) => alert.orderNumber != orderId).toList();
    notifyListeners();
  }
  
  // Set para mantener IDs de alertas eliminadas (para evitar que vuelvan a aparecer)
  final Set<String> _dismissedAlertIds = {};
  
  // Eliminar una alerta (marcarla como leída en el backend)
  Future<void> removeAlert(String alertId) async {
    // Agregar a la lista de alertas descartadas para evitar que vuelva a aparecer
    _dismissedAlertIds.add(alertId);
    
    // Intentar marcar como leída en el backend si tiene ID numérico
    try {
      final alertaIdInt = int.tryParse(alertId);
      if (alertaIdInt != null) {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) {
          final dio = Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ));
          
          await dio.patch('/alertas/$alertaIdInt/leida');
          print('✅ Capitán: Alerta $alertId marcada como leída en BD');
        }
      }
    } catch (e) {
      print('⚠️ Capitán: Error al marcar alerta como leída (continuando): $e');
      // Continuar aunque falle, es mejor eliminar la alerta localmente
    }
    
    // Eliminar de la lista local
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }
  
  // Limpiar todas las alertas (marcar todas como leídas)
  Future<void> clearAllAlerts() async {
    // Agregar todas las alertas actuales a la lista de descartadas
    for (final alert in _alerts) {
      _dismissedAlertIds.add(alert.id);
    }
    
    // Marcar todas las alertas como leídas en el backend
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        final dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
        
        await dio.post('/alertas/marcar-todas-leidas');
        print('✅ Capitán: Todas las alertas marcadas como leídas en BD');
      }
    } catch (e) {
      print('⚠️ Capitán: Error al marcar todas las alertas como leídas (continuando): $e');
      // Continuar aunque falle
    }
    
    // Limpiar todas las alertas localmente
    _alerts.clear();
    notifyListeners();
  }
  
  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  
  // Cargar alertas pendientes desde BD (igual que cocinero)
  Future<void> _loadPendingAlerts() async {
    try {
      print('📥 Capitán: Cargando alertas pendientes desde la BD...');
      
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      
      final token = await _storage.read(key: 'accessToken');
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await dio.get('/alertas');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> alertas = [];
        
        if (responseData is Map<String, dynamic> && responseData['data'] != null) {
          alertas = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          alertas = responseData;
        }
        
        print('📥 Capitán: ${alertas.length} alertas recibidas del backend');
        
        for (final alertaData in alertas) {
          try {
            final ordenId = alertaData['ordenId'] as int?;
            if (ordenId == null) continue;
            
            final mensaje = alertaData['mensaje'] as String? ?? '';
            final mesaId = alertaData['mesaId'] as int?;
            final alertaId = alertaData['id'] as int?;
            final creadoEn = alertaData['creadoEn'] as String?;
            
            // Parsear fecha
            final timestampParsed = creadoEn != null 
              ? date_utils.AppDateUtils.parseToLocal(creadoEn)
              : DateTime.now();
            
            // Parsear metadata para obtener prioridad y mesaCodigo
            final metadataRaw = alertaData['metadata'];
            Map<String, dynamic> metadata = {};
            if (metadataRaw is String && metadataRaw.isNotEmpty) {
              try {
                metadata = jsonDecode(metadataRaw) as Map<String, dynamic>;
              } catch (e) {
                print('⚠️ Capitán: Error al parsear metadata JSON: $e');
              }
            } else if (metadataRaw is Map) {
              metadata = Map<String, dynamic>.from(metadataRaw);
            }
            
            String priority = metadata['priority']?.toString() ?? 'Normal';
            String priorityOldFormat = 'medium';
            if (priority.toLowerCase() == 'urgente' || priority.toLowerCase() == 'urgent') {
              priorityOldFormat = 'high';
            } else if (priority.toLowerCase() == 'high') {
              priorityOldFormat = 'high';
            }
            
            // Determinar tipo de alerta
            String alertType = 'order_delayed';
            String alertTypeDisplay = 'Demora';
            if (mensaje.toLowerCase().contains('cancel')) {
              alertType = 'service_issue';
              alertTypeDisplay = 'Cancelación';
            } else if (mensaje.toLowerCase().contains('cambio')) {
              alertType = 'service_issue';
              alertTypeDisplay = 'Cambio en orden';
            }
            
            final orderIdStr = 'ORD-${ordenId.toString().padLeft(6, '0')}';
            
            final alertId = alertaId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
            
            // Verificar si esta alerta ya fue descartada
            if (_dismissedAlertIds.contains(alertId)) {
              continue;
            }
            
            // Obtener número de mesa correcto: primero intentar desde metadata.mesaCodigo, luego desde orden activa
            int? tableNumber;
            final mesaCodigo = metadata['mesaCodigo'] as String?;
            if (mesaCodigo != null) {
              tableNumber = int.tryParse(mesaCodigo);
            }
            
            // Si no hay mesaCodigo, buscar en la orden activa
            if (tableNumber == null) {
              try {
                final order = _activeOrders.firstWhere(
                  (o) => o.id == orderIdStr,
                  orElse: () => _activeOrders.firstWhere(
                    (o) => o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '') == ordenId.toString(),
                    orElse: () => throw Exception('Orden no encontrada'),
                  ),
                );
                tableNumber = order.tableNumber;
              } catch (e) {
                // Si no se encuentra, usar mesaId como fallback
                tableNumber = mesaId;
              }
            }
            
            final captainAlert = CaptainAlert(
              id: alertId,
              type: alertType,
              title: alertTypeDisplay,
              message: mensaje,
              tableNumber: tableNumber,
              orderNumber: orderIdStr,
              minutes: 0,
              priority: priorityOldFormat,
              timestamp: timestampParsed,
            );
            
            // Mejorar lógica de detección de duplicados: verificar por ID, orden+tipo, o orden+mensaje similar
            final isDuplicate = _alerts.any((a) {
              // Mismo ID
              if (a.id == captainAlert.id) return true;
              // Misma orden, mismo tipo, y menos de 5 minutos de diferencia
              if (a.orderNumber == captainAlert.orderNumber && 
                  a.type == captainAlert.type &&
                  (captainAlert.timestamp.difference(a.timestamp).inMinutes.abs() < 5)) {
                return true;
              }
              // Misma orden y mensaje muy similar (para evitar duplicados por diferentes fuentes)
              if (a.orderNumber == captainAlert.orderNumber &&
                  a.message == captainAlert.message &&
                  (captainAlert.timestamp.difference(a.timestamp).inMinutes.abs() < 10)) {
                return true;
              }
              return false;
            });
            
            if (!isDuplicate) {
              _alerts.add(captainAlert);
            } else {
              print('⚠️ Capitán: Alerta duplicada ignorada al cargar desde BD - Orden: $orderIdStr, Tipo: $alertType');
            }
          } catch (e) {
            print('⚠️ Capitán: Error al parsear alerta: $e');
          }
        }
        
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
        print('✅ Capitán: ${_alerts.length} alertas cargadas desde BD');
      }
    } catch (e) {
      print('❌ Capitán: Error al cargar alertas: $e');
    }
  }
  
  // Cargar órdenes activas desde el backend
  Future<void> loadActiveOrders() async {
    try {
      print('📋 Capitán: Cargando órdenes activas...');
      
      final ordenes = await _ordenesService.getOrdenes();
      
      // Filtrar órdenes activas (no pagadas, no canceladas)
      final estadosFinalizados = [
        'pagada', 'cancelada', 'cerrada', 'cobrada',
        'entregada', 'completada', 'finalizada',
      ];
      
      final ordenesActivas = ordenes
          .where((o) {
            final ordenData = o as Map<String, dynamic>;
            final estadoNombre = (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';
            final esFinalizada = estadosFinalizados.any((estado) => estadoNombre.contains(estado));
            return !esFinalizada;
          })
          .toList();
      
      // Mapear órdenes con sus detalles completos (para obtener items con precios)
      final ordenesMapeadas = <OrderModel>[];
      for (final ordenData in ordenesActivas) {
        try {
          final ordenId = (ordenData as Map<String, dynamic>)['id'] as int?;
          if (ordenId != null) {
            // Cargar detalles completos de la orden para obtener items con precios
            final ordenDetalle = await _ordenesService.getOrden(ordenId);
            if (ordenDetalle != null) {
              ordenesMapeadas.add(_mapBackendToOrderModel(ordenDetalle));
            } else {
              // Si no se puede cargar detalle, mapear con los datos básicos
              ordenesMapeadas.add(_mapBackendToOrderModel(ordenData));
            }
          } else {
            ordenesMapeadas.add(_mapBackendToOrderModel(ordenData));
          }
        } catch (e) {
          print('⚠️ Capitán: Error al cargar detalles de orden ${ordenData['id']}: $e');
          // Continuar con mapeo básico si falla
          ordenesMapeadas.add(_mapBackendToOrderModel(ordenData as Map<String, dynamic>));
        }
      }
      
      _activeOrders = ordenesMapeadas;
      
      // Ordenar por fecha de creación (más recientes primero)
      _activeOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      
      notifyListeners();
      print('✅ Capitán: ${_activeOrders.length} órdenes activas cargadas');
    } catch (e) {
      print('❌ Capitán: Error al cargar órdenes: $e');
      _activeOrders = [];
      notifyListeners();
    }
  }
  
  // Manejar nueva orden creada
  void _handleOrderCreated(Map<String, dynamic> data) {
    try {
      final orden = _mapBackendToOrderModel(data);
      
      // Recargar mesas
      loadTables();
      
      // Agregar orden a la lista si no existe
      final ordenId = data['id'] as int?;
      final ordenIdStr = ordenId != null ? 'ORD-${ordenId.toString().padLeft(6, '0')}' : orden.id;
      final existe = _activeOrders.any((o) => 
        o.id == ordenIdStr || o.id == orden.id
      );
      if (!existe) {
        final nuevaOrden = orden.copyWith(id: ordenIdStr);
        _activeOrders.insert(0, nuevaOrden);
        
        // Cargar detalles completos para obtener items con precios
        _loadOrderDetailsForAdditionalData(ordenId);
        
        notifyListeners();
        print('✅ Capitán: Nueva orden agregada - $ordenIdStr');
      }
      
      // Actualizar estadísticas
      _updateStats();
    } catch (e) {
      print('❌ Capitán: Error al manejar orden creada: $e');
    }
  }
  
  // Manejar orden actualizada
  void _handleOrderUpdated(Map<String, dynamic> data) {
    try {
      final orden = _mapBackendToOrderModel(data);
      final estadoNombre = (data['estadoNombre'] as String?)?.toLowerCase() ?? '';
      
      // Recargar mesas
      loadTables();
      
      // Verificar si la orden debe seguir en la lista
      // IMPORTANTE: Cuando el mesero cierra la cuenta y la envía al cajero, 
      // la orden se marca como "cerrada" en el backend, y debe desaparecer del capitán
      final estadosFinalizados = [
        'pagada', 'cancelada', 'cerrada', 'cobrada',
        'entregada', 'completada', 'finalizada', 'enviada',
      ];
      final esFinalizada = estadosFinalizados.any((estado) => estadoNombre.contains(estado));
      
      final ordenId = data['id'] as int?;
      final ordenIdStr = ordenId != null ? 'ORD-${ordenId.toString().padLeft(6, '0')}' : orden.id;
      
      if (esFinalizada) {
        // Remover orden si está finalizada (cuando el mesero cierra la cuenta y envía al cajero)
        _activeOrders.removeWhere((o) => 
          o.id == ordenIdStr || o.id == orden.id
        );
        // Limpiar datos adicionales
        _orderAdditionalData.remove(ordenIdStr);
        print('🗑️ Capitán: Orden $ordenIdStr removida (estado: $estadoNombre - enviada al cajero)');
      } else {
        // Actualizar orden existente o agregarla
        final index = _activeOrders.indexWhere((o) => 
          o.id == ordenIdStr || o.id == orden.id
        );
        if (index >= 0) {
          _activeOrders[index] = orden.copyWith(id: ordenIdStr);
        } else {
          _activeOrders.insert(0, orden.copyWith(id: ordenIdStr));
        }
        
        // Cargar detalles completos para obtener items con precios
        _loadOrderDetailsForAdditionalData(ordenId);
      }
      
      notifyListeners();
      _updateStats();
      print('✅ Capitán: Orden actualizada - $ordenIdStr');
    } catch (e) {
      print('❌ Capitán: Error al manejar orden actualizada: $e');
    }
  }
  
  // Helper para mapear datos del backend a OrderModel (similar a cocinero)
  OrderModel _mapBackendToOrderModel(Map<String, dynamic> data) {
    final ordenId = data['id'] as int? ?? 0;
    final ordenIdStr = 'ORD-${ordenId.toString().padLeft(6, '0')}';
    final estadoNombre = (data['estadoNombre'] as String?)?.toLowerCase() ?? 'pendiente';
    
    // Mapear estado - usar constantes de OrderStatus para consistencia
    String status = OrderStatus.pendiente;
    if (estadoNombre.contains('preparacion') || estadoNombre.contains('preparación')) {
      status = OrderStatus.enPreparacion;
    } else if (estadoNombre.contains('listo') && !estadoNombre.contains('recoger')) {
      status = OrderStatus.listo;
    } else if (estadoNombre.contains('listo') && estadoNombre.contains('recoger')) {
      status = OrderStatus.listoParaRecoger;
    } else if (estadoNombre.contains('cancelada') || estadoNombre.contains('cancelado')) {
      status = OrderStatus.cancelada;
    }
    
    // Obtener items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final orderItems = itemsData.map((itemJson) {
      String station = 'Tacos';
      final productName = ((itemJson['productoNombre'] as String?) ?? 
                          (itemJson['nombre'] as String?) ?? '').toLowerCase();
      if (productName.contains('consom') || productName.contains('mix')) {
        station = 'Consomes';
      } else if (productName.contains('bebida') || productName.contains('refresco')) {
        station = 'Bebidas';
      }
      
      return OrderItem(
        id: itemJson['id'] as int? ?? 0,
        name: itemJson['productoNombre'] as String? ?? 
              itemJson['nombre'] as String? ?? 'Producto',
        quantity: itemJson['cantidad'] as int? ?? itemJson['quantity'] as int? ?? 1,
        station: station,
        notes: itemJson['notas'] as String? ?? itemJson['notes'] as String? ?? '',
      );
    }).toList();
    
    // Guardar información adicional de items con precios y formato de texto
    final itemsText = <String>[];
    double orderTotal = 0.0;
    for (final itemJson in itemsData) {
      final cantidad = (itemJson['cantidad'] as num?)?.toInt() ?? 
                      (itemJson['quantity'] as num?)?.toInt() ?? 1;
      final nombre = itemJson['productoNombre'] as String? ?? 
                    itemJson['nombre'] as String? ?? 'Producto';
      final precioUnitario = (itemJson['precioUnitario'] as num?)?.toDouble() ?? 0.0;
      
      // CRÍTICO: Calcular totalLinea siempre como cantidad × precioUnitario
      // Si totalLinea viene del backend como 0 o incorrecto, recalcular
      final totalLineaBackend = (itemJson['totalLinea'] as num?)?.toDouble() ?? 0.0;
      final totalLineaCalculado = precioUnitario * cantidad;
      
      // Usar el cálculo si el backend viene con 0 o si el calculado es diferente (tolerancia de 0.01)
      final totalLinea = (totalLineaBackend <= 0.01 || (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
          ? totalLineaCalculado
          : totalLineaBackend;
      
      itemsText.add('${cantidad}x $nombre');
      orderTotal += totalLinea;
    }
    
    // Guardar datos adicionales para esta orden
    _orderAdditionalData[ordenIdStr] = {
      'itemsText': itemsText,
      'total': orderTotal,
    };
    
    print('💰 Capitán: Orden $ordenIdStr - Total calculado: \$${orderTotal.toStringAsFixed(2)} (${itemsData.length} items)');
    
    // Obtener mesa
    final mesaId = data['mesaId'] as int?;
    final mesaCodigo = data['mesaCodigo'] as String?;
    int? tableNumber;
    if (mesaCodigo != null) {
      tableNumber = int.tryParse(mesaCodigo);
    } else if (mesaId != null) {
      // Si no hay código, usar el ID como número de mesa temporalmente
      tableNumber = mesaId;
    }
    
    // CRÍTICO: Determinar si es para llevar basándose en mesaId
    // Si mesaId es null, entonces es un pedido para llevar
    // Esto es más confiable que depender de campos booleanos que pueden no estar presentes
    final isTakeaway = mesaId == null;
    
    // Parsear fecha
    final fechaCreacion = data['creadoEn'] as String? ?? 
                         data['createdAt'] as String? ?? 
                         DateTime.now().toIso8601String();
    final orderTime = date_utils.AppDateUtils.parseToLocal(fechaCreacion);
    
    // Prioridad
    final prioridadBackend = data['prioridad'] as String? ?? 'normal';
    String priority = 'normal';
    if (prioridadBackend.toLowerCase() == 'alta' || 
        prioridadBackend.toLowerCase() == 'urgente' ||
        prioridadBackend.toLowerCase() == 'high') {
      priority = 'alta';
    }
    
    return OrderModel(
      id: ordenIdStr,
      tableNumber: tableNumber,
      items: orderItems,
      status: status,
      orderTime: orderTime,
      estimatedTime: data['tiempoEstimado'] as int? ?? data['estimatedTime'] as int? ?? 15,
      waiter: data['meseroNombre'] as String? ?? 
              data['waiter'] as String? ?? 
              'Mesero',
      priority: priority,
      isTakeaway: isTakeaway,
      customerName: data['clienteNombre'] as String? ?? data['customerName'] as String?,
      customerPhone: data['clienteTelefono'] as String? ?? data['customerPhone'] as String?,
      pickupTime: data['pickupTime'] as String?,
    );
  }
  
  // Cargar detalles de una orden para obtener información adicional (items con precios, etc.)
  Future<void> _loadOrderDetailsForAdditionalData(int? ordenId) async {
    if (ordenId == null) return;
    try {
      final ordenDetalle = await _ordenesService.getOrden(ordenId);
      if (ordenDetalle == null) return;
      
      final ordenIdStr = 'ORD-${ordenId.toString().padLeft(6, '0')}';
      final itemsData = ordenDetalle['items'] as List<dynamic>? ?? [];
      
      final itemsText = <String>[];
      double orderTotal = 0.0;
      for (final itemJson in itemsData) {
        final cantidad = (itemJson['cantidad'] as num?)?.toInt() ?? 
                        (itemJson['quantity'] as num?)?.toInt() ?? 1;
        final nombre = itemJson['productoNombre'] as String? ?? 
                      itemJson['nombre'] as String? ?? 'Producto';
        final precioUnitario = (itemJson['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        final totalLinea = (itemJson['totalLinea'] as num?)?.toDouble() ?? 
                          (precioUnitario * cantidad);
        
        itemsText.add('${cantidad}x $nombre');
        orderTotal += totalLinea;
      }
      
      // Guardar datos adicionales para esta orden
      _orderAdditionalData[ordenIdStr] = {
        'itemsText': itemsText,
        'total': orderTotal,
      };
      
      print('💰 Capitán: Detalles adicionales cargados para $ordenIdStr - Total: \$${orderTotal.toStringAsFixed(2)}');
      
      // Notificar cambios para actualizar la UI
      notifyListeners();
    } catch (e) {
      print('⚠️ Capitán: Error al cargar detalles adicionales de orden $ordenId: $e');
    }
  }
  
  // Manejar orden cancelada
  void _handleOrderCancelled(Map<String, dynamic> data) {
    try {
      final ordenId = data['ordenId'] as int? ?? data['id'] as int?;
      if (ordenId == null) return;
      
      final ordenIdStr = 'ORD-${ordenId.toString().padLeft(6, '0')}';
      
      // Remover orden de la lista
      _activeOrders.removeWhere((o) => 
        o.id == ordenIdStr || 
        o.id == ordenId.toString() ||
        (o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '') == ordenId.toString())
      );
      
      // Recargar mesas
      loadTables();
      
      notifyListeners();
      _updateStats();
      print('✅ Capitán: Orden cancelada removida - $ordenIdStr');
    } catch (e) {
      print('❌ Capitán: Error al manejar orden cancelada: $e');
    }
  }
  
  // Actualizar estadísticas
  void _updateStats() {
    try {
      // Calcular estadísticas básicas
      final activeTablesCount = _tables.where((t) => 
        t.status == CaptainTableStatus.ocupada || 
        t.status == CaptainTableStatus.cuenta
      ).length;
      
      final pendingOrdersCount = _activeOrders.length;
      final urgentOrdersCount = getUrgentOrders().length;
      
      // Calcular ventas del día (simplificado, se puede mejorar)
      final totalBills = _billRepository.bills
          .where((b) => b.status == BillStatus.paid)
          .fold(0.0, (sum, bill) => sum + bill.total);
      
      final avgTicket = pendingOrdersCount > 0 
          ? getPendingBillsAmount() / pendingOrdersCount 
          : 0.0;
      
      _stats = CaptainStats(
        todaySales: totalBills,
        variation: '+0%', // Se puede calcular comparando con día anterior
        avgTicket: avgTicket,
        totalOrders: pendingOrdersCount,
        activeTables: activeTablesCount,
        pendingOrders: pendingOrdersCount,
        urgentOrders: urgentOrdersCount,
      );
      
      notifyListeners();
    } catch (e) {
      print('❌ Capitán: Error al actualizar estadísticas: $e');
    }
  }
}

