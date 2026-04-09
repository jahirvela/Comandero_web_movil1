import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../models/table_model.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../services/kitchen_order_service.dart';
import '../services/bill_repository.dart';
import '../services/ordenes_service.dart';
import '../services/mesas_service.dart';
import '../services/productos_service.dart';
import '../services/categorias_service.dart';
import '../services/socket_service.dart';
import '../services/alertas_service.dart';
import '../services/kitchen_alerts_service.dart';
import '../services/configuracion_service.dart';
import '../services/auth_service.dart';
import '../models/kitchen_alert.dart';
import '../utils/date_utils.dart' as date_utils;

class MeseroController extends ChangeNotifier {
  final BillRepository _billRepository;
  final OrdenesService _ordenesService = OrdenesService();
  final MesasService _mesasService = MesasService();
  final ProductosService _productosService = ProductosService();
  final CategoriasService _categoriasService = CategoriasService();
  final AlertasService _alertasService = AlertasService();
  final ConfiguracionService _configuracionService = ConfiguracionService();
  KitchenAlertsService? _kitchenAlertsService;
  bool _socketListenersConfigured = false;

  // Estado de las mesas
  List<TableModel> _tables = [];
  TableModel? _selectedTable;

  // Estado del carrito por mesa (se persiste por mesa para no perderlo al recargar/reiniciar)
  final Map<String, List<CartItem>> _tableOrders = {};
  static const String _cartStoragePrefix = 'mesero_cart_';

  // Historial de pedidos por mesa (pedidos enviados a cocina)
  final Map<String, List<Map<String, dynamic>>> _tableOrderHistory = {};

  // Bandera para controlar si se debe recargar el historial automáticamente
  final Map<String, bool> _historyCleared = {};

  // Storage para persistir el estado de historial limpiado
  final AuthStorage _storage = AuthStorage();

  // Notificaciones pendientes
  final List<Map<String, dynamic>> _pendingNotifications = [];

  // Notificaciones limpiadas (guardadas en storage para persistencia)
  final Set<String> _clearedNotifications = {};

  // Órdenes para llevar ya enviadas al cajero (para filtrar del historial)
  // Se persiste en storage para mantener después de logout/login
  final Set<int> _sentToCashierOrders = {};
  
  // Flag para prevenir ejecuciones simultáneas de sendTakeawayToCashier
  bool _processingTakeawayOrder = false;

  // Estado de la vista actual
  String _currentView = 'floor';

  // Nombre del usuario logueado (para enviar al cajero y mostrar en historial)
  String? _loggedUserName;

  /// Fijar usuario logueado sin notificar (evita loops en build)
  void setLoggedUserName(String userName) {
    if (userName.isEmpty) return;
    if (_loggedUserName == userName) return;
    _loggedUserName = userName;
  }

  // Estado para cuenta dividida por persona (por mesa)
  final Map<String, bool> _isDividedAccountModeByTable = {}; // tableId -> si está en modo cuenta dividida
  final Map<String, Map<String, List<String>>> _personCartItemsByTable = {}; // tableId -> {personId -> [cartItemId, ...]}
  final Map<String, Map<String, String>> _personNamesByTable = {}; // tableId -> {personId -> nombre}
  final Map<String, int> _nextPersonIdByTable = {}; // tableId -> siguiente ID de persona
  final Map<String, String?> _selectedPersonIdByTable = {}; // tableId -> ID de persona seleccionada

  /// Por mesa (id string): personIds que ya fueron incluidos en un bill enviado al cajero (cuenta dividida).
  final Map<String, Set<String>> _dividedPersonsBillSentByTable = {};
  static const String _storageDividedPersonsBillSent = 'mesero_divided_persons_bill_sent';

  // Información del cliente para pedidos "Para llevar"
  String? _takeawayCustomerName;
  String? _takeawayCustomerPhone;

