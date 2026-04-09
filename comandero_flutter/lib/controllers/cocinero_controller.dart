import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../models/order_model.dart';
import '../models/kitchen_alert.dart';
import '../services/ordenes_service.dart';
import '../services/socket_service.dart';
import '../services/kitchen_alerts_service.dart';
import '../services/categorias_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/performance_helper.dart';

// Modelo viejo de alerta (mantener por compatibilidad con UI existente)
// Exportado para uso en otras partes de la aplicación
class OldKitchenAlert {
  final String id;
  final String tableNumber;
  final String orderId;
  final String type;
  final String reason;
  final String? details;
  final String priority;
  final DateTime timestamp;
  final String? sentBy; // Nombre del usuario que envió (mesero o capitán)
  final String? sentByRole; // Rol del usuario (mesero o capitan)

  OldKitchenAlert({
    required this.id,
    required this.tableNumber,
    required this.orderId,
    required this.type,
    required this.reason,
    this.details,
    required this.priority,
    required this.timestamp,
    this.sentBy,
    this.sentByRole,
  });
}

class CocineroController extends ChangeNotifier with DebounceChangeNotifier {
  final OrdenesService _ordenesService = OrdenesService();
  final CategoriasService _categoriasService = CategoriasService();
  final ApiService _api = ApiService();
  // Estado de los pedidos
  List<OrderModel> _orders = [];
  final List<OldKitchenAlert> _alerts = [];

  // IDs de órdenes marcadas como "listo" por este cocinero (para no recargarlas)
  final Set<String> _completedOrderIds = {};

  // Storage para persistir órdenes completadas
  final AuthStorage _storage = AuthStorage();

  // Filtros
  String _selectedStation = 'todas';
  String _selectedStatus = 'todas';
  String _selectedShow = 'todos'; // 'todos', 'para_llevar', 'mesas'
  String _selectedAlert =
      'todas'; // 'todas', 'demoras', 'canceladas', 'cambios'
  bool _showTakeawayOnly = false;
  Map<String, String> _stationOptions = {'todas': 'Todas las Estaciones'};

  // Vista actual
  String _currentView = 'main';

  // Getters
  List<OrderModel> get orders => _orders;
  String get selectedStation => _selectedStation;
  String get selectedStatus => _selectedStatus;
  String get selectedShow => _selectedShow;
  String get selectedAlert => _selectedAlert;
  bool get showTakeawayOnly => _showTakeawayOnly;
  String get currentView => _currentView;
  List<OldKitchenAlert> get alerts => List.unmodifiable(_alerts);
  Map<String, String> get stationOptions => Map.unmodifiable(_stationOptions);

  String _normalizeRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'mesero';
    return role
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  String _normalizeAlertPriority(String rawPriority) {
    final p = rawPriority
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    if (p == 'urgente' || p == 'urgent' || p == 'alta' || p == 'high') {
      return 'urgente';
    }
    return 'medium';
  }

  String _stationKeyFromCategory(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return KitchenStation.tacos;
    final normalized = rawName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? KitchenStation.tacos : normalized;
  }

  Future<void> loadStationOptions() async {
    try {
      final categorias = await _categoriasService.getCategorias();
      final options = <String, String>{'todas': 'Todas las Estaciones'};
      for (final raw in categorias) {
        final c = raw as Map<String, dynamic>;
        final nombre = (c['nombre'] as String?)?.trim();
        final activo = c['activo'] as bool? ?? true;
        if (nombre == null || nombre.isEmpty || !activo) continue;
        options[_stationKeyFromCategory(nombre)] = nombre;
      }
      _stationOptions = options;
      if (_selectedStation != 'todas' &&
          !_stationOptions.containsKey(_selectedStation)) {
        _selectedStation = 'todas';
      }
    } catch (e) {
      print('⚠️ Cocinero: No se pudieron cargar categorías dinámicas: $e');
    }
  }

  // Obtener pedidos filtrados
  List<OrderModel> get filteredOrders {
    final filtered = _orders.where((order) {
      final stationMatch =
          _selectedStation == 'todas' ||
          order.items.any((item) => item.station == _selectedStation);

      // Filtrar por estado seleccionado
      bool statusMatch;
      if (_selectedStatus == 'todas') {
        // Mostrar todas las órdenes (pero las listas ya no deberían estar en _orders)
        statusMatch = true;
      } else {
        // Filtrar por el estado específico seleccionado
        statusMatch = order.status == _selectedStatus;
      }

      // Filtro de Mostrar
      final showMatch =
          _selectedShow == 'todos' ||
          (_selectedShow == 'para_llevar' && order.isTakeaway) ||
          (_selectedShow == 'mesas' && !order.isTakeaway);

      return stationMatch && statusMatch && showMatch;
    }).toList();

    int statusRank(String status) {
      switch (status) {
        case OrderStatus.pendiente:
          return 0;
        case OrderStatus.enPreparacion:
          return 1;
        case OrderStatus.listo:
          return 2;
        case OrderStatus.listoParaRecoger:
          return 3;
        case OrderStatus.cancelada:
          return 4;
        default:
          return 99;
      }
    }

    filtered.sort((a, b) {
      // Primero urgentes
      final priorityCmp = (b.priority == OrderPriority.alta ? 1 : 0)
          .compareTo(a.priority == OrderPriority.alta ? 1 : 0);
      if (priorityCmp != 0) return priorityCmp;

      // Luego estado operativo
      final statusCmp = statusRank(a.status).compareTo(statusRank(b.status));
      if (statusCmp != 0) return statusCmp;

      // Y dentro del mismo estado, las más antiguas primero (FIFO)
      return a.orderTime.compareTo(b.orderTime);
    });

    return filtered;
  }

  List<OldKitchenAlert> get filteredAlerts {
    return _alerts.where((alert) {
      if (_selectedAlert == 'todas') return true;
      final tipo = alert.type.toLowerCase();
      switch (_selectedAlert) {
        case 'demoras':
          return tipo.contains('demora') || tipo.contains('delay');
        case 'canceladas':
          return tipo.contains('cancel');
        case 'cambios':
          return tipo.contains('cambio') || tipo.contains('update');
        default:
          return true;
      }
    }).toList();
  }

  CocineroController() {
    loadStationOptions();
    _initializeOrders();
    // NO configurar listeners aquí - se configurarán después de que el socket esté conectado
    // Reducido delay para inicio más rápido
    Future.delayed(const Duration(milliseconds: 200), () async {
      await _connectSocket();
      // Configurar listeners DESPUÉS de que el socket esté conectado
      _setupSocketListeners();
    });
    // Cargar órdenes completadas desde storage PRIMERO y luego cargar órdenes
    // Esto es crítico para que el filtro funcione correctamente
    _loadCompletedOrders()
        .then((_) {
          print(
            '✅ Cocinero: Órdenes completadas cargadas, ahora cargando órdenes del backend',
          );
          // Cargar órdenes desde el backend después de cargar las completadas
          loadOrders();
        })
        .catchError((e) {
          print('❌ Error al cargar órdenes completadas: $e');
          // Aún así, intentar cargar órdenes pero con el set vacío
          _completedOrdersLoaded = true;
          loadOrders();
        });
  }

