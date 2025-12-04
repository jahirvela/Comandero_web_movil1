import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order_model.dart';
import '../services/ordenes_service.dart';
import '../services/socket_service.dart';
import '../utils/date_utils.dart' as date_utils;

class CocineroController extends ChangeNotifier {
  final OrdenesService _ordenesService = OrdenesService();
  // Estado de los pedidos
  List<OrderModel> _orders = [];
  final List<KitchenAlert> _alerts = [];

  // IDs de órdenes marcadas como "listo" por este cocinero (para no recargarlas)
  final Set<String> _completedOrderIds = {};

  // Storage para persistir órdenes completadas
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Filtros
  String _selectedStation = 'todas';
  String _selectedStatus = 'todas';
  String _selectedShow = 'todos'; // 'todos', 'para_llevar', 'mesas'
  String _selectedAlert =
      'todas'; // 'todas', 'demoras', 'canceladas', 'cambios'
  bool _showTakeawayOnly = false;

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
  List<KitchenAlert> get alerts => List.unmodifiable(_alerts);

  // Obtener pedidos filtrados
  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
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
  }

  List<KitchenAlert> get filteredAlerts {
    return _alerts.where((alert) {
      if (_selectedAlert == 'todas') return true;
      switch (_selectedAlert) {
        case 'demoras':
          return alert.type.toLowerCase() == 'demora';
        case 'canceladas':
          return alert.type.toLowerCase().contains('cancel');
        case 'cambios':
          return alert.type.toLowerCase().contains('cambio');
        default:
          return true;
      }
    }).toList();
  }

  CocineroController() {
    _initializeOrders();
    _setupSocketListeners();
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
          await _storage.read(key: 'cocinero_completed_orders') ?? '[]';
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
        await _storage.write(key: 'cocinero_completed_orders', value: '[]');
        print('💾 Cocinero: No hay órdenes completadas para guardar');
        return;
      }

      final json = '["${ids.join('","')}"]';
      await _storage.write(key: 'cocinero_completed_orders', value: json);
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

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    final socketService = SocketService();

    // Escuchar alertas de cocina en tiempo real (del capitán, mesero, etc.)
    socketService.onCocinaAlerta((data) {
      try {
        print('🔔 Cocinero: Alerta recibida vía Socket.IO');
        print('   📋 Datos: $data');

        // Extraer datos de la alerta
        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

        final tableNumber =
            data['mesaId']?.toString() ??
            metadata['tableNumber']?.toString() ??
            'N/A';
        final orderId =
            data['ordenId']?.toString() ??
            metadata['orderId']?.toString() ??
            'N/A';

        // Determinar el tipo de alerta
        String alertType =
            metadata['alertType']?.toString() ??
            data['tipo']?.toString().replaceAll('alerta.', '') ??
            'General';

        // Capitalizar primera letra
        if (alertType.isNotEmpty) {
          alertType = alertType[0].toUpperCase() + alertType.substring(1);
        }

        // Extraer motivo y mensaje
        final reason =
            metadata['reason']?.toString() ??
            data['mensaje']?.toString() ??
            'Sin motivo especificado';
        final details = metadata['details']?.toString();

        // Mapear prioridad
        String priority = data['prioridad']?.toString() ?? 'media';
        if (priority == 'urgente')
          priority = 'high';
        else if (priority == 'baja')
          priority = 'low';
        else
          priority = 'medium';

        // Obtener información del emisor
        final emisor = data['emisor'] as Map<String, dynamic>?;
        final emisorNombre = emisor?['username']?.toString() ?? 'Sistema';

        final alert = KitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: tableNumber,
          orderId: orderId,
          type: alertType,
          reason: '$reason (enviado por $emisorNombre)',
          details: details,
          priority: priority,
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );

        _alerts.insert(0, alert);
        notifyListeners();

        print(
          '✅ Cocinero: Alerta agregada - Tipo: $alertType, Mesa: $tableNumber, Orden: $orderId',
        );
      } catch (e, stackTrace) {
        print('❌ Error al procesar alerta de cocina: $e');
        print('   Stack: $stackTrace');
      }
    });

    // Escuchar alertas de demora
    socketService.onAlertaDemora((data) {
      try {
        final alert = KitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: data['mesaId']?.toString() ?? 'N/A',
          orderId: data['ordenId']?.toString() ?? 'N/A',
          type: 'Demora',
          reason: data['mensaje']?.toString() ?? 'Orden con demora',
          details: data['metadata']?['tiempoEspera']?.toString(),
          priority: data['prioridad']?.toString() ?? 'Normal',
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de demora: $e');
      }
    });

    // Escuchar alertas de cancelación
    socketService.onAlertaCancelacion((data) {
      try {
        final alert = KitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: data['mesaId']?.toString() ?? 'N/A',
          orderId: data['ordenId']?.toString() ?? 'N/A',
          type: 'Cancelación',
          reason: data['mensaje']?.toString() ?? 'Orden cancelada',
          details: data['metadata']?['motivo']?.toString(),
          priority: 'Urgente',
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cancelación: $e');
      }
    });

    // Escuchar alertas de modificación
    socketService.onAlertaModificacion((data) {
      try {
        final alert = KitchenAlert(
          id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
          tableNumber: data['mesaId']?.toString() ?? 'N/A',
          orderId: data['ordenId']?.toString() ?? 'N/A',
          type: 'Cambio en orden',
          reason: data['mensaje']?.toString() ?? 'Orden modificada',
          details: data['metadata']?['cambio']?.toString(),
          priority: 'Normal',
          timestamp: date_utils.AppDateUtils.parseToLocal(
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de modificación: $e');
      }
    });

    // Escuchar alertas generales de cocina
    socketService.onAlertaCocina((data) {
      try {
        final alert = KitchenAlert(
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
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );
        _alerts.insert(0, alert);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta general de cocina: $e');
      }
    });

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
                KitchenAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tableNumber: nuevaOrden.tableNumber?.toString() ?? '0',
                  orderId: nuevaOrden.id.toString(),
                  type: 'Nueva Orden Urgente',
                  reason:
                      'Nueva orden #${nuevaOrden.id} requiere atención inmediata',
                  priority: 'high',
                  timestamp: DateTime.now(),
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
        if (ordenId != null) {
          final ordenIdStr = ordenId.toString();

          // VERIFICAR PRIMERO si la orden ya fue completada previamente
          if (_completedOrderIds.contains(ordenIdStr)) {
            print(
              '🚫 Cocinero: Actualización de orden $ordenIdStr ignorada porque ya fue completada previamente',
            );
            // Asegurar que no esté en la lista
            _orders.removeWhere((o) => o.id == ordenIdStr);
            notifyListeners();
            return;
          }

          final index = _orders.indexWhere((o) => o.id == ordenIdStr);
          final estadoNombre =
              (data['estadoNombre'] as String?)?.toLowerCase() ?? '';

          // Verificar si la orden es relevante para cocina
          // Las órdenes "listas" no son relevantes para cocina (ya están completadas)
          final esRelevanteParaCocina =
              !estadoNombre.contains('pagada') &&
              !estadoNombre.contains('cancelada') &&
              !estadoNombre.contains('cerrada') &&
              !estadoNombre.contains('listo') &&
              !estadoNombre.contains('ready') &&
              !estadoNombre.contains('completada') &&
              !estadoNombre.contains('finalizada');

          if (index != -1) {
            if (esRelevanteParaCocina) {
              _orders[index] = _mapBackendToOrderModel(
                data as Map<String, dynamic>,
              );
              notifyListeners();
            } else {
              // Si ya no es relevante para cocina (incluyendo "listo"), removerla
              _orders.removeAt(index);
              notifyListeners();
            }
          } else if (esRelevanteParaCocina) {
            // Si no existe y es relevante, agregarla
            _orders.add(_mapBackendToOrderModel(data as Map<String, dynamic>));
            notifyListeners();
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
          _orders.removeWhere((o) => o.id == ordenId.toString());
          notifyListeners();

          // Agregar alerta de cancelación
          _alerts.add(
            KitchenAlert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              tableNumber: '0',
              orderId: ordenId.toString(),
              type: 'Cancelación',
              reason: 'La orden #$ordenId ha sido cancelada',
              priority: 'high',
              timestamp: DateTime.now(),
            ),
          );
          notifyListeners();
        }
      } catch (e) {
        print('Error al procesar cancelación de orden: $e');
      }
    });

    // Escuchar alertas de cocina (del sistema)
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
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cocina: $e');
      }
    });

    // NOTA: El listener para alertas de cocina (cocina.alerta) ya está
    // configurado arriba en la línea 194 con onCocinaAlerta()
    // No agregar otro listener duplicado aquí
  }

  // Cargar órdenes desde el backend
  Future<void> loadOrders() async {
    try {
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
            final ahora = DateTime.now();
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
      _orders = []; // Mantener lista vacía si falla la carga
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
      // Determinar estación basada en el nombre del producto o categoría
      String station = KitchenStation.tacos;
      final productName =
          ((itemJson['productoNombre'] as String?) ??
                  (itemJson['nombre'] as String?) ??
                  '')
              .toLowerCase();
      if (productName.contains('consom') || productName.contains('mix')) {
        station = KitchenStation.consomes;
      } else if (productName.contains('agua') ||
          productName.contains('horchata') ||
          productName.contains('refresco') ||
          productName.contains('bebida')) {
        station = KitchenStation.bebidas;
      }

      return OrderItem(
        id:
            (itemJson['id'] as num?)?.toInt() ??
            (itemJson['ordenItemId'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        name:
            (itemJson['productoNombre'] as String?) ??
            (itemJson['nombre'] as String?) ??
            'Producto',
        quantity: (itemJson['cantidad'] as num?)?.toInt() ?? 1,
        station: station,
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
    final now = DateTime.now();
    final diff = now.difference(orderTime);

    // Validar fecha: si es muy antigua (más de 7 días) o muy futura, usar fecha actual
    DateTime finalOrderTime = orderTime;
    if (diff.isNegative && diff.inDays.abs() > 7) {
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} en el futuro (${diff.inDays.abs()} días), usando fecha actual',
      );
      finalOrderTime = DateTime.now();
    } else if (!diff.isNegative && diff.inDays > 7) {
      // Si la fecha es muy antigua (más de 7 días), probablemente es un error de datos
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} muy antigua (${diff.inDays} días), usando fecha actual',
      );
      finalOrderTime = DateTime.now();
    } else if (!diff.isNegative && diff.inDays > 1) {
      // Si es entre 1-7 días, puede ser datos de prueba, pero logueamos
      print(
        '⚠️ Cocinero: Fecha de orden ${data['id']} antigua (${diff.inDays} días) - puede ser datos de prueba',
      );
    }

    // Calcular tiempo estimado basado en items (aproximación: 5-8 min por item)
    final itemsCount = orderItems.length;
    final estimatedTime = (itemsCount * 6).clamp(5, 30);

    // Obtener datos del cliente si están disponibles
    final customerPhone = data['clienteTelefono'] as String?;
    final pickupTimeStr = data['pickupTime'] as String?;
    // pickupTime en OrderModel es String?, mantenerlo como String si viene del backend
    final pickupTime = pickupTimeStr;

    // Formatear ID como ORD-XXXXXX para consistencia con mesero
    final orderIdNum = data['id'] as int? ?? 0;
    final formattedOrderId = 'ORD-${orderIdNum.toString().padLeft(6, '0')}';

    return OrderModel(
      id: formattedOrderId,
      tableNumber: data['mesaId'] as int?,
      items: orderItems,
      status: status,
      orderTime: finalOrderTime,
      estimatedTime: data['estimatedTime'] as int? ?? estimatedTime,
      waiter:
          data['creadoPorNombre'] as String? ??
          data['creadoPorUsuarioNombre'] as String? ??
          'Desconocido',
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
    _selectedStation = station;
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
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
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
      await _ordenesService.cambiarEstado(ordenIdInt, estadoOrdenId);

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
        // Si es "listo", eliminar INMEDIATAMENTE de la lista (no actualizar)
        print(
          '✅ Cocinero: Orden $orderId marcada como lista, eliminando de la vista',
        );
        _orders.removeWhere((order) => order.id == orderId);

        // Marcar como completada para no recargarla en futuras sesiones
        // Normalizar el ID: convertir "ORD-5" a "5" o mantener "5" si ya es numérico
        final normalizedId = ordenIdInt
            .toString(); // Usar el ID numérico del backend
        _completedOrderIds.add(normalizedId);
        print(
          '💾 Cocinero: Guardando orden completada: $normalizedId (original: $orderId)',
        );
        print(
          '💾 Cocinero: IDs antes de guardar: ${_completedOrderIds.toList()}',
        );

        // Guardar INMEDIATAMENTE y esperar a que se complete
        try {
          await _saveCompletedOrders(); // Persistir el estado
          print(
            '✅ Cocinero: Orden $normalizedId guardada como completada en storage',
          );

          // Verificar que se guardó correctamente leyendo de nuevo
          final verification = await _storage.read(
            key: 'cocinero_completed_orders',
          );
          print('✅ Cocinero: Verificación de storage: $verification');
        } catch (e) {
          print('❌ Cocinero: ERROR al guardar orden completada: $e');
          // Re-lanzar el error para que se maneje
          rethrow;
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

  // Actualizar tiempo estimado
  void updateEstimatedTime(String orderId, int newTime) {
    _orders = _orders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(estimatedTime: newTime);
      }
      return order;
    }).toList();
    notifyListeners();
  }

  // Agregar nuevo pedido
  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void addAlert(KitchenAlert alert) {
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
      await updateOrderStatus(orderId, OrderStatus.cancelada);
      // Opcional: registrar la razón de cancelación si se proporciona
      if (reason != null && reason.isNotEmpty) {
        print('Orden $orderId cancelada. Razón: $reason');
      }
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
    final now = DateTime.now();
    return _orders.where((order) {
      final elapsed = now.difference(order.orderTime).inMinutes;
      return elapsed > 15 &&
          order.status != OrderStatus.listo &&
          order.status != OrderStatus.listoParaRecoger;
    }).toList();
  }

  // Formatear tiempo transcurrido
  String formatElapsedTime(DateTime orderTime) {
    final now = DateTime.now();
    final elapsed = now.difference(orderTime);

    // Si el tiempo es negativo, puede ser un error de parseo o zona horaria
    if (elapsed.isNegative) {
      // Si es negativo pero muy pequeño (menos de 1 minuto), probablemente es un problema de zona horaria
      if (elapsed.inSeconds.abs() < 60) {
        return 'Recién creado';
      }
      // Si es muy negativo, hay un error de parseo
      print(
        'ADVERTENCIA: Tiempo negativo detectado. orderTime: $orderTime, now: $now, diferencia: ${elapsed.inMinutes} min',
      );
      return 'Recién creado';
    }

    final totalSeconds = elapsed.inSeconds;
    final minutes = elapsed.inMinutes;
    final hours = elapsed.inHours;
    final days = elapsed.inDays;

    // Si el tiempo es muy grande (más de 1 día), probablemente es una fecha antigua de datos de prueba
    // En producción, las órdenes no deberían tener más de unas horas
    if (days > 1) {
      print(
        '⚠️ Cocinero: Tiempo transcurrido muy grande: $days días. orderTime: $orderTime, now: $now',
      );
      // Si es más de 7 días, definitivamente es un error
      if (days > 7) {
        return 'Recién creado';
      }
      // Si es entre 1-7 días, puede ser datos de prueba, pero mostramos el tiempo real
      // (aunque en producción esto no debería pasar)
    }

    // Formatear según el tiempo transcurrido
    if (totalSeconds < 60) {
      return 'Recién creado';
    } else if (minutes < 60) {
      return 'Hace $minutes min';
    } else if (hours < 24) {
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return 'Hace ${hours}h ${remainingMinutes}min';
      } else {
        return 'Hace ${hours}h';
      }
    } else {
      final remainingHours = hours % 24;
      if (remainingHours > 0) {
        return 'Hace ${days}d ${remainingHours}h';
      } else {
        return 'Hace ${days}d';
      }
    }
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

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  List<KitchenAlert> getAlertsByPriority(String priority) {
    return _alerts.where((alert) => alert.priority == priority).toList();
  }
}

class KitchenAlert {
  final String id;
  final String tableNumber;
  final String orderId;
  final String type;
  final String reason;
  final String? details;
  final String priority;
  final DateTime timestamp;

  KitchenAlert({
    required this.id,
    required this.tableNumber,
    required this.orderId,
    required this.type,
    required this.reason,
    this.details,
    required this.priority,
    required this.timestamp,
  });
}