  // Estado de productos y categorías
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];

  // Getters
  List<TableModel> get tables => _tables;
  TableModel? get selectedTable => _selectedTable;
  String get currentView => _currentView;
  List<Map<String, dynamic>> get pendingNotifications => _pendingNotifications;
  String? get takeawayCustomerName => _takeawayCustomerName;
  String? get takeawayCustomerPhone => _takeawayCustomerPhone;
  bool get isTakeawayMode =>
      _currentView == 'takeaway' ||
      (_selectedTable == null && _takeawayCustomerName != null);
  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isDividedAccountMode {
    if (_selectedTable == null) return false;
    return _isDividedAccountModeByTable[_selectedTable!.id.toString()] ?? false;
  }
  
  Map<String, String> get personNames {
    if (_selectedTable == null) return {};
    final tableId = _selectedTable!.id.toString();
    return Map.unmodifiable(_personNamesByTable[tableId] ?? {});
  }
  
  Map<String, List<String>> get personCartItems {
    if (_selectedTable == null) return {};
    final tableId = _selectedTable!.id.toString();
    return Map.unmodifiable(_personCartItemsByTable[tableId] ?? {});
  }
  
  String? get selectedPersonId {
    if (_selectedTable == null) return null;
    final tableId = _selectedTable!.id.toString();
    return _selectedPersonIdByTable[tableId];
  }

  // Obtener carrito de la mesa actual o del modo takeaway
  List<CartItem> getCurrentCart() {
    // Determinar la clave del carrito
    String? cartKey;
    if (_selectedTable != null) {
      cartKey = _selectedTable!.id.toString();
    } else if (isTakeawayMode) {
      cartKey = 'takeaway';
    }

    if (cartKey == null) return [];
    return _tableOrders[cartKey] ?? [];
  }

  /// Persiste el carrito de una mesa en storage (para no perderlo al recargar/reiniciar).
  Future<void> _persistCartForTable(String tableId) async {
    try {
      final cart = _tableOrders[tableId] ?? [];
      final key = '$_cartStoragePrefix$tableId';
      if (cart.isEmpty) {
        await _storage.delete(key);
      } else {
        final list = cart.map((e) => e.toJson()).toList();
        await _storage.write(key, jsonEncode(list));
      }
    } catch (e) {
      print('⚠️ Mesero: Error al persistir carrito mesa $tableId: $e');
    }
  }

  /// Restaura el carrito de una mesa desde storage (solo si el carrito en memoria está vacío).
  Future<void> _loadPersistedCartForTable(String tableId) async {
    try {
      final key = '$_cartStoragePrefix$tableId';
      final raw = await _storage.read(key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      final cart = list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (cart.isNotEmpty) {
        _tableOrders[tableId] = cart;
        print('✅ Mesero: Carrito de mesa $tableId restaurado (${cart.length} artículos)');
      }
    } catch (e) {
      print('⚠️ Mesero: Error al cargar carrito persistido mesa $tableId: $e');
    }
  }

  // Obtener total de artículos en todos los carritos
  int get totalCartItems {
    return _tableOrders.values.fold(0, (total, items) => total + items.length);
  }

  int? _mesaNumeroForTableId(int tableId) {
    try {
      return _tables.firstWhere((t) => t.id == tableId).number;
    } catch (_) {
      if (_selectedTable?.id == tableId) return _selectedTable!.number;
      return null;
    }
  }

  /// True si esta persona aún tiene cuenta **pendiente de cobro** en cajero (bill activo).
  bool _hasPendingBillForPerson(int tableId, String personId) {
    final mesaNum = _mesaNumeroForTableId(tableId);
    if (mesaNum == null) return false;
    return _billRepository.bills.any(
      (bill) =>
          bill.status == BillStatus.pending &&
          bill.isDividedAccount == true &&
          bill.personAccounts != null &&
          bill.tableNumber == mesaNum &&
          bill.personAccounts!.any((p) => p.id == personId),
    );
  }

  /// Cuenta dividida: cobro del cajero **ya hecho** para esta persona (sin bill pendiente y ya envió cuenta).
  /// Antes estaba invertido y comparaba tableId con tableNumber (mesa).
  bool isPersonAccountClosed(int tableId, String personId) {
    if (getItemsForPerson(personId).isNotEmpty) return false;
    if (_hasPendingBillForPerson(tableId, personId)) return false;
    final key = tableId.toString();
    final sent = _dividedPersonsBillSentByTable[key];
    return sent != null && sent.contains(personId);
  }

  void _registerDividedPersonsBillSent(String tableIdStr, List<PersonAccount>? personAccounts) {
    if (personAccounts == null || personAccounts.isEmpty) return;
    _dividedPersonsBillSentByTable.putIfAbsent(tableIdStr, () => <String>{});
    for (final pa in personAccounts) {
      _dividedPersonsBillSentByTable[tableIdStr]!.add(pa.id);
    }
  }

  Future<void> _loadDividedPersonsBillSent() async {
    try {
      final raw = await _storage.read(_storageDividedPersonsBillSent);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>?;
      decoded?.forEach((k, v) {
        if (v is List) {
          _dividedPersonsBillSentByTable[k] = v.map((e) => e.toString()).toSet();
        }
      });
    } catch (e) {
      print('⚠️ Mesero: Error al cargar divided persons bill sent: $e');
    }
  }

  Future<void> _saveDividedPersonsBillSent() async {
    try {
      final map = <String, dynamic>{};
      _dividedPersonsBillSentByTable.forEach((k, v) {
        map[k] = v.toList();
      });
      await _storage.write(_storageDividedPersonsBillSent, jsonEncode(map));
    } catch (e) {
      print('⚠️ Mesero: Error al guardar divided persons bill sent: $e');
    }
  }

  MeseroController({required BillRepository billRepository})
    : _billRepository = billRepository {
    // Al cobrar en cajero se eliminan bills: refrescar UI (ej. botón "Cerrar división de cuenta")
    _billRepository.addListener(_onBillsChanged);
    // Inicialización simplificada para mejor rendimiento
    _initializeAsync();
  }

  void _onBillsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _billRepository.removeListener(_onBillsChanged);
    _kitchenAlertsService?.dispose();
    super.dispose();
  }

  // Inicialización asíncrona optimizada (no bloquea la UI)
  Future<void> _initializeAsync() async {
    try {
      // 1. PRIMERO cargar órdenes enviadas al cajero (CRÍTICO - antes de todo)
      // Esto es rápido (solo lectura de storage local)
      await _loadSentToCashierOrders();
      await _loadDividedPersonsBillSent();
      print('✅ Órdenes enviadas al cajero cargadas: $_sentToCashierOrders');
      notifyListeners();

      // 2. Cargar mesas y productos en paralelo (operaciones pesadas)
      // Hacer esto en background para no bloquear la UI
      Future.wait([_initializeTables(), _loadProductsAndCategories()])
          .then((_) {
            notifyListeners();

            // 3. DESPUÉS cargar historial de para llevar (para que el filtro funcione)
            loadTakeawayOrderHistory().then((_) {
              notifyListeners();

              // 4. Cargar historial de todas las mesas con órdenes activas
              _loadAllTablesHistory().then((_) {
                notifyListeners();
              });
            });
          })
          .catchError((e) {
            print('Error cargando datos iniciales: $e');
          });

      // 5. Socket.IO ya se conecta en AuthController.login()
      // NO conectar aquí para evitar conexiones duplicadas
      // Configurar listeners después de un breve delay para asegurar que el socket esté conectado
      // Esperar más tiempo y verificar conexión antes de configurar listeners
      Future.delayed(const Duration(milliseconds: 2000), () {
        final socketService = SocketService();
        if (socketService.isConnected) {
          _setupSocketListeners();
          print('✅ Mesero: Listeners de Socket.IO configurados');
        } else {
          print('⚠️ Mesero: Socket.IO no está conectado aún, reintentando...');
          socketService.connect().then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _setupSocketListeners();
              print('✅ Mesero: Listeners de Socket.IO configurados después de reconectar');
            });
          }).catchError((e) {
            print('❌ Mesero: Error al conectar Socket.IO: $e');
          });
        }
      });

      // 6. Cargar flags y notificaciones en background (no crítico)
      _loadClearedHistoryFlags()
          .then((_) {
            _historyCleared.forEach((tableKey, isCleared) {
              if (isCleared == true) {
                _tableOrderHistory[tableKey] = [];
              }
            });
            notifyListeners();
          })
          .catchError((e) {
            print('Error cargando flags: $e');
            return null;
          });

      _loadClearedNotifications().catchError((e) {
        print('Error cargando notificaciones: $e');
        return null;
      });

      // 7. Cargar alertas no leídas desde la BD (en background)
      _loadAlertasNoLeidas().catchError((e) {
        print('❌ Error cargando alertas no leídas: $e');
        return null;
      });

      print('✅ Mesero: Inicialización iniciada (operaciones en background)');
    } catch (e) {
      print('❌ Error en inicialización del mesero: $e');
    }
  }

  // ELIMINADO: Ya no se conecta Socket.IO aquí porque AuthController.login() 
  // ya maneja la conexión. Esto evita conexiones duplicadas que causaban
  // problemas de autenticación con usuarios incorrectos.

  // Cargar notificaciones limpiadas desde storage
  Future<void> _loadClearedNotifications() async {
    try {
      final clearedData = await _storage.read('mesero_cleared_notifications');
      if (clearedData != null) {
        final List<dynamic> clearedList = clearedData
            .split(',')
            .where((id) => id.isNotEmpty)
            .toList();
        _clearedNotifications.addAll(clearedList.map((id) => id.toString()));
      }
    } catch (e) {
      print('Error al cargar notificaciones limpiadas: $e');
    }
  }

  // Guardar notificaciones limpiadas en storage
  Future<void> _saveClearedNotifications() async {
    try {
      final clearedData = _clearedNotifications.join(',');
      await _storage.write('mesero_cleared_notifications', clearedData);
    } catch (e) {
      print('Error al guardar notificaciones limpiadas: $e');
    }
  }

  // Verificar si una notificación fue limpiada
  bool _isNotificationCleared(int ordenId, String tipo) {
    final key = '$ordenId-$tipo';
    return _clearedNotifications.contains(key);
  }

  // Marcar notificación como limpiada
  Future<void> _markNotificationAsCleared(int ordenId, String tipo) async {
    final key = '$ordenId-$tipo';
    _clearedNotifications.add(key);
    await _saveClearedNotifications();
  }

  // Cargar alertas no leídas desde la BD al iniciar sesión
  // Esto es importante para cuando el usuario hace logout/login
  // Las alertas que llegaron mientras estaba desconectado se cargan aquí
  Future<void> _loadAlertasNoLeidas() async {
    try {
      print('📥 Mesero: Cargando alertas no leídas desde la BD...');
      final alertas = await _alertasService.obtenerAlertasNoLeidas();

      print(
        '📊 Mesero: Respuesta del servicio de alertas: ${alertas.length} alertas',
      );

      if (alertas.isEmpty) {
        print('📭 Mesero: No hay alertas no leídas para cargar');
        // Aún así notificar cambios para actualizar UI
        notifyListeners();
        return;
      }

      print('📬 Mesero: ${alertas.length} alertas no leídas encontradas');
      print(
        '📋 Mesero: Detalles de alertas: ${alertas.map((a) => 'Orden ${a['ordenId']}: ${a['mensaje']}').join(', ')}',
      );

      // Procesar cada alerta y convertirla en notificación
      for (final alerta in alertas) {
        final ordenId = alerta['ordenId'] as int?;
        final mensaje = alerta['mensaje'] as String?;
        final metadata = alerta['metadata'] as Map<String, dynamic>? ?? {};

        if (ordenId == null || mensaje == null) continue;

        // Usar metadata.estado si está disponible, si no, inferir del mensaje
        String tipo = 'listo';
        String? estado = metadata['estado'] as String?;

        if (estado == null) {
          // Intentar determinar el tipo de alerta desde el mensaje (compatibilidad hacia atrás)
          final mensajeLower = mensaje.toLowerCase();
          if (mensajeLower.contains('preparación') ||
              mensajeLower.contains('preparacion')) {
            tipo = 'preparacion';
            estado = 'preparacion';
          } else if (mensajeLower.contains('listo')) {
            tipo = 'listo';
            estado = 'listo';
          } else if (mensajeLower.contains('cancel') || mensajeLower.contains('cancelación') || mensajeLower.contains('cancelado')) {
            tipo = 'cancelada';
            estado = 'cancelada';
          }
        } else {
          if (estado == 'preparacion') {
            tipo = 'preparacion';
          } else if (estado == 'cancelada' || estado == 'cancelado') {
            tipo = 'cancelada';
          } else {
            tipo = 'listo';
          }
        }

        // Verificar si la notificación ya fue limpiada
        if (_isNotificationCleared(ordenId, tipo)) {
          print(
            '🚫 Mesero: Alerta de orden $ordenId (tipo: $tipo) ya fue limpiada, ignorando',
          );
          continue;
        }

        // Determinar si es para llevar o de mesa
        final mesaId = alerta['mesaId'] as int?;
        final isTakeaway = metadata['isTakeaway'] as bool? ?? (mesaId == null);
        final mesaCodigo = metadata['mesaCodigo'] as String?;

        // Crear título y mensaje de notificación
        String tituloNotificacion;
        String mensajeNotificacion;

        if (estado == 'preparacion') {
          tituloNotificacion = 'Pedido en Preparación';
          mensajeNotificacion = mensaje;
        } else if (estado == 'cancelada' || estado == 'cancelado' || tipo == 'cancelada') {
          // Es cancelación
          tituloNotificacion = '❌ Orden Cancelada';
          mensajeNotificacion = mensaje; // Usar el mensaje completo que incluye "Cocinero canceló..."
        } else {
          // Es "listo"
          if (isTakeaway) {
            tituloNotificacion = 'Pedido Para Llevar Listo';
            mensajeNotificacion = 'Pedido #$ordenId está listo para recoger';
          } else if (mesaCodigo != null) {
            tituloNotificacion = 'Pedido Listo';
            mensajeNotificacion =
                'Pedido #$ordenId de ${TableModel.displayLabelFromCodigo(mesaCodigo)} está listo para servir';
          } else {
            tituloNotificacion = 'Pedido Listo';
            mensajeNotificacion = mensaje;
          }
        }

        // Usar creadoEn de la alerta para que "Hace X min/h" sea correcto (evita mostrar 6h por zona horaria)
        DateTime? alertaCreatedAt;
        final creadoEnRaw = alerta['creadoEn'];
        if (creadoEnRaw != null) {
          alertaCreatedAt = date_utils.AppDateUtils.parseToLocal(creadoEnRaw);
        }

        // Agregar notificación
        print(
          '📝 Mesero: Agregando notificación - Título: $tituloNotificacion, Mensaje: $mensajeNotificacion, OrdenId: $ordenId, Tipo: $tipo',
        );

        final meseroNombreCarga = metadata['meseroNombre'] as String?;
        addNotification(
          tituloNotificacion,
          mensajeNotificacion,
          ordenId: ordenId,
          tipo: tipo,
          createdAt: alertaCreatedAt,
          meseroNombre: meseroNombreCarga,
        );

        print(
          '✅ Mesero: Notificación agregada exitosamente - $tituloNotificacion: $mensajeNotificacion (estado: $estado)',
        );
      }

      // SIEMPRE notificar cambios para actualizar UI, incluso si no hay alertas
      notifyListeners();
      print(
        '📊 Mesero: Total de notificaciones después de cargar alertas: ${_pendingNotifications.length}',
      );
      print(
        '📊 Mesero: Notificaciones actuales: ${_pendingNotifications.map((n) => '${n['title']}: ${n['message']}').join(', ')}',
      );
    } catch (e) {
      print('❌ Error al cargar alertas no leídas: $e');
    }
  }

  // Cargar órdenes enviadas al cajero desde storage
  Future<void> _loadSentToCashierOrders() async {
    try {
      final data = await _storage.read('mesero_sent_to_cashier_orders');
      print('📋 Storage data leído: $data');
      if (data != null && data.isNotEmpty) {
        final ids = data.split(',').where((id) => id.isNotEmpty);
        for (final id in ids) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            _sentToCashierOrders.add(parsed);
          }
        }
        print(
          '📋 Cargadas ${_sentToCashierOrders.length} órdenes enviadas al cajero: $_sentToCashierOrders',
        );
      } else {
        print('📋 No hay órdenes enviadas al cajero guardadas');
      }
    } catch (e) {
      print('Error al cargar órdenes enviadas al cajero: $e');
    }
  }

  // Guardar órdenes enviadas al cajero en storage
  Future<void> _saveSentToCashierOrders() async {
    try {
      final data = _sentToCashierOrders.map((id) => id.toString()).join(',');
      await _storage.write('mesero_sent_to_cashier_orders', data);
    } catch (e) {
      print('Error al guardar órdenes enviadas al cajero: $e');
    }
  }

  // Helper: Marcar orden como cerrada en el backend
  // Esta es la FUENTE DE VERDAD para persistir entre reinicios de la app
  Future<bool> _marcarOrdenComoCerradaEnBackend(int ordenId) async {
    try {
      final estados = await _ordenesService.getEstadosOrden();
      print(
        '📋 Estados disponibles en backend: ${estados.map((e) => e['nombre']).toList()}',
      );

      // Buscar estado "cerrada", "enviada", "cobrada" o similar
      final estadoCerrada = estados.firstWhere((e) {
        final nombre = (e['nombre'] as String?)?.toLowerCase() ?? '';
        return nombre.contains('cerrada') ||
            nombre.contains('enviada') ||
            nombre.contains('cobrada') ||
            nombre.contains('entregada') ||
            nombre.contains('pagada');
      }, orElse: () => {'id': null});

      final estadoId = estadoCerrada['id'] as int?;
      if (estadoId != null) {
        await _ordenesService.cambiarEstado(ordenId, estadoId);
        print(
          '✅ Orden $ordenId marcada como "${estadoCerrada['nombre']}" en backend (ID: $estadoId)',
        );
        return true;
      } else {
        print(
          '⚠️ No se encontró estado "cerrada" en backend. Estados disponibles: ${estados.map((e) => e['nombre']).toList()}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al marcar orden como cerrada en backend: $e');
      return false;
    }
  }

  // Cargar flags de historial limpiado desde storage
  Future<void> _loadClearedHistoryFlags() async {
    try {
      final clearedTablesJson =
          await _storage.read('cleared_table_history') ?? '{}';
      // Parsear JSON simple: {"1":true,"2":true}
      final clearedTables = <String, bool>{};
      if (clearedTablesJson != '{}' && clearedTablesJson.isNotEmpty) {
        final entries = clearedTablesJson
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',');
        for (final entry in entries) {
          if (entry.isNotEmpty) {
            final parts = entry.split(':');
            if (parts.length == 2) {
              final tableId = parts[0]
                  .trim()
                  .replaceAll('"', '')
                  .replaceAll("'", '');
              final isCleared = parts[1].trim() == 'true';
              if (tableId.isNotEmpty) {
                clearedTables[tableId] = isCleared;
              }
            }
          }
        }
      }
      _historyCleared.addAll(clearedTables);
      final clearedTablesList = _historyCleared.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();
      print('📋 Mesero: Historiales limpiados cargados: $clearedTablesList');
      print(
        '📋 Mesero: Total de mesas con historial limpiado: ${clearedTablesList.length}',
      );

      // Limpiar el historial en memoria para las mesas que fueron limpiadas
      for (final tableKey in clearedTablesList) {
        _tableOrderHistory[tableKey] = [];
      }
    } catch (e) {
      print('Error al cargar flags de historial limpiado: $e');
    }
  }

  // No guardar historial localmente - Backend es fuente de verdad
  Future<void> _savePersistedHistory() async {
    // No hacer nada - el historial se carga siempre del backend
  }

  static String _dividirCuentaKey(String tableId) =>
      'mesero_dividir_cuenta_$tableId';

  /// Persiste el estado de "dividir cuenta" para una mesa (nombres y asignaciones).
  /// Así al cerrar sesión y volver a entrar, se restaura la interfaz de división.
  Future<void> _persistDividedAccountState(String tableId) async {
    try {
      final names = _personNamesByTable[tableId];
      if (names == null || names.isEmpty) return;
      final assignments = _personCartItemsByTable[tableId];
      final selectedId = _selectedPersonIdByTable[tableId];
      final nextId = _nextPersonIdByTable[tableId] ?? 1;
      final payload = {
        'personNames': names,
        'personAssignments': assignments ?? {},
        'selectedPersonId': selectedId,
        'nextPersonId': nextId,
      };
      await _storage.write(_dividirCuentaKey(tableId), jsonEncode(payload));
    } catch (e) {
      print('⚠️ Mesero: Error al persistir estado dividir cuenta: $e');
    }
  }

  /// Restaura desde storage el estado de "dividir cuenta" para una mesa.
  /// Devuelve true si se restauró algo (personNames no vacío).
  Future<bool> _restoreDividedAccountState(String tableId) async {
    try {
      final raw = await _storage.read(_dividirCuentaKey(tableId));
      if (raw == null || raw.isEmpty) return false;
      final data = jsonDecode(raw) as Map<String, dynamic>?;
      if (data == null) return false;
      final personNames = data['personNames'] as Map<String, dynamic>?;
      if (personNames == null || personNames.isEmpty) return false;
      final names = personNames.map((k, v) => MapEntry(k, v.toString()));
      _personNamesByTable[tableId] = names;
      _isDividedAccountModeByTable[tableId] = true;
      if (!_personCartItemsByTable.containsKey(tableId)) {
        _personCartItemsByTable[tableId] = {};
      }
      final assignments = data['personAssignments'] as Map<String, dynamic>?;
      if (assignments != null) {
        for (final e in assignments.entries) {
          final list = e.value;
          if (list is List) {
            _personCartItemsByTable[tableId]![e.key] =
                list.map((x) => x.toString()).toList();
          }
        }
      }
      final nextId = data['nextPersonId'] as int?;
      if (nextId != null) _nextPersonIdByTable[tableId] = nextId;
      final selectedId = data['selectedPersonId'] as String?;
      if (selectedId != null && names.containsKey(selectedId)) {
        _selectedPersonIdByTable[tableId] = selectedId;
      } else if (names.isNotEmpty) {
        _selectedPersonIdByTable[tableId] = names.keys.first;
      }
      return true;
    } catch (e) {
      print('⚠️ Mesero: Error al restaurar estado dividir cuenta: $e');
      return false;
    }
  }

  // Guardar flags de historial limpiado en storage
  Future<void> _saveClearedHistoryFlags() async {
    try {
      // Convertir mapa a JSON simple
      final clearedEntries = _historyCleared.entries
          .where((e) => e.value == true) // Solo guardar los que están limpiados
          .toList();

      if (clearedEntries.isEmpty) {
        await _storage.write('cleared_table_history', '{}');
        print('💾 Mesero: No hay historiales limpiados para guardar');
        return;
      }

      final entries = clearedEntries
          .map((e) => '"${e.key}":${e.value}')
          .join(',');
      final json = '{$entries}';

      print(
        '💾 Mesero: Guardando historiales limpiados: ${clearedEntries.map((e) => e.key).toList()}',
      );
      await _storage.write('cleared_table_history', json);

      // Verificar que se guardó correctamente
      final verification = await _storage.read('cleared_table_history');
      print(
        '✅ Mesero: Historiales limpiados guardados: ${clearedEntries.map((e) => e.key).toList()}',
      );
      print('✅ Mesero: Verificación de storage: $verification');
    } catch (e) {
      print('❌ Mesero: Error al guardar flags de historial limpiado: $e');
      rethrow; // Re-lanzar para que se pueda manejar el error
    }
  }

  // Configurar listeners de Socket.IO
  // NUEVO SISTEMA SIMPLIFICADO: Backend es fuente de verdad
  Future<void> _setupSocketListeners() async {
    if (_socketListenersConfigured) {
      print('ℹ️ Mesero: Listeners de Socket ya estaban configurados, omitiendo');
      return;
    }
    final socketService = SocketService();
    
    // Verificar que Socket.IO esté conectado antes de configurar listeners
    if (!socketService.isConnected) {
      print('⚠️ Mesero: Socket.IO no está conectado, esperando conexión...');
      // Esperar hasta 5 segundos para que se conecte
      int attempts = 0;
      while (attempts < 10 && !socketService.isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      if (!socketService.isConnected) {
        print('❌ Mesero: Socket.IO no se conectó después de esperar, intentando reconectar...');
        try {
          await socketService.connect();
        } catch (e) {
          print('❌ Mesero: Error al reconectar Socket.IO: $e');
          return; // Los listeners se configurarán en el siguiente intento
        }
        if (!socketService.isConnected) return;
      }
    }
    
    print('✅ Mesero: Socket.IO está conectado, configurando listeners...');
    _socketListenersConfigured = true;

    // Cuando admin habilita/deshabilita un producto (o lo edita), recargar menú para reflejar cambios
    socketService.onProductoActualizado((_) {
      loadProducts();
    });

    // Estados FINALIZADOS que deben remover la orden del historial
    final estadosFinalizados = [
      'pagada',
      'cancelada',
      'cerrada',
      'cobrada',
      'entregada',
      'enviada',
    ];

    // Escuchar actualizaciones de órdenes
    socketService.onOrderUpdated((data) async {
      try {
        final ordenId = data['id'] as int?;
        final estadoNombre = data['estadoNombre'] as String?;
        final mesaId = data['mesaId'] as int?;
        final mesaCodigo = data['mesaCodigo'] as String?;
        final tiempoEstimadoNuevo =
            data['tiempoEstimadoPreparacion'] ?? data['estimatedTime'];

        // CRÍTICO: capturar tiempo anterior ANTES de mutar el historial (si no, la notificación nunca sale)
        int? tiempoEstimadoAnterior;
        if (ordenId != null && tiempoEstimadoNuevo != null) {
          for (final orders in _tableOrderHistory.values) {
            for (final o in orders) {
              if (o['ordenId'] == ordenId) {
                tiempoEstimadoAnterior = o['estimatedTime'] as int?;
                break;
              }
            }
          }
        }

        if (ordenId != null && estadoNombre != null) {
          final estadoLower = estadoNombre.toLowerCase();

          // Verificar si es un estado finalizado
          bool esEstadoFinalizado = false;
          for (final estadoFinal in estadosFinalizados) {
            if (estadoLower.contains(estadoFinal)) {
              esEstadoFinalizado = true;
              break;
            }
          }

          // Actualizar o remover orden del historial
          _tableOrderHistory.forEach((tableId, orders) {
            // Actualizar el estado de la orden
            for (var order in orders) {
              if (order['ordenId'] == ordenId) {
                order['status'] = estadoNombre;
                final tiempoEstimado =
                    data['tiempoEstimadoPreparacion'] ??
                    data['estimatedTime'];
                if (tiempoEstimado != null) {
                  final tiempoAnterior = order['estimatedTime'] as int?;
                  order['estimatedTime'] = tiempoEstimado;
                  
                  // Si el tiempo cambió, mostrar notificación
                  if (tiempoAnterior != null && tiempoAnterior != tiempoEstimado) {
                    // La notificación se mostrará más abajo en el código
                    print('⏱️ Mesero: Tiempo estimado actualizado para orden $ordenId: $tiempoAnterior -> $tiempoEstimado min');
                  }
                }
                break;
              }
            }

            // IMPORTANTE: Para órdenes "para llevar", NO remover por estado finalizado
            // Solo se deben remover cuando se cierra la cuenta y se envía al cajero (tienen bill pendiente)
            // Las órdenes deben permanecer visibles durante todo el proceso: pendiente -> en preparación -> listo -> listo para recoger
            final isTakeawayTable = tableId.startsWith('takeaway') || tableId == 'takeaway-all';
            if (isTakeawayTable) {
              // Para takeaway, NO remover por estado, solo actualizar el estado
              // La orden se removerá cuando tenga un bill pendiente (en loadTakeawayOrderHistory)
              print('📝 Orden $ordenId (takeaway) actualizada a estado: $estadoNombre (permanece visible)');
            } else {
              // Para órdenes de mesa, sí remover si es estado finalizado
              if (esEstadoFinalizado) {
                final antes = orders.length;
                orders.removeWhere((o) => o['ordenId'] == ordenId);
                if (orders.length < antes) {
                  print(
                    '🗑️ Orden $ordenId removida del historial de mesa (estado: $estadoLower)',
                  );
                }
              }
            }
          });

          // Si es para llevar, SIEMPRE recargar historial para actualizar estados en tiempo real
          // PERO NO remover órdenes por estado, solo por bills pendientes
          if (mesaId == null) {
            // Actualizar el estado en el historial local primero
            _tableOrderHistory.forEach((tableId, orders) {
              if (tableId.startsWith('takeaway') || tableId == 'takeaway-all') {
                for (var order in orders) {
                  if (order['ordenId'] == ordenId) {
                    order['status'] = estadoNombre;
                    break;
                  }
                }
              }
            });
            
            // Recargar desde backend para asegurar sincronización y actualizar items si es necesario
            // Este método solo filtrará órdenes con bills pendientes, NO por estado
            await loadTakeawayOrderHistory();
          }

          notifyListeners();

          // Tiempo estimado: comparar con valor capturado antes de mutar órdenes
          if (tiempoEstimadoNuevo != null) {
            final cambioTiempo = tiempoEstimadoAnterior == null ||
                tiempoEstimadoAnterior != tiempoEstimadoNuevo;
            if (cambioTiempo) {
              final mesaInfo = mesaCodigo != null && mesaCodigo.isNotEmpty
                  ? TableModel.displayLabelFromCodigo(mesaCodigo)
                  : 'Para llevar';
              final deTxt = tiempoEstimadoAnterior != null
                  ? '${tiempoEstimadoAnterior} min → ${tiempoEstimadoNuevo} min'
                  : '${tiempoEstimadoNuevo} min';
              addNotification(
                '⏱️ Tiempo estimado actualizado',
                'Orden $ordenId ($mesaInfo): $deTxt',
                ordenId: ordenId,
                tipo: 'info',
              );
            }
          }

          // Mostrar notificación para estados importantes
          final esEstadoImportante =
              estadoLower.contains('preparacion') ||
              estadoLower.contains('preparación') ||
              estadoLower.contains('cooking') ||
              estadoLower.contains('iniciar') ||
              estadoLower.contains('listo');

          if (esEstadoImportante) {
            // Intentar determinar si es para llevar desde el historial local o del evento
            final isTakeawayFromData =
                data['isTakeaway'] as bool? ??
                data['esParaLlevar'] as bool? ??
                estadoLower.contains('recoger');

            // Buscar también en el historial local
            bool isTakeaway = isTakeawayFromData;
            if (!isTakeaway) {
              for (var orders in _tableOrderHistory.values) {
                final orderFound = orders.firstWhere(
                  (o) => o['ordenId'] == ordenId,
                  orElse: () => <String, dynamic>{},
                );
                if (orderFound.isNotEmpty) {
                  isTakeaway = orderFound['isTakeaway'] == true;
                  break;
                }
              }
            }

            final notificacion = _crearNotificacionOrden(
              ordenId: ordenId,
              estadoNombre: estadoNombre,
              mesaId: mesaId,
              mesaCodigo: mesaCodigo,
              isTakeaway: isTakeaway,
            );

            final tipoNotif = estadoLower.contains('listo')
                ? 'listo'
                : 'preparacion';

            if (!_isNotificationCleared(ordenId, tipoNotif)) {
              addNotification(
                notificacion['titulo']!,
                notificacion['mensaje']!,
                ordenId: ordenId,
                tipo: tipoNotif,
              );
            }
          }
        }
      } catch (e) {
        print('Error al procesar actualización de orden: $e');
      }
    });

    // Escuchar cancelaciones de órdenes
    socketService.onOrderCancelled((data) async {
      try {
        final ordenId = data['id'] as int?;
        final mesaId = data['mesaId'] as int?;

        print('🔔 Mesero: Orden cancelada recibida - OrdenId: $ordenId, MesaId: $mesaId');

        if (ordenId != null) {
          // Remover de todos los historiales INMEDIATAMENTE (para que desaparezca de la UI al instante)
          String? mesaKeyRemovida;
          
          _tableOrderHistory.forEach((tableId, orders) {
            final antes = orders.length;
            orders.removeWhere((order) => order['ordenId'] == ordenId);
            if (orders.length < antes) {
              mesaKeyRemovida = tableId;
              print('🗑️ Mesero: Orden $ordenId removida del historial de mesa/tableId: $tableId');
            }
          });
          
          // Si es una orden para llevar, también remover del historial de takeaway
          if (mesaId == null) {
            // Buscar en historiales de takeaway
            _tableOrderHistory.forEach((tableId, orders) {
              if (tableId.startsWith('takeaway-') || tableId == 'takeaway-all') {
                final antes = orders.length;
                orders.removeWhere((order) => order['ordenId'] == ordenId);
                if (orders.length < antes) {
                  print('🗑️ Mesero: Orden $ordenId removida del historial de takeaway: $tableId');
                }
              }
            });
          }
          
          notifyListeners();

          // Recargar historial desde el backend para asegurar que la orden cancelada no vuelva a aparecer
          // Esto es importante especialmente si la orden estaba "en medio" del historial
          if (mesaId != null && mesaKeyRemovida != null) {
            try {
              await loadTableOrderHistory(mesaId);
              print('✅ Mesero: Historial de mesa $mesaId recargado después de cancelación');
            } catch (e) {
              print('⚠️ Mesero: Error al recargar historial después de cancelación: $e');
            }
          } else if (mesaId == null) {
            // Es orden para llevar, recargar historial de takeaway
            try {
              await loadTakeawayOrderHistory();
              print('✅ Mesero: Historial de takeaway recargado después de cancelación');
            } catch (e) {
              print('⚠️ Mesero: Error al recargar historial de takeaway después de cancelación: $e');
            }
          }

          addNotification(
            '❌ Orden Cancelada',
            'La orden #$ordenId ha sido cancelada',
            ordenId: ordenId,
            tipo: 'cancelada',
          );
        }
      } catch (e) {
        print('Error al procesar cancelación de orden: $e');
      }
    });

    // Escuchar alertas de cancelación específicas (incluye cuando cocinero cancela)
    socketService.onAlertaCancelacion((data) async {
      try {
        final ordenId = data['ordenId'] as int?;
        final mensaje = data['mensaje'] as String? ?? 'Orden cancelada';
        final emisor = data['emisor'] as Map<String, dynamic>?;
        final rolEmisor = emisor?['rol'] as String?;
        final mesaId = data['mesaId'] as int?;

        print('🔔 Mesero: Alerta de cancelación recibida - OrdenId: $ordenId, Mensaje: $mensaje, Emisor: $rolEmisor, MesaId: $mesaId');

        if (ordenId != null) {
          // Remover de todos los historiales INMEDIATAMENTE (para que desaparezca de la UI al instante)
          String? mesaKeyRemovida;
          
          _tableOrderHistory.forEach((tableId, orders) {
            final antes = orders.length;
            orders.removeWhere((order) => order['ordenId'] == ordenId);
            if (orders.length < antes) {
              mesaKeyRemovida = tableId;
              print('🗑️ Mesero: Orden $ordenId removida del historial de mesa/tableId: $tableId');
            }
          });
          
          // Si es una orden para llevar, también remover del historial de takeaway
          if (mesaId == null) {
            // Buscar en historiales de takeaway
            _tableOrderHistory.forEach((tableId, orders) {
              if (tableId.startsWith('takeaway-') || tableId == 'takeaway-all') {
                final antes = orders.length;
                orders.removeWhere((order) => order['ordenId'] == ordenId);
                if (orders.length < antes) {
                  print('🗑️ Mesero: Orden $ordenId removida del historial de takeaway: $tableId');
                }
              }
            });
          }
          
          notifyListeners();

          // Recargar historial desde el backend para asegurar que la orden cancelada no vuelva a aparecer
          // Esto es importante especialmente si la orden estaba "en medio" del historial
          if (mesaId != null && mesaKeyRemovida != null) {
            try {
              await loadTableOrderHistory(mesaId);
              print('✅ Mesero: Historial de mesa $mesaId recargado después de cancelación');
            } catch (e) {
              print('⚠️ Mesero: Error al recargar historial después de cancelación: $e');
            }
          } else if (mesaId == null) {
            // Es orden para llevar, recargar historial de takeaway
            try {
              await loadTakeawayOrderHistory();
              print('✅ Mesero: Historial de takeaway recargado después de cancelación');
            } catch (e) {
              print('⚠️ Mesero: Error al recargar historial de takeaway después de cancelación: $e');
            }
          }

          // Usar el mensaje específico de la alerta (ya incluye "Cocinero canceló la orden X" si fue cocinero)
          addNotification(
            '❌ Orden Cancelada',
            mensaje,
            ordenId: ordenId,
            tipo: 'cancelada',
          );
        }
      } catch (e) {
        print('Error al procesar alerta de cancelación: $e');
      }
    });

    // Escuchar actualizaciones de mesas
    socketService.onAlertaMesa((data) {
      try {
        // Recargar mesas cuando haya cambios
        loadTables();
      } catch (e) {
        print('Error al procesar actualización de mesa: $e');
      }
    });

    // Escuchar eventos de mesas
    socketService.onTableCreated((data) {
      try {
        final mesaId = data['id'] as int?;
        final ubicacion = data['ubicacion'] as String?;
        print(
          '📢 Mesero: Mesa creada recibida vía socket - Mesa ID: $mesaId, Área: $ubicacion',
        );
        // Recargar mesas cuando se crea una nueva (puede tener un área nueva)
        // Esto asegura que las áreas nuevas creadas en admin se reflejen en mesero
        loadTables();
        notifyListeners();
        print(
          '✅ Mesero: Mesas recargadas después de creación (área nueva sincronizada)',
        );
      } catch (e) {
        print('Error al procesar mesa creada en mesero: $e');
      }
    });

    socketService.onTableUpdated((data) {
      try {
        final mesaId = data['id'] as int?;
        final estadoNombre = data['estadoNombre'] as String?;
        final ubicacion = data['ubicacion'] as String?;
        print(
          '📢 Mesero: Mesa actualizada recibida vía socket - Mesa ID: $mesaId, Estado: $estadoNombre, Área: $ubicacion',
        );

        // Recargar mesas cuando se actualiza una mesa (desde otro rol)
        // Esto asegura que los cambios del admin (incluyendo cambios de área) se reflejen en mesero
        // Usar un pequeño delay para agrupar múltiples actualizaciones si vienen en rápida sucesión
        Future.delayed(const Duration(milliseconds: 200), () async {
          try {
            await loadTables();
            notifyListeners();
            print(
              '✅ Mesero: Mesas recargadas después de actualización de área',
            );
          } catch (e) {
            print('❌ Error al recargar mesas en mesero: $e');
          }
        });
      } catch (e) {
        print('Error al procesar mesa actualizada en mesero: $e');
      }
    });

    socketService.onTableDeleted((data) {
      try {
        final mesaId = data['id'] as int?;
        print(
          '📢 Mesero: Mesa eliminada recibida vía socket - Mesa ID: $mesaId',
        );

        // Eliminar la mesa de la lista local inmediatamente
        if (mesaId != null) {
          _tables.removeWhere((t) => t.id == mesaId);
          // Si la mesa eliminada estaba seleccionada, deseleccionarla
          if (_selectedTable?.id == mesaId) {
            _selectedTable = null;
          }
          notifyListeners();
          print('✅ Mesero: Mesa $mesaId eliminada de la lista local');
        }

        // Recargar mesas desde el backend para asegurar sincronización completa
        loadTables();
      } catch (e) {
        print('❌ Error al procesar mesa eliminada en mesero: $e');
        // Si hay error, recargar desde el backend
        loadTables();
      }
    });

    // Escuchar alertas de cocina (pedido listo/preparación) - OPTIMIZADO
    socketService.onAlertaCocina((data) {
      try {
        print('🔔 Mesero: Alerta de cocina recibida: $data');

        // Verificar si es una alerta de preparación o de listo
        // El estado puede venir directamente en data['estado'] O en data['metadata']['estado']
        final metadata = data['metadata'] as Map<String, dynamic>?;
        final estado =
            (data['estado'] as String?) ?? (metadata?['estado'] as String?);
        final ordenId = data['ordenId'] as int?;
        final mensaje = data['mensaje'] as String?;

        print('📋 Mesero: Estado parseado: $estado, ordenId: $ordenId');

        // Si es alerta de preparación, agregar notificación Y actualizar historial
        if (estado == 'preparacion' && ordenId != null && mensaje != null) {
          final mesaId = data['mesaId'] as int?;
          final isTakeaway = metadata?['isTakeaway'] as bool? ?? false;

          // Actualizar estado en el historial INMEDIATAMENTE
          bool estadoActualizado = false;
          _tableOrderHistory.forEach((tableId, orders) {
            for (var order in orders) {
              if (order['ordenId'] == ordenId) {
                order['status'] = 'En Preparación';
                estadoActualizado = true;
                notifyListeners(); // Notificar cambios inmediatamente
                break;
              }
            }
          });

          // Si la orden no está en el historial, intentar agregarla
          if (!estadoActualizado) {
            // Para órdenes "para llevar", buscar en historial de takeaway
            if (isTakeaway || mesaId == null) {
              _tableOrderHistory.forEach((tableId, orders) {
                if (tableId.startsWith('takeaway-')) {
                  for (var order in orders) {
                    if (order['ordenId'] == ordenId) {
                      order['status'] = 'En Preparación';
                      estadoActualizado = true;
                      notifyListeners();
                      break;
                    }
                  }
                }
              });
            }
          }

          final meseroNombre = metadata?['meseroNombre'] as String?;
          // Verificar si la notificación ya fue limpiada
          if (!_isNotificationCleared(ordenId, 'preparacion')) {
            addNotification(
              'Pedido en Preparación',
              mensaje,
              ordenId: ordenId,
              tipo: 'preparacion',
              meseroNombre: meseroNombre,
            );
            print(
              '✅ Mesero: Notificación de preparación agregada desde alerta.cocina - $mensaje',
            );
            print(
              '✅ Mesero: Estado actualizado en historial para orden $ordenId',
            );
          } else {
            print(
              '🚫 Mesero: Notificación de preparación ignorada porque ya fue limpiada',
            );
          }
          return; // No procesar más si es alerta de preparación
        }

        // Continuar con el procesamiento normal de alertas de "listo"
        // (si estado es 'listo' o no hay estado especificado - compatibilidad hacia atrás)
        // Si el estado es algo diferente de 'listo' o null, y NO es 'preparacion' (ya procesado arriba), ignorar
        if (estado != null && estado != 'listo') {
          // Si ya se procesó como preparación, no debería llegar aquí
          if (estado == 'preparacion') {
            return; // Ya se procesó arriba, esto no debería pasar
          }
          print('⚠️ Mesero: Estado desconocido: $estado, ignorando alerta');
          return;
        }

        // Si llegamos aquí, es una alerta de "listo" (estado == 'listo' o null)

        final mesaId = data['mesaId'] as int?;
        final mesaCodigo = metadata?['mesaCodigo'] as String?;
        final isTakeaway = metadata?['isTakeaway'] as bool? ?? false;

        if (ordenId != null) {
          print(
            '🔔 Mesero: Procesando alerta de LISTO para orden $ordenId (isTakeaway: $isTakeaway)',
          );

          // Actualizar estado en el historial INMEDIATAMENTE
          bool estadoActualizado = false;
          final nuevoStatus = isTakeaway ? 'Listo para Recoger' : 'Listo';

          _tableOrderHistory.forEach((tableId, orders) {
            for (var order in orders) {
              if (order['ordenId'] == ordenId) {
                order['status'] = nuevoStatus;
                estadoActualizado = true;
                print(
                  '✅ Mesero: Estado actualizado a "$nuevoStatus" para orden $ordenId en historial "$tableId"',
                );
                break;
              }
            }
          });

          if (!estadoActualizado) {
            print(
              '⚠️ Mesero: Orden $ordenId no encontrada en ningún historial local',
            );
          }

          // Crear mensaje más descriptivo para la notificación
          String tituloNotificacion;
          String mensajeNotificacion;

          if (isTakeaway) {
            tituloNotificacion = 'Pedido Para Llevar Listo';
            mensajeNotificacion = 'Pedido #$ordenId está listo para recoger';
          } else if (mesaCodigo != null) {
            tituloNotificacion = 'Pedido Listo';
            mensajeNotificacion =
                'Pedido #$ordenId de ${TableModel.displayLabelFromCodigo(mesaCodigo)} está listo para servir';
          } else if (mesaId != null) {
            tituloNotificacion = 'Pedido Listo';
            mensajeNotificacion =
                'Pedido #$ordenId de ${TableModel.displayLabelFromCodigo(null, mesaId)} está listo para servir';
          } else {
            tituloNotificacion = 'Pedido Listo';
            mensajeNotificacion = 'Pedido #$ordenId está listo';
          }

          final meseroNombre = metadata?['meseroNombre'] as String?;
          // Verificar si la notificación ya fue limpiada antes de agregarla
          if (!_isNotificationCleared(ordenId, 'listo')) {
            // Agregar notificación INMEDIATAMENTE (esto actualiza el icono de campanita)
            // Usar ordenId y tipo para evitar duplicados
            addNotification(
              tituloNotificacion,
              mensajeNotificacion,
              ordenId: ordenId,
              tipo:
                  'listo', // Tipo fijo porque alerta.cocina siempre es para pedido listo
              meseroNombre: meseroNombre,
            );
          } else {
            print(
              '🚫 Mesero: Notificación de orden $ordenId (tipo: listo) ignorada porque ya fue limpiada',
            );
          }

          print(
            '✅ Mesero: Notificación agregada - $tituloNotificacion: $mensajeNotificacion (ordenId: $ordenId)',
          );
          print(
            '📊 Total de notificaciones pendientes: ${_pendingNotifications.length}',
          );

          // Notificar cambios INMEDIATAMENTE
          if (estadoActualizado) {
            notifyListeners();
          }

          // Si hay mesaId, recargar el historial de esa mesa (en background)
          // Siempre recargar historial del backend para obtener órdenes activas
          if (mesaId != null) {
            loadTableOrderHistory(mesaId);
          }
        } else {
          print('⚠️ Mesero: Alerta recibida sin ordenId: $data');
        }
      } catch (e, stackTrace) {
        print('❌ Error al procesar alerta de cocina en mesero: $e');
        print('Stack trace: $stackTrace');
      }
    });

    // Escuchar alertas nuevas de cocina (nuevo sistema) para mostrarlas al mesero
    _kitchenAlertsService?.dispose();
    _kitchenAlertsService = KitchenAlertsService(socketService);
    _kitchenAlertsService!.listenNewAlerts((KitchenAlert alert) {
      try {
        final createdByRole =
            (alert.createdByRole ?? '').toLowerCase().trim();
        final createdByUsername = alert.createdByUsername;
        final isFromKitchen =
            createdByRole == 'cocinero' || createdByRole == 'cocina';
        final isSameMesero = createdByUsername != null &&
            _loggedUserName != null &&
            createdByUsername.trim().toLowerCase() ==
                _loggedUserName!.trim().toLowerCase();

        // Evitar ruido: este evento se usa principalmente para cocina/capitán.
        // En mesero solo mostrar cuando realmente venga de cocina.
        if (!isFromKitchen || isSameMesero) {
          return;
        }

        final mesaCodigo = alert.mesaCodigo ?? alert.tableId?.toString();
        final senderLabel = (createdByUsername != null &&
                createdByUsername.isNotEmpty)
            ? '$createdByUsername ($createdByRole)'
            : createdByRole;

        final titulo = '🚨 Alerta a cocina';
        final mensaje = mesaCodigo != null && mesaCodigo.isNotEmpty
            ? '${TableModel.displayLabelFromCodigo(mesaCodigo)} - ${alert.message} ($senderLabel)'
            : '${alert.message} ($senderLabel)';

        addNotification(
          titulo,
          mensaje,
          ordenId: alert.orderId,
          tipo: 'kitchen-alert-${alert.type.name}',
        );
      } catch (e) {
        print('❌ Mesero: Error al procesar kitchen:alert:new: $e');
      }
    });
  }

  // Mapa para guardar ordenId por mesa
  final Map<String, int> _tableOrderIds = {};

  // Cargar mesas desde el backend
  Future<void> loadTables() async {
    try {
      final backendMesas = await _mesasService.getMesas();
      // Filtrar mesas inactivas (activo = false) - el backend marca como inactivo en lugar de eliminar
      final mesasActivas = backendMesas.where((m) {
        final data = m as Map<String, dynamic>;
        return (data['activo'] as bool?) ?? true; // Solo incluir mesas activas
      }).toList();

      _tables = mesasActivas
          .map((json) => _mapBackendToTableModel(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
      print('✅ Mesero: ${_tables.length} mesas activas cargadas');
    } catch (e) {
      print('❌ Error al cargar mesas: $e');
      // Mantener último estado en memoria para no vaciar UI por fallo transitorio.
      notifyListeners();
    }
  }

  /// Recarga datos clave cuando el usuario regresa a la pestaña/pantalla
  /// (desbloqueo del celular, cambio de app, etc.).
  ///
  /// Evita que se quede la UI con listas vacías si el socket/token se cayó
  /// mientras la app estuvo en segundo plano.
  Future<void> refreshAfterResume() async {
    try {
      await loadTables();
      await Future.wait([
        loadProducts(),
        loadCategories(),
        loadTakeawayOrderHistory(),
      ]);

      // Recargar historial de mesas activas (fuente de verdad: backend)
      await _loadAllTablesHistory();

      // Después de recargar por API (para que si expiró el token, se refresque),
      // intenta reconectar el socket si sigue desconectado.
      final socketService = SocketService();
      if (!socketService.isConnected) {
        await socketService.connect();
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ Mesero: refreshAfterResume falló: $e');
    }
  }

  // Helper para mapear datos del backend a TableModel
  TableModel _mapBackendToTableModel(Map<String, dynamic> data) {
    final codigo = (data['codigo'] as String?)?.trim() ?? data['id']?.toString() ?? '0';
    final numero = int.tryParse(codigo) ?? 0;
    final estadoNombre =
        (data['estadoNombre'] as String?)?.toLowerCase() ?? 'libre';

    String status = TableStatus.libre;
    final estadoLower = estadoNombre.toLowerCase().trim();

    if (estadoLower.contains('ocupad') || estadoLower == 'ocupada') {
      status = TableStatus.ocupada;
    } else if (estadoLower.contains('limpieza') ||
        estadoLower == 'en limpieza' ||
        estadoLower == 'en-limpieza') {
      status = TableStatus.enLimpieza;
    } else if (estadoLower.contains('reservad') || estadoLower == 'reservada') {
      status = TableStatus.reservada;
    } else if (estadoLower.contains('libre') || estadoLower == 'libre') {
      status = TableStatus.libre;
    }

    final tableId = data['id'] as int;
    final x = ((numero - 1) % 3) + 1;
    final y = ((numero - 1) ~/ 3) + 1;

    final comRaw = data['comensales'];
    int? customers;
    if (comRaw is int) {
      customers = comRaw > 0 ? comRaw : null;
    } else if (comRaw is num) {
      final c = comRaw.toInt();
      customers = c > 0 ? c : null;
    }

    return TableModel(
      id: tableId,
      codigo: codigo,
      number: numero,
      status: status,
      seats: data['capacidad'] as int? ?? 4,
      customers: customers,
      orderValue: null,
      reservation: null,
      position: TablePosition(x: x, y: y),
      section: data['ubicacion'] as String?,
    );
  }

  /// Áreas (secciones) existentes a partir de las mesas cargadas (para agregar/editar mesa)
  List<String> get tableAreas {
    final areas = _tables
        .map((t) => t.section)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (areas.isEmpty) return ['Área Principal'];
    return areas;
  }

  /// True si ya existe una mesa con ese código/nombre (comparación sin distinguir mayúsculas). excludeTableId para edición.
  bool tableCodigoExists(String codigo, {int? excludeTableId}) {
    final c = codigo.trim().toLowerCase();
    if (c.isEmpty) return false;
    for (final t in _tables) {
      if (excludeTableId != null && t.id == excludeTableId) continue;
      if (t.codigo.trim().toLowerCase() == c) return true;
    }
    return false;
  }

  /// Crear nueva mesa (mesero puede agregar, no eliminar).
  Future<void> addTable(TableModel table) async {
    try {
      final estados = await _mesasService.getEstadosMesa();
      final estadoLibre = estados.firstWhere(
        (e) => (e['nombre'] as String).toLowerCase() == 'libre',
        orElse: () => estados.isNotEmpty ? estados[0] : {'id': 1},
      );
      final data = {
        'codigo': table.codigo.trim(),
        'nombre': table.codigo.trim().isNotEmpty ? table.codigo.trim() : null,
        'capacidad': table.seats,
        'ubicacion': table.section,
        'estadoMesaId': estadoLibre['id'] as int,
        'activo': true,
      };
      await _mesasService.createMesa(data);
      await loadTables();
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar mesa (mesero puede editar/renombrar).
  Future<void> updateTable(TableModel table) async {
    try {
      final data = {
        'codigo': table.codigo.trim(),
        'nombre': table.codigo.trim().isNotEmpty ? table.codigo.trim() : null,
        'capacidad': table.seats,
        'ubicacion': table.section,
      };
      await _mesasService.updateMesa(table.id, data);
      await loadTables();
    } catch (e) {
      rethrow;
    }
  }

  // Inicializar mesas (ahora desde el backend)
  Future<void> _initializeTables() async {
    await loadTables();
  }

  // Cargar productos y categorías desde el backend
  Future<void> _loadProductsAndCategories() async {
    await Future.wait([loadProducts(), loadCategories()]);
  }

  // Cargar productos desde el backend
  Future<void> loadProducts() async {
    try {
      final backendProducts = await _productosService.getProductos();
      _products = backendProducts
          .map((p) => _mapBackendToProductModel(p as Map<String, dynamic>))
          .where((p) => p.available) // Solo productos disponibles
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error al cargar productos: $e');
      // Mantener último catálogo visible si hay error temporal de red/token.
      notifyListeners();
    }
  }

  // Cargar categorías desde el backend
  Future<void> loadCategories() async {
    try {
      final backendCategories = await _categoriasService.getCategorias();
      _categories = backendCategories
          .map((c) => c as Map<String, dynamic>)
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error al cargar categorías: $e');
      // Mantener categorías actuales para evitar parpadeo/vaciado en UI.
      notifyListeners();
    }
  }

  // Mapear producto del backend a ProductModel
  ProductModel _mapBackendToProductModel(Map<String, dynamic> data) {
    // Usar el nombre real de la categoría del backend para que cada producto
    // aparezca en su categoría correcta (ej. Sandwiches, Tacos, etc.)
    final categoriaNombre =
        data['categoriaNombre'] as String? ??
        data['categoria'] as String? ??
        'Otros';

    // Mantener un ID de categoría para compatibilidad (usado si no hay categoryName)
    int categoryId = _getCategoryIdFromName(categoriaNombre);

    final tamanosRaw = data['tamanos'] as List<dynamic>? ?? [];
    final tamanos = tamanosRaw
        .map((t) => ProductSize.fromJson(t as Map<String, dynamic>))
        .toList();

    // Obtener precio (puede venir de tamanos si tiene tamaños)
    double price = 0.0;
    if (tamanos.isNotEmpty) {
      price = tamanos.first.price;
    } else {
      price = (data['precio'] as num?)?.toDouble() ?? 0.0;
    }

    return ProductModel(
      id: data['id'] as int,
      name: data['nombre'] as String,
      description: data['descripcion'] as String? ?? '',
      price: price,
      image: null,
      category: categoryId,
      categoryName: categoriaNombre,
      available: data['disponible'] as bool? ?? true,
      hot: data['picante'] as bool? ?? false,
      extras: null,
      customizations: null,
      sizes: tamanos,
      hasSizes: tamanos.isNotEmpty,
      descuentoPorcentaje: (data['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0,
      descuentoActivo: data['descuentoActivo'] as bool? ?? false,
      descuentoInicio: data['descuentoInicio'] != null
          ? date_utils.AppDateUtils.parseToLocal(data['descuentoInicio'])
          : null,
      descuentoFin: data['descuentoFin'] != null
          ? date_utils.AppDateUtils.parseToLocal(data['descuentoFin'])
          : null,
      precioOriginal: (data['precioOriginal'] as num?)?.toDouble(),
    );
  }

  // Obtener ID de categoría desde el nombre (solo para compatibilidad cuando no se usa categoryName)
  int _getCategoryIdFromName(String categoryName) {
    final normalized = categoryName.toLowerCase();
    if (normalized.contains('taco')) {
      return ProductCategory.tacos;
    } else if (normalized.contains('plato') ||
        normalized.contains('especial')) {
      return ProductCategory.platosEspeciales;
    } else if (normalized.contains('acompañamiento') ||
        normalized.contains('acompanamiento')) {
      return ProductCategory.acompanamientos;
    } else if (normalized.contains('bebida')) {
      return ProductCategory.bebidas;
    } else if (normalized.contains('consom') ||
        normalized.contains('consome')) {
      return ProductCategory.consomes;
    } else if (normalized.contains('salsa') || normalized.contains('extra')) {
      return ProductCategory.extras;
    }
    return ProductCategory.tacos; // Default (ya no se usa para mostrar; se usa categoryName)
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    // Al abrir el menú, recargar productos para reflejar disponibilidad (habilitar/deshabilitar)
    if (view == 'menu') {
      loadProducts();
    }
    notifyListeners();
  }

  // Seleccionar mesa
  void selectTable(TableModel table) async {
    _selectedTable = table;
    // No fijar vista todavía: se decidirá tras cargar historial (ir directo a cuenta dividida si ya hay datos)
    notifyListeners();

    // Cargar historial de forma asíncrona respetando los flags
    await _loadHistoryForTable(table.id);

    final tableId = table.id.toString();
    // Restaurar carrito persistido si en memoria está vacío (evita perder productos al recargar/reiniciar)
    if ((_tableOrders[tableId] ?? []).isEmpty) {
      await _loadPersistedCartForTable(tableId);
      if ((_tableOrders[tableId] ?? []).isNotEmpty) notifyListeners();
    }
    
    // Después de cargar el historial, verificar si hay órdenes en modo dividido o personas en memoria
    final history = _tableOrderHistory[tableId] ?? [];
    final hasDividedOrders = history.any((order) => order['isDividedAccount'] == true);
    final alreadyHasPersons = (_personNamesByTable[tableId]?.isNotEmpty ?? false);
    
    if ((hasDividedOrders || alreadyHasPersons) && !(_isDividedAccountModeByTable[tableId] ?? false)) {
      _isDividedAccountModeByTable[tableId] = true;
    }
    
    if (hasDividedOrders) {
      // Restaurar modo dividido si hay órdenes en modo dividido
      _isDividedAccountModeByTable[tableId] = true;
      
      final personNamesFromHistory = <String, String>{};
      final personAssignmentsFromHistory = <String, List<String>>{};
      
      for (var order in history) {
        if (order['isDividedAccount'] == true) {
          final personNames = order['personNames'] as Map<String, dynamic>?;
          final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
          
          if (personNames != null) {
            personNames.forEach((personId, name) {
              if (!personNamesFromHistory.containsKey(personId)) {
                personNamesFromHistory[personId] = name.toString();
              }
            });
          }
          
          if (personAssignments != null) {
            personAssignments.forEach((personId, items) {
              if (items is List) {
                if (!personAssignmentsFromHistory.containsKey(personId)) {
                  personAssignmentsFromHistory[personId] = [];
                }
                personAssignmentsFromHistory[personId]!.addAll(
                  items.map((item) => item.toString())
                );
              }
            });
          }
        }
      }
      
      if (personNamesFromHistory.isNotEmpty) {
        _personNamesByTable[tableId] = personNamesFromHistory;
        
        if (!_personCartItemsByTable.containsKey(tableId)) {
          _personCartItemsByTable[tableId] = {};
        }
        
        if (personNamesFromHistory.isNotEmpty) {
          final maxId = personNamesFromHistory.keys
              .map((id) {
                final match = RegExp(r'person_(\d+)').firstMatch(id);
                return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
              })
              .fold(0, (max, id) => id > max ? id : max);
          _nextPersonIdByTable[tableId] = maxId + 1;
        }
        
        if (_selectedPersonIdByTable[tableId] == null && personNamesFromHistory.isNotEmpty) {
          _selectedPersonIdByTable[tableId] = personNamesFromHistory.keys.first;
        }
      }
    }
    
    // Restaurar estado "dividir cuenta" desde storage al reentrar a la mesa (tras cerrar sesión o cambiar de rol)
    bool hasDividedData = (_personNamesByTable[tableId]?.isNotEmpty ?? false) ||
        (_isDividedAccountModeByTable[tableId] ?? false);
    if (!hasDividedData) {
      final restored = await _restoreDividedAccountState(tableId);
      if (restored) hasDividedData = true;
    }
    // Si la mesa ya tiene personas o datos de cuenta dividida, ir directo a Cuenta Dividida; si no, a Consumo de Mesa
    setCurrentView(hasDividedData ? 'divided_account' : 'table');
    notifyListeners();
  }

  // Seleccionar vista de Para Llevar
  void selectTakeawayView() {
    _selectedTable = null; // No hay mesa seleccionada para "Para llevar"
    setCurrentView('takeaway');

    // Notificar cambio inmediatamente para actualizar la UI
    notifyListeners();

    // Cargar historial de órdenes para llevar
    loadTakeawayOrderHistory();
  }

  // Establecer información del cliente para pedido "Para llevar"
  void setTakeawayCustomerInfo(String name, String phone) {
    _takeawayCustomerName = name;
    _takeawayCustomerPhone = phone;
    _selectedTable = null; // Asegurar que no hay mesa seleccionada
    notifyListeners();
    print('📦 Mesero: Cliente para llevar: $name, Tel: $phone');
  }

  // Limpiar información del cliente "Para llevar"
  void clearTakeawayCustomerInfo() {
    _takeawayCustomerName = null;
    _takeawayCustomerPhone = null;
    notifyListeners();
  }

  // Método auxiliar para cargar historial desde el backend
  // SIEMPRE carga del backend para obtener órdenes activas
  // El flag _historyCleared ya no bloquea la carga - las órdenes activas siempre deben mostrarse
  Future<void> _loadHistoryForTable(int tableId) async {
    // Siempre cargar historial desde el backend
    // Las órdenes activas (abierta, en_preparacion, listo) siempre deben aparecer
    await loadTableOrderHistory(tableId);
  }

  // Cambiar estado de mesa
  Future<void> changeTableStatus(int tableId, String newStatus) async {
    try {
      // Obtener estados de mesa disponibles
      final estados = await _mesasService.getEstadosMesa();

      // Mapear estado del frontend al ID del backend
      int? estadoMesaId;
      final statusLower = newStatus.toLowerCase();

      if (statusLower.contains('libre')) {
        final estado = estados.firstWhere(
          (e) => (e['nombre'] as String).toLowerCase().contains('libre'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 1},
        );
        estadoMesaId = estado['id'] as int;
      } else if (statusLower.contains('ocupada') ||
          statusLower.contains('ocupado')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('ocupada') ||
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
      } else if (statusLower.contains('reservada') ||
          statusLower.contains('reservado')) {
        final estado = estados.firstWhere(
          (e) =>
              (e['nombre'] as String).toLowerCase().contains('reservada') ||
              (e['nombre'] as String).toLowerCase().contains('reservado'),
          orElse: () => estados.isNotEmpty ? estados[0] : {'id': 4},
        );
        estadoMesaId = estado['id'] as int;
      }

      if (estadoMesaId == null) {
        throw Exception('Estado de mesa no encontrado: $newStatus');
      }

      // Actualizar estado en BD
      await _mesasService.cambiarEstadoMesa(tableId, estadoMesaId);

      // Actualizar estado localmente después de confirmar en el backend
      final mesaIndex = _tables.indexWhere((t) => t.id == tableId);
      if (mesaIndex != -1) {
        final mesaActual = _tables[mesaIndex];
        final mesaActualizada = TableModel(
          id: mesaActual.id,
          codigo: mesaActual.codigo,
          number: mesaActual.number,
          status: newStatus,
          seats: mesaActual.seats,
          customers: mesaActual.customers,
          orderValue: mesaActual.orderValue,
          reservation: mesaActual.reservation,
          position: mesaActual.position,
          section: mesaActual.section,
        );
        _tables[mesaIndex] = mesaActualizada;
        notifyListeners(); // Notificar inmediatamente para actualizar UI
        print(
          '✅ Mesero: Estado de mesa ${mesaActual.number} actualizado a "$newStatus"',
        );
      }

      // NO recargar inmediatamente - el estado ya está actualizado localmente
      // El evento de socket se encargará de sincronizar con otros roles
      // Solo recargar en segundo plano después de un delay para verificar sincronización
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await loadTables();
        } catch (e) {
          print('⚠️ Error al recargar mesas en segundo plano (mesero): $e');
        }
      });
    } catch (e) {
      print('Error al cambiar estado de mesa: $e');
      rethrow;
    }
  }

  // Agregar producto al carrito
  void addToCart(ProductModel product, {Map<String, dynamic>? customizations}) {
    // Determinar la clave del carrito: mesa seleccionada o "takeaway" para pedidos para llevar
    String cartKey;
    if (_selectedTable != null) {
      cartKey = _selectedTable!.id.toString();
    } else if (isTakeawayMode) {
      cartKey = 'takeaway';
    } else {
      // Si no hay mesa ni modo takeaway, no hacer nada
      return;
    }

    final cartItemId = DateTime.now().millisecondsSinceEpoch.toString();
    final cartItemCustomizations = Map<String, dynamic>.from(customizations ?? {});

    // Si está en modo dividida y hay una persona seleccionada, asignar automáticamente
    if (isDividedAccountMode && selectedPersonId != null) {
      final tableId = _selectedTable!.id.toString();
      cartItemCustomizations['personId'] = selectedPersonId;
      // Agregar a la lista de items de la persona
      if (!_personCartItemsByTable.containsKey(tableId)) {
        _personCartItemsByTable[tableId] = {};
      }
      if (!_personCartItemsByTable[tableId]!.containsKey(selectedPersonId)) {
        _personCartItemsByTable[tableId]![selectedPersonId!] = [];
      }
      _personCartItemsByTable[tableId]![selectedPersonId!]!.add(cartItemId);
    }

    final cartItem = CartItem(
      id: cartItemId,
      product: product,
      customizations: cartItemCustomizations,
      tableId: cartKey,
    );

    _tableOrders[cartKey] = [...(_tableOrders[cartKey] ?? []), cartItem];
    notifyListeners();
    _persistCartForTable(cartKey);
  }

  // Remover producto del carrito
  void removeFromCart(String itemId) {
    // Determinar la clave del carrito
    String? cartKey;
    if (_selectedTable != null) {
      cartKey = _selectedTable!.id.toString();
    } else if (isTakeawayMode) {
      cartKey = 'takeaway';
    }

    if (cartKey == null) return;

    if (_tableOrders[cartKey] != null) {
      // Si está en modo dividida, remover también de asignaciones de personas
      if (isDividedAccountMode && _selectedTable != null) {
        final tableId = _selectedTable!.id.toString();
        final personCartItems = _personCartItemsByTable[tableId];
        if (personCartItems != null) {
          for (var personItems in personCartItems.values) {
            personItems.remove(itemId);
          }
        }
      }
      
      _tableOrders[cartKey] = _tableOrders[cartKey]!
          .where((item) => item.id != itemId)
          .toList();
      notifyListeners();
      _persistCartForTable(cartKey);
    }
  }

  /// Actualiza las customizations de un ítem del carrito (ej. cantidad, nota).
  /// [customizationsOverride] se fusiona sobre las existentes (solo las claves indicadas).
  void updateCartItem(String itemId, Map<String, dynamic> customizationsOverride) {
    String? cartKey;
    if (_selectedTable != null) {
      cartKey = _selectedTable!.id.toString();
    } else if (isTakeawayMode) {
      cartKey = 'takeaway';
    }
    if (cartKey == null || _tableOrders[cartKey] == null) return;

    final list = _tableOrders[cartKey]!;
    final index = list.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final item = list[index];
    final merged = Map<String, dynamic>.from(item.customizations);
    merged.addAll(customizationsOverride);

    final updated = CartItem(
      id: item.id,
      product: item.product,
      customizations: merged,
      tableId: item.tableId,
    );
    _tableOrders[cartKey] = [
      ...list.sublist(0, index),
      updated,
      ...list.sublist(index + 1),
    ];
    notifyListeners();
    _persistCartForTable(cartKey);
  }

  // ========== MÉTODOS PARA CUENTA DIVIDIDA POR PERSONA ==========
  
  /// True si la mesa actual tiene personas o productos en cuenta dividida (órdenes enviadas o en carrito).
  bool get hasDividedAccountDataForCurrentTable {
    if (_selectedTable == null) return false;
    final tableId = _selectedTable!.id.toString();
    if (personNames.isNotEmpty) return true;
    final byPerson = _personCartItemsByTable[tableId];
    if (byPerson != null && byPerson.values.any((list) => list.isNotEmpty)) return true;
    final history = _tableOrderHistory[tableId] ?? [];
    return history.any((order) => order['isDividedAccount'] == true);
  }
  
  /// Llamar desde el botón atrás de Cuenta Dividida: ir a consumo de mesa si no hay datos, o al plano si hay.
  void navigateBackFromDividedAccount() {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    if (!hasDividedAccountDataForCurrentTable) {
      _isDividedAccountModeByTable[tableId] = false;
      setCurrentView('table');
    } else {
      setCurrentView('floor');
    }
    notifyListeners();
  }
  
  /// Activar/desactivar modo cuenta dividida (por mesa)
  void setDividedAccountMode(bool enabled) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    
    if ((_isDividedAccountModeByTable[tableId] ?? false) == enabled) return;
    _isDividedAccountModeByTable[tableId] = enabled;
    
    if (!enabled) {
      // Al desactivar, limpiar asignaciones de personas para esta mesa
      _personCartItemsByTable.remove(tableId);
      _personNamesByTable.remove(tableId);
      _selectedPersonIdByTable.remove(tableId);
      _nextPersonIdByTable.remove(tableId);
      // Remover personId de todos los items del carrito de esta mesa
      final cart = getCurrentCart();
      for (var item in cart) {
        item.customizations.remove('personId');
      }
    } else {
      // Al activar, solo inicializar estructuras; no crear persona hasta que el usuario pulse "Agregar Persona"
      if (!_personNamesByTable.containsKey(tableId)) {
        _personNamesByTable[tableId] = {};
        _personCartItemsByTable[tableId] = {};
        _nextPersonIdByTable[tableId] = 1;
      }
    }
    
    notifyListeners();
  }
  
  /// Resetear modo dividido para una mesa (cuando se cierra la cuenta completamente)
  Future<void> resetDividedAccountModeForTable(String tableId) async {
    _isDividedAccountModeByTable.remove(tableId);
    _personCartItemsByTable.remove(tableId);
    _personNamesByTable.remove(tableId);
    _selectedPersonIdByTable.remove(tableId);
    _nextPersonIdByTable.remove(tableId);
    _dividedPersonsBillSentByTable.remove(tableId);
    try {
      await _storage.delete(_dividirCuentaKey(tableId));
      await _saveDividedPersonsBillSent();
    } catch (_) {}
    notifyListeners();
  }

  /// Agregar una nueva persona (para la mesa actual)
  String addPerson({String? name}) {
    if (_selectedTable == null) throw Exception('No hay mesa seleccionada');
    final tableId = _selectedTable!.id.toString();
    
    if (!_nextPersonIdByTable.containsKey(tableId)) {
      _nextPersonIdByTable[tableId] = 1;
    }
    if (!_personNamesByTable.containsKey(tableId)) {
      _personNamesByTable[tableId] = {};
      _personCartItemsByTable[tableId] = {};
    }
    
    final nextId = _nextPersonIdByTable[tableId]!;
    final personId = 'person_$nextId';
    _nextPersonIdByTable[tableId] = nextId + 1;
    
    final personNames = _personNamesByTable[tableId]!;
    personNames[personId] = name ?? 'Persona ${personNames.length + 1}';
    _personCartItemsByTable[tableId]![personId] = [];
    notifyListeners();
    _persistDividedAccountState(tableId);
    return personId;
  }

  /// Eliminar una persona (solo si no tiene productos asignados)
  void removePerson(String personId) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    final personCartItems = _personCartItemsByTable[tableId];
    
    if (personCartItems?[personId]?.isNotEmpty ?? false) {
      throw Exception('No se puede eliminar una persona que tiene productos asignados');
    }
    _personNamesByTable[tableId]?.remove(personId);
    _personCartItemsByTable[tableId]?.remove(personId);
    notifyListeners();
  }

  /// Renombrar una persona
  void renamePerson(String personId, String newName) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    final personNames = _personNamesByTable[tableId];
    
    if (personNames == null || !personNames.containsKey(personId)) {
      throw Exception('Persona no encontrada: $personId');
    }
    personNames[personId] = newName.trim().isEmpty 
        ? 'Persona ${personNames.keys.toList().indexOf(personId) + 1}'
        : newName.trim();
    notifyListeners();
    _persistDividedAccountState(tableId);
  }

  /// Asignar un producto del carrito a una persona
  void assignCartItemToPerson(String cartItemId, String personId) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    final personNames = _personNamesByTable[tableId];
    final personCartItems = _personCartItemsByTable[tableId];
    
    if (personNames == null || !personNames.containsKey(personId)) {
      throw Exception('Persona no encontrada: $personId');
    }
    
    // Remover de otras personas
    if (personCartItems != null) {
      for (var personItems in personCartItems.values) {
        personItems.remove(cartItemId);
      }
      
      // Agregar a la persona seleccionada
      if (!personCartItems[personId]!.contains(cartItemId)) {
        personCartItems[personId]!.add(cartItemId);
      }
    }
    
    // Actualizar customizations del CartItem
    final cart = getCurrentCart();
    final item = cart.firstWhere((item) => item.id == cartItemId, orElse: () => cart.first);
    item.customizations['personId'] = personId;
    
    notifyListeners();
  }

  /// Obtener el personId asignado a un cartItem
  String? getPersonIdForCartItem(String cartItemId) {
    final cart = getCurrentCart();
    final item = cart.firstWhere((item) => item.id == cartItemId, orElse: () => cart.first);
    return item.customizations['personId'] as String?;
  }

  /// Obtener productos asignados a una persona
  List<CartItem> getItemsForPerson(String personId) {
    if (_selectedTable == null) return [];
    final tableId = _selectedTable!.id.toString();
    final cart = getCurrentCart();
    final itemIds = _personCartItemsByTable[tableId]?[personId] ?? [];
    return cart.where((item) => itemIds.contains(item.id)).toList();
  }

  /// Obtener productos sin asignar (solo en modo dividida)
  List<CartItem> getUnassignedItems() {
    if (!isDividedAccountMode) return [];
    final cart = getCurrentCart();
    return cart.where((item) => item.customizations['personId'] == null).toList();
  }

  /// Establecer la persona seleccionada para agregar productos
  void setSelectedPersonId(String? personId) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id.toString();
    
    if (personId != null) {
      final personNames = _personNamesByTable[tableId];
      if (personNames == null || !personNames.containsKey(personId)) {
        throw Exception('Persona no encontrada: $personId');
      }
    }
    _selectedPersonIdByTable[tableId] = personId;
    notifyListeners();
  }

  // Limpiar carrito de la mesa actual
  void clearCart() {
    // Determinar la clave del carrito
    String? cartKey;
    if (_selectedTable != null) {
      cartKey = _selectedTable!.id.toString();
    } else if (isTakeawayMode) {
      cartKey = 'takeaway';
    }

    if (cartKey == null) return;

    _tableOrders[cartKey] = [];
    _persistCartForTable(cartKey);
    
    // Si está en modo dividida, limpiar también asignaciones de personas para esta mesa
    if (isDividedAccountMode && _selectedTable != null) {
      final tableId = _selectedTable!.id.toString();
      _personCartItemsByTable[tableId]?.clear();
      // No limpiar _personNamesByTable ni _nextPersonIdByTable porque las personas pueden seguir existiendo
    }
    
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

  // Calcular total del carrito actual (incluyendo extras y salsas)
  double calculateTotal() {
    final cart = getCurrentCart();
    return cart.fold(0.0, (total, item) {
      final qty = (item.customizations['quantity'] as num?)?.toDouble() ?? 1.0;
      double itemTotal = _getBaseUnitPrice(item) * qty;

      // Agregar precio de extras si existen
      final extraPrices =
          item.customizations['extraPrices'] as List<dynamic>? ?? [];
      for (var priceEntry in extraPrices) {
        if (priceEntry is Map) {
          final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
          itemTotal += precio * qty; // Multiplicar por cantidad
        }
      }

      // Agregar precio de salsa si existe (usando el precio real guardado)
      final saucePrice =
          (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
      if (saucePrice > 0) {
        itemTotal += saucePrice * qty;
      }

      return total + itemTotal;
    });
  }

  double _getBaseUnitPrice(CartItem item) {
    final sizePrice = item.customizations['sizePrice'] ??
        item.customizations['unitPrice'];
    if (sizePrice is num) {
      return sizePrice.toDouble();
    }
    return item.product.price;
  }

  String _formatProductNameWithSize(String name, String? size) {
    if (size == null || size.isEmpty) {
      return name;
    }
    return '$name ($size)';
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
    if (_tables.isEmpty) return 0.0;
    final occupiedTables = _tables
        .where((t) => t.status != TableStatus.libre)
        .length;
    final totalTables = _tables.length;
    if (totalTables == 0) return 0.0;
    final rate = (occupiedTables / totalTables) * 100;
    return rate.isNaN || rate.isInfinite ? 0.0 : rate;
  }

  /// Actualiza comensales en UI y en el servidor (persiste al salir y volver a la mesa).
  Future<void> updateTableCustomers(int tableId, int customers) async {
    final updatedCustomers = customers > 0 ? customers : null;

    _tables = _tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(customers: updatedCustomers);
      }
      return table;
    }).toList();

    if (_selectedTable != null && _selectedTable!.id == tableId) {
      _selectedTable = _selectedTable!.copyWith(customers: updatedCustomers);
    }

    notifyListeners();

    try {
      await _mesasService.updateMesa(tableId, {'comensales': updatedCustomers});
    } catch (e) {
      print('❌ Mesero: no se pudo guardar comensales en servidor: $e');
      rethrow;
    }
  }

  // Obtener historial de pedidos de una mesa
  // NUEVO SISTEMA: Siempre obtiene del backend como fuente de verdad
  // Solo incluye órdenes con estados ACTIVOS (abierta, en_preparacion, listo)
  List<Map<String, dynamic>> getTableOrderHistory(int tableId) {
    final tableKey = tableId.toString();

    // Obtener historial de memoria
    final historial = _tableOrderHistory[tableKey] ?? [];

    // FILTRADO ESTRICTO: Solo órdenes con estados activos
    // Estados válidos: abierta, en_preparacion, listo, pendiente
    // Estados EXCLUIDOS: pagada, cancelada, cerrada, cobrada
    final historialFiltrado = historial.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';

      // Lista de estados FINALIZADOS que NO deben aparecer (no usar "enviada": coincide con textos de cocina)
      final estadosFinalizados = [
        'pagada',
        'cancelada',
        'cerrada',
        'cobrada',
        'entregada',
        'completada',
        'finalizada',
      ];

      // Verificar si el estado está finalizado
      for (final estadoFinal in estadosFinalizados) {
        if (status.contains(estadoFinal)) {
          print(
            '🚫 Historial: Orden ${order['ordenId']} EXCLUIDA (estado: $status)',
          );
          return false;
        }
      }

      return true;
    }).toList();

    // Actualizar historial si se filtraron órdenes
    if (historialFiltrado.length != historial.length) {
      _tableOrderHistory[tableKey] = historialFiltrado;
    }

    return historialFiltrado;
  }

  // Obtener historial de órdenes "para llevar"
  // FILTRADO ESTRICTO: Solo órdenes con estados activos (no filtrar por cajero: el estado en BD decide)
  List<Map<String, dynamic>> getTakeawayOrderHistory() {
    // Buscar en todas las claves de takeaway
    final allTakeawayOrders = <Map<String, dynamic>>[];
    _tableOrderHistory.forEach((tableId, orders) {
      if (tableId.startsWith('takeaway-') || tableId == 'takeaway-all') {
        allTakeawayOrders.addAll(orders);
      }
    });

    // Estados FINALIZADOS que NO deben aparecer
    final estadosFinalizados = [
      'pagada',
      'cancelada',
      'cerrada',
      'cobrada',
      'entregada',
      'completada',
      'finalizada',
      'pending',
    ];

    final historialFiltrado = allTakeawayOrders.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      for (final estadoFinal in estadosFinalizados) {
        if (status.contains(estadoFinal)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Eliminar duplicados por ordenId
    final ordenIdsVistos = <int>{};
    final historialSinDuplicados = historialFiltrado.where((order) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId == null) return false;
      if (ordenIdsVistos.contains(ordenId)) return false;
      ordenIdsVistos.add(ordenId);
      return true;
    }).toList();

    // Orden FIFO: más antiguas primero
    historialSinDuplicados.sort((a, b) {
      try {
        final fechaA = date_utils.AppDateUtils.parseToLocal(a['date']);
        final fechaB = date_utils.AppDateUtils.parseToLocal(b['date']);
        return fechaA.compareTo(fechaB);
      } catch (e) {
        return 0;
      }
    });

    return historialSinDuplicados;
  }

  // Forzar recarga del historial desde el backend
  // NUEVO SISTEMA: Siempre consulta el backend como fuente de verdad
  Future<void> forceReloadTableHistory(int tableId) async {
    final tableKey = tableId.toString();

    // Limpiar historial local
    _tableOrderHistory[tableKey] = [];

    // Cargar desde el backend (fuente de verdad)
    await loadTableOrderHistory(tableId);

    print('✅ Historial de mesa $tableId recargado desde backend');
    notifyListeners();
  }

  // Obtener detalles de una orden del backend
  Future<Map<String, dynamic>?> getOrdenDetalle(int ordenId) async {
    try {
      return await _ordenesService.getOrden(ordenId);
    } catch (e) {
      print('Error al obtener detalles de orden: $e');
      return null;
    }
  }

  /// IVA habilitado en configuración (para mostrar IVA en Cerrar cuenta aunque las órdenes tengan 0).
  Future<bool> getIvaHabilitado() async {
    try {
      final config = await _configuracionService.getConfiguracion();
      return config.ivaHabilitado;
    } catch (_) {
      return false;
    }
  }

  // Limpiar historial de una mesa
  // IMPORTANTE: Marca TODAS las órdenes activas como cerradas en el backend
  // para que no vuelvan a aparecer después de login/logout
  Future<void> clearTableHistory(int tableId) async {
    final tableKey = tableId.toString();

    // Obtener todas las órdenes activas del historial
    final historial = _tableOrderHistory[tableKey] ?? [];
    final ordenesActivas = historial.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      final esFinalizada =
          status.contains('pagada') ||
          status.contains('cancelada') ||
          status.contains('cerrada');
      return !esFinalizada;
    }).toList();

    // Marcar TODAS las órdenes activas como cerradas en el backend
    for (var order in ordenesActivas) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId != null) {
        await _marcarOrdenComoCerradaEnBackend(ordenId);
        print('🗑️ Orden $ordenId marcada como cerrada al limpiar historial');
      }
    }

    // Limpiar historial en memoria
    _tableOrderHistory[tableKey] = [];

    // NO marcar como "limpiada" porque las órdenes ya están cerradas
    // El historial se limpiará automáticamente porque las órdenes están cerradas

    print(
      '🗑️ Historial de mesa $tableId limpiado. ${ordenesActivas.length} órdenes marcadas como cerradas en backend.',
    );
    notifyListeners();
  }

  // Verificar si el historial está vacío
  bool isHistoryCleared(int tableId) {
    final historial = _tableOrderHistory[tableId.toString()] ?? [];
    return historial.isEmpty;
  }

  // Resetear historial (simplemente recargar desde backend)
  Future<void> resetHistoryClearedFlag(int tableId) async {
    await forceReloadTableHistory(tableId);
    notifyListeners();
  }

  void closeTable(int tableId) {
    final tableKey = tableId.toString();
    _tableOrders[tableKey] = [];
    _tableOrderHistory[tableKey] = [];

    // NO llamar a removeBillsForTable: [BillRepository] es compartido con cajero y gerente.
    // Las cuentas enviadas deben seguir visibles allí hasta cobrarse (cualquier método) o
    // cancelarse la orden; liberar la mesa aquí solo actualiza estado de mesas en mesero.

    _tables = _tables.map((tableEntry) {
      if (tableEntry.id == tableId) {
        return tableEntry.copyWith(
          status: TableStatus.libre,
          customers: null,
          orderValue: null,
        );
      }
      return tableEntry;
    }).toList();

    if (_selectedTable != null && _selectedTable!.id == tableId) {
      _selectedTable = _selectedTable!.copyWith(
        status: TableStatus.libre,
        customers: null,
        orderValue: null,
      );
    }

    notifyListeners();
  }

  /// Cierra mesa en UI local y sincroniza estado en backend.
  /// Si falla backend, conserva el cierre local para no bloquear operación,
  /// pero relanza error para que la UI informe al usuario.
  Future<void> closeTableAndSync(int tableId) async {
    closeTable(tableId);
    try {
      await _mesasService.updateMesa(tableId, {
        'estado': 'libre',
        'comensales': null,
      });
    } catch (e) {
      print('❌ Mesero: Error al sincronizar cierre de mesa $tableId: $e');
      rethrow;
    }
  }

  // Cargar historial de órdenes "para llevar" desde el backend
  // SIMPLIFICADO: Usa datos de la lista sin hacer peticiones individuales
  Future<void> loadTakeawayOrderHistory() async {
    try {
      print('📋 Cargando historial de órdenes para llevar...');

      // Estados FINALIZADOS que NO deben aparecer
      final estadosFinalizados = [
        'pagada',
        'cancelada',
        'cerrada',
        'cobrada',
        'entregada',
        'enviada',
      ];

      // Obtener todas las órdenes del backend
      final ordenes = await _ordenesService.getOrdenes();

      // Asegurarse de que los bills estén cargados desde el backend
      // Esto es crítico porque los bills persisten después del logout
      await _billRepository.loadBills();
      final billsPendientes = _billRepository.pendingBills;
      
      // IMPORTANTE: Solo considerar bills que fueron creados EXPLÍCITAMENTE por el mesero
      // (cuando cierra la cuenta), NO bills creados automáticamente por BillRepository.loadBills()
      // Los bills creados por el mesero tienen:
      // 1. requestedByWaiter: true (pero esto también lo tienen los automáticos, así que no es suficiente)
      // 2. Formato agrupado: BILL-TAKEAWAY-* o BILL-MESA-* (estos SÍ fueron creados por el mesero)
      // 3. O bills individuales que están en bills agrupados (también fueron creados por el mesero)
      final ordenIdsConBill = <int>{};
      for (final bill in billsPendientes) {
        // Solo considerar bills que fueron creados explícitamente por el mesero:
        // - Bills agrupados (BILL-TAKEAWAY-* o BILL-MESA-*) siempre fueron creados por el mesero
        // - Bills individuales (BILL-ORD-*) solo si están en un bill agrupado o fueron creados vía cuenta.enviada
        final esBillAgrupado = bill.id.startsWith('BILL-TAKEAWAY-') || 
                                bill.id.startsWith('BILL-MESA-') ||
                                bill.id.startsWith('CUENTA-AGRUPADA-');
        
        if (esBillAgrupado) {
          // Bill agrupado: extraer todos los ordenIds del billId
          if (bill.id.startsWith('BILL-TAKEAWAY-')) {
            final parts = bill.id.split('-');
            // Los números al final son los ordenIds
            for (var i = parts.length - 1; i >= 2; i--) {
              final posibleOrdenId = int.tryParse(parts[i]);
              if (posibleOrdenId != null) {
                ordenIdsConBill.add(posibleOrdenId);
              } else {
                break; // Ya no hay más números
              }
            }
          } else if (bill.id.startsWith('BILL-MESA-')) {
            final parts = bill.id.split('-');
            // Los números después de "BILL-MESA-X" son los ordenIds
            for (var i = 3; i < parts.length; i++) {
              final posibleOrdenId = int.tryParse(parts[i]);
              if (posibleOrdenId != null) {
                ordenIdsConBill.add(posibleOrdenId);
              }
            }
          } else if (bill.id.startsWith('CUENTA-AGRUPADA-')) {
            final parts = bill.id.replaceFirst('CUENTA-AGRUPADA-', '').split('-');
            for (var part in parts) {
              final posibleOrdenId = int.tryParse(part);
              if (posibleOrdenId != null) {
                ordenIdsConBill.add(posibleOrdenId);
              }
            }
          }
          
          // También agregar ordenIds directos si existen
          if (bill.ordenIds != null) {
            ordenIdsConBill.addAll(bill.ordenIds!);
          }
        }
        // NO considerar bills individuales (BILL-ORD-*) porque estos son creados automáticamente
        // por BillRepository.loadBills() y NO indican que el mesero cerró la cuenta
      }

      // Filtrar solo órdenes "para llevar" (mesaId == null) y con estados activos
      final takeawayOrdenesActivas = ordenes.where((o) {
        final ordenData = o as Map<String, dynamic>;
        final mesaId = ordenData['mesaId'];
        if (mesaId != null) return false;

        final ordenId = ordenData['id'] as int?;
        
        // PRIORIDAD 1: Filtrar por ID (registro local de órdenes ya enviadas)
        // Esto es la fuente de verdad más confiable
        if (ordenId != null && _sentToCashierOrders.contains(ordenId)) {
          print(
            '🚫 Orden $ordenId filtrada (registro local de enviada al cajero)',
          );
          return false;
        }
        
        // PRIORIDAD 1.5: Filtrar por bills agrupados creados EXPLÍCITAMENTE por el mesero
        // NO filtrar por bills individuales (BILL-ORD-*) porque estos son creados automáticamente
        // Solo los bills agrupados (BILL-TAKEAWAY-*, BILL-MESA-*) indican que el mesero cerró la cuenta
        if (ordenId != null && ordenIdsConBill.contains(ordenId)) {
          print(
            '🚫 Orden $ordenId filtrada (ya tiene bill agrupado creado por mesero)',
          );
          // IMPORTANTE: Agregar al registro local para persistencia
          if (!_sentToCashierOrders.contains(ordenId)) {
            _sentToCashierOrders.add(ordenId);
            _saveSentToCashierOrders();
            print('💾 Orden $ordenId agregada a _sentToCashierOrders (bill agrupado encontrado)');
          }
          return false;
        }

        // PRIORIDAD 2: Filtrar por estado del backend
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';
        for (final estadoFinal in estadosFinalizados) {
          if (estadoNombre.contains(estadoFinal)) {
            print(
              '🚫 Orden ${ordenData['id']} filtrada por estado: $estadoNombre',
            );
            return false;
          }
        }
        return true;
      }).toList();

      print('📋 ${takeawayOrdenesActivas.length} órdenes para llevar ACTIVAS');

      // Convertir órdenes al formato de historial (sin peticiones adicionales)
      final history = <Map<String, dynamic>>[];
      for (final orden in takeawayOrdenesActivas) {
        final ordenData = orden as Map<String, dynamic>;
        final ordenId = ordenData['id'] as int?;
        if (ordenId == null) continue;
        int? tiempoEstimado;

        final createdAt = ordenData['creadoEn'] as String?;
        DateTime fecha;
        if (createdAt != null) {
          try {
            fecha = date_utils.AppDateUtils.parseToLocal(createdAt);
          } catch (e) {
            fecha = date_utils.AppDateUtils.nowCdmx();
          }
        } else {
          fecha = date_utils.AppDateUtils.nowCdmx();
        }

        // Cargar items de la orden desde el backend
        List<String> itemsNombres = [];
        try {
          final ordenDetalle = await _ordenesService.getOrden(ordenId);
          if (ordenDetalle != null) {
            final items = ordenDetalle['items'] as List<dynamic>? ?? [];
            tiempoEstimado = ordenDetalle['tiempoEstimadoPreparacion'] as int? ??
                ordenDetalle['estimatedTime'] as int?;
            itemsNombres = items.map((item) {
              final nombre = item['productoNombre'] as String? ?? 'Producto';
              final tamanoEtiqueta = item['productoTamanoEtiqueta'] as String?;
              final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
              final nombreConTamano = _formatProductNameWithSize(nombre, tamanoEtiqueta);
              return cantidad > 1 ? '${cantidad}x $nombreConTamano' : nombreConTamano;
            }).toList();
          }
        } catch (e) {
          print('⚠️ Error al cargar items de orden $ordenId: $e');
        }

        history.add({
          'id': 'ORD-${ordenId.toString().padLeft(6, '0')}',
          'ordenId': ordenId,
          'items': itemsNombres, // Items cargados desde el backend
          'status': ordenData['estadoNombre'] as String? ?? 'Pendiente',
          'time': date_utils.AppDateUtils.formatTime(fecha),
          'date': fecha.toIso8601String(),
          'subtotal': (ordenData['subtotal'] as num?)?.toDouble() ?? 0.0,
          'total': (ordenData['total'] as num?)?.toDouble() ?? 0.0,
          'isTakeaway': true,
          'customerName': ordenData['clienteNombre'] as String? ?? 'Cliente',
          'customerPhone': ordenData['clienteTelefono'] as String? ?? '',
          'tableNumber': null,
          'estimatedTime': tiempoEstimado ??
              ordenData['tiempoEstimadoPreparacion'] ??
              ordenData['estimatedTime'],
        });
      }

      // Orden FIFO: más antiguas primero
      history.sort((a, b) {
        try {
          final fechaA = date_utils.AppDateUtils.parseToLocal(a['date']);
          final fechaB = date_utils.AppDateUtils.parseToLocal(b['date']);
          return fechaA.compareTo(fechaB);
        } catch (e) {
          return 0;
        }
      });

      // Asegurarse de que _sentToCashierOrders esté cargado antes de filtrar
      if (_sentToCashierOrders.isEmpty) {
        await _loadSentToCashierOrders();
        print('🔄 Mesero: _sentToCashierOrders recargado antes de filtrar: $_sentToCashierOrders');
      }
      
      // Filtrar órdenes que ya fueron enviadas al cajero ANTES de guardar
      // Nota: ordenIdsConBill ya fue calculado arriba en el primer filtro
      print('🔍 Filtrando historial: ${_sentToCashierOrders.length} órdenes en _sentToCashierOrders: $_sentToCashierOrders');
      final historyFiltrado = history.where((order) {
        final ordenId = order['ordenId'] as int?;
        if (ordenId == null) return true;
        
        // PRIORIDAD 1: Filtrar por registro local (_sentToCashierOrders)
        if (_sentToCashierOrders.contains(ordenId)) {
          print('🚫 Orden $ordenId filtrada (ya enviada al cajero - registro local)');
          return false;
        }
        
        // PRIORIDAD 2: Filtrar por bills pendientes creados EXPLÍCITAMENTE por el mesero
        // (ordenIdsConBill ya fue calculado arriba, solo incluye bills agrupados)
        // NO filtrar por bills individuales (BILL-ORD-*) porque estos son creados automáticamente
        if (ordenIdsConBill.contains(ordenId)) {
          print('🚫 Orden $ordenId filtrada (ya tiene bill agrupado creado por mesero)');
          // IMPORTANTE: Agregar al registro local para persistencia
          if (!_sentToCashierOrders.contains(ordenId)) {
            _sentToCashierOrders.add(ordenId);
            _saveSentToCashierOrders();
            print('💾 Orden $ordenId agregada a _sentToCashierOrders (bill agrupado encontrado)');
          }
          return false;
        }
        
        return true;
      }).toList();
      print('📊 Resultado del filtro: ${history.length} órdenes originales -> ${historyFiltrado.length} órdenes filtradas');

      // Guardar en historial de takeaway (ya filtrado)
      _tableOrderHistory['takeaway-all'] = historyFiltrado;
      print(
        '📋 Mesero: Historial para llevar cargado: ${historyFiltrado.length} órdenes (${history.length - historyFiltrado.length} filtradas)',
      );

      notifyListeners();
    } catch (e) {
      print('Error al cargar historial de órdenes para llevar: $e');
      // Asegurar que hay una lista vacía para evitar errores
      _tableOrderHistory['takeaway-all'] = [];
      notifyListeners();
    }
  }

  // Cargar historial de todas las mesas con órdenes activas
  Future<void> _loadAllTablesHistory() async {
    try {
      print('📋 Cargando historial de todas las mesas con órdenes activas...');

      // Obtener todas las órdenes del backend
      final ordenes = await _ordenesService.getOrdenes();

      // Estados finalizados que debemos excluir
      final estadosFinalizados = [
        'pagada',
        'cancelada',
        'cerrada',
        'cobrada',
        'entregada',
        'completada',
        'finalizada',
        'enviada',
      ];

      // Filtrar órdenes activas de mesas (excluir para llevar)
      final ordenesMesas = ordenes.where((o) {
        final ordenData = o as Map<String, dynamic>;
        final mesaId = ordenData['mesaId'];

        // Solo órdenes de mesas (no para llevar)
        if (mesaId == null) return false;

        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // Excluir órdenes finalizadas
        for (final estadoFinal in estadosFinalizados) {
          if (estadoNombre.contains(estadoFinal)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Agrupar órdenes por mesa
      final mesasConOrdenes = <int>{};
      for (final orden in ordenesMesas) {
        final ordenData = orden as Map<String, dynamic>;
        final mesaId = ordenData['mesaId'];
        if (mesaId != null) {
          final mesaIdInt = mesaId is int
              ? mesaId
              : int.tryParse(mesaId.toString());
          if (mesaIdInt != null) {
            mesasConOrdenes.add(mesaIdInt);
          }
        }
      }

      print(
        '📋 Encontradas ${mesasConOrdenes.length} mesas con órdenes activas',
      );

      // Filtrar mesas que NO estén marcadas como limpiadas
      final mesasParaCargar = mesasConOrdenes.where((mesaId) {
        final tableKey = mesaId.toString();
        final isCleared = _historyCleared[tableKey] == true;
        if (isCleared) {
          print('⏭️ Mesa $mesaId está marcada como limpiada, omitiendo carga');
        }
        return !isCleared;
      }).toList();

      print(
        '📋 ${mesasParaCargar.length} mesas para cargar (${mesasConOrdenes.length - mesasParaCargar.length} omitidas por estar limpiadas)',
      );

      // Cargar historial solo para mesas que NO están marcadas como limpiadas
      // (limitado a 5 a la vez para no sobrecargar)
      for (var i = 0; i < mesasParaCargar.length; i += 5) {
        final batch = mesasParaCargar.skip(i).take(5).toList();
        await Future.wait(batch.map((mesaId) => loadTableOrderHistory(mesaId)));
      }

      print('✅ Historial de todas las mesas cargado');
    } catch (e) {
      print('❌ Error al cargar historial de todas las mesas: $e');
    }
  }

  // Cargar historial de órdenes desde el backend para una mesa
  // NUEVO SISTEMA: Fuente de verdad es el backend, no el historial local
  Future<void> loadTableOrderHistory(int tableId) async {
    try {
      final tableKey = tableId.toString();

      // Verificar si el historial de esta mesa está marcado como limpiado
      if (_historyCleared[tableKey] == true) {
        print(
          '⏭️ Mesa $tableId está marcada como limpiada, no cargando historial',
        );
        _tableOrderHistory[tableKey] = [];
        return;
      }

      print('📋 Cargando historial para mesa $tableId desde backend...');

      // Obtener todas las órdenes del backend
      final ordenes = await _ordenesService.getOrdenes();

      // Filtrar órdenes de esta mesa
      final ordenesEstaMesa = ordenes.where((o) {
        final ordenData = o as Map<String, dynamic>;
        final mesaId = ordenData['mesaId'];

        // Si mesaId es null, es orden para llevar, no pertenece a esta mesa
        if (mesaId == null) return false;

        // Comparación robusta del mesaId
        if (mesaId == tableId) return true;
        if (mesaId is num) return mesaId.toInt() == tableId;
        if (mesaId is int) return mesaId == tableId;
        if (mesaId is String) {
          final parsed = int.tryParse(mesaId);
          return parsed != null && parsed == tableId;
        }
        return false;
      }).toList();

      print(
        '📋 Encontradas ${ordenesEstaMesa.length} órdenes para mesa $tableId',
      );

      // Filtrar SOLO órdenes con estados ACTIVOS
      // Solo excluir órdenes con estados FINALIZADOS (cerradas por mesero/cajero)
      // NO filtrar por antigüedad - las órdenes activas aparecen sin importar cuándo se crearon
      final estadosFinalizados = [
        'pagada',
        'cancelada',
        'cerrada',
        'cobrada',
        'entregada',
        'completada',
        'finalizada',
      ];

      final ordenesActivas = ordenesEstaMesa.where((o) {
        final ordenData = o as Map<String, dynamic>;
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

        // SOLO verificar si está en estados finalizados (cerradas por mesero/cajero)
        for (final estadoFinal in estadosFinalizados) {
          if (estadoNombre.contains(estadoFinal)) {
            final oid = ordenData['id'];
            print(
              '🚫 Orden $oid EXCLUIDA (estado finalizado: $estadoNombre)',
            );
            return false;
          }
        }

        // Si no está en estado finalizado, incluirla (sin importar la antigüedad)
        return true;
      }).toList();

      print('📋 ${ordenesActivas.length} órdenes ACTIVAS para mesa $tableId');

      // Construir historial con detalles completos
      final history = <Map<String, dynamic>>[];

      for (final orden in ordenesActivas) {
        final ordenData = orden as Map<String, dynamic>;
        final ordenId = ordenData['id'] as int?;

        if (ordenId == null) continue;

        // Obtener detalle completo
        final ordenDetalle = await _ordenesService.getOrden(ordenId);
        if (ordenDetalle == null) continue;

        // Verificar estado REAL del detalle
        final estadoReal =
            (ordenDetalle['estadoNombre'] as String?)?.toLowerCase() ?? '';
        bool esEstadoFinalizado = false;
        for (final estadoFinal in estadosFinalizados) {
          if (estadoReal.contains(estadoFinal)) {
            esEstadoFinalizado = true;
            break;
          }
        }

        if (esEstadoFinalizado) {
          print(
            '🚫 Orden $ordenId EXCLUIDA tras verificar detalle (estado finalizado: $estadoReal)',
          );
          continue;
        }

        // NO filtrar por antigüedad - si la orden está activa, incluirla

        // Construir datos de la orden
        final items = (ordenDetalle['items'] as List<dynamic>?) ?? [];
        final itemsText = items.map((item) {
          final itemData = item as Map<String, dynamic>;
          final cantidad = itemData['cantidad'] as int? ?? 1;
          final nombre = itemData['productoNombre'] as String? ?? 'Producto';
          final tamanoEtiqueta = itemData['productoTamanoEtiqueta'] as String?;
          final nombreConTamano = _formatProductNameWithSize(nombre, tamanoEtiqueta);
          return '${cantidad}x $nombreConTamano';
        }).toList();

        final createdAt = ordenDetalle['creadoEn'] as String?;
        DateTime fecha;
        if (createdAt != null) {
          fecha = date_utils.AppDateUtils.parseToLocal(createdAt);
        } else {
          fecha = date_utils.AppDateUtils.nowCdmx();
        }

        history.add({
          'id': 'ORD-${ordenId.toString().padLeft(6, '0')}',
          'ordenId': ordenId,
          'items': itemsText,
          'status': ordenDetalle['estadoNombre'] as String? ?? 'Pendiente',
          'time': date_utils.AppDateUtils.formatTime(fecha),
          'date': fecha.toIso8601String(),
          'subtotal': (ordenDetalle['subtotal'] as num?)?.toDouble() ?? 0.0,
          'discount':
              (ordenDetalle['descuentoTotal'] as num?)?.toDouble() ?? 0.0,
          'tip': (ordenDetalle['propinaSugerida'] as num?)?.toDouble() ?? 0.0,
          'total': (ordenDetalle['total'] as num?)?.toDouble() ?? 0.0,
          'isTakeaway': ordenDetalle['mesaId'] == null,
          'customerName': ordenDetalle['clienteNombre'] as String?,
          'customerPhone': ordenDetalle['clienteTelefono'] as String?,
          'tableNumber': ordenDetalle['mesaCodigo'] as String?,
          'estimatedTime': ordenDetalle['tiempoEstimadoPreparacion'] ??
              ordenDetalle['estimatedTime'],
          'notes': ordenDetalle['notas'] as String?,
        });
      }

      // También agregar órdenes locales recién creadas (que pueden no estar en backend aún)
      final historialLocal = _tableOrderHistory[tableKey] ?? [];
      final ordenIdsBackend = history
          .map((o) => o['ordenId'] as int?)
          .whereType<int>()
          .toSet();

      for (final ordenLocal in historialLocal) {
        final ordenIdLocal = ordenLocal['ordenId'] as int?;
        if (ordenIdLocal == null) continue;

        // Si ya está en el backend, no duplicar
        if (ordenIdsBackend.contains(ordenIdLocal)) continue;

        // NO filtrar por antigüedad - si la orden está activa, incluirla

        // Verificar estado de la orden local
        final statusLocal =
            (ordenLocal['status'] as String?)?.toLowerCase() ?? '';
        bool esLocalFinalizada = false;
        for (final estadoFinal in estadosFinalizados) {
          if (statusLocal.contains(estadoFinal)) {
            esLocalFinalizada = true;
            break;
          }
        }

        if (esLocalFinalizada) continue;

        // Verificar estado REAL en el backend
        try {
          final ordenBackendCheck = await _ordenesService.getOrden(
            ordenIdLocal,
          );
          if (ordenBackendCheck != null) {
            final estadoBackend =
                (ordenBackendCheck['estadoNombre'] as String?)?.toLowerCase() ??
                '';
            bool esBackendFinalizada = false;
            for (final estadoFinal in estadosFinalizados) {
              if (estadoBackend.contains(estadoFinal)) {
                esBackendFinalizada = true;
                break;
              }
            }
            if (esBackendFinalizada) {
              print(
                '🚫 Orden local $ordenIdLocal está FINALIZADA en backend, no se agrega',
              );
              continue;
            }
          }
        } catch (e) {
          // Si hay error al verificar, agregar de todas formas
        }

        history.add(ordenLocal);
        print('✅ Orden local $ordenIdLocal agregada (no está en backend aún)');
      }

      // Orden FIFO: más antiguas primero
      history.sort((a, b) {
        try {
          final fechaA = date_utils.AppDateUtils.parseToLocal(a['date']);
          final fechaB = date_utils.AppDateUtils.parseToLocal(b['date']);
          return fechaA.compareTo(fechaB);
        } catch (e) {
          return 0;
        }
      });

      // Eliminar duplicados
      final ordenIdsVistos = <int>{};
      history.removeWhere((orden) {
        final ordenId = orden['ordenId'] as int?;
        if (ordenId == null) return true;
        if (ordenIdsVistos.contains(ordenId)) return true;
        ordenIdsVistos.add(ordenId);
        return false;
      });

      // Preservar metadata de cuenta dividida desde el historial local anterior:
      // las órdenes del backend no traen isDividedAccount/personNames/personAssignments,
      // así que los copiamos del historial local para que al volver a cuenta dividida sigan apareciendo las personas.
      final historialLocalPrev = _tableOrderHistory[tableKey] ?? [];
      for (final orden in history) {
        final ordenId = orden['ordenId'] as int?;
        if (ordenId == null) continue;
        Map<String, dynamic>? ordenLocal;
        for (final o in historialLocalPrev) {
          if ((o['ordenId'] as int?) == ordenId) {
            ordenLocal = o;
            break;
          }
        }
        if (ordenLocal != null) {
          if (ordenLocal['isDividedAccount'] != null) {
            orden['isDividedAccount'] = ordenLocal['isDividedAccount'];
          }
          if (ordenLocal['personNames'] != null) {
            orden['personNames'] = ordenLocal['personNames'];
          }
          if (ordenLocal['personAssignments'] != null) {
            orden['personAssignments'] = ordenLocal['personAssignments'];
          }
        }
      }

      // Guardar historial
      _tableOrderHistory[tableKey] = history;

      print(
        '✅ Historial mesa $tableId cargado: ${history.length} órdenes activas',
      );

      // Verificar si hay órdenes en modo dividido y restaurar/sincronizar modo y personas
      final hasDividedOrders = history.any((order) => order['isDividedAccount'] == true);
      final personNamesFromHistory = <String, String>{};
      if (hasDividedOrders) {
        for (var order in history) {
          if (order['isDividedAccount'] == true) {
            final personNames = order['personNames'] as Map<String, dynamic>?;
            if (personNames != null) {
              personNames.forEach((personId, name) {
                if (!personNamesFromHistory.containsKey(personId)) {
                  personNamesFromHistory[personId] = name.toString();
                }
              });
            }
          }
        }
      }

      if (hasDividedOrders && !(_isDividedAccountModeByTable[tableKey] ?? false)) {
        // Restaurar modo dividido si hay órdenes en modo dividido
        _isDividedAccountModeByTable[tableKey] = true;
        print('✅ Modo dividido restaurado para mesa $tableId');
      }

      // Siempre sincronizar lista de personas cuando hay cuenta dividida (restaurar o quitar quienes ya cerraron)
      if (hasDividedOrders && personNamesFromHistory.isNotEmpty) {
        _personNamesByTable[tableKey] = personNamesFromHistory;
        if (!_personCartItemsByTable.containsKey(tableKey)) {
          _personCartItemsByTable[tableKey] = {};
        }
        final maxId = personNamesFromHistory.keys
            .map((id) {
              final match = RegExp(r'person_(\d+)').firstMatch(id);
              return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
            })
            .fold(0, (max, id) => id > max ? id : max);
        _nextPersonIdByTable[tableKey] = maxId + 1;
        if (_selectedPersonIdByTable[tableKey] == null || !personNamesFromHistory.containsKey(_selectedPersonIdByTable[tableKey])) {
          _selectedPersonIdByTable[tableKey] = personNamesFromHistory.keys.first;
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar historial de mesa $tableId: $e');
    }
  }

  // Enviar orden "para llevar" al cajero (ahora agrupa todas las órdenes del mismo cliente)
  Future<void> sendTakeawayToCashier(int ordenId) async {
    // PROTECCIÓN: Prevenir ejecuciones simultáneas
    if (_processingTakeawayOrder) {
      print('⚠️ Mesero: Ya se está procesando una orden para llevar, ignorando solicitud duplicada');
      return;
    }
    
    // PROTECCIÓN: Verificar que la orden no esté ya enviada al cajero
    if (_sentToCashierOrders.contains(ordenId)) {
      print('⚠️ Mesero: Orden $ordenId ya fue enviada al cajero anteriormente, ignorando');
      return;
    }
    
    _processingTakeawayOrder = true;
    
    try {
      // Cargar historial de órdenes "para llevar" si no está cargado
      final takeawayHistory = getTakeawayOrderHistory();
      if (takeawayHistory.isEmpty) {
        await loadTakeawayOrderHistory();
      }

      // Buscar la orden específica en el historial o en el backend
      final ordenInicial = getTakeawayOrderHistory()
          .where((o) => o['ordenId'] == ordenId)
          .firstOrNull;

      // Obtener datos del cliente de la orden inicial
      String? clienteNombre;
      String? clienteTelefono;

      if (ordenInicial != null) {
        clienteNombre = ordenInicial['customerName'] as String?;
        clienteTelefono = ordenInicial['customerPhone'] as String?;
      } else {
        // Si no está en el historial, obtenerla del backend
        final ordenData = await _ordenesService.getOrden(ordenId);
        if (ordenData == null) {
          throw Exception('Orden no encontrada');
        }

        // Verificar que la orden no esté pagada/cancelada
        final estadoNombre =
            (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';
        if (estadoNombre == 'pagada' ||
            estadoNombre == 'cancelada' ||
            estadoNombre == 'cerrada') {
          throw Exception('La orden ya fue pagada o cancelada');
        }

        clienteNombre = ordenData['clienteNombre'] as String?;
        clienteTelefono = ordenData['clienteTelefono'] as String?;
      }

      // IMPORTANTE: Tomar TODAS las órdenes activas del mismo cliente
      // Esto permite cerrar la cuenta con todas las órdenes del cliente
      final historialCompleto = getTakeawayOrderHistory();
      final ordenesDelCliente = historialCompleto.where((order) {
        // Filtrar por mismo cliente (nombre y teléfono)
        final orderCustomerName = order['customerName'] as String? ?? '';
        final orderCustomerPhone = order['customerPhone'] as String? ?? '';

        final nombreCoincide =
            (clienteNombre?.toLowerCase().trim() ?? '') ==
            (orderCustomerName.toLowerCase().trim());
        final telefonoCoincide =
            (clienteTelefono?.trim() ?? '') == (orderCustomerPhone.trim());

        // Coincide si el nombre coincide Y (el teléfono coincide O ambos están vacíos)
        final esMismoCliente =
            nombreCoincide &&
            (telefonoCoincide ||
                (clienteTelefono?.isEmpty ??
                    true && orderCustomerPhone.isEmpty));

        if (!esMismoCliente) return false;

        // Excluir órdenes ya pagadas/cerradas
        final status = (order['status'] as String?)?.toLowerCase() ?? '';
        final esExcluida =
            status.contains('pagada') ||
            status.contains('cancelada') ||
            status.contains('cerrada') ||
            status.contains('enviada') ||
            status.contains('cobrada');
        return !esExcluida;
      }).toList();

      // Ordenar por fecha (más reciente primero)
      ordenesDelCliente.sort((a, b) {
        try {
          final fechaA = date_utils.AppDateUtils.parseToLocal(
            a['date'] ?? '1970-01-01',
          );
          final fechaB = date_utils.AppDateUtils.parseToLocal(
            b['date'] ?? '1970-01-01',
          );
          return fechaB.compareTo(fechaA);
        } catch (e) {
          return 0;
        }
      });

      // PROTECCIÓN: Eliminar duplicados y filtrar órdenes ya enviadas
      final ordenIdsVistos = <int>{};
      final allOrders = ordenesDelCliente.where((order) {
        final ordenId = order['ordenId'] as int?;
        if (ordenId == null) return false;
        
        // Excluir si ya está en _sentToCashierOrders
        if (_sentToCashierOrders.contains(ordenId)) {
          print('🚫 Mesero: Orden $ordenId ya fue enviada al cajero, excluyendo');
          return false;
        }
        
        // Excluir duplicados
        if (ordenIdsVistos.contains(ordenId)) {
          print('🚫 Mesero: Orden $ordenId duplicada, excluyendo');
          return false;
        }
        
        ordenIdsVistos.add(ordenId);
        return true;
      }).toList();
      
      print(
        '📋 Mesero: ${allOrders.length} órdenes activas del cliente $clienteNombre para cerrar cuenta (sin duplicados): ${allOrders.map((o) => o['ordenId']).toList()}',
      );

      if (allOrders.isEmpty) {
        print('⚠️ Mesero: No hay órdenes activas para procesar (todas ya fueron enviadas o están duplicadas)');
        _processingTakeawayOrder = false;
        return;
      }

      // Obtener todos los items de todas las órdenes
      final allBillItems = <BillItem>[];
      double totalConsumo = 0.0;
      int? lastOrdenId;
      double descuentoTotal = 0.0;
      double propinaSugerida = 0.0;
      int splitCount = 1;
      String? waiterNotes;
      DateTime? fechaCreacionMasAntigua;

      // IMPORTANTE: Obtener datos adicionales del historial (propina, descuento, etc.)
      final firstOrder = allOrders.first;
      descuentoTotal = (firstOrder['discount'] as num?)?.toDouble() ?? 0.0;
      propinaSugerida = (firstOrder['tip'] as num?)?.toDouble() ?? 0.0;
      splitCount = (firstOrder['splitCount'] as int?) ?? 1;
      waiterNotes = firstOrder['notes'] as String?;

      String? waiterNameFromOrder;
      for (var order in allOrders) {
        final ordenIdActual = order['ordenId'] as int?;
        if (ordenIdActual != null) {
          lastOrdenId = ordenIdActual;
          try {
            final ordenData = await _ordenesService.getOrden(ordenIdActual);
            if (ordenData != null) {
              // Obtener el nombre del mesero desde la orden (solo la primera vez)
              if (waiterNameFromOrder == null) {
                waiterNameFromOrder = ordenData['creadoPorNombre'] as String? ??
                    ordenData['creadoPorUsuarioNombre'] as String? ??
                    ordenData['waiterName'] as String?;
              }
              
              // Acumular descuentos y propinas de todas las órdenes
              final descuentoOrden =
                  (ordenData['descuentoTotal'] as num?)?.toDouble() ?? 0.0;
              final propinaOrden =
                  (ordenData['propinaSugerida'] as num?)?.toDouble() ?? 0.0;
              descuentoTotal += descuentoOrden;
              propinaSugerida += propinaOrden;

              // Combinar notas de todas las órdenes
              final notasOrden = ordenData['notas'] as String?;
              if (notasOrden != null && notasOrden.isNotEmpty) {
                if (waiterNotes == null || waiterNotes.isEmpty) {
                  waiterNotes = notasOrden;
                } else {
                  waiterNotes = '$waiterNotes\n$notasOrden';
                }
              }

              // Obtener fecha de creación más antigua
              final createdAt = ordenData['creadoEn'] as String?;
              if (createdAt != null) {
                try {
                  final fechaCreacion = date_utils.AppDateUtils.parseToLocal(
                    createdAt,
                  );
                  if (fechaCreacionMasAntigua == null ||
                      fechaCreacion.isBefore(fechaCreacionMasAntigua)) {
                    fechaCreacionMasAntigua = fechaCreacion;
                  }
                } catch (e) {
                  // Ignorar errores de parsing de fecha
                }
              }

              final items = ordenData['items'] as List<dynamic>? ?? [];
              for (var item in items) {
                final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
                final precioUnitario =
                    (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                
                // CRÍTICO: Calcular totalLinea siempre como cantidad × precioUnitario
                // Si totalLinea viene del backend como 0 o incorrecto, recalcular
                final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
                final totalLineaCalculado = precioUnitario * cantidad;
                
                // Usar el cálculo si el backend viene con 0 o si el calculado es diferente (tolerancia de 0.01)
                final totalLinea = (totalLineaBackend <= 0.01 || (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
                    ? totalLineaCalculado
                    : totalLineaBackend;
                
                totalConsumo += totalLinea;

                final productoNombre =
                    item['productoNombre'] as String? ?? 'Producto';
                final tamanoEtiqueta =
                    item['productoTamanoEtiqueta'] as String?;
                allBillItems.add(
                  BillItem(
                    name: _formatProductNameWithSize(
                      productoNombre,
                      tamanoEtiqueta,
                    ),
                    quantity: cantidad,
                    price: precioUnitario,
                    total: totalLinea,
                  ),
                );
              }
            }
          } catch (e) {
            print('Error al obtener detalles de orden $ordenIdActual: $e');
          }
        }
      }

      if (allBillItems.isNotEmpty) {
        // IMPORTANTE: Generar billId único basado en TODAS las órdenes agrupadas
        // Si hay múltiples órdenes, usar un formato que incluya todas
        final ordenIdsList =
            allOrders.map((o) => o['ordenId'] as int?).whereType<int>().toList()
              ..sort();

        final billId = ordenIdsList.length > 1
            ? 'BILL-TAKEAWAY-${clienteNombre?.replaceAll(' ', '-') ?? 'CLIENTE'}-${ordenIdsList.join('-')}'
            : (ordenIdsList.isNotEmpty
                  ? 'BILL-ORD-${ordenIdsList.first}'
                  : 'BILL-TEMP-${DateTime.now().millisecondsSinceEpoch}');

        // Verificar si ya existe un bill PENDIENTE para este billId (no solo por ordenId)
        final existingBill = _billRepository.bills
            .where((b) => b.id == billId && b.status == BillStatus.pending)
            .toList();
        if (existingBill.isNotEmpty) {
          print(
            '⚠️ Mesero: Ya existe un bill pendiente con ID $billId, no se crea duplicado',
          );

          // IMPORTANTE: Aunque ya exista el bill, las órdenes deben desaparecer del historial
          // porque ya fueron enviadas al cajero anteriormente
          final ordenIdsACerrar = allOrders
              .map((o) => o['ordenId'] as int?)
              .whereType<int>()
              .toSet();

          // Registrar órdenes como enviadas al cajero si no están registradas
          for (var ordenId in ordenIdsACerrar) {
            if (!_sentToCashierOrders.contains(ordenId)) {
              _sentToCashierOrders.add(ordenId);
              print('📝 Mesero: Orden $ordenId agregada a _sentToCashierOrders (bill ya existía)');
            }
          }
          await _saveSentToCashierOrders();
          
          // Verificar que se guardó correctamente
          final savedData = await _storage.read('mesero_sent_to_cashier_orders');
          print('✅ Mesero: Storage guardado correctamente: $savedData');

          // Remover órdenes del historial local INMEDIATAMENTE
          _tableOrderHistory.forEach((key, orders) {
            if (key.startsWith('takeaway') || key == 'takeaway-all') {
              final antes = orders.length;
              _tableOrderHistory[key] = orders.where((order) {
                final ordenId = order['ordenId'] as int?;
                return ordenId == null || !ordenIdsACerrar.contains(ordenId);
              }).toList();
              final despues = _tableOrderHistory[key]!.length;
              if (antes != despues) {
                print('🗑️ Mesero: ${antes - despues} órdenes removidas de $key (bill ya existía)');
              }
            }
          });

          // Notificar cambios INMEDIATAMENTE para actualizar la UI
          notifyListeners();

          // Recargar historial de takeaway desde el backend para asegurar sincronización
          await Future.delayed(const Duration(milliseconds: 300));
          await loadTakeawayOrderHistory();

          print(
            '✅ Mesero: ${ordenIdsACerrar.length} órdenes removidas del historial (bill ya existía): $ordenIdsACerrar',
          );
          _processingTakeawayOrder = false;
          return;
        }

        // Calcular total final: subtotal - descuento + propina
        final subtotalConDescuento = totalConsumo - descuentoTotal;
        final totalFinal = subtotalConDescuento + propinaSugerida;

        // PROTECCIÓN: Verificar nuevamente que el bill no exista antes de agregarlo
        final billExiste = _billRepository.bills
            .where((b) => b.id == billId && b.status == BillStatus.pending)
            .isNotEmpty;
        
        if (billExiste) {
          print('⚠️ Mesero: Bill $billId ya existe, no se crea duplicado');
          _processingTakeawayOrder = false;
          return;
        }

        // Verificar si es cuenta dividida (buscar en la primera orden del historial)
        final firstOrderTakeaway = allOrders.isNotEmpty ? allOrders.first : null;
        final isDividedAccountTakeaway = firstOrderTakeaway?['isDividedAccount'] as bool? ?? false;
        Map<String, dynamic>? personAssignmentsFromHistoryTakeaway;
        Map<String, String>? personNamesFromHistoryTakeaway;
        
        if (isDividedAccountTakeaway && firstOrderTakeaway != null) {
          personAssignmentsFromHistoryTakeaway = firstOrderTakeaway['personAssignments'] as Map<String, dynamic>?;
          personNamesFromHistoryTakeaway = (firstOrderTakeaway['personNames'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));
        }

        // Si es cuenta dividida, crear estructura por persona (misma lógica que en sendToCashier)
        List<PersonAccount>? personAccountsTakeaway;
        if (isDividedAccountTakeaway && personAssignmentsFromHistoryTakeaway != null && personNamesFromHistoryTakeaway != null) {
          personAccountsTakeaway = [];
          
          final itemsByPersonTakeaway = <String, List<BillItem>>{};
          
          for (var personId in personNamesFromHistoryTakeaway.keys) {
            itemsByPersonTakeaway[personId] = [];
            final assignedItems = personAssignmentsFromHistoryTakeaway[personId] as List<dynamic>? ?? [];
            
            for (var assignedItemKey in assignedItems) {
              final itemKeyParts = assignedItemKey.toString().split('|');
              if (itemKeyParts.length >= 2) {
                final itemName = itemKeyParts[0];
                final itemQty = int.tryParse(itemKeyParts[1]) ?? 1;
                
                final matchingItem = allBillItems.firstWhere(
                  (item) => item.name == itemName && item.quantity == itemQty,
                  orElse: () => allBillItems.first,
                );
                
                itemsByPersonTakeaway[personId]!.add(matchingItem.copyWith(personId: personId));
              }
            }
            
            final personSubtotal = itemsByPersonTakeaway[personId]!.fold<double>(
              0.0,
              (sum, item) => sum + item.total,
            );
            
            final personDiscount = descuentoTotal > 0
                ? (personSubtotal / totalConsumo) * descuentoTotal
                : 0.0;
            
            final personTip = propinaSugerida > 0
                ? (personSubtotal / totalConsumo) * propinaSugerida
                : 0.0;
            
            final personTotal = personSubtotal - personDiscount + personTip;
            
            personAccountsTakeaway.add(PersonAccount(
              id: personId,
              name: personNamesFromHistoryTakeaway[personId] ?? 'Persona',
              items: itemsByPersonTakeaway[personId]!,
              subtotal: personSubtotal,
              tax: 0.0,
              discount: personDiscount,
              total: personTotal,
            ));
          }
          
          // Items sin asignar
          final assignedItemNamesTakeaway = personAssignmentsFromHistoryTakeaway.values
              .expand((list) => (list as List<dynamic>).map((e) => e.toString()))
              .toSet();
          
          final unassignedItemsTakeaway = <BillItem>[];
          for (var item in allBillItems) {
            final itemKey = '${item.name}|${item.quantity}';
            if (!assignedItemNamesTakeaway.contains(itemKey)) {
              unassignedItemsTakeaway.add(item);
            }
          }
          
          if (unassignedItemsTakeaway.isNotEmpty) {
            final unassignedSubtotal = unassignedItemsTakeaway.fold<double>(
              0.0,
              (sum, item) => sum + item.total,
            );
            final unassignedDiscount = descuentoTotal > 0
                ? (unassignedSubtotal / totalConsumo) * descuentoTotal
                : 0.0;
            final unassignedTip = propinaSugerida > 0
                ? (unassignedSubtotal / totalConsumo) * propinaSugerida
                : 0.0;
            final unassignedTotal = unassignedSubtotal - unassignedDiscount + unassignedTip;
            
            personAccountsTakeaway.add(PersonAccount(
              id: 'unassigned',
              name: 'Sin asignar',
              items: unassignedItemsTakeaway,
              subtotal: unassignedSubtotal,
              tax: 0.0,
              discount: unassignedDiscount,
              total: unassignedTotal,
            ));
          }
        }
        
        final bill = BillModel(
          id: billId,
          tableNumber: null, // null para órdenes "para llevar"
          ordenId: lastOrdenId,
          ordenIds: ordenIdsList.isNotEmpty ? ordenIdsList : null,
          items: allBillItems,
          subtotal: totalConsumo,
          tax: 0.0,
          total: totalFinal,
          discount: descuentoTotal,
          splitCount: splitCount,
          status: BillStatus.pending,
          createdAt: fechaCreacionMasAntigua ?? date_utils.AppDateUtils.now(),
          waiterName: _loggedUserName ?? waiterNameFromOrder ?? 'Mesero',
          waiterNotes: waiterNotes,
          requestedByWaiter: true,
          isTakeaway: true,
          customerName: clienteNombre,
          customerPhone: clienteTelefono,
          isDividedAccount: isDividedAccountTakeaway,
          personAccounts: personAccountsTakeaway,
        );

        _billRepository.addBill(bill);

        // PROTECCIÓN: Emitir evento Socket.IO solo una vez
        final socketService = SocketService();
        print('📤 Mesero: Emitiendo evento cuenta.enviada para bill $billId');
        socketService.emit('cuenta.enviada', {
          'id': bill.id,
          'tableNumber': 'Para Llevar',
          'ordenId': lastOrdenId, // Orden principal para compatibilidad
          'ordenIds': ordenIdsList, // TODAS las órdenes agrupadas
          'items': allBillItems
              .map(
                (item) => ({
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.price,
                  'total': item.total,
                }),
              )
              .toList(),
          'subtotal': totalConsumo,
          'tax': 0.0,
          'total': totalFinal,
          'discount': descuentoTotal,
          'tip': propinaSugerida,
          'status': 'pending',
          'createdAt':
              (fechaCreacionMasAntigua ?? date_utils.AppDateUtils.now())
                  .toIso8601String(),
          'waiterName': bill.waiterName,
          'splitCount': splitCount,
          'isTakeaway': true,
          'customerName': clienteNombre,
          'customerPhone': clienteTelefono,
          'waiterNotes': waiterNotes,
          'multipleOrders':
              ordenIdsList.length > 1, // Flag para indicar múltiples órdenes
          'isDividedAccount': isDividedAccountTakeaway,
          if (personAccountsTakeaway != null)
            'personAccounts': personAccountsTakeaway.map((pa) => pa.toJson()).toList(),
        });

        print(
          '✅ Mesero: Bill enviado al cajero - ID: $billId, Cliente: $clienteNombre, ${ordenIdsList.length} órdenes agrupadas: $ordenIdsList',
        );

        print(
          '✅ Mesero: Bill creado con - Subtotal: $totalConsumo, Descuento: $descuentoTotal, Propina: $propinaSugerida, Total: $totalFinal',
        );

        // IMPORTANTE: Remover las órdenes del historial INMEDIATAMENTE antes de cerrarlas
        // Esto hace que desaparezcan instantáneamente de la UI
        final ordenIdsACerrar = allOrders
            .map((o) => o['ordenId'] as int?)
            .whereType<int>()
            .toSet();

        // IMPORTANTE: Registrar localmente PRIMERO para que el filtro funcione inmediatamente
        for (var order in allOrders) {
          final ordenIdActual = order['ordenId'] as int?;
          if (ordenIdActual != null && !_sentToCashierOrders.contains(ordenIdActual)) {
            _sentToCashierOrders.add(ordenIdActual);
            print('📝 Mesero: Orden $ordenIdActual agregada a _sentToCashierOrders');
          }
        }
        await _saveSentToCashierOrders();
        
        // Verificar que se guardó correctamente
        final savedData = await _storage.read('mesero_sent_to_cashier_orders');
        print('✅ Mesero: ${ordenIdsACerrar.length} órdenes registradas localmente como enviadas al cajero: $_sentToCashierOrders');
        print('✅ Mesero: Storage guardado correctamente: $savedData');

        // IMPORTANTE: Cambiar estado de TODAS las órdenes en el backend a "cerrada"
        // Esto es la FUENTE DE VERDAD - persiste entre reinicios de la app
        for (var order in allOrders) {
          final ordenIdActual = order['ordenId'] as int?;
          if (ordenIdActual != null) {
            await _marcarOrdenComoCerradaEnBackend(ordenIdActual);
            print(
              '✅ Mesero: Orden $ordenIdActual marcada como cerrada en backend',
            );
          }
        }

        // Remover órdenes del historial local INMEDIATAMENTE después de cerrarlas
        _tableOrderHistory.forEach((key, orders) {
          if (key.startsWith('takeaway') || key == 'takeaway-all') {
            final antes = orders.length;
            _tableOrderHistory[key] = orders.where((order) {
              final ordenId = order['ordenId'] as int?;
              return ordenId == null || !ordenIdsACerrar.contains(ordenId);
            }).toList();
            final despues = _tableOrderHistory[key]!.length;
            if (antes != despues) {
              print('🗑️ Mesero: ${antes - despues} órdenes removidas de $key');
            }
          }
        });

        // Notificar cambios INMEDIATAMENTE para actualizar la UI
        notifyListeners();

        // Recargar historial de takeaway desde el backend para asegurar sincronización
        // (con un pequeño delay para asegurar que el backend haya actualizado el estado)
        await Future.delayed(const Duration(milliseconds: 300));
        await loadTakeawayOrderHistory();

        print(
          '✅ Mesero: ${ordenIdsACerrar.length} órdenes removidas del historial y recargadas desde backend: $ordenIdsACerrar',
        );
      } else {
        throw Exception('No se encontraron items en las órdenes del cliente');
      }
    } catch (e) {
      print('❌ Error al enviar orden para llevar al cajero: $e');
      rethrow;
    } finally {
      // Siempre liberar el flag, incluso si hay error
      _processingTakeawayOrder = false;
    }
  }

  // Enviar cuenta al cajero (ahora obtiene la orden del backend si es necesario)
  Future<void> sendToCashier(int tableId) async {
    final tableIdStr = tableId.toString();
    final cart = _tableOrders[tableIdStr] ?? [];

    // Cargar historial si no está cargado
    final history = _tableOrderHistory[tableIdStr] ?? [];
    if (history.isEmpty) {
      await loadTableOrderHistory(tableId);
    }

    // IMPORTANTE: Tomar TODAS las órdenes activas (no pagadas/cerradas) de la mesa
    // Esto permite cerrar la cuenta con todas las órdenes del cliente actual
    final historialCompleto = _tableOrderHistory[tableIdStr] ?? [];
    final ordenesNoPagadas = historialCompleto.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      final esExcluida =
          status.contains('pagada') ||
          status.contains('cancelada') ||
          status.contains('cerrada') ||
          status.contains('enviada') ||
          status.contains('cobrada');
      return !esExcluida;
    }).toList();

    // Ordenar por fecha (más reciente primero)
    ordenesNoPagadas.sort((a, b) {
      try {
        final fechaA = date_utils.AppDateUtils.parseToLocal(
          a['date'] ?? '1970-01-01',
        );
        final fechaB = date_utils.AppDateUtils.parseToLocal(
          b['date'] ?? '1970-01-01',
        );
        return fechaB.compareTo(fechaA);
      } catch (e) {
        return 0;
      }
    });

    // Tomar TODAS las órdenes activas (no solo la primera)
    final allOrders = ordenesNoPagadas;
    print(
      '📋 Mesero: ${allOrders.length} órdenes activas para cerrar cuenta: ${allOrders.map((o) => o['ordenId']).toList()}',
    );

    final selectedTable = _tables.firstWhere(
      (table) => table.id == tableId,
      orElse: () {
        if (_selectedTable != null) {
          return _selectedTable!;
        }
        // Si no hay tabla seleccionada y la lista está vacía, lanzar excepción
        if (_tables.isEmpty) {
          throw Exception('No hay mesas disponibles');
        }
        return _tables.first;
      },
    );

    // Si hay órdenes en el historial, crear bill desde las órdenes
    if (allOrders.isNotEmpty) {
      // Obtener todos los items de todas las órdenes
      final allBillItems = <BillItem>[];
      double totalConsumo = 0.0;
      int? lastOrdenId;

      // IMPORTANTE: Obtener datos adicionales del historial (propina, descuento, etc.)
      // Estos datos se guardaron cuando se creó la orden en sendOrderToKitchen
      final firstOrder = allOrders.first;
      final descuentoHistorial =
          (firstOrder['discount'] as num?)?.toDouble() ?? 0.0;
      final propinaHistorial = (firstOrder['tip'] as num?)?.toDouble() ?? 0.0;
      final splitCountHistorial = (firstOrder['splitCount'] as int?) ?? 1;
      final customerNameHistorial = firstOrder['customerName'] as String?;
      final customerPhoneHistorial = firstOrder['customerPhone'] as String?;
      final isTakeawayHistorial = firstOrder['isTakeaway'] as bool? ?? false;
      final notesHistorial = firstOrder['notes'] as String?;

      print(
        '📋 Mesero: Datos del historial - Descuento: $descuentoHistorial, Propina: $propinaHistorial, SplitCount: $splitCountHistorial',
      );

      String? waiterNameFromOrder;
      for (var order in allOrders) {
        final ordenId = order['ordenId'] as int?;
        if (ordenId != null) {
          lastOrdenId = ordenId;
          try {
            final ordenData = await _ordenesService.getOrden(ordenId);
            if (ordenData != null) {
              // Obtener el nombre del mesero desde la orden (solo la primera vez)
              if (waiterNameFromOrder == null) {
                waiterNameFromOrder = ordenData['creadoPorNombre'] as String? ??
                    ordenData['creadoPorUsuarioNombre'] as String? ??
                    ordenData['waiterName'] as String?;
              }
              
              final items = ordenData['items'] as List<dynamic>? ?? [];
              for (var item in items) {
                final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
                final precioUnitario =
                    (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                
                // CRÍTICO: Calcular totalLinea siempre como cantidad × precioUnitario
                // Si totalLinea viene del backend como 0 o incorrecto, recalcular
                final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
                final totalLineaCalculado = precioUnitario * cantidad;
                
                // Usar el cálculo si el backend viene con 0 o si el calculado es diferente (tolerancia de 0.01)
                final totalLinea = (totalLineaBackend <= 0.01 || (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
                    ? totalLineaCalculado
                    : totalLineaBackend;
                
                totalConsumo += totalLinea;

                final productoNombre = item['productoNombre'] as String? ?? 'Producto';
                final tamanoEtiqueta = (item['productoTamanoEtiqueta'] ?? item['tamanoEtiqueta'] ?? item['tamanoNombre'] ?? item['sizeName'] ?? item['size'])?.toString();
                allBillItems.add(
                  BillItem(
                    name: _formatProductNameWithSize(productoNombre, tamanoEtiqueta),
                    quantity: cantidad,
                    price: precioUnitario,
                    total: totalLinea,
                  ),
                );
              }
            }
          } catch (e) {
            print('Error al obtener detalles de orden $ordenId: $e');
          }
        }
      }

      if (allBillItems.isNotEmpty) {
        // IMPORTANTE: Generar billId único basado en TODAS las órdenes agrupadas
        // Si hay múltiples órdenes, usar un formato que incluya todas
        final ordenIdsList =
            allOrders.map((o) => o['ordenId'] as int?).whereType<int>().toList()
              ..sort();

        final billId = ordenIdsList.length > 1
            ? 'BILL-MESA-${selectedTable.number}-${ordenIdsList.join('-')}'
            : (ordenIdsList.isNotEmpty
                  ? 'BILL-ORD-${ordenIdsList.first}'
                  : 'BILL-TEMP-${DateTime.now().millisecondsSinceEpoch}');

        // Verificar si ya existe un bill PENDIENTE para este billId (no solo por ordenId)
        final existingBill = _billRepository.bills
            .where((b) => b.id == billId && b.status == BillStatus.pending)
            .toList();
        if (existingBill.isNotEmpty) {
          print(
            '⚠️ Mesero: Ya existe un bill pendiente con ID $billId, no se crea duplicado',
          );

          // IMPORTANTE: Aunque ya exista el bill, las órdenes deben desaparecer del historial
          // porque ya fueron enviadas al cajero anteriormente
          final ordenIdsACerrar = allOrders
              .map((o) => o['ordenId'] as int?)
              .whereType<int>()
              .toSet();

          // Remover órdenes del historial local INMEDIATAMENTE
          final historialActual = _tableOrderHistory[tableIdStr] ?? [];
          _tableOrderHistory[tableIdStr] = historialActual.where((order) {
            final ordenId = order['ordenId'] as int?;
            return ordenId == null || !ordenIdsACerrar.contains(ordenId);
          }).toList();

          // Registrar órdenes como enviadas al cajero si no están registradas
          for (var ordenId in ordenIdsACerrar) {
            if (!_sentToCashierOrders.contains(ordenId)) {
              _sentToCashierOrders.add(ordenId);
            }
          }
          await _saveSentToCashierOrders();

          final eb = existingBill.first;
          if (eb.isDividedAccount == true && eb.personAccounts != null) {
            _registerDividedPersonsBillSent(tableIdStr, eb.personAccounts);
            await _saveDividedPersonsBillSent();
          }

          // Notificar cambios INMEDIATAMENTE para actualizar la UI
          notifyListeners();

          print(
            '✅ Mesero: ${ordenIdsACerrar.length} órdenes removidas del historial (bill ya existía): $ordenIdsACerrar',
          );
          return;
        }

        // Calcular total final: subtotal - descuento + propina
        final subtotalConDescuento = totalConsumo - descuentoHistorial;
        final totalFinal = subtotalConDescuento + propinaHistorial;

        // Verificar si es cuenta dividida (buscar en TODAS las órdenes del historial)
        final isDividedAccount = allOrders.any((order) => order['isDividedAccount'] == true);
        Map<String, dynamic>? personAssignmentsFromHistory;
        Map<String, String>? personNamesFromHistory;
        
        if (isDividedAccount) {
          // Consolidar personAssignments y personNames de TODAS las órdenes
          personAssignmentsFromHistory = <String, dynamic>{};
          personNamesFromHistory = <String, String>{};
          
          for (var order in allOrders) {
            if (order['isDividedAccount'] == true) {
              final orderPersonAssignments = order['personAssignments'] as Map<String, dynamic>?;
              final orderPersonNames = (order['personNames'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));
              
              // Agregar nombres de personas (sin duplicar)
              if (orderPersonNames != null) {
                personNamesFromHistory.addAll(orderPersonNames);
              }
              
              // Consolidar asignaciones de items por persona
              if (orderPersonAssignments != null) {
                for (var personId in orderPersonAssignments.keys) {
                  if (!personAssignmentsFromHistory.containsKey(personId)) {
                    personAssignmentsFromHistory[personId] = <dynamic>[];
                  }
                  final assignedItems = orderPersonAssignments[personId] as List<dynamic>? ?? [];
                  (personAssignmentsFromHistory[personId] as List).addAll(assignedItems);
                }
              }
            }
          }
          
          // Si no hay personNames en el historial, usar los del estado actual de la mesa
          if (personNamesFromHistory.isEmpty && _selectedTable != null) {
            final tableId = _selectedTable!.id.toString();
            personNamesFromHistory = Map.from(_personNamesByTable[tableId] ?? {});
          }
        }

        // Si es cuenta dividida, crear estructura por persona
        List<PersonAccount>? personAccounts;
        if (isDividedAccount && personAssignmentsFromHistory != null && personNamesFromHistory != null) {
          personAccounts = [];
          
          // Crear un mapa de items por persona basado en personAssignments
          final itemsByPerson = <String, List<BillItem>>{};
          
          // Crear un mapa de items disponibles con contadores para evitar duplicados
          // Usar un mapa que cuenta cuántas veces aparece cada item
          final itemCountMap = <String, List<BillItem>>{};
          for (var item in allBillItems) {
            final itemKey = '${item.name}|${item.quantity}';
            if (!itemCountMap.containsKey(itemKey)) {
              itemCountMap[itemKey] = [];
            }
            itemCountMap[itemKey]!.add(item);
          }
          
          // Para cada persona, buscar sus items en allBillItems
          for (var personId in personNamesFromHistory.keys) {
            itemsByPerson[personId] = [];
            final assignedItems = personAssignmentsFromHistory[personId] as List<dynamic>? ?? [];
            
            // Para cada item asignado a esta persona, buscarlo en itemCountMap
            for (var assignedItemKey in assignedItems) {
              final itemKey = assignedItemKey.toString();
              
              // Buscar el item en itemCountMap
              if (itemCountMap.containsKey(itemKey) && itemCountMap[itemKey]!.isNotEmpty) {
                // Tomar el primer item disponible y removerlo para evitar duplicados
                final matchingItem = itemCountMap[itemKey]!.removeAt(0);
                
                // Crear BillItem con personId
                itemsByPerson[personId]!.add(matchingItem.copyWith(personId: personId));
              } else {
                // Si no se encuentra, intentar parsear el key para buscar por nombre y cantidad
                final itemKeyParts = itemKey.split('|');
                if (itemKeyParts.length >= 2) {
                  final itemName = itemKeyParts[0];
                  final itemQty = int.tryParse(itemKeyParts[1]) ?? 1;
                  final searchKey = '$itemName|$itemQty';
                  
                  if (itemCountMap.containsKey(searchKey) && itemCountMap[searchKey]!.isNotEmpty) {
                    final matchingItem = itemCountMap[searchKey]!.removeAt(0);
                    itemsByPerson[personId]!.add(matchingItem.copyWith(personId: personId));
                  } else {
                    print('⚠️ No se encontró item "$itemKey" en allBillItems para $personId');
                  }
                }
              }
            }
            
            // Calcular subtotales por persona
            final personSubtotal = itemsByPerson[personId]!.fold<double>(
              0.0,
              (sum, item) => sum + item.total,
            );
            
            // Aplicar descuento proporcional por persona (si hay descuento)
            final personDiscount = descuentoHistorial > 0
                ? (personSubtotal / totalConsumo) * descuentoHistorial
                : 0.0;
            
            // Aplicar propina proporcional por persona (si hay propina)
            final personTip = propinaHistorial > 0
                ? (personSubtotal / totalConsumo) * propinaHistorial
                : 0.0;
            
            final personTotal = personSubtotal - personDiscount + personTip;
            
            personAccounts.add(PersonAccount(
              id: personId,
              name: personNamesFromHistory[personId] ?? 'Persona',
              items: itemsByPerson[personId]!,
              subtotal: personSubtotal,
              tax: 0.0,
              discount: personDiscount,
              total: personTotal,
            ));
          }
          
          // Agregar items sin asignar (si los hay) a una persona "Sin asignar"
          // Usar los items que quedaron en itemCountMap (no fueron asignados a ninguna persona)
          final unassignedItems = <BillItem>[];
          for (var itemsList in itemCountMap.values) {
            unassignedItems.addAll(itemsList);
          }
          
          if (unassignedItems.isNotEmpty) {
            final unassignedSubtotal = unassignedItems.fold<double>(
              0.0,
              (sum, item) => sum + item.total,
            );
            final unassignedDiscount = descuentoHistorial > 0
                ? (unassignedSubtotal / totalConsumo) * descuentoHistorial
                : 0.0;
            final unassignedTip = propinaHistorial > 0
                ? (unassignedSubtotal / totalConsumo) * propinaHistorial
                : 0.0;
            final unassignedTotal = unassignedSubtotal - unassignedDiscount + unassignedTip;
            
            personAccounts.add(PersonAccount(
              id: 'unassigned',
              name: 'Sin asignar',
              items: unassignedItems,
              subtotal: unassignedSubtotal,
              tax: 0.0,
              discount: unassignedDiscount,
              total: unassignedTotal,
            ));
          }
        }

        final bill = BillModel(
          id: billId,
          tableNumber: selectedTable.number,
          mesaCodigo: selectedTable.codigo,
          ordenId: lastOrdenId,
          // Siempre lista explícita si hay órdenes (cajero/loadBills/restore usan effectiveOrdenIds).
          ordenIds: ordenIdsList.isNotEmpty ? ordenIdsList : null,
          items: allBillItems, // Mantener items planos para compatibilidad
          subtotal: totalConsumo,
          tax: 0.0,
          total: totalFinal,
          discount: descuentoHistorial,
          status: BillStatus.pending,
          createdAt: date_utils.AppDateUtils.now(),
          waiterName: _loggedUserName ?? waiterNameFromOrder ?? 'Mesero',
          waiterNotes: notesHistorial,
          requestedByWaiter: true,
          isTakeaway: isTakeawayHistorial,
          customerName: customerNameHistorial,
          customerPhone: customerPhoneHistorial,
          splitCount: splitCountHistorial,
          isDividedAccount: isDividedAccount,
          personAccounts: personAccounts,
        );

        _billRepository.addBill(bill);

        if (isDividedAccount && personAccounts != null && personAccounts.isNotEmpty) {
          _registerDividedPersonsBillSent(tableIdStr, personAccounts);
          await _saveDividedPersonsBillSent();
        }

        // Emitir evento Socket.IO para notificar al cajero
        final socketService = SocketService();
        socketService.emit('cuenta.enviada', {
          'id': bill.id,
          'tableNumber': bill.tableNumber,
          'mesaCodigo': bill.mesaCodigo ?? bill.tableNumber?.toString(),
          'ordenId': lastOrdenId, // Orden principal para compatibilidad
          'ordenIds': ordenIdsList, // TODAS las órdenes agrupadas
          'items': allBillItems
              .map(
                (item) => ({
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.price,
                  'total': item.total,
                }),
              )
              .toList(),
          'subtotal': totalConsumo,
          'tax': 0.0,
          'total': totalFinal,
          'discount': descuentoHistorial,
          'tip': propinaHistorial,
          'status': 'pending',
          'createdAt': date_utils.AppDateUtils.now().toIso8601String(),
          'waiterName': bill.waiterName,
          'splitCount': splitCountHistorial,
          'isTakeaway': isTakeawayHistorial,
          'customerName': customerNameHistorial,
          'customerPhone': customerPhoneHistorial,
          'waiterNotes': notesHistorial,
          'multipleOrders':
              ordenIdsList.length > 1, // Flag para indicar múltiples órdenes
          'isDividedAccount': isDividedAccount,
          if (personAccounts != null)
            'personAccounts': personAccounts.map((pa) => pa.toJson()).toList(),
        });

        print(
          '✅ Mesero: Bill enviado al cajero - ID: $billId, Mesa: ${bill.tableNumber}, ${ordenIdsList.length} órdenes agrupadas: $ordenIdsList',
        );

        print(
          '✅ Mesero: Bill creado con - Subtotal: $totalConsumo, Descuento: $descuentoHistorial, Propina: $propinaHistorial, Total: $totalFinal',
        );

        // IMPORTANTE: Remover las órdenes del historial INMEDIATAMENTE antes de cerrarlas
        // Esto hace que desaparezcan instantáneamente de la UI
        final ordenIdsACerrar = allOrders
            .map((o) => o['ordenId'] as int?)
            .whereType<int>()
            .toSet();

        // Remover órdenes del historial local INMEDIATAMENTE
        final historialActual = _tableOrderHistory[tableIdStr] ?? [];
        _tableOrderHistory[tableIdStr] = historialActual.where((order) {
          final ordenId = order['ordenId'] as int?;
          return ordenId == null || !ordenIdsACerrar.contains(ordenId);
        }).toList();

        // No resetear aquí el modo dividido: el mesero debe usar "Cerrar división de cuenta"
        // después de que el cajero cobró, para volver a la vista de consumo.

        // Notificar cambios INMEDIATAMENTE para actualizar la UI
        notifyListeners();

        print(
          '✅ Mesero: ${ordenIdsACerrar.length} órdenes removidas del historial instantáneamente: $ordenIdsACerrar',
        );

        // IMPORTANTE: Cambiar estado de TODAS las órdenes en el backend a "cerrada"
        // Esto es la FUENTE DE VERDAD - persiste entre reinicios de la app
        for (var order in allOrders) {
          final ordenId = order['ordenId'] as int?;
          if (ordenId != null) {
            await _marcarOrdenComoCerradaEnBackend(ordenId);
            print('✅ Mesero: Orden $ordenId marcada como cerrada en backend');

            // Registrar también localmente como respaldo (igual que en takeaway)
            _sentToCashierOrders.add(ordenId);
          }
        }

        // Guardar registro de órdenes enviadas al cajero
        await _saveSentToCashierOrders();
        print(
          '📝 ${ordenIdsACerrar.length} órdenes registradas localmente como enviadas al cajero',
        );

        // Actualizar valor de orden en la mesa
        _tables = _tables.map((tableEntry) {
          if (tableEntry.id == tableId) {
            return tableEntry.copyWith(orderValue: totalFinal);
          }
          return tableEntry;
        }).toList();

        // Notificar cambios finales
        notifyListeners();
        return;
      }
    }

    // Si no hay órdenes en el historial pero hay carrito, crear bill desde el carrito
    if (cart.isNotEmpty) {
      // Obtener el ordenId de la última orden enviada para esta mesa
      final ordenId = _tableOrderIds[tableIdStr];

      // Si ya hay una orden creada, usar su ID para el bill
      // Si no, crear un ID temporal (se actualizará cuando se cree la orden)
      final billId = ordenId != null
          ? 'BILL-ORD-$ordenId'
          : 'BILL-TEMP-${DateTime.now().millisecondsSinceEpoch}';

      // Verificar si ya existe un bill para esta orden
      if (ordenId != null) {
        try {
          final existingBill = _billRepository.bills.firstWhere(
            (b) => b.ordenId == ordenId,
            orElse: () => BillModel(
              id: '',
              tableNumber: 0,
              items: [],
              subtotal: 0,
              tax: 0,
              total: 0,
              status: BillStatus.pending,
              createdAt: date_utils.AppDateUtils.now(),
            ),
          );
          // Si el bill existe y tiene un ID válido, no crear duplicado
          if (existingBill.id.isNotEmpty) {
            notifyListeners();
            return;
          }
        } catch (e) {
          // Si hay error al buscar, continuar con la creación
          print('Error al verificar bill existente: $e');
        }
      }

      // Calcular total incluyendo extras y salsas
      final total = cart.fold(0.0, (sum, item) {
        final qty =
            (item.customizations['quantity'] as num?)?.toDouble() ?? 1.0;
        double itemTotal = _getBaseUnitPrice(item) * qty;

        // Agregar precio de extras si existen
        final extraPrices =
            item.customizations['extraPrices'] as List<dynamic>? ?? [];
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            itemTotal += precio * qty;
          }
        }

        // Agregar precio de salsa si existe
        final saucePrice =
            (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
        if (saucePrice > 0) {
          itemTotal += saucePrice * qty;
        }

        return sum + itemTotal;
      });

      final billItems = cart.map((item) {
        final quantity =
            (item.customizations['quantity'] as num?)?.toInt() ?? 1;

        // Calcular precio unitario incluyendo extras y salsas
        double unitPrice = _getBaseUnitPrice(item);

        // Agregar extras al precio unitario
        final extraPrices =
            item.customizations['extraPrices'] as List<dynamic>? ?? [];
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            unitPrice += precio;
          }
        }

        // Agregar precio de salsa al precio unitario
        final saucePrice =
            (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
        if (saucePrice > 0) {
          unitPrice += saucePrice;
        }

        return BillItem(
          name: _formatProductNameWithSize(
            item.product.name,
            item.customizations['size'] as String?,
          ),
          quantity: quantity,
          price: unitPrice,
          total: unitPrice * quantity,
        );
      }).toList();

      // Intentar obtener el nombre del mesero desde la orden del backend
      String? waiterNameFromOrder;
      if (ordenId != null) {
        try {
          final ordenData = await _ordenesService.getOrden(ordenId);
          if (ordenData != null) {
            waiterNameFromOrder = ordenData['creadoPorNombre'] as String? ??
                ordenData['creadoPorUsuarioNombre'] as String? ??
                ordenData['waiterName'] as String?;
          }
        } catch (e) {
          print('Error al obtener nombre del mesero desde orden $ordenId: $e');
        }
      }

      final bill = BillModel(
        id: billId,
        tableNumber: selectedTable.number,
        mesaCodigo: selectedTable.codigo,
        ordenId: ordenId, // Incluir ordenId de la orden creada
        items: billItems,
        subtotal: total,
        tax: 0.0,
        total: total,
        discount: 0.0,
        status: BillStatus.pending,
        createdAt: date_utils.AppDateUtils.now(),
        waiterName: _loggedUserName ?? waiterNameFromOrder ?? 'Mesero',
        requestedByWaiter: true,
      );

      _billRepository.addBill(bill);

      // Emitir evento Socket.IO para notificar al cajero
      final socketService = SocketService();
      socketService.emit('cuenta.enviada', {
        'id': bill.id,
        'tableNumber': bill.tableNumber,
        'mesaCodigo': bill.mesaCodigo ?? bill.tableNumber?.toString(),
        'ordenId': ordenId,
        'items': billItems
            .map(
              (item) => ({
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'total': item.total,
              }),
            )
            .toList(),
        'subtotal': total,
        'tax': 0.0,
        'total': total,
        'status': 'pending',
        'createdAt': date_utils.AppDateUtils.nowCdmx().toIso8601String(),
        'waiterName': bill.waiterName,
        'splitCount': bill.splitCount,
      });

      // Actualizar valor de orden en la mesa
      _tables = _tables.map((tableEntry) {
        if (tableEntry.id == tableId) {
          return tableEntry.copyWith(orderValue: total);
        }
        return tableEntry;
      }).toList();

      // Agregar al historial como "Enviado al Cajero"
      final orderIdStr =
          ordenId?.toString() ?? 'ACC-${DateTime.now().millisecondsSinceEpoch}';
      final order = {
        'id': orderIdStr,
        'ordenId': ordenId,
        'items': cart.map((item) {
          final qty = (item.customizations['quantity'] as num?)?.toInt() ?? 1;
          return '${qty}x ${item.product.name}';
        }).toList(),
        'status': 'Enviado al Cajero',
        'time': date_utils.AppDateUtils.formatTime(date_utils.AppDateUtils.nowCdmx()),
        'date': date_utils.AppDateUtils.nowCdmx().toIso8601String(),
        'total': total,
      };

      final history = _tableOrderHistory[tableIdStr] ?? [];
      // Siempre agregar órdenes nuevas al historial
      _tableOrderHistory[tableIdStr] = [order, ...history];

      notifyListeners();
      return;
    }

    // Si no hay carrito ni órdenes en el historial, intentar obtener la orden del backend
    int? ordenIdParaBill = _tableOrderIds[tableIdStr];

    if (ordenIdParaBill == null) {
      // Intentar obtenerlo del historial
      final history = _tableOrderHistory[tableIdStr] ?? [];
      if (history.isNotEmpty) {
        final lastOrder = history.first;
        ordenIdParaBill = lastOrder['ordenId'] as int?;
      }
    }

    if (ordenIdParaBill == null) {
      // No hay orden disponible, no se puede crear bill
      throw Exception('No hay orden disponible para crear la cuenta');
    }

    // Obtener la orden del backend
    try {
      final ordenData = await _ordenesService.getOrden(ordenIdParaBill);
      if (ordenData == null) {
        throw Exception('No se pudo obtener la orden del backend');
      }

      // Crear billItems desde los items de la orden
      final itemsData = ordenData['items'] as List<dynamic>? ?? [];
      final billItems = itemsData.map((itemJson) {
        return BillItem(
          name: itemJson['productoNombre'] as String? ?? 'Producto',
          quantity: (itemJson['cantidad'] as num?)?.toInt() ?? 1,
          price: (itemJson['precioUnitario'] as num?)?.toDouble() ?? 0.0,
          total: (itemJson['totalLinea'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final subtotal = (ordenData['subtotal'] as num?)?.toDouble() ?? 0.0;
      final descuento =
          (ordenData['descuentoTotal'] as num?)?.toDouble() ?? 0.0;
      final impuesto = (ordenData['impuestoTotal'] as num?)?.toDouble() ?? 0.0;
      final total = (ordenData['total'] as num?)?.toDouble() ?? subtotal;

      final bill = BillModel(
        id: 'BILL-${DateTime.now().millisecondsSinceEpoch}',
        tableNumber: selectedTable.number,
        mesaCodigo: selectedTable.codigo,
        ordenId: ordenIdParaBill,
        items: billItems,
        subtotal: subtotal,
        tax: impuesto,
        total: total,
        discount: descuento,
        status: BillStatus.pending,
        createdAt: date_utils.AppDateUtils.now(),
        waiterName:
            ordenData['creadoPorNombre'] as String? ??
            ordenData['creadoPorUsuarioNombre'] as String? ??
            'Mesero',
        requestedByWaiter: true,
      );

      _billRepository.addBill(bill);

      // Actualizar valor de orden en la mesa
      _tables = _tables.map((tableEntry) {
        if (tableEntry.id == tableId) {
          return tableEntry.copyWith(orderValue: total);
        }
        return tableEntry;
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error al obtener orden del backend: $e');
      rethrow;
    }
  }

  // Enviar cuenta individual de una persona específica al cajero
  Future<void> sendPersonAccountToCashier(int tableId, String personId, String personName) async {
    final tableIdStr = tableId.toString();
    
    // Cargar historial si no está cargado
    final history = _tableOrderHistory[tableIdStr] ?? [];
    if (history.isEmpty) {
      await loadTableOrderHistory(tableId);
    }

    // Obtener solo las órdenes de esta persona específica
    final historialCompleto = _tableOrderHistory[tableIdStr] ?? [];
    final personOrders = historialCompleto.where((order) {
      // Verificar que sea cuenta dividida y que esta orden pertenezca a esta persona
      if (order['isDividedAccount'] != true) return false;
      
      final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
      if (personAssignments == null) return false;
      
      // Verificar si esta orden tiene items asignados a esta persona
      final assignedItems = personAssignments[personId] as List<dynamic>?;
      return assignedItems != null && assignedItems.isNotEmpty;
    }).toList();

    if (personOrders.isEmpty) {
      throw Exception('$personName no tiene pedidos para cerrar cuenta');
    }

    // Filtrar solo órdenes no pagadas/cerradas
    final ordenesNoPagadas = personOrders.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      final esExcluida =
          status.contains('pagada') ||
          status.contains('cancelada') ||
          status.contains('cerrada') ||
          status.contains('enviada') ||
          status.contains('cobrada');
      return !esExcluida;
    }).toList();

    if (ordenesNoPagadas.isEmpty) {
      throw Exception('$personName no tiene pedidos activos para cerrar cuenta');
    }

    final selectedTable = _tables.firstWhere(
      (table) => table.id == tableId,
      orElse: () {
        if (_selectedTable != null) {
          return _selectedTable!;
        }
        if (_tables.isEmpty) {
          throw Exception('No hay mesas disponibles');
        }
        return _tables.first;
      },
    );

    // Obtener todos los items de las órdenes de esta persona
    final allBillItems = <BillItem>[];
    double totalConsumo = 0.0;
    int? lastOrdenId;

    for (var order in ordenesNoPagadas) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId == null) continue;
      
      lastOrdenId = ordenId;
      try {
        final ordenData = await _ordenesService.getOrden(ordenId);
        if (ordenData != null) {
          final items = ordenData['items'] as List<dynamic>? ?? [];
          final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
          final assignedItems = personAssignments?[personId] as List<dynamic>? ?? [];
          
          // Crear un set de items asignados a esta persona para filtrar
          final assignedItemKeys = assignedItems.map((e) => e.toString()).toSet();
          
          for (var item in items) {
            final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
            final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
            final productoNombre = item['productoNombre'] as String? ?? 'Producto';
            final tamanoEtiqueta = (item['productoTamanoEtiqueta'] ?? item['tamanoEtiqueta'] ?? item['tamanoNombre'] ?? item['sizeName'] ?? item['size'])?.toString();
            final nombreConTamano = _formatProductNameWithSize(productoNombre, tamanoEtiqueta);
            final itemKey = '$nombreConTamano|$cantidad';
            
            // Solo incluir items que están asignados a esta persona
            if (!assignedItemKeys.contains(itemKey)) continue;
            
            final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
            final totalLineaCalculado = precioUnitario * cantidad;
            final totalLinea = (totalLineaBackend <= 0.01 || (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
                ? totalLineaCalculado
                : totalLineaBackend;
            
            totalConsumo += totalLinea;
            
            allBillItems.add(
              BillItem(
                name: nombreConTamano,
                quantity: cantidad,
                price: precioUnitario,
                total: totalLinea,
                personId: personId,
              ),
            );
          }
        }
      } catch (e) {
        print('Error al obtener detalles de orden $ordenId: $e');
      }
    }

    if (allBillItems.isEmpty) {
      throw Exception('No se encontraron items para $personName');
    }

    // Obtener datos adicionales de la primera orden
    final firstOrder = ordenesNoPagadas.first;
    final descuentoHistorial = (firstOrder['discount'] as num?)?.toDouble() ?? 0.0;
    final propinaHistorial = (firstOrder['tip'] as num?)?.toDouble() ?? 0.0;
    final splitCountHistorial = (firstOrder['splitCount'] as int?) ?? 1;
    final notesHistorial = firstOrder['notes'] as String?;
    String? waiterNameFromOrder;
    for (var order in ordenesNoPagadas) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId != null) {
        try {
          final ordenData = await _ordenesService.getOrden(ordenId);
          if (ordenData != null && waiterNameFromOrder == null) {
            waiterNameFromOrder = ordenData['creadoPorNombre'] as String? ??
                ordenData['creadoPorUsuarioNombre'] as String? ??
                ordenData['waiterName'] as String?;
          }
        } catch (e) {
          // Continuar si hay error
        }
      }
    }

    // Generar billId único para esta persona
    final ordenIdsList = ordenesNoPagadas.map((o) => o['ordenId'] as int?).whereType<int>().toList()..sort();
    final billId = 'BILL-MESA-${selectedTable.number}-PERSONA-$personId-${ordenIdsList.join('-')}';

    // Verificar si ya existe un bill pendiente
    final existingBill = _billRepository.bills
        .where((b) => b.id == billId && b.status == BillStatus.pending)
        .toList();
    if (existingBill.isNotEmpty) {
      print('⚠️ Mesero: Ya existe un bill pendiente para $personName con ID $billId');
      // Remover solo las órdenes de esta persona del historial
      final ordenIdsACerrar = ordenIdsList.toSet();
      final historialActual = _tableOrderHistory[tableIdStr] ?? [];
      _tableOrderHistory[tableIdStr] = historialActual.map((order) {
        final ordenId = order['ordenId'] as int?;
        if (ordenId == null || !ordenIdsACerrar.contains(ordenId)) {
          return order;
        }
        // Marcar como cerrada solo para esta persona (no eliminar completamente)
        final updatedOrder = Map<String, dynamic>.from(order);
        final personAssignments = updatedOrder['personAssignments'] as Map<String, dynamic>?;
        if (personAssignments != null && personAssignments.containsKey(personId)) {
          // Remover esta persona de las asignaciones (indicando que su cuenta está cerrada)
          final updatedAssignments = Map<String, dynamic>.from(personAssignments);
          updatedAssignments.remove(personId);
          updatedOrder['personAssignments'] = updatedAssignments;
        }
        return updatedOrder;
      }).toList();
      
      notifyListeners();
      return;
    }

    // Calcular totales
    final subtotalConDescuento = totalConsumo - descuentoHistorial;
    final totalFinal = subtotalConDescuento + propinaHistorial;

    // Crear PersonAccount solo para esta persona
    final personSubtotal = totalConsumo;
    final personDiscount = descuentoHistorial;
    final personTip = propinaHistorial;
    final personTotal = totalFinal;

    final personAccount = PersonAccount(
      id: personId,
      name: personName,
      items: allBillItems,
      subtotal: personSubtotal,
      tax: 0.0,
      discount: personDiscount,
      total: personTotal,
    );

    // Crear bill solo con esta persona
    final bill = BillModel(
      id: billId,
      tableNumber: selectedTable.number,
      mesaCodigo: selectedTable.codigo,
      items: allBillItems,
      subtotal: personSubtotal,
      tax: 0.0,
      discount: personDiscount,
      total: personTotal, // personTotal ya incluye la propina (personSubtotal - personDiscount + personTip)
      status: BillStatus.pending,
      createdAt: date_utils.AppDateUtils.now(),
      waiterName: _loggedUserName ?? waiterNameFromOrder ?? 'Mesero',
      waiterNotes: notesHistorial,
      requestedByWaiter: true,
      isTakeaway: false,
      splitCount: splitCountHistorial,
      isDividedAccount: true,
      personAccounts: [personAccount], // Solo esta persona
    );

    _billRepository.addBill(bill);

    // Emitir evento Socket.IO
    final socketService = SocketService();
    socketService.emit('cuenta.enviada', {
      'id': bill.id,
      'tableNumber': bill.tableNumber,
      'mesaCodigo': bill.mesaCodigo ?? bill.tableNumber?.toString(),
      'ordenId': lastOrdenId,
      'ordenIds': ordenIdsList,
      'items': allBillItems.map((item) => ({
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
            'total': item.total,
          })).toList(),
      'subtotal': personSubtotal,
      'tax': 0.0,
      'total': personTotal,
      'discount': personDiscount,
      'tip': personTip,
      'status': 'pending',
      'createdAt': date_utils.AppDateUtils.now().toIso8601String(),
      'waiterName': bill.waiterName,
      'splitCount': splitCountHistorial,
      'isDividedAccount': true,
      'personAccounts': [personAccount.toJson()],
    });

    print('✅ Mesero: Cuenta de $personName enviada al cajero - ID: $billId');

    // Remover solo las órdenes de esta persona del historial (marcándolas como parcialmente cerradas)
    final ordenIdsACerrar = ordenIdsList.toSet();
    final historialActual = _tableOrderHistory[tableIdStr] ?? [];
    _tableOrderHistory[tableIdStr] = historialActual.map((order) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId == null || !ordenIdsACerrar.contains(ordenId)) {
        return order;
      }
      // Si la orden tiene múltiples personas, solo remover esta persona
      final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
      if (personAssignments != null && personAssignments.length > 1) {
        final updatedOrder = Map<String, dynamic>.from(order);
        final updatedAssignments = Map<String, dynamic>.from(personAssignments);
        updatedAssignments.remove(personId);
        updatedOrder['personAssignments'] = updatedAssignments;
        return updatedOrder;
      }
      // Si solo tiene esta persona, remover completamente la orden
      return null;
    }).whereType<Map<String, dynamic>>().toList();

    // Marcar órdenes como cerradas en backend solo si ya no tienen otras personas
    for (var order in ordenesNoPagadas) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId != null) {
        final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
        // Solo marcar como cerrada si esta era la única persona o si ya no quedan personas
        if (personAssignments == null || personAssignments.length <= 1) {
          await _marcarOrdenComoCerradaEnBackend(ordenId);
          _sentToCashierOrders.add(ordenId);
        }
      }
    }

    await _saveSentToCashierOrders();
    notifyListeners();

    print('✅ Mesero: Cuenta de $personName cerrada. Quedan órdenes activas para otras personas.');
  }

  // Mejorar sendToKitchen para agregar al historial y enviar a cocina
  Future<void> sendOrderToKitchen({
    bool isTakeaway = false,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
    String? waiterName,
    double discount = 0.0,
    String? orderNote,
    double tip = 0.0,
    int splitCount = 1,
    List<CartItem>? specificItems, // Items específicos a enviar (para cuenta dividida)
    String? personId, // ID de la persona (para cuenta dividida)
  }) async {
    // Permitir pedidos para llevar sin mesa seleccionada
    if (!isTakeaway && _selectedTable == null) return;

    // Usar items específicos si se proporcionan, sino usar el carrito completo
    final currentCart = specificItems ?? getCurrentCart();
    if (currentCart.isEmpty) return;

    // Variables para el catch (necesarias para guardar historial en caso de error)
    Map<String, dynamic>? ordenCreada;
    int? ordenIdInt;
    double discountAmount = discount;
    double subtotal = 0.0;
    double totalConPropina = 0.0;
    List<String> itemsText = [];
    DateTime fechaCreacion = date_utils.AppDateUtils.now();
    String estadoRealOrden = 'abierta';

    try {
      // Preparar items para la orden
      final items = currentCart.map((cartItem) {
        final quantity =
            (cartItem.customizations['quantity'] as num?)?.toDouble() ?? 1.0;

        // Extraer nota de customizations si existe
        final nota = cartItem.customizations['nota'] as String?;
        final kitchenNotes = cartItem.customizations['kitchenNotes'] as String?;
        final notaCompleta = [
          nota,
          kitchenNotes,
        ].where((n) => n != null && n.isNotEmpty).join(' | ');

        // Extraer modificadores de extras si existen
        // IMPORTANTE: No enviar modificadores con IDs temporales para evitar errores de foreign key
        // En su lugar, agregar la información de extras a la nota del item
        final modificadores = <Map<String, dynamic>>[];
        final extras =
            cartItem.customizations['extras'] as List<dynamic>? ?? [];
        final extraPrices =
            cartItem.customizations['extraPrices'] as List<dynamic>? ?? [];

        // Construir texto de extras para agregar a la nota
        final extrasText = <String>[];
        for (var extraName in extras) {
          if (extraName is String && extraName.isNotEmpty) {
            // Buscar el precio correspondiente
            double precio = 0.0;
            for (var priceEntry in extraPrices) {
              if (priceEntry is Map && priceEntry['name'] == extraName) {
                precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
                break;
              }
            }
            if (precio > 0) {
              extrasText.add('$extraName (+\$${precio.toStringAsFixed(0)})');
            } else {
              extrasText.add(extraName);
            }
          }
        }

        // Agregar extras a la nota si existen
        String notaFinal = notaCompleta;
        if (extrasText.isNotEmpty) {
          final extrasStr = extrasText.join(', ');
          if (notaFinal.isNotEmpty) {
            notaFinal = '$notaFinal | Extras: $extrasStr';
          } else {
            notaFinal = 'Extras: $extrasStr';
          }
        }

        // Agregar salsa a la nota si existe
        final sauce = cartItem.customizations['sauce'] as String?;
        if (sauce != null && sauce.isNotEmpty && sauce != 'Sin salsa') {
          if (notaFinal.isNotEmpty) {
            notaFinal = '$notaFinal | Salsa: $sauce';
          } else {
            notaFinal = 'Salsa: $sauce';
          }
        }

        // Marcar descuento aplicado para reflejarlo en cuentas por cobrar (cajero/capitán).
        if (cartItem.product.descuentoActivo && cartItem.product.descuentoPorcentaje > 0) {
          final descuentoTag =
              'Descuento aplicado: ${cartItem.product.descuentoPorcentaje.toStringAsFixed(0)}%';
          if (notaFinal.isNotEmpty) {
            notaFinal = '$notaFinal | $descuentoTag';
          } else {
            notaFinal = descuentoTag;
          }
        }

        // Usar product.id directamente (ya es int)
        final productoId = cartItem.product.id;

        // Calcular precio unitario incluyendo extras
        double precioUnitarioConExtras = _getBaseUnitPrice(cartItem);
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            precioUnitarioConExtras += precio;
          }
        }

        // Agregar precio de salsa si tiene precio (buscar en productos de salsas)
        // Nota: El precio de la salsa ya debería estar en el producto si es de la BD
        // Por ahora, si la salsa tiene precio en el nombre o en los datos, se agrega
        if (sauce != null && sauce != 'Sin salsa') {
          // Si la salsa viene de la BD, el precio ya está incluido en el producto
          // Si no, buscar si tiene precio en el nombre (formato: "Nombre +$X")
          final match = RegExp(r'\+\$(\d+)').firstMatch(sauce);
          if (match != null) {
            final precioSalsa = double.tryParse(match.group(1) ?? '0') ?? 0.0;
            precioUnitarioConExtras += precioSalsa;
          }
        }

        return {
          'productoId': productoId,
          'productoTamanoId': cartItem.customizations['sizeId'] as int?,
          'cantidad': quantity,
          'precioUnitario': precioUnitarioConExtras,
          'nota': notaFinal.isNotEmpty ? notaFinal : null,
          'modificadores':
              modificadores, // Vacío por ahora, la info está en la nota
        };
      }).toList();

      // Calcular totales (incluyendo extras y salsas)
      subtotal = currentCart.fold(0.0, (sum, item) {
        final qty =
            (item.customizations['quantity'] as num?)?.toDouble() ?? 1.0;
        double itemTotal = _getBaseUnitPrice(item) * qty;

        // Agregar precio de extras si existen
        final extraPrices =
            item.customizations['extraPrices'] as List<dynamic>? ?? [];
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            itemTotal += precio * qty;
          }
        }

        // Agregar precio de salsa si existe (usando el precio real guardado)
        final saucePrice =
            (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
        if (saucePrice > 0) {
          itemTotal += saucePrice * qty;
        }

        return sum + itemTotal;
      });

      // Aplicar descuento
      discountAmount = discount;
      final subtotalAfterDiscount = subtotal - discountAmount;

      // Calcular tiempo estimado basado en items (aproximación: 5-8 min por item)
      final estimatedTimeMinutes = (items.length * 6).clamp(5, 30);

      // Crear orden en BD
      // pickupTime puede venir como String (ISO) o necesitar ser parseado
      String? pickupTimeISO;
      if (pickupTime != null && pickupTime.isNotEmpty) {
        // Si pickupTime es un String, intentar parsearlo y convertirlo a ISO
        final parsed = DateTime.tryParse(pickupTime);
        if (parsed != null) {
          pickupTimeISO = parsed.toIso8601String();
        } else {
          // Si no se puede parsear, asumir que ya está en formato ISO
          pickupTimeISO = pickupTime;
        }
      }

      // IVA México CDMX (16%): solo si está habilitado en configuración por el admin.
      // Si falla la config, el backend recalcula el IVA al crear la orden según su configuración.
      double impuestoTotal = 0.0;
      try {
        final config = await _configuracionService.getConfiguracion();
        if (config.ivaHabilitado) {
          impuestoTotal = (subtotal - discountAmount) * 0.16;
        }
      } catch (e) {
        // El backend aplica IVA según su configuración al crear la orden si la app envía 0
        assert(() {
          debugPrint('Mesero: no se pudo cargar config IVA: $e');
          return true;
        }());
      }
      totalConPropina = subtotalAfterDiscount + impuestoTotal + tip;

      // IMPORTANTE: Siempre guardar el mesaId si hay una mesa seleccionada
      final ordenData = {
        'mesaId': _selectedTable?.id,
        'clienteNombre': customerName,
        'clienteTelefono': customerPhone,
        'subtotal': subtotal,
        'descuentoTotal': discountAmount,
        'impuestoTotal': impuestoTotal,
        'propinaSugerida': tip > 0 ? tip : null,
        'total': totalConPropina,
        'items': items,
        'pickupTime': pickupTimeISO,
        'estimatedTime': estimatedTimeMinutes,
      };

      ordenCreada = await _createOrderWithSessionRecovery(ordenData);

      if (ordenCreada == null) {
        throw Exception('No se pudo crear la orden en el backend');
      }

      // Obtener el ID real de la orden del backend
      ordenIdInt = ordenCreada['id'] as int?;
      if (ordenIdInt == null) {
        throw Exception('La orden creada no tiene un ID válido');
      }

      final orderId = ordenIdInt.toString();

      // Guardar el ordenId en el mapa de ordenes por mesa (solo si no es para llevar)
      if (!isTakeaway && _selectedTable != null) {
        final tableId = _selectedTable!.id.toString();
        _tableOrderIds[tableId] = ordenIdInt;
      }

      // Obtener la fecha real de creación de la orden desde el backend
      // Usar AppDateUtils para convertir correctamente a zona horaria local
      final ordenCreadaFecha = ordenCreada['creadoEn'] as String?;
      fechaCreacion = date_utils.AppDateUtils.parseToLocal(ordenCreadaFecha);

      // Obtener el estado real de la orden desde el backend
      estadoRealOrden = ordenCreada['estadoNombre'] as String? ?? 'abierta';

      // Guardar items del carrito antes de limpiarlo (para el historial)
      itemsText = currentCart.map((item) {
        final qty = item.customizations['quantity'] as int? ?? 1;
        final nombreProducto = item.product.name;
        final tamano = item.customizations['size'] as String?;
        final nombreConTamano = _formatProductNameWithSize(nombreProducto, tamano);
        return '${qty}x $nombreConTamano';
      }).toList();

      // Crear pedido para historial local usando la fecha real del backend
      // IMPORTANTE: Usar formato consistente para el ID: ORD-{numero}
      final formattedOrderId = 'ORD-${ordenIdInt.toString().padLeft(6, '0')}';
      
      // Guardar información de asignación de personas si está en modo dividida
      Map<String, dynamic>? personAssignments;
      Map<String, String>? personNamesForHistory;
      if (isDividedAccountMode && _selectedTable != null) {
        final tableId = _selectedTable!.id.toString();
        personAssignments = {};
        personNamesForHistory = Map.from(_personNamesByTable[tableId] ?? {});
        
        // Si se está enviando el pedido de una persona específica, solo incluir esa persona
        if (personId != null && personNamesForHistory.containsKey(personId)) {
          // Solo incluir esta persona en el historial
          personNamesForHistory = {personId: personNamesForHistory[personId]!};
        }
        
        // Mapear cada item del carrito a su personId
        for (var item in currentCart) {
          final itemPersonId = item.customizations['personId'] as String?;
          // Si se especificó una persona, solo incluir items de esa persona
          if (personId != null && itemPersonId != personId) {
            continue;
          }
          if (itemPersonId != null) {
            final qty = item.customizations['quantity'] as int? ?? 1;
            final nombreProducto = item.product.name;
            final tamano = item.customizations['size'] as String?;
            final nombreConTamano = _formatProductNameWithSize(nombreProducto, tamano);
            final itemKey = '$nombreConTamano|$qty';
            
            if (!personAssignments.containsKey(itemPersonId)) {
              personAssignments[itemPersonId] = [];
            }
            (personAssignments[itemPersonId] as List).add(itemKey);
          }
        }
      }
      
      final order = {
        'id': formattedOrderId, // Formato estandarizado: ORD-000067
        'ordenId': ordenIdInt, // ID real de la orden en BD
        'items': itemsText, // Usar items guardados
        'status': estadoRealOrden, // Usar el estado real del backend
        'time': date_utils.AppDateUtils.formatTime(fechaCreacion),
        'date': fechaCreacion.toIso8601String(),
        'isTakeaway': isTakeaway,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'pickupTime': pickupTime,
        'notes': orderNote ?? '',
        'discount': discountAmount,
        'tip': tip,
        'splitCount': splitCount,
        'subtotal': subtotal,
        'total': totalConPropina,
        'tableNumber': isTakeaway
            ? null
            : _selectedTable?.number, // Agregar número de mesa
        'estimatedTime': ordenCreada['tiempoEstimadoPreparacion'] ??
            ordenCreada['estimatedTime'] ??
            estimatedTimeMinutes,
        // Campos para cuenta dividida (usando getter que obtiene el estado por mesa)
        'isDividedAccount': isDividedAccountMode,
        if (personAssignments != null) 'personAssignments': personAssignments,
        if (personNamesForHistory != null) 'personNames': personNamesForHistory,
      };

      // IMPORTANTE: Guardar en historial local INMEDIATAMENTE después de crear la orden
      // Esto asegura que el historial se guarde incluso si hay errores posteriores
      // Aplicar para TODOS los casos: pedidos normales Y pedidos para llevar (si hay mesa)
      if (_selectedTable != null) {
        final mesaTableId = _selectedTable!.id.toString();

        // Desactivar el flag de limpieza porque hay una nueva orden
        if (_historyCleared[mesaTableId] == true) {
          _historyCleared[mesaTableId] = false;
          await _saveClearedHistoryFlags();
        }

        // Agregar al historial local (asegurar que no haya duplicados)
        final history = _tableOrderHistory[mesaTableId] ?? [];
        // Verificar que no exista ya esta orden en el historial
        final existeOrden = history.any((o) => o['ordenId'] == ordenIdInt);
        if (!existeOrden) {
          _tableOrderHistory[mesaTableId] = [order, ...history];
        } else {
          // Si ya existe, actualizarla con los datos más recientes
          final index = history.indexWhere((o) => o['ordenId'] == ordenIdInt);
          if (index != -1) {
            history[index] = order;
            _tableOrderHistory[mesaTableId] = history;
          }
        }

        // Verificar que se guardó correctamente
        final historialVerificado = _tableOrderHistory[mesaTableId] ?? [];
        final ordenGuardada = historialVerificado.any(
          (o) => o['ordenId'] == ordenIdInt,
        );

        if (!ordenGuardada) {
          // Si no se guardó, intentar de nuevo
          final historyRetry = _tableOrderHistory[mesaTableId] ?? [];
          _tableOrderHistory[mesaTableId] = [order, ...historyRetry];
        }

        // Notificar cambios inmediatamente para actualizar la UI
        notifyListeners();
        // Guardar historial persistido después de agregar orden
        _savePersistedHistory();
        // Persistir estado dividir cuenta para restaurar al reentrar a la mesa
        if (isDividedAccountMode) {
          _persistDividedAccountState(mesaTableId);
        }
      } else if (isTakeaway && _selectedTable == null) {
        // Si es pedido para llevar sin mesa seleccionada, guardar con clave especial
        final takeawayKey = 'takeaway-$ordenIdInt';
        final history = _tableOrderHistory[takeawayKey] ?? [];
        final existeOrden = history.any((o) => o['ordenId'] == ordenIdInt);
        if (!existeOrden) {
          _tableOrderHistory[takeawayKey] = [order, ...history];
        } else {
          // Si ya existe, actualizarla con los datos más recientes
          final index = history.indexWhere((o) => o['ordenId'] == ordenIdInt);
          if (index != -1) {
            history[index] = order;
            _tableOrderHistory[takeawayKey] = history;
          }
        }
        // Notificar cambios inmediatamente para actualizar la UI
        notifyListeners();
        // Guardar historial persistido después de agregar orden
        _savePersistedHistory();
      }

      // IMPORTANTE: NO crear bill automáticamente aquí
      // El bill se crea cuando el mesero hace "cerrar cuenta" (sendToCashier)
      // Esto permite que la orden aparezca en el historial del mesero primero
      // y el mesero pueda revisarla antes de enviarla al cajero

      // Nota: Los datos de propina, descuento, etc. están guardados en el historial
      // y se usarán cuando se cree el bill en sendToCashier

      print(
        '📋 Mesero: Orden $ordenIdInt enviada a cocina. Aparecerá en historial.',
      );
      print(
        '📋 Mesero: Para enviar al cajero, el mesero debe hacer "Cerrar cuenta".',
      );

      // Enviar pedido a cocina a través del servicio (para notificaciones en tiempo real)
      final service = KitchenOrderService();
      service.sendOrderToKitchen(
        orderId: orderId,
        cartItems: currentCart,
        tableNumber: isTakeaway ? null : _selectedTable?.number,
        waiterName: waiterName ?? 'Mesero',
        isTakeaway: isTakeaway,
        customerName: customerName,
        customerPhone: customerPhone,
        pickupTime: pickupTime,
      );

      // Limpiar carrito: solo los items enviados si se especificaron items específicos
      if (specificItems != null) {
        // Remover solo los items específicos que se enviaron
        for (var item in specificItems) {
          removeFromCart(item.id);
        }
      } else {
        // Limpiar carrito completo si no se especificaron items
        clearCart();
      }

      // Verificación final: asegurar que el historial tenga la orden
      // Esto es una medida de seguridad en caso de que algo haya fallado antes
      // Incluir tanto pedidos normales como pedidos para llevar (si hay mesa seleccionada)
      if (_selectedTable != null) {
        final mesaTableId = _selectedTable!.id.toString();
        final historialVerificado = _tableOrderHistory[mesaTableId] ?? [];
        final ordenEnHistorial = historialVerificado.any(
          (o) => o['ordenId'] == ordenIdInt,
        );

        if (!ordenEnHistorial) {
          // Si no está, agregarla de nuevo usando el objeto order que ya creamos
          final history = _tableOrderHistory[mesaTableId] ?? [];
          _tableOrderHistory[mesaTableId] = [order, ...history];
        }
      }

      // Notificar cambios finales
      notifyListeners();

      // NO recargar bills aquí; solo deben crearse al enviar cuenta al cajero
    } catch (e, stackTrace) {
      print('Error al enviar orden a cocina: $e');
      print('Stack trace: $stackTrace');

      // IMPORTANTE: Asegurar que el historial se guarde incluso si hay errores
      // Si la orden se creó exitosamente pero falló algo después, guardar el historial
      try {
        if (ordenCreada != null &&
            ordenIdInt != null &&
            _selectedTable != null) {
          final mesaTableId = _selectedTable!.id.toString();
          final historialVerificado = _tableOrderHistory[mesaTableId] ?? [];
          final ordenEnHistorial = historialVerificado.any(
            (o) => o['ordenId'] == ordenIdInt,
          );

          if (!ordenEnHistorial) {
            // Si no está en el historial, intentar agregarla
            // Usar los datos que ya tenemos
            // IMPORTANTE: Usar formato consistente para el ID: ORD-{numero}
            final formattedOrderIdCatch =
                'ORD-${ordenIdInt.toString().padLeft(6, '0')}';
            final order = {
              'id': formattedOrderIdCatch,
              'ordenId': ordenIdInt,
              'items': itemsText.isNotEmpty
                  ? itemsText
                  : (currentCart.isEmpty
                        ? ['Error al obtener items']
                        : currentCart.map((item) {
                            final qty =
                                item.customizations['quantity'] as int? ?? 1;
                            final nombreProducto = item.product.name;
                            final tamano = item.customizations['size'] as String?;
                            final nombreConTamano = _formatProductNameWithSize(nombreProducto, tamano);
                            return '${qty}x $nombreConTamano';
                          }).toList()),
              'status': estadoRealOrden,
              'time': date_utils.AppDateUtils.formatTime(fechaCreacion),
              'date': fechaCreacion.toIso8601String(),
              'isTakeaway': isTakeaway,
              'customerName': customerName,
              'customerPhone': customerPhone,
              'pickupTime': pickupTime,
              'notes': orderNote ?? '',
              'discount': discountAmount,
              'tip': tip,
              'splitCount': splitCount,
              'subtotal': subtotal,
              'total': totalConPropina,
              'tableNumber': isTakeaway ? null : _selectedTable?.number,
            };

            final history = _tableOrderHistory[mesaTableId] ?? [];
            _tableOrderHistory[mesaTableId] = [order, ...history];
            notifyListeners();
          }
        }
      } catch (historialError) {
        print('Error al guardar historial en catch: $historialError');
      }

      rethrow;
    }
  }

  bool _isAuthRelatedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('no autorizado');
  }

  Future<Map<String, dynamic>?> _createOrderWithSessionRecovery(
    Map<String, dynamic> ordenData,
  ) async {
    try {
      return await _ordenesService.createOrden(ordenData);
    } catch (e) {
      if (!_isAuthRelatedError(e)) rethrow;

      final refreshToken = await _storage.read('refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception(
          'Tu sesión expiró. Inicia sesión de nuevo para seguir enviando órdenes.',
        );
      }

      final refreshed = await AuthService().refreshToken(refreshToken);
      if (!refreshed) {
        throw Exception(
          'Tu sesión expiró. Inicia sesión de nuevo para seguir enviando órdenes.',
        );
      }

      return await _ordenesService.createOrden(ordenData);
    }
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

  /// Crea una notificación descriptiva según el estado de la orden
  Map<String, String> _crearNotificacionOrden({
    required int ordenId,
    required String estadoNombre,
    int? mesaId,
    String? mesaCodigo,
    bool isTakeaway = false,
  }) {
    final estadoLower = estadoNombre.toLowerCase();
    String titulo;
    String mensaje;

    // Determinar si es para llevar (por estado o por falta de mesa)
    final esParaLlevar =
        isTakeaway ||
        estadoLower.contains('recoger') ||
        (mesaId == null && mesaCodigo == null);

    // Información de ubicación
    final ubicacion = esParaLlevar
        ? 'Para llevar'
        : TableModel.displayLabelFromCodigo(mesaCodigo, mesaId is int ? mesaId : null);

    // Determinar título y mensaje según el estado
    if (estadoLower.contains('listo') || estadoLower.contains('ready')) {
      if (esParaLlevar) {
        titulo = '🛍️ ¡Pedido Para Llevar Listo!';
        mensaje = 'Orden #$ordenId está lista para recoger';
      } else {
        titulo = '🍽️ ¡Pedido Listo!';
        mensaje = 'Orden #$ordenId ($ubicacion) está lista para servir';
      }
    } else if (estadoLower.contains('preparacion') ||
        estadoLower.contains('preparación') ||
        estadoLower.contains('cooking')) {
      if (esParaLlevar) {
        titulo = '👨‍🍳 Pedido Para Llevar en Preparación';
        mensaje = 'Orden #$ordenId para llevar se está preparando';
      } else {
        titulo = '👨‍🍳 En Preparación';
        mensaje = 'Orden #$ordenId ($ubicacion) se está preparando';
      }
    } else if (estadoLower.contains('pendiente') ||
        estadoLower.contains('pending')) {
      titulo = '📝 Orden Recibida';
      mensaje = 'Orden #$ordenId ($ubicacion) fue recibida';
    } else if (estadoLower.contains('pagada') || estadoLower.contains('paid')) {
      titulo = '✅ Orden Pagada';
      mensaje = 'Orden #$ordenId ($ubicacion) fue pagada';
    } else if (estadoLower.contains('cancelada') ||
        estadoLower.contains('cancelled')) {
      titulo = '❌ Orden Cancelada';
      mensaje = 'Orden #$ordenId ($ubicacion) fue cancelada';
    } else if (estadoLower.contains('entregada') ||
        estadoLower.contains('delivered')) {
      titulo = '🎉 Orden Entregada';
      mensaje = 'Orden #$ordenId ($ubicacion) fue entregada';
    } else if (estadoLower.contains('abierta') ||
        estadoLower.contains('open')) {
      titulo = '📋 Orden Abierta';
      mensaje = 'Orden #$ordenId ($ubicacion) está en curso';
    } else {
      // Estado genérico
      titulo = '📢 Actualización';
      mensaje = 'Orden #$ordenId ($ubicacion): $estadoNombre';
    }

    return {'titulo': titulo, 'mensaje': mensaje};
  }

  // Métodos de notificaciones
  // ordenId es opcional pero si se proporciona, se usa para evitar duplicados
  // createdAt: opcional; si se pasa (ej. al cargar desde API), se usa para mostrar "hace cuánto" correcto
  void addNotification(
    String title,
    String message, {
    int? ordenId,
    String? tipo,
    DateTime? createdAt,
    String? meseroNombre,
  }) {
    final now = DateTime.now();
    // Siempre usar "now" como timestamp para notificaciones en tiempo real (socket).
    // Si viene createdAt (carga desde API), usarlo parseado a local para evitar desfase de 6h.
    final DateTime timestampToStore = createdAt != null
        ? (createdAt.isUtc ? createdAt.toLocal() : createdAt)
        : now;

    // Evitar duplicados: si hay ordenId, verificar que no exista una notificación
    // para la misma orden con el mismo tipo en los últimos 30 segundos
    bool isDuplicate = false;

    if (ordenId != null) {
      isDuplicate = _pendingNotifications.any((notif) {
        final notifOrdenId = notif['ordenId'] as int?;
        final notifTipo = notif['tipo'] as String?;
        final notifTime = notif['timestamp'] as DateTime;
        final timeDiff = now.difference(notifTime).inSeconds;

        // Es duplicado si es la misma orden y mismo tipo (listo, preparacion, etc)
        // en los últimos 30 segundos
        return notifOrdenId == ordenId && notifTipo == tipo && timeDiff < 30;
      });
    } else {
      // Si no hay ordenId, comparar por mensaje exacto en los últimos 5 segundos
      isDuplicate = _pendingNotifications.any((notif) {
        final notifTime = notif['timestamp'] as DateTime;
        final timeDiff = now.difference(notifTime).inSeconds;
        return notif['title'] == title &&
            notif['message'] == message &&
            timeDiff < 5;
      });
    }

    if (!isDuplicate) {
      _pendingNotifications.insert(0, {
        'title': title,
        'message': message,
        'timestamp': timestampToStore,
        'ordenId': ordenId,
        'tipo': tipo,
        'read': false, // Para marcar si fue leída
        if (meseroNombre != null && meseroNombre.isNotEmpty) 'meseroNombre': meseroNombre,
      });

      // Mantener máximo 50 notificaciones
      if (_pendingNotifications.length > 50) {
        _pendingNotifications.removeRange(50, _pendingNotifications.length);
      }

      print(
        '📬 Notificación agregada: $title - $message (ordenId: $ordenId, tipo: $tipo, Total: ${_pendingNotifications.length})',
      );
      notifyListeners();
    } else {
      print(
        '⚠️ Notificación duplicada ignorada: $title - $message (ordenId: $ordenId, tipo: $tipo)',
      );
    }
  }

  void removeNotification(int index) async {
    if (index >= 0 && index < _pendingNotifications.length) {
      final notif = _pendingNotifications[index];
      removeNotificationByOrderAndType(
        notif['ordenId'] as int?,
        notif['tipo'] as String? ?? 'general',
      );
    }
  }

  /// Elimina una notificación por ordenId y tipo (estable). Evita errores por índice
  /// al hacer clic en la X. Actualización optimista: quita de la lista al instante.
  void removeNotificationByOrderAndType(int? ordenId, String tipo) {
    final idx = _pendingNotifications.indexWhere((n) {
      final oid = n['ordenId'] as int?;
      final t = n['tipo'] as String? ?? 'general';
      return oid == ordenId && t == tipo;
    });
    if (idx < 0) return;

    _pendingNotifications.removeAt(idx);
    notifyListeners();

    // Marcar como limpiada en backend en segundo plano (no bloquear la UI)
    if (ordenId != null) {
      _markNotificationAsCleared(ordenId, tipo).catchError((e) {
        print('⚠️ Mesero: Error al marcar notificación como limpiada: $e');
      });
    }
  }

  void clearAllNotifications() async {
    try {
      print('🧹 Mesero: Limpiando todas las notificaciones...');

      // IMPORTANTE: Primero marcar todas las alertas como leídas en el backend
      // Esto asegura que no vuelvan a aparecer cuando se recarguen desde la BD
      final alertasMarcadas = await _alertasService
          .marcarTodasLasAlertasComoLeidas();
      print(
        '✅ Mesero: $alertasMarcadas alertas marcadas como leídas en el backend',
      );

      // También marcar todas las notificaciones actuales como limpiadas localmente (respaldo)
      for (final notif in _pendingNotifications) {
        final ordenId = notif['ordenId'] as int?;
        final tipo = notif['tipo'] as String? ?? 'general';
        if (ordenId != null) {
          await _markNotificationAsCleared(ordenId, tipo);
        }
      }

      // Limpiar la lista local de notificaciones
      _pendingNotifications.clear();
      await _saveClearedNotifications();

      print('✅ Mesero: Todas las notificaciones limpiadas (backend y local)');
      notifyListeners();
    } catch (e) {
      print('❌ Error al limpiar todas las notificaciones: $e');
      // Aún así limpiar localmente para que la UI se actualice
      _pendingNotifications.clear();
      notifyListeners();
    }
  }

  // Obtener solo notificaciones no leídas
  int get unreadNotificationsCount {
    return _pendingNotifications.where((n) => n['read'] != true).length;
  }
}