  // Conectar Socket.IO para recibir alertas
  Future<void> _connectSocket() async {
    final socketService = SocketService();

    // Verificar que el rol sea cocinero
    final storedRole = await _storage.read('userRole');
    final storedUserId = await _storage.read('userId');
    String? storedRoleLower = storedRole
        ?.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    if (storedRoleLower == 'admin') {
      storedRoleLower = 'administrador';
    }

    if (storedRoleLower != 'cocinero' && storedRoleLower != 'administrador') {
      print(
        '⚠️ Cocinero: Rol no es cocinero ($storedRole), no se conectará socket',
      );
      return;
    }

    print(
      '🔌 Cocinero: Verificando conexión Socket.IO - UserId: $storedUserId, Role: $storedRole',
    );

    // Esperar un momento adicional para asegurar que el auth_controller haya terminado (reducido)
    await Future.delayed(const Duration(milliseconds: 200));

    // Si ya está conectado, esperar a que el evento 'connected' haya llegado antes de verificar
    if (socketService.isConnected) {
      // Esperar hasta 3 segundos para que llegue el evento 'connected'
      int attempts = 0;
      while (attempts < 6 && socketService.getSocketUserId() == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      final socketUserId = socketService.getSocketUserId();
      final socketRole = socketService.getSocketUserRole();
      String? socketRoleNormalized = socketRole
          ?.toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ü', 'u')
          .replaceAll('ñ', 'n');
      if (socketRoleNormalized == 'admin') {
        socketRoleNormalized = 'administrador';
      }

      if (socketUserId != null &&
          socketRole != null &&
          storedUserId == socketUserId &&
          storedRoleLower == socketRoleNormalized) {
        print(
          '✅ Cocinero: Socket.IO ya está conectado con el usuario/rol correcto - UserId: $socketUserId, Role: $socketRole',
        );
        // Esperar un momento más para asegurar que el backend haya unido el socket a las rooms
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      } else if (socketUserId == null || socketRole == null) {
        print(
          '⚠️ Cocinero: Socket conectado pero aún no se recibió el evento "connected". Esperando...',
        );
        // Esperar un poco más y verificar de nuevo
        await Future.delayed(const Duration(milliseconds: 1000));
        final socketUserId2 = socketService.getSocketUserId();
        final socketRole2 = socketService.getSocketUserRole();
        if (socketUserId2 == null || socketRole2 == null) {
          print(
            '⚠️ Cocinero: El evento "connected" no llegó después de esperar. Continuando de todas formas...',
          );
        } else {
          // Esperar un momento más para asegurar que el backend haya unido el socket a las rooms
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        print(
          '⚠️ Cocinero: Socket.IO conectado con usuario/rol incorrecto (Socket: $socketUserId/$socketRole, Storage: $storedUserId/$storedRole). Forzando reconexión.',
        );
        await socketService.forceReconnect();
        // Esperar a que se reconecte
        int attempts2 = 0;
        while (attempts2 < 10 && !socketService.isConnected) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts2++;
        }
        if (socketService.isConnected) {
          // Esperar un momento más para asegurar que el backend haya unido el socket a las rooms
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return;
      }
    } else {
      print('🔌 Cocinero: Socket no conectado, intentando conectar...');

      // Conectar con el token actual del cocinero (el auth_controller ya lo configuró)
      await socketService.connect();

      // Esperar a que se conecte y verificar
      int attempts = 0;
      while (attempts < 10 && !socketService.isConnected) {
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }

      if (socketService.isConnected) {
        final socketUserId = socketService.getSocketUserId();
        final socketRole = socketService.getSocketUserRole();
        print(
          '✅ Cocinero: Socket.IO conectado correctamente - UserId: $socketUserId, Role: $socketRole',
        );
        // Esperar un momento más para asegurar que el backend haya unido el socket a las rooms (reducido)
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        print('⚠️ Cocinero: Socket.IO no se conectó después de 5 segundos');
      }
    }
  }

  // Flag para saber si las órdenes completadas ya fueron cargadas
  bool _completedOrdersLoaded = false;

  // Esperar a que las órdenes completadas se carguen antes de cargar órdenes
  Future<void> _ensureCompletedOrdersLoaded() async {
    if (!_completedOrdersLoaded) {
      await _loadCompletedOrders();
      _completedOrdersLoaded = true;
    }
  }

  // Cargar IDs de órdenes completadas desde storage
  Future<void> _loadCompletedOrders() async {
    try {
      final completedOrdersJson =
          await _storage.read('cocinero_completed_orders') ?? '[]';
      // Parsear JSON simple: ["1","2","3"]
      if (completedOrdersJson != '[]' && completedOrdersJson.isNotEmpty) {
        final cleaned = completedOrdersJson
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .replaceAll("'", '');
        if (cleaned.isNotEmpty) {
          final ids = cleaned
              .split(',')
              .where((id) => id.trim().isNotEmpty)
              .map(
                (id) => id.trim().replaceAll('ORD-', ''),
              ) // Normalizar al cargar
              .where((id) => id.isNotEmpty)
              .toList();
          _completedOrderIds.clear(); // Limpiar antes de agregar
          _completedOrderIds.addAll(ids);
          _completedOrdersLoaded = true; // Marcar como cargado
          print(
            '📋 Cocinero: ${_completedOrderIds.length} órdenes completadas cargadas: ${ids.take(10).toList()}',
          );
        } else {
          _completedOrdersLoaded = true;
        }
      } else {
        _completedOrdersLoaded = true;
      }
    } catch (e) {
      print('Error al cargar órdenes completadas: $e');
      _completedOrdersLoaded = true; // Marcar como cargado incluso si hay error
    }
  }

  // Guardar IDs de órdenes completadas en storage
  Future<void> _saveCompletedOrders() async {
    try {
      // Convertir set a JSON simple, asegurando que todos los IDs sean numéricos
      final ids = _completedOrderIds
          .map((id) => id.replaceAll('ORD-', '')) // Normalizar IDs
          .where((id) => id.trim().isNotEmpty)
          .toSet() // Eliminar duplicados
          .toList();

      if (ids.isEmpty) {
        await _storage.write('cocinero_completed_orders', '[]');
        print('💾 Cocinero: No hay órdenes completadas para guardar');
        return;
      }

      final json = '["${ids.join('","')}"]';
      await _storage.write('cocinero_completed_orders', json);
      print(
        '💾 Cocinero: ${ids.length} órdenes completadas guardadas: ${ids.take(10).toList()}',
      );
    } catch (e) {
      print('❌ Error al guardar órdenes completadas: $e');
      rethrow; // Re-lanzar para que se pueda manejar el error
    }
  }

  // Limpiar todas las órdenes completadas (para resetear si es necesario)
  Future<void> clearCompletedOrders() async {
    _completedOrderIds.clear();
    await _saveCompletedOrders();
    notifyListeners();
  }

  // Cargar alertas pendientes desde el backend
  Future<void> _loadPendingAlerts() async {
    try {
      print('📥 Cocinero: Cargando alertas pendientes desde la BD...');
      final response = await _api.get('/alertas');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> alertas = [];

        if (responseData is Map<String, dynamic> &&
            responseData['data'] != null) {
          alertas = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          alertas = responseData;
        }

        print('📥 Cocinero: ${alertas.length} alertas recibidas del backend');

        // Convertir alertas de BD al formato de KitchenAlert
        for (final alertaData in alertas) {
          try {
            final ordenId = alertaData['ordenId'] as int?;
            if (ordenId == null) continue;

            final mensaje = alertaData['mensaje'] as String? ?? '';
            final alertaId = alertaData['id'] as int?;
            final creadoEn = alertaData['creadoEn'] as String?;

            // Determinar tipo de alerta desde el mensaje (solo deben llegar alertas enviadas por mesero/capitán)
            // No mostrar como "Demora" los mensajes de cambio de estado automático (modificada: Estado cambiado a:)
            String alertTypeDisplay = 'Demora';
            final m = mensaje.toLowerCase();
            if (m.contains('cancel')) {
              alertTypeDisplay = 'Cancelación';
            } else if (m.contains('cambio') || (m.contains('modificada') && m.contains('estado cambiado'))) {
              alertTypeDisplay = 'Cambio en orden';
            }
            // Si no es cancelación ni cambio, se mantiene Demora (alertas explícitas de demora)

            // Extraer prioridad de metadata si existe, o usar 'Normal' por defecto
            final metadataRaw = alertaData['metadata'];
            Map<String, dynamic> metadata = {};

            // Parsear metadata si es string (JSON), Map, o null
            if (metadataRaw != null) {
              if (metadataRaw is String) {
                try {
                  metadata =
                      jsonDecode(metadataRaw) as Map<String, dynamic>? ?? {};
                } catch (e) {
                  print('⚠️ Cocinero: Error al parsear metadata JSON: $e');
                  metadata = {};
                }
              } else if (metadataRaw is Map) {
                metadata = Map<String, dynamic>.from(metadataRaw);
              }
            }

            String priority = 'Normal';
            if (metadata.isNotEmpty && metadata.containsKey('priority')) {
              priority = metadata['priority']?.toString() ?? 'Normal';
            }

            print(
              '🔍 Cocinero: Prioridad extraída - Raw metadata: $metadataRaw, Parsed metadata: $metadata, Priority: $priority',
            );

            // Mapear prioridad a formato viejo: 'Normal' -> 'medium', 'Urgente' -> 'urgente' o 'high'
            String priorityOldFormat = 'medium';
            final priorityLower = priority.toLowerCase();
            if (priorityLower == 'urgente' || priorityLower == 'urgent') {
              priorityOldFormat = 'urgente';
            } else if (priorityLower == 'high') {
              priorityOldFormat = 'high';
            }

            print(
              '🔍 Cocinero: Prioridad mapeada - Original: $priority, Mapeada: $priorityOldFormat',
            );

            // Obtener información del emisor desde metadata
            final sentBy = metadata['createdByUsername']?.toString();
            final sentByRole = metadata['createdByRole']?.toString();

            // Parsear fecha correctamente usando parseToLocal para convertir UTC a CDMX
            final timestampParsed = creadoEn != null
                ? date_utils.AppDateUtils.parseToLocal(creadoEn)
                : date_utils.AppDateUtils.nowCdmx();

            // Convertir al formato viejo para la UI
            // NUNCA usar mesaId para "Mesa X": es el ID de BD (ej. 4) y no el número visible (ej. 3).
            // Usar solo mesaCodigo (desde API o metadata). Si no hay, "Para llevar".
            final mesaCodigo = alertaData['mesaCodigo']?.toString() ?? metadata['mesaCodigo']?.toString();
            final tableNumber = (mesaCodigo != null && mesaCodigo.isNotEmpty) ? mesaCodigo : 'Para llevar';
            final orderIdStr = 'ORD-${ordenId.toString().padLeft(6, '0')}';

            final oldFormatAlert = OldKitchenAlert(
              id:
                  alertaId?.toString() ??
                  'ALT-${DateTime.now().millisecondsSinceEpoch}',
              tableNumber: tableNumber,
              orderId: orderIdStr,
              type: alertTypeDisplay,
              reason: mensaje,
              details: null,
              priority: priorityOldFormat,
              timestamp: timestampParsed,
              sentBy: sentBy,
              sentByRole: sentByRole,
            );

            // Evitar duplicados
            final isDuplicate = _alerts.any(
              (a) =>
                  a.id == oldFormatAlert.id ||
                  (a.orderId == oldFormatAlert.orderId &&
                      a.type == oldFormatAlert.type &&
                      (oldFormatAlert.timestamp
                              .difference(a.timestamp)
                              .inMinutes <
                          2)),
            );

            if (!isDuplicate) {
              _alerts.insert(0, oldFormatAlert);
              print(
                '✅ Cocinero: Alerta pendiente cargada - Tipo: $alertTypeDisplay, Orden: $orderIdStr',
              );
            }
          } catch (e) {
            print('⚠️ Cocinero: Error al procesar alerta pendiente: $e');
          }
        }

        if (_alerts.isNotEmpty) {
          notifyListeners();
          print(
            '✅ Cocinero: ${_alerts.length} alertas pendientes cargadas desde BD',
          );
        } else {
          print('📭 Cocinero: No hay alertas pendientes');
        }
      }
    } catch (e) {
      print('❌ Cocinero: Error al cargar alertas pendientes: $e');
    }
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    final socketService = SocketService();
    
    if (!socketService.isConnected) {
      print('⚠️ Cocinero: Socket.IO no está conectado, registrando listeners pendientes...');
      socketService.connect().catchError((e) {
        print('❌ Cocinero: Error al conectar Socket.IO: $e');
      });
    } else {
      print('✅ Cocinero: Socket.IO está conectado, configurando listeners...');
    }
    print('📡 Cocinero: URL de Socket.IO: ${ApiConfig.socketUrl}');

    // Cargar alertas pendientes desde BD cuando se configuran los listeners
    _loadPendingAlerts();

    // ============================================
    // NUEVO SISTEMA DE ALERTAS DE COCINA
    // ============================================
    // Usar el nuevo servicio de alertas de cocina
    final kitchenAlertsService = KitchenAlertsService(socketService);

    // Escuchar nuevas alertas del nuevo sistema
    kitchenAlertsService.listenNewAlerts((alert) {
      try {
        print(
          '🔔 Cocinero: Nueva alerta recibida (kitchen:alert:new) - OrderId: ${alert.orderId}, Type: ${alert.type.name}, Station: ${alert.station.name}',
        );

        // Convertir la nueva alerta al formato del KitchenAlert viejo para mantener compatibilidad con la UI
        // NUNCA usar tableId para "Mesa X": puede ser el ID de BD, no el número visible. Solo mesaCodigo.
        final tableNumber = (alert.mesaCodigo != null && alert.mesaCodigo!.isNotEmpty)
            ? alert.mesaCodigo!
            : 'Para llevar';
        final orderId = 'ORD-${alert.orderId.toString().padLeft(6, '0')}';

        // Mapear tipo del nuevo sistema al formato viejo
        // El tipo EXTRA_ITEM se usa para "Demora" en el modal del mesero
        String alertType = alert.type.displayName;
        if (alert.type == AlertType.EXTRA_ITEM &&
            alert.message.toLowerCase().contains('demora')) {
          alertType = 'Demora';
        }

        // Mapear prioridad desde el alert
        // El alert.priority puede ser 'Normal' o 'Urgente'
        // Lo mapeamos a 'medium' o 'high'/'urgente' para el formato viejo
        String priority = 'medium';
        final alertPriorityLower = alert.priority.toLowerCase();
        print(
          '🔍 Cocinero: Prioridad desde Socket.IO - Original: ${alert.priority}, Lowercase: $alertPriorityLower',
        );

        if (alertPriorityLower == 'urgente' || alertPriorityLower == 'urgent') {
          priority = 'urgente';
        } else if (alertPriorityLower == 'high') {
          priority = 'high';
        }

        print(
          '🔍 Cocinero: Prioridad mapeada desde Socket.IO - Resultado: $priority',
        );

        final oldFormatAlert = OldKitchenAlert(
          id:
              alert.id?.toString() ??
              'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: tableNumber,
          orderId: orderId,
          type: alertType,
          reason: alert.message,
          details: null,
          priority: _normalizeAlertPriority(priority),
          timestamp: alert.createdAt ?? date_utils.AppDateUtils.nowCdmx(),
          sentBy: alert.createdByUsername,
          sentByRole: _normalizeRole(alert.createdByRole),
        );

        // Evitar duplicados
        final isDuplicate = _alerts.any(
          (a) =>
              a.id == oldFormatAlert.id ||
              (a.orderId == oldFormatAlert.orderId &&
                  a.type == oldFormatAlert.type &&
                  (oldFormatAlert.timestamp.difference(a.timestamp).inMinutes <
                      2)),
        );

        if (!isDuplicate) {
          _alerts.insert(0, oldFormatAlert);
          notifyListeners();
          print(
            '✅ Cocinero: Alerta agregada (nuevo sistema) - Tipo: $alertType, Mesa: $tableNumber, Orden: $orderId (Total: ${_alerts.length})',
          );
        } else {
          print(
            '⚠️ Cocinero: Alerta duplicada ignorada (nuevo sistema) - Tipo: $alertType, Orden: $orderId',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Error al procesar alerta del nuevo sistema: $e');
        print('   Stack: $stackTrace');
      }
    });

    // Escuchar errores del nuevo sistema
    kitchenAlertsService.listenErrors((errorMessage, details) {
      print('❌ Cocinero: Error en alerta (nuevo sistema): $errorMessage');
      if (details != null) {
        print('   Detalles: $details');
      }
    });

    // ============================================
    // SISTEMA VIEJO DE ALERTAS (DEPRECADO)
    // ============================================
    // TODO: Este listener se mantiene por compatibilidad, pero debería eliminarse
    // después de verificar que el nuevo sistema funciona correctamente.
    // Escuchar alertas de cocina en tiempo real (igual que cuenta.enviada)
    // El mesero emite 'cocina.alerta' directamente y el backend lo re-emite a role:cocinero
    socketService.onCocinaAlerta((data) {
      try {
        print('🔔 Cocinero: Alerta recibida (cocina.alerta) - Datos: $data');

        // Extraer datos de la alerta
        final dataMap = data is Map<String, dynamic>
            ? data
            : <String, dynamic>{};
        final metadata = dataMap['metadata'] as Map<String, dynamic>? ?? {};

        // NUNCA usar mesaId para "Mesa X": es el ID de BD. Solo mesaCodigo o metadata tableNumber.
        final _mesa = dataMap['mesaCodigo']?.toString() ?? metadata['tableNumber']?.toString();
        final tableNumber = (_mesa != null && _mesa.isNotEmpty) ? _mesa : 'Para llevar';
        final orderId =
            dataMap['ordenId']?.toString() ??
            metadata['orderId']?.toString() ??
            'N/A';

        // Determinar el tipo de alerta
        String alertType =
            dataMap['tipo']?.toString() ??
            metadata['alertType']?.toString() ??
            'General';

        // Remover prefijo 'alerta.' si existe
        if (alertType.startsWith('alerta.')) {
          alertType = alertType.replaceAll('alerta.', '');
        }

        // Capitalizar primera letra
        if (alertType.isNotEmpty) {
          alertType = alertType[0].toUpperCase() + alertType.substring(1);
        }

        // Mapear nombres de tipos
        switch (alertType.toLowerCase()) {
          case 'demora':
            alertType = 'Demora';
            break;
          case 'cancelacion':
          case 'cancelación':
            alertType = 'Cancelación';
            break;
          case 'modificacion':
          case 'modificación':
            alertType = 'Cambio en orden';
            break;
          default:
            alertType = alertType.isEmpty ? 'General' : alertType;
        }

        // Extraer motivo y mensaje
        // El mensaje viene directamente en dataMap['mensaje'] desde el mesero
        final mensaje = dataMap['mensaje']?.toString() ?? 'Sin mensaje';
        final details = metadata['details']?.toString();

        // Mapear prioridad
        String priority = dataMap['prioridad']?.toString() ?? 'media';
        if (priority == 'urgente' || priority == 'alta')
          priority = 'high';
        else if (priority == 'baja')
          priority = 'low';
        else
          priority = 'medium';

        // Usar ID del backend si está disponible, sino generar uno único
        final alertId =
            dataMap['id']?.toString() ??
            'ALT-${DateTime.now().millisecondsSinceEpoch}-${_alerts.length}';

        final alert = OldKitchenAlert(
          id: alertId,
          tableNumber: tableNumber,
          orderId: orderId,
          type: alertType,
          reason: mensaje, // Usar el mensaje completo que viene del mesero
          details: details,
          priority: priority,
          timestamp: date_utils.AppDateUtils.parseToLocal(
            dataMap['timestamp'] ?? date_utils.AppDateUtils.nowCdmx().toIso8601String(),
          ),
        );

        // Evitar duplicados si la alerta ya existe (por ID o por ordenId + tipo)
        final isDuplicate = _alerts.any(
          (a) =>
              a.id == alert.id ||
              (a.orderId == alert.orderId &&
                  a.type == alert.type &&
                  (alert.timestamp.difference(a.timestamp).inMinutes < 2)),
        );

        if (!isDuplicate) {
          _alerts.insert(0, alert);
          notifyListeners();
          print(
            '✅ Cocinero: Alerta agregada - Tipo: $alertType, Mesa: $tableNumber, Orden: $orderId, Mensaje: $mensaje (Total: ${_alerts.length})',
          );
        } else {
          print(
            '⚠️ Cocinero: Alerta duplicada ignorada - Tipo: $alertType, Orden: $orderId',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Error al procesar alerta de cocina: $e');
        print('   Stack: $stackTrace');
      }
    });

    // NOTA: Los listeners específicos (onAlertaDemora, onAlertaCancelacion)
    // ya están cubiertos por el listener genérico onAlerta() arriba.
    // Se mantienen comentados para evitar duplicados, pero se pueden activar
    // si se necesita lógica específica para cada tipo de alerta.

    // Escuchar alertas de modificación
    // COMENTADO: No mostrar alertas visuales en cocinero cuando cambia el estado
    // Las notificaciones al mesero siguen funcionando correctamente
    /*
    socketService.onAlertaModificacion((data) {
      try {
        final alert = OldKitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: data['mesaId']?.toString() ?? 'N/A',
          orderId: data['ordenId']?.toString() ?? 'N/A',
          type: 'Cambio en orden',
          reason: data['mensaje']?.toString() ?? 'Orden modificada',
          details: data['metadata']?['cambio']?.toString(),
          priority: 'Normal',
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? date_utils.AppDateUtils.nowCdmx().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de modificación: $e');
      }
    });
    */

    // Escuchar alertas generales de cocina
    // COMENTADO: No mostrar alertas visuales en cocinero cuando cambia el estado
    // Las notificaciones al mesero siguen funcionando correctamente
    /*
    socketService.onAlertaCocina((data) {
      try {
        final alert = OldKitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber:
              data['mesaId']?.toString() ??
              data['metadata']?['tableNumber']?.toString() ??
              'N/A',
          orderId:
              data['ordenId']?.toString() ??
              data['metadata']?['orderId']?.toString() ??
              'N/A',
          type: data['tipo']?.toString().replaceAll('alerta.', '') ?? 'General',
          reason: data['mensaje']?.toString() ?? 'Alerta de cocina',
          details: data['metadata']?['details']?.toString(),
          priority: data['prioridad']?.toString() ?? 'Normal',
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? date_utils.AppDateUtils.nowCdmx().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta general de cocina: $e');
      }
    });
    */

    // Escuchar nuevas órdenes creadas
    socketService.onOrderCreated((data) {
      try {
        final ordenId = (data['id'] as int?)?.toString() ?? '';

        // VERIFICAR PRIMERO si la orden ya fue completada previamente
        if (_completedOrderIds.contains(ordenId)) {
          print(
            '🚫 Cocinero: Nueva orden $ordenId ignorada porque ya fue completada previamente',
          );
          return;
        }

        final estadoNombre =
            (data['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // Solo agregar si es relevante para cocina
        final esRelevanteParaCocina =
            !estadoNombre.contains('pagada') &&
            !estadoNombre.contains('cancelada') &&
            !estadoNombre.contains('cerrada') &&
            !estadoNombre.contains('listo') &&
            !estadoNombre.contains('ready') &&
            !estadoNombre.contains('completada') &&
            !estadoNombre.contains('finalizada');

        if (esRelevanteParaCocina) {
          final nuevaOrden = _mapBackendToOrderModel(
            data as Map<String, dynamic>,
          );

          // Verificar si la orden ya existe
          final existe = _orders.any((o) => o.id == nuevaOrden.id);
          if (!existe) {
            _orders.add(nuevaOrden);
            notifyListeners();

            // Agregar alerta si es urgente (prioridad alta)
            if (nuevaOrden.priority.toLowerCase() == OrderPriority.alta) {
              _alerts.add(
                OldKitchenAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tableNumber: nuevaOrden.tableNumber?.toString() ?? '0',
                  orderId: nuevaOrden.id.toString(),
                  type: 'Nueva Orden Urgente',
                  reason:
                      'Nueva orden #${nuevaOrden.id} requiere atención inmediata',
                  priority: 'high',
                  timestamp: date_utils.AppDateUtils.nowCdmx(),
                ),
              );
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('Error al procesar nueva orden: $e');
      }
    });

    // Escuchar actualizaciones de órdenes
    socketService.onOrderUpdated((data) {
      try {
        final ordenId = data['id'] as int?;
        if (ordenId == null) return;

        final ordenIdStr = ordenId.toString();
        final formattedOrderId = 'ORD-${ordenIdStr.padLeft(6, '0')}';
        final estadoNombre =
            (data['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // PRIMERO: Verificar SIEMPRE si la orden ya existe en la lista
        // Buscar por múltiples formatos de ID para asegurar que encontramos la orden
        final index = _orders.indexWhere((o) {
          final oId =
              o.id
                  .replaceAll('ORD-', '')
                  .replaceAll(RegExp(r'^0+'), '') // Remover ceros iniciales
                  .isEmpty
              ? '0'
              : o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '');
          final dataId = ordenIdStr.replaceAll(RegExp(r'^0+'), '');
          return oId == dataId ||
              o.id == ordenIdStr ||
              o.id == formattedOrderId ||
              oId == ordenIdStr;
        });

        // Verificar si el estado es "cancelada"
        final esCancelada =
            estadoNombre.contains('cancelada') ||
            estadoNombre.contains('cancelado');

        // Verificar si el estado es "listo" o similar
        final esListo =
            estadoNombre.contains('listo') ||
            estadoNombre.contains('ready') ||
            estadoNombre.contains('completada') ||
            estadoNombre.contains('finalizada');

        // Si es "cancelada" o "listo", marcar como completada y eliminar de la lista
        if (esCancelada || esListo) {
          // Marcar como completada si no está ya marcada
          if (!_completedOrderIds.contains(ordenIdStr)) {
            _completedOrderIds.add(ordenIdStr);
            _saveCompletedOrders().catchError((e) {
              print('Error al guardar orden completada: $e');
            });
          }

          // Eliminar de la lista si existe
          if (index != -1) {
            _orders.removeAt(index);
            notifyListeners();
            print(
              '🚫 Cocinero: Orden $ordenIdStr eliminada (estado: $estadoNombre)',
            );
          }
          return;
        }

        // VERIFICAR si la orden ya fue completada previamente (incluye canceladas)
        if (_completedOrderIds.contains(ordenIdStr)) {
          // Asegurar que no esté en la lista
          if (index != -1) {
            _orders.removeAt(index);
            notifyListeners();
          }
          return;
        }

        // Verificar si la orden es relevante para cocina
        final esRelevanteParaCocina =
            !estadoNombre.contains('pagada') &&
            !estadoNombre.contains('cancelada') &&
            !estadoNombre.contains('cerrada') &&
            !estadoNombre.contains('listo') &&
            !estadoNombre.contains('ready') &&
            !estadoNombre.contains('completada') &&
            !estadoNombre.contains('finalizada');

        if (index != -1) {
          // La orden ya existe - solo actualizarla si es relevante
          if (esRelevanteParaCocina) {
            // Verificar si el tiempo estimado cambió
            final tiempoEstimadoNuevo = data['tiempoEstimadoPreparacion'] as int? ??
                data['estimatedTime'] as int?;
            final tiempoEstimadoAnterior = _orders[index].estimatedTime;
            
            // Actualizar la orden existente sin duplicarla
            _orders[index] = _mapBackendToOrderModel(
              data as Map<String, dynamic>,
            );
            
            // Si el tiempo estimado cambió, loguear para debugging
            if (tiempoEstimadoNuevo != null && tiempoEstimadoNuevo != tiempoEstimadoAnterior) {
              print('⏱️ Cocinero: Tiempo estimado actualizado para orden $ordenIdStr: $tiempoEstimadoAnterior -> $tiempoEstimadoNuevo min');
            }
            
            notifyListeners();
            // NO loguear para evitar spam cuando hay múltiples eventos
          } else {
            // Si ya no es relevante para cocina, removerla
            _orders.removeAt(index);
            notifyListeners();
          }
          // IMPORTANTE: Retornar aquí SIEMPRE para evitar agregar duplicados
          return;
        }

        // La orden NO existe - solo agregarla si es relevante para cocina
        if (esRelevanteParaCocina) {
          // Verificar UNA VEZ MÁS que no esté en la lista (protección contra race conditions)
          final yaExiste = _orders.any((o) {
            final oId =
                o.id
                    .replaceAll('ORD-', '')
                    .replaceAll(RegExp(r'^0+'), '')
                    .isEmpty
                ? '0'
                : o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '');
            final dataId = ordenIdStr.replaceAll(RegExp(r'^0+'), '');
            return oId == dataId ||
                o.id == ordenIdStr ||
                o.id == formattedOrderId ||
                oId == ordenIdStr;
          });

          if (!yaExiste) {
            _orders.add(_mapBackendToOrderModel(data as Map<String, dynamic>));
            notifyListeners();
            print(
              '✅ Cocinero: Orden $ordenIdStr agregada desde pedido.actualizado',
            );
          } else {
            // Si ya existe, solo actualizarla (no duplicar)
            final existingIndex = _orders.indexWhere((o) {
              final oId =
                  o.id
                      .replaceAll('ORD-', '')
                      .replaceAll(RegExp(r'^0+'), '')
                      .isEmpty
                  ? '0'
                  : o.id.replaceAll('ORD-', '').replaceAll(RegExp(r'^0+'), '');
              final dataId = ordenIdStr.replaceAll(RegExp(r'^0+'), '');
              return oId == dataId ||
                  o.id == ordenIdStr ||
                  o.id == formattedOrderId ||
                  oId == ordenIdStr;
            });
            if (existingIndex != -1) {
              _orders[existingIndex] = _mapBackendToOrderModel(
                data as Map<String, dynamic>,
              );
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('Error al procesar actualización de orden: $e');
      }
    });

    // Escuchar cancelaciones de órdenes
    socketService.onOrderCancelled((data) {
      try {
        final ordenId = data['id'] as int?;
        if (ordenId != null) {
          final normalizedId = ordenId.toString();
          final formattedOrderId = 'ORD-${ordenId.toString().padLeft(6, '0')}';

          // Marcar como completada para evitar que vuelva a aparecer
          _completedOrderIds.add(normalizedId);
          print(
            '💾 Cocinero: Marcando orden $normalizedId como completada después de recibir evento de cancelación',
          );

          // Guardar en storage
          _saveCompletedOrders().catchError((e) {
            print('❌ Cocinero: ERROR al guardar orden completada: $e');
          });

          // Eliminar de la lista (buscar por ID numérico o formato ORD-XXX)
          final removedCount = _orders.length;
          _orders.removeWhere((o) {
            final orderIdStr = o.id.replaceAll('ORD-', '');
            return orderIdStr == normalizedId ||
                o.id == formattedOrderId ||
                o.id == normalizedId;
          });
          final newCount = _orders.length;

          if (removedCount != newCount) {
            print(
              '✅ Cocinero: Orden $formattedOrderId eliminada de la vista después de evento de cancelación (${removedCount - newCount} orden(es) eliminada(s))',
            );
          }

          // NO agregar alerta de cancelación aquí porque ya la recibimos del mesero
          // Solo eliminar la orden de la vista
          notifyListeners();
        }
      } catch (e) {
        print('Error al procesar cancelación de orden: $e');
      }
    });

    // Escuchar alertas de cocina (del sistema)
    // COMENTADO: No mostrar alertas visuales en cocinero cuando cambia el estado
    // Las notificaciones al mesero siguen funcionando correctamente
    /*
    socketService.onAlertaCocina((data) {
      try {
        _alerts.add(
          KitchenAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tableNumber: data['mesaNumero']?.toString() ?? '0',
            orderId: data['ordenId']?.toString() ?? '',
            type: data['tipo'] ?? 'Alerta',
            reason: data['mensaje'] ?? 'Nueva alerta',
            priority: data['prioridad'] ?? 'medium',
            timestamp: date_utils.AppDateUtils.nowCdmx(),
          ),
        );
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cocina: $e');
      }
    });
    */

    // NOTA: El listener para alertas de cocina (cocina.alerta) ya está
    // configurado arriba en la línea 194 con onCocinaAlerta()
    // No agregar otro listener duplicado aquí
  }

  // Cargar órdenes desde el backend
  Future<void> loadOrders() async {
    try {
      await loadStationOptions();
      // Asegurar que las órdenes completadas estén cargadas antes de filtrar
      await _ensureCompletedOrdersLoaded();

      print('🔄 Cocinero: Cargando órdenes desde el backend...');
      print(
        '📋 Cocinero: IDs de órdenes completadas guardadas: ${_completedOrderIds.toList()}',
      );
      // Usar el endpoint específico de cocina
      final backendOrders = await _ordenesService.getOrdenesCocina();
      print(
        '📦 Cocinero: ${backendOrders.length} órdenes recibidas del backend',
      );

      // Filtrar órdenes que NO estén en estado "listo" o "completada"
      // Y que NO hayan sido marcadas como completadas previamente por este cocinero
      // Esto es una doble verificación por si el backend no filtró correctamente
      final ordenesFiltradas = backendOrders.where((json) {
        final data = json as Map<String, dynamic>;
        final ordenId = (data['id'] as int?)?.toString() ?? '';
        final estadoNombre = (data['estadoNombre'] as String? ?? '')
            .toLowerCase();

        // Excluir órdenes que ya fueron marcadas como completadas por este cocinero
        // Verificar tanto el ID numérico como posibles variantes (ORD-5, 5, etc.)
        final isCompleted =
            _completedOrderIds.contains(ordenId) ||
            _completedOrderIds.contains('ORD-$ordenId') ||
            _completedOrderIds.contains(ordenId.replaceAll('ORD-', ''));

        if (isCompleted) {
          print(
            '🚫 Cocinero: Orden $ordenId excluida por haber sido completada previamente (IDs guardados: ${_completedOrderIds.take(10).toList()})',
          );
          return false;
        }

        // Excluir órdenes que estén "listas" o "completadas"
        final esLista =
            estadoNombre.contains('listo') ||
            estadoNombre.contains('ready') ||
            estadoNombre.contains('completada') ||
            estadoNombre.contains('finalizada');

        if (esLista) {
          print(
            '⚠️ Cocinero: Orden ${data['id']} excluida por estar en estado: $estadoNombre',
          );
          return false;
        }

        // Excluir órdenes muy antiguas (más de 1 día) - probablemente datos de prueba
        try {
          final fechaCreacion =
              data['creadoEn'] ??
              data['fechaCreacion'] ??
              data['createdAt'] ??
              data['fecha_creacion'];
          if (fechaCreacion != null) {
            final fecha = _parseDateTime(fechaCreacion);
            final ahora = date_utils.AppDateUtils.nowCdmx();
            final diferencia = ahora.difference(fecha);

            // Si la orden es más antigua de 1 día, excluirla (probablemente datos de prueba)
            if (diferencia.inDays > 1) {
              print(
                '⚠️ Cocinero: Orden ${data['id']} excluida por ser muy antigua (${diferencia.inDays} días)',
              );
              return false;
            }
          }
        } catch (e) {
          // Si hay error al parsear la fecha, incluir la orden
          print(
            '⚠️ Cocinero: Error al parsear fecha de orden ${data['id']}: $e',
          );
        }

        return true;
      }).toList();

      _orders = ordenesFiltradas
          .map((json) => _mapBackendToOrderModel(json as Map<String, dynamic>))
          .toList();

      print(
        '✅ Cocinero: ${_orders.length} órdenes cargadas (${backendOrders.length - _orders.length} excluidas por estar listas)',
      );
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error al cargar órdenes: $e');
      print('Stack trace: $stackTrace');
      // Mantener órdenes previas para no vaciar panel por error transitorio.
      notifyListeners();
    }
  }

  // Helper para parsear fecha del backend
  DateTime _parseDateTime(dynamic fecha) {
    return date_utils.AppDateUtils.parseToLocal(fecha);
  }

  // Helper para mapear prioridad del backend
  String _mapPriorityFromBackend(String? prioridadBackend) {
    if (prioridadBackend == null) return OrderPriority.normal;
    final prioridad = prioridadBackend.toLowerCase();
    if (prioridad == 'alta' || prioridad == 'urgente' || prioridad == 'high') {
      return OrderPriority.alta;
    }
    return OrderPriority.normal;
  }

  static String _formatProductNameWithSize(String name, String? size) {
    if (size == null || size.isEmpty || size.trim().isEmpty) return name;
    final cleanSize = size.trim();
    if (name.contains('($cleanSize)')) return name;
    return '$name ($cleanSize)';
  }

  // Helper para mapear datos del backend a OrderModel
  OrderModel _mapBackendToOrderModel(Map<String, dynamic> data) {
    final estadoNombre =
        (data['estadoNombre'] as String?)?.toLowerCase() ?? 'pendiente';

    String status = OrderStatus.pendiente;
    if (estadoNombre.contains('preparacion') ||
        estadoNombre.contains('preparación')) {
      status = OrderStatus.enPreparacion;
    } else if (estadoNombre.contains('listo') &&
        !estadoNombre.contains('recoger')) {
      status = OrderStatus.listo;
    } else if (estadoNombre.contains('listo') &&
        estadoNombre.contains('recoger')) {
      status = OrderStatus.listoParaRecoger;
    } else if (estadoNombre.contains('cancelada') ||
        estadoNombre.contains('cancelado')) {
      status = OrderStatus.cancelada;
    }

    // Obtener items de la orden (pueden venir en diferentes formatos del backend)
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final orderItems = itemsData.map((itemJson) {
      final baseName = (itemJson['productoNombre'] as String?) ??
          (itemJson['nombre'] as String?) ??
          'Producto';
      final tamano = (itemJson['productoTamanoEtiqueta'] ??
              itemJson['tamanoEtiqueta'] ??
              itemJson['tamanoNombre'] ??
              itemJson['sizeName'] ??
              itemJson['size'])
          ?.toString();
      final displayName = _formatProductNameWithSize(baseName, tamano);

      // Determinar estación basada en categoría real (dinámica) y fallback por nombre.
      final categoriaNombre = (itemJson['categoriaNombre'] as String?) ??
          (itemJson['categoria'] as String?);
      final stationLabel = categoriaNombre?.trim() ?? '';
      String station = _stationKeyFromCategory(categoriaNombre);
      final productName = baseName.toLowerCase();
      if (station == KitchenStation.tacos &&
          (productName.contains('consom') || productName.contains('mix'))) {
        station = KitchenStation.consomes;
      } else if (station == KitchenStation.tacos &&
          (productName.contains('agua') ||
              productName.contains('horchata') ||
              productName.contains('refresco') ||
              productName.contains('bebida'))) {
        station = KitchenStation.bebidas;
      }

      return OrderItem(
        id:
            (itemJson['id'] as num?)?.toInt() ??
            (itemJson['ordenItemId'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        name: displayName,
        quantity: (itemJson['cantidad'] as num?)?.toInt() ?? 1,
        station: station,
        stationLabel: stationLabel,
        notes:
            (itemJson['nota'] as String?) ??
            (itemJson['notas'] as String?) ??
            '',
      );
    }).toList();

    // Parsear fecha de creación (debe ser la fecha real cuando el mesero envió el pedido)
    // Intentar múltiples campos de fecha del backend
    final fechaCreacion =
        data['creadoEn'] ??
        data['fechaCreacion'] ??
        data['createdAt'] ??
        data['fecha_creacion'];

    final orderTime = _parseDateTime(fechaCreacion);

    // Validar que la fecha sea razonable (no muy antigua ni futura)
    final now = date_utils.AppDateUtils.nowCdmx();
    final diff = now.difference(orderTime);

    // Validar fecha: si es muy antigua (más de 7 días) o muy futura, usar fecha actual
    DateTime finalOrderTime = orderTime;
    if (diff.isNegative && diff.inDays.abs() > 7) {
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} en el futuro (${diff.inDays.abs()} días), usando fecha actual',
      );
      finalOrderTime = date_utils.AppDateUtils.nowCdmx();
    } else if (!diff.isNegative && diff.inDays > 7) {
      // Si la fecha es muy antigua (más de 7 días), probablemente es un error de datos
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} muy antigua (${diff.inDays} días), usando fecha actual',
      );
      finalOrderTime = date_utils.AppDateUtils.nowCdmx();
    } else if (!diff.isNegative && diff.inDays > 1) {
      // Si es entre 1-7 días, puede ser datos de prueba, pero logueamos
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} antigua (${diff.inDays} días) - puede ser datos de prueba',
      );
    }

    // Tiempo estimado por defecto: 6 minutos
    const defaultEstimatedTime = 6;

    // Obtener datos del cliente si están disponibles
    final customerPhone = data['clienteTelefono'] as String?;
    final pickupTimeStr = data['pickupTime'] as String?;
    // pickupTime en OrderModel es String?, mantenerlo como String si viene del backend
    final pickupTime = pickupTimeStr;

    // Formatear ID como ORD-XXXXXX para consistencia con mesero
    final orderIdNum = data['id'] as int? ?? 0;
    final formattedOrderId = 'ORD-${orderIdNum.toString().padLeft(6, '0')}';

    final mesaCodigoRaw = data['mesaCodigo']?.toString();
    final mesaCodigoParsed = mesaCodigoRaw != null
        ? int.tryParse(mesaCodigoRaw.replaceAll('Mesa ', '').trim())
        : null;
    return OrderModel(
      id: formattedOrderId,
      tableNumber: mesaCodigoParsed ?? (data['mesaId'] as int?),
      mesaCodigo: mesaCodigoRaw,
      items: orderItems,
      status: status,
      orderTime: finalOrderTime,
      estimatedTime: data['tiempoEstimadoPreparacion'] as int? ??
          data['estimatedTime'] as int? ??
          defaultEstimatedTime,
      waiter:
          data['creadoPorNombre'] as String? ??
          data['creadoPorUsuarioNombre'] as String? ??
          data['creadoPor'] as String? ??
          'Sin asignar',
      priority: _mapPriorityFromBackend(data['prioridad'] as String?),
      isTakeaway: data['mesaId'] == null,
      customerName: data['clienteNombre'] as String?,
      customerPhone: customerPhone,
      pickupTime: pickupTime,
    );
  }

  // Inicializar órdenes (ahora desde el backend)
  Future<void> _initializeOrders() async {
    await loadOrders();
  }

  // Cambiar filtro de estación
  void setSelectedStation(String station) {
    _selectedStation = _stationOptions.containsKey(station) ? station : 'todas';
    notifyListeners();
  }

  // Cambiar filtro de estado
  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de para llevar
  void setShowTakeawayOnly(bool show) {
    _showTakeawayOnly = show;
    notifyListeners();
  }

  // Cambiar filtro de Mostrar
  void setSelectedShow(String show) {
    _selectedShow = show;
    notifyListeners();
  }

  // Cambiar filtro de Alertas
  void setSelectedAlert(String alert) {
    _selectedAlert = alert;
    notifyListeners();
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Actualizar estado de pedido
  /// [forzarSinStock] Si true, permite marcar como listo aunque falte stock en inventario (uso excepcional).
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    bool forzarSinStock = false,
  }) async {
    try {
      // Convertir orderId de string a int (puede venir como "ORD-123" o "123")
      final ordenIdStr = orderId.replaceAll('ORD-', '');
      final ordenIdInt = int.tryParse(ordenIdStr) ?? int.tryParse(orderId);
      if (ordenIdInt == null) {
        throw Exception('ID de orden inválido: $orderId');
      }

      // Obtener estados de orden disponibles
      final estados = await _ordenesService.getEstadosOrden();

      // Mapear estado del frontend al ID del backend
      int? estadoOrdenId;
      final statusLower = newStatus.toLowerCase();

      if (statusLower.contains('pendiente') ||
          statusLower.contains('abierta')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('pendiente') ||
              (e['nombre'] as String).toLowerCase().contains('abierta'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 1},
        );
        estadoOrdenId = estado['id'] as int;
      } else if (statusLower.contains('preparacion') ||
          statusLower.contains('preparación')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('preparacion') ||
              (e['nombre'] as String).toLowerCase().contains('preparación'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 2},
        );
        estadoOrdenId = estado['id'] as int;
      } else if (statusLower.contains('listo') &&
          !statusLower.contains('recoger')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('listo') &&
              !(e['nombre'] as String).toLowerCase().contains('recoger'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 3},
        );
        estadoOrdenId = estado['id'] as int;
      } else if (statusLower.contains('listo') &&
          statusLower.contains('recoger')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('listo') &&
              (e['nombre'] as String).toLowerCase().contains('recoger'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 4},
        );
        estadoOrdenId = estado['id'] as int;
      } else if (statusLower.contains('cancelada') ||
          statusLower.contains('cancelado')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('cancelada') ||
              (e['nombre'] as String).toLowerCase().contains('cancelado'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 5},
        );
        estadoOrdenId = estado['id'] as int;
      }

      if (estadoOrdenId == null) {
        throw Exception('Estado de orden no encontrado: $newStatus');
      }

      // Actualizar estado en BD
      // El backend se encarga automáticamente de emitir las alertas al mesero
      // cuando el estado cambia a "en_preparacion" o "listo"
      await _ordenesService.cambiarEstado(
        ordenIdInt,
        estadoOrdenId,
        forzarSinStock: forzarSinStock,
      );

      print(
        '✅ Cocinero: Estado de orden $ordenIdInt cambiado a $newStatus. El backend emitirá las alertas automáticamente.',
      );

      // Verificar si el nuevo estado es "listo" para eliminar de la vista
      final isListo =
          statusLower.contains('listo') ||
          statusLower.contains('ready') ||
          statusLower.contains('completada') ||
          statusLower.contains('finalizada');

      if (isListo) {
        // IMPORTANTE: Marcar como completada PRIMERO antes de eliminar
        // Esto previene que el evento onOrderUpdated la vuelva a agregar
        final normalizedId = ordenIdInt.toString();
        _completedOrderIds.add(normalizedId);
        print(
          '💾 Cocinero: Marcando orden $normalizedId como completada ANTES de eliminar (original: $orderId)',
        );

        // Guardar INMEDIATAMENTE para persistir el estado
        try {
          await _saveCompletedOrders();
          print(
            '✅ Cocinero: Orden $normalizedId guardada como completada en storage',
          );
        } catch (e) {
          print('❌ Cocinero: ERROR al guardar orden completada: $e');
          // Continuar aunque falle el guardado
        }

        // Ahora eliminar de la lista
        final removedCount = _orders.length;
        _orders.removeWhere((order) {
          // Eliminar por ID numérico o formato ORD-XXX
          final orderIdStr = order.id.replaceAll('ORD-', '');
          return orderIdStr == normalizedId ||
              order.id == orderId ||
              order.id == orderIdStr;
        });
        final newCount = _orders.length;

        if (removedCount != newCount) {
          print(
            '✅ Cocinero: Orden $orderId eliminada de la vista (${removedCount - newCount} orden(es) eliminada(s))',
          );
        } else {
          print(
            '⚠️ Cocinero: Orden $orderId no se encontró en la lista para eliminar',
          );
        }

        notifyListeners();
      } else {
        // Si no es "listo", actualizar el estado localmente
        _orders = _orders.map((order) {
          if (order.id == orderId) {
            return order.copyWith(status: newStatus);
          }
          return order;
        }).toList();
        notifyListeners();
      }

      // NO recargar todas las órdenes inmediatamente para evitar conflictos
      // El backend enviará un evento Socket.IO que actualizará la orden automáticamente
      // Solo recargar si hay un error o después de un delay para sincronización
    } catch (e) {
      print('Error al actualizar estado de orden: $e');
      rethrow;
    }
  }

  // Actualizar tiempo estimado (ahora guarda en BD)
  Future<void> updateEstimatedTime(String orderId, int newTime) async {
    try {
      // Convertir orderId de string a int (puede venir como "ORD-123" o "123")
      final ordenIdStr = orderId.replaceAll('ORD-', '');
      final ordenIdInt = int.tryParse(ordenIdStr) ?? int.tryParse(orderId);
      if (ordenIdInt == null) {
        throw Exception('ID de orden inválido: $orderId');
      }

      // Actualizar en el backend
      await _ordenesService.updateTiempoEstimado(ordenIdInt, newTime);

      // Actualizar localmente
    _orders = _orders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(estimatedTime: newTime);
      }
      return order;
    }).toList();
    notifyListeners();
    } catch (e) {
      print('Error al actualizar tiempo estimado: $e');
      rethrow;
    }
  }

  // Agregar nuevo pedido
  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void addAlert(OldKitchenAlert alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  // Remover pedido
  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  // Cancelar orden
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      // Extraer el ID numérico de la orden (puede venir como "ORD-000070" o "70")
      final ordenIdInt =
          int.tryParse(orderId.replaceAll('ORD-', '')) ??
          int.tryParse(orderId) ??
          0;

      if (ordenIdInt == 0) {
        throw Exception('ID de orden inválido: $orderId');
      }

      await updateOrderStatus(orderId, OrderStatus.cancelada);

      // Opcional: registrar la razón de cancelación si se proporciona
      if (reason != null && reason.isNotEmpty) {
        print('Orden $orderId cancelada. Razón: $reason');
      }

      // IMPORTANTE: Eliminar la orden de la vista inmediatamente después de cancelar
      // Similar a como se hace cuando se marca como "listo"
      final normalizedId = ordenIdInt.toString();

      // Marcar como completada para evitar que vuelva a aparecer
      _completedOrderIds.add(normalizedId);
      print(
        '💾 Cocinero: Marcando orden $normalizedId como completada después de cancelar (original: $orderId)',
      );

      // Guardar en storage
      try {
        await _saveCompletedOrders();
        print(
          '✅ Cocinero: Orden $normalizedId guardada como completada en storage',
        );
      } catch (e) {
        print('❌ Cocinero: ERROR al guardar orden completada: $e');
      }

      // Eliminar de la lista
      final removedCount = _orders.length;
      _orders.removeWhere((order) {
        // Eliminar por ID numérico o formato ORD-XXX
        final orderIdStr = order.id.replaceAll('ORD-', '');
        return orderIdStr == normalizedId ||
            order.id == orderId ||
            order.id == normalizedId;
      });
      final newCount = _orders.length;

      if (removedCount != newCount) {
        print(
          '✅ Cocinero: Orden $orderId eliminada de la vista después de cancelar (${removedCount - newCount} orden(es) eliminada(s))',
        );
      } else {
        print(
          '⚠️ Cocinero: Orden $orderId no se encontró en la lista para eliminar',
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error al cancelar orden: $e');
      rethrow;
    }
  }

  // Obtener estadísticas
  Map<String, int> getOrderStats() {
    return {
      'pendiente': _orders
          .where((o) => o.status == OrderStatus.pendiente)
          .length,
      'en_preparacion': _orders
          .where((o) => o.status == OrderStatus.enPreparacion)
          .length,
      'listo': _orders.where((o) => o.status == OrderStatus.listo).length,
      'listo_para_recoger': _orders
          .where((o) => o.status == OrderStatus.listoParaRecoger)
          .length,
      'cancelada': _orders
          .where((o) => o.status == OrderStatus.cancelada)
          .length,
    };
  }

  // Obtener pedidos por estación
  Map<String, int> getStationStats() {
    return {
      'tacos': _orders
          .where(
            (o) => o.items.any((item) => item.station == KitchenStation.tacos),
          )
          .length,
      'consomes': _orders
          .where(
            (o) =>
                o.items.any((item) => item.station == KitchenStation.consomes),
          )
          .length,
      'bebidas': _orders
          .where(
            (o) =>
                o.items.any((item) => item.station == KitchenStation.bebidas),
          )
          .length,
    };
  }

  // Obtener pedidos urgentes (más de 15 minutos)
  List<OrderModel> getUrgentOrders() {
    final now = date_utils.AppDateUtils.nowCdmx();
    return _orders.where((order) {
      final elapsed = now.difference(order.orderTime).inMinutes;
      return elapsed > 15 &&
          order.status != OrderStatus.listo &&
          order.status != OrderStatus.listoParaRecoger;
    }).toList();
  }

  // Formatear tiempo transcurrido (unificado con el resto de la app)
  String formatElapsedTime(DateTime orderTime) {
    final elapsed = DateTime.now().difference(orderTime.isUtc ? orderTime.toLocal() : orderTime);
    if (elapsed.isNegative) return 'Recién creado';
    if (elapsed.inSeconds < 60) return 'Recién creado';
    return date_utils.AppDateUtils.formatDurationShort(elapsed);
  }

  // Verificar si una nota es crítica
  bool isCriticalNote(String notes) {
    if (notes.isEmpty) return false;

    final criticalKeywords = [
      'alergia',
      'alérgico',
      'alérgica',
      'alergico',
      'alergica',
      'sin',
      'no',
      'diabético',
      'diabética',
      'diabetico',
      'diabetica',
      'celíaco',
      'celíaca',
      'celiaco',
      'celiaca',
      'gluten',
      'importante',
      'cuidado',
      'atención',
      'especial',
    ];

    final lowerNotes = notes.toLowerCase();
    return criticalKeywords.any((keyword) => lowerNotes.contains(keyword));
  }

  // Obtener color de estado
  Color getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pendiente:
        return Colors.red;
      case OrderStatus.enPreparacion:
        return Colors.orange;
      case OrderStatus.listo:
        return Colors.green;
      case OrderStatus.listoParaRecoger:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de prioridad
  Color getPriorityColor(String priority) {
    switch (priority) {
      case OrderPriority.alta:
        return Colors.red;
      case OrderPriority.normal:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  Future<void> removeAlert(String alertId) async {
    // Intentar marcar como leída en el backend si tiene ID numérico
    try {
      final alertaIdInt = int.tryParse(alertId);
      if (alertaIdInt != null) {
        await _api.patch('/alertas/$alertaIdInt/leida');
        print('✅ Cocinero: Alerta $alertId marcada como leída en BD');
      }
    } catch (e) {
      print('⚠️ Cocinero: Error al marcar alerta como leída (continuando): $e');
      // Continuar aunque falle, es mejor eliminar la alerta localmente
    }

    // Eliminar de la lista local
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  Future<void> clearAlerts() async {
    // Marcar todas las alertas como leídas en el backend
    try {
      await _api.post('/alertas/marcar-todas-leidas');
      print('✅ Cocinero: Todas las alertas marcadas como leídas en BD');
    } catch (e) {
      print(
        '⚠️ Cocinero: Error al marcar todas las alertas como leídas (continuando): $e',
      );
      // Continuar aunque falle
    }

    // Limpiar lista local
    _alerts.clear();
    notifyListeners();
  }

  List<OldKitchenAlert> getAlertsByPriority(String priority) {
    return _alerts.where((alert) => alert.priority == priority).toList();
  }
}
