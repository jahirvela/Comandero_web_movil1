import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Estado de conexión de Socket.IO
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Servicio para comunicación en tiempo real con Socket.IO
///
/// Incluye:
/// - Reconexión automática
/// - Estado de conexión observable
/// - Manejo robusto de errores de red
/// - Prevención de conexiones duplicadas
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Stream controller para el estado de conexión
  final _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();
  final _connectionState = ValueNotifier<SocketConnectionState>(
    SocketConnectionState.disconnected,
  );

  // Contador de listeners para evitar duplicados (se limpia al desconectar)
  final Map<String, int> _listenerCounts = {};

  /// Stream del estado de conexión
  Stream<SocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Notifier del estado de conexión (para usar con ValueListenableBuilder)
  ValueNotifier<SocketConnectionState> get connectionState => _connectionState;

  /// Estado actual de conexión
  SocketConnectionState get currentState => _connectionState.value;

  /// Verificar si está conectado
  bool get isConnected => _socket?.connected ?? false;

  /// Obtener el userId del socket autenticado (desde el evento 'connected')
  // Almacenar datos del usuario recibidos del evento 'connected'
  String? _connectedUserId;
  String? _connectedUserRole;
  List<String> _connectedUserRoles = [];

  /// Limpiar datos del usuario conectado
  void _clearConnectedUserData() {
    _connectedUserId = null;
    _connectedUserRole = null;
    _connectedUserRoles = [];
  }

  String? getSocketUserId() {
    // Preferir los datos del evento 'connected' sobre socket.auth
    // porque socket.auth puede no estar actualizado
    return _connectedUserId ?? _socket?.auth?['userId']?.toString();
  }

  /// Obtener el role del socket autenticado (desde el evento 'connected')
  String? getSocketUserRole() {
    // Preferir los datos del evento 'connected' sobre socket.auth
    return _connectedUserRole ?? _socket?.auth?['role']?.toString();
  }

  /// Obtener todos los roles del usuario conectado
  List<String> getSocketUserRoles() {
    return _connectedUserRoles.isNotEmpty
        ? _connectedUserRoles
        : (_socket?.auth?['roles'] as List<dynamic>? ?? [])
              .map((r) => r.toString())
              .toList();
  }

  /// Conectar al servidor Socket.IO
  ///
  /// IMPORTANTE: Este método SIEMPRE crea una nueva conexión usando el token más reciente del storage.
  /// NO reutiliza conexiones anteriores para evitar problemas de autenticación con usuarios diferentes.
  Future<void> connect() async {
    // CRÍTICO: Desconectar cualquier socket anterior ANTES de leer el token
    // Esto asegura que no usemos un token viejo de una conexión anterior
    if (_socket != null) {
      print(
        '🔄 Socket: Desconectando socket anterior antes de nueva conexión...',
      );
      try {
        _socket!.clearListeners();
        if (_socket!.connected) {
          _socket!.disconnect();
        }
        _socket!.dispose();
      } catch (e) {
        // Ignorar errores al desconectar
      }
      _socket = null;
      _clearConnectedUserData(); // Limpiar datos del usuario
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Si ya hay una conexión en progreso, esperar a que termine antes de crear otra
    if (_connectionState.value == SocketConnectionState.connecting ||
        _connectionState.value == SocketConnectionState.reconnecting) {
      print('⚠️ Socket: Ya hay una conexión en progreso, esperando...');
      int attempts = 0;
      while (attempts < 10 &&
          (_connectionState.value == SocketConnectionState.connecting ||
              _connectionState.value == SocketConnectionState.reconnecting)) {
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
      // Si después de esperar ya está conectado, verificar que sea con el usuario correcto
      if (_socket != null && _socket!.connected) {
        final currentUserId = await _storage.read(key: 'userId');
        final currentUserRole = await _storage.read(key: 'userRole');
        final socketUserId = getSocketUserId();
        final socketRole = getSocketUserRole();

        if (currentUserId != null &&
            currentUserRole != null &&
            socketUserId == currentUserId &&
            socketRole == currentUserRole) {
          print(
            '✅ Socket: Conexión previa válida - UserId: $currentUserId, Role: $currentUserRole',
          );
          Future.delayed(const Duration(milliseconds: 100), () {
            _registerPendingListeners();
          });
          return;
        } else {
          // Usuario no coincide, desconectar y continuar con nueva conexión
          print(
            '⚠️ Socket: Conexión previa con usuario incorrecto, desconectando...',
          );
          disconnectCompletely();
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    try {
      _updateState(SocketConnectionState.connecting);

      // CRÍTICO: Leer el token del storage directamente (sin cache)
      // IMPORTANTE: Leer siempre del storage para asegurar que tenemos el token más reciente
      // En Flutter Web, puede haber problemas de sincronización, así que leemos múltiples veces si es necesario
      String? token = await _storage.read(key: 'accessToken');
      final station = await _storage.read(key: 'station');
      String? userId = await _storage.read(key: 'userId');
      String? userRole = await _storage.read(key: 'userRole');

      // Si el token es null, intentar leer nuevamente después de un pequeño delay
      // Esto ayuda con problemas de sincronización en Flutter Web
      if (token == null) {
        print(
          '⚠️ Socket: Token no encontrado en primer intento, reintentando...',
        );
        await Future.delayed(const Duration(milliseconds: 200));
        token = await _storage.read(key: 'accessToken');
        userId = await _storage.read(key: 'userId');
        userRole = await _storage.read(key: 'userRole');
      }

      // Log de debug para ver qué se está leyendo
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length >= 2) {
            final payload = parts[1];
            final base64Payload = payload
                .replaceAll('-', '+')
                .replaceAll('_', '/');
            final paddedPayload =
                base64Payload + '=' * (4 - base64Payload.length % 4);
            final decoded = utf8.decode(base64Decode(paddedPayload));
            final payloadJson = jsonDecode(decoded) as Map<String, dynamic>;
            final tokenUserId = payloadJson['sub']?.toString();
            final tokenRoles = (payloadJson['roles'] as List<dynamic>? ?? [])
                .map((r) => r.toString())
                .toList();
            print(
              '🔍 Socket: Token leído del storage - userId en token: $tokenUserId, roles: ${tokenRoles.join(", ")}',
            );
            print(
              '🔍 Socket: Datos en storage - userId: $userId, userRole: $userRole',
            );
          }
        } catch (e) {
          print('⚠️ Socket: No se pudo decodificar el token para debug: $e');
        }
      }

      // Validar que tenemos todos los datos necesarios
      if (token == null || token.isEmpty) {
        print('❌ Socket: No hay token disponible para conectar');
        _updateState(SocketConnectionState.error);
        return;
      }

      if (userId == null ||
          userId.isEmpty ||
          userRole == null ||
          userRole.isEmpty) {
        print(
          '❌ Socket: Faltan datos de usuario (userId: $userId, userRole: $userRole)',
        );
        _updateState(SocketConnectionState.error);
        return;
      }

      // CRÍTICO: Verificar que el token corresponde al usuario actual
      // Decodificar el token para validar el userId
      String? tokenUserId;
      List<String> tokenRoles = [];

      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          final base64Payload = payload
              .replaceAll('-', '+')
              .replaceAll('_', '/');
          final paddedPayload =
              base64Payload + '=' * (4 - base64Payload.length % 4);
          final decoded = utf8.decode(base64Decode(paddedPayload));
          final payloadJson = jsonDecode(decoded) as Map<String, dynamic>;
          tokenUserId = payloadJson['sub']?.toString();
          tokenRoles = (payloadJson['roles'] as List<dynamic>? ?? [])
              .map((r) => r.toString())
              .toList();

          // Validar coincidencia
          if (tokenUserId != userId || !tokenRoles.contains(userRole)) {
            print('❌ Socket: Token no coincide con storage');
            print('   Token userId: $tokenUserId, Storage userId: $userId');
            print(
              '   Token roles: ${tokenRoles.join(", ")}, Storage role: $userRole',
            );
            print(
              '   ⚠️ Esto puede indicar que el storage tiene datos inconsistentes.',
            );
            print('   💡 Solución: Hacer logout y login nuevamente.');
            _updateState(SocketConnectionState.error);
            return;
          }
        } else {
          print('❌ Socket: Token inválido (no tiene formato JWT)');
          _updateState(SocketConnectionState.error);
          return;
        }
      } catch (e) {
        print('❌ Socket: Error al decodificar token: $e');
        _updateState(SocketConnectionState.error);
        return;
      }

      // Log de información (sin exponer el token completo)
      print(
        '🔌 Socket: Conectando con usuario - UserId: $userId, Role: $userRole',
      );
      print(
        '   🔑 Token válido y verificado (userId: $tokenUserId, roles: ${tokenRoles.join(", ")})',
      );

      // CRÍTICO: Releer el token JUSTO ANTES de crear el socket para evitar caché
      // En Flutter Web, FlutterSecureStorage puede tener problemas de sincronización
      // así que leemos el token una última vez justo antes de usarlo
      await Future.delayed(const Duration(milliseconds: 100));
      final finalToken = await _storage.read(key: 'accessToken');
      final finalUserIdFromStorage = await _storage.read(key: 'userId');
      final finalRoleFromStorage = await _storage.read(key: 'userRole');

      // Usar el token más reciente si está disponible
      if (finalToken != null && finalToken.isNotEmpty) {
        token = finalToken;
        // Actualizar userId y userRole solo si están disponibles en storage
        if (finalUserIdFromStorage != null &&
            finalUserIdFromStorage.isNotEmpty) {
          userId = finalUserIdFromStorage;
        }
        if (finalRoleFromStorage != null && finalRoleFromStorage.isNotEmpty) {
          userRole = finalRoleFromStorage;
        }

        // Revalidar el token actualizado si cambió
        if (finalToken != token) {
          print('   🔄 Usando token más reciente del storage');
          try {
            final parts = token.split('.');
            if (parts.length >= 2) {
              final payload = parts[1];
              final base64Payload = payload
                  .replaceAll('-', '+')
                  .replaceAll('_', '/');
              final paddedPayload =
                  base64Payload + '=' * (4 - base64Payload.length % 4);
              final decoded = utf8.decode(base64Decode(paddedPayload));
              final payloadJson = jsonDecode(decoded) as Map<String, dynamic>;
              tokenUserId = payloadJson['sub']?.toString();
              tokenRoles = (payloadJson['roles'] as List<dynamic>? ?? [])
                  .map((r) => r.toString())
                  .toList();
            }
          } catch (e) {
            print('⚠️ Socket: Error al revalidar token actualizado: $e');
          }
        }
      } else if (finalToken == null || finalToken.isEmpty) {
        print(
          '❌ Socket: Token desapareció del storage justo antes de conectar',
        );
        _updateState(SocketConnectionState.error);
        return;
      }

      // CRÍTICO: Crear conexión NUEVA sin reutilizar manager/sesión anterior
      // El backend SOLO usa el JWT para autenticación, NO necesita userId/role del cliente
      // IMPORTANTE: Usar enableForceNew() para forzar una nueva conexión cada vez
      final authData = <String, dynamic>{
        'token': token, // SOLO token - el backend extrae userId/roles del JWT
        if (station != null && station.isNotEmpty) 'station': station,
        // NO enviar userId ni role - el backend los obtiene del JWT verificado
      };

      // Log del token (sin exponer el token completo)
      final tokenPreview = token.length > 50
          ? '${token.substring(0, 20)}...${token.substring(token.length - 20)}'
          : token.substring(0, token.length > 30 ? 30 : token.length) + '...';
      print('📤 Socket: Conectando con token JWT (preview: $tokenPreview)');
      print(
        '📤 Socket: Token userId: $tokenUserId, Token roles: ${tokenRoles.join(", ")}',
      );

      // Crear socket NUEVO con enableForceNew para NO reutilizar conexiones anteriores
      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth(authData) // SOLO token y station (opcional)
            .enableForceNew() // CRÍTICO: Forzar nueva conexión, no reutilizar manager
            .disableAutoConnect() // Conectar manualmente después de configurar handlers
            .enableReconnection() // Permitir reconexión automática
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      print('Error al conectar Socket.IO: $e');
      _updateState(SocketConnectionState.error);
    }
  }

  /// Configurar manejadores de eventos
  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      final socketId = _socket?.id ?? 'unknown';
      print('✅ Socket.IO: Conectado exitosamente (socket id: $socketId)');
      _updateState(SocketConnectionState.connected);
      Future.delayed(const Duration(milliseconds: 200), () {
        print('🔧 Socket.IO: Registrando listeners pendientes...');
        _registerPendingListeners();
        print('✅ Socket.IO: Listeners registrados');
      });
    });

    _socket!.on('connected', (data) async {
      print('✅ Socket.IO: Confirmación de conexión recibida');

      if (data is! Map<String, dynamic>) {
        print('⚠️ Socket.IO: Datos de conexión inválidos');
        return;
      }

      final user = data['user'] as Map<String, dynamic>?;
      if (user == null) {
        print(
          '⚠️ Socket.IO: No se recibió información de usuario en el evento connected',
        );
        return;
      }

      final socketUserId = user['id']?.toString() ?? '';
      final socketUsername = user['username']?.toString() ?? 'N/A';
      final socketRoles = (user['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString())
          .toList();

      // CRÍTICO: Guardar los datos del usuario para uso posterior
      _connectedUserId = socketUserId;
      _connectedUserRoles = socketRoles;
      // El role principal es el primer rol o el que coincida con el storage
      _connectedUserRole = socketRoles.isNotEmpty ? socketRoles.first : null;

      print(
        '👤 Socket.IO: Usuario autenticado - ID: $socketUserId, Username: $socketUsername, Roles: ${socketRoles.join(", ")}',
      );

      // Verificar que el usuario del socket coincida con el del storage
      final storedUserId = await _storage.read(key: 'userId') ?? '';
      final storedRole = await _storage.read(key: 'userRole') ?? '';

      if (storedUserId.isEmpty || storedRole.isEmpty) {
        print(
          '⚠️ Socket.IO: No hay datos de usuario en storage para verificar',
        );
        _updateState(SocketConnectionState.error);
        return;
      }

      final mismatchUser = storedUserId != socketUserId;
      final mismatchRole = !socketRoles.contains(storedRole);

      if (mismatchUser || mismatchRole) {
        print('❌ Socket.IO: ERROR - Usuario/Rol no coincide');
        print(
          '   Socket recibido: id=$socketUserId, roles=${socketRoles.join(",")}',
        );
        print('   Storage esperado: id=$storedUserId, role=$storedRole');
        print(
          '   ⚠️ Esto indica que el backend recibió un token diferente al esperado.',
        );
        print('   💡 Posibles causas:');
        print(
          '      1. El token en storage es del usuario anterior (no se limpió en logout)',
        );
        print(
          '      2. El socket se creó antes de que el nuevo token se guardara',
        );
        print('      3. Hay múltiples instancias de la app corriendo');
        print('   🔧 Solución: Cierra sesión y vuelve a iniciar sesión.');

        // NO intentar reconectar automáticamente - esto causaría un bucle infinito
        // En su lugar, marcar como error y dejar que el usuario haga logout/login
        _updateState(SocketConnectionState.error);

        // Desconectar para evitar que se use este socket con usuario incorrecto
        disconnectCompletely();

        return;
      }

      // Conexión exitosa
      print('✅ Socket.IO: Usuario verificado correctamente - Todo coincide');
    });

    _socket!.onDisconnect((reason) {
      // Validar reason antes de imprimir
      final reasonStr = reason?.toString() ?? 'desconocida';
      print('Socket.IO desconectado: $reasonStr');
      _updateState(SocketConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      // Validar error antes de imprimir
      final errorStr = error?.toString() ?? 'Error desconocido';
      print('Error de conexión Socket.IO: $errorStr');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onError((error) {
      // Validar error antes de imprimir
      final errorStr = error?.toString() ?? 'Error desconocido';
      print('Error en Socket.IO: $errorStr');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onReconnect((attemptNumber) {
      // Validar attemptNumber antes de imprimir
      final attemptStr = attemptNumber?.toString() ?? 'desconocido';
      print('Socket.IO reconectando (intento $attemptStr)');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      // Validar attemptNumber antes de imprimir
      final attemptStr = attemptNumber?.toString() ?? 'desconocido';
      print('Socket.IO: Intento de reconexión $attemptStr');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnectError((error) {
      // Validar error antes de imprimir
      final errorStr = error?.toString() ?? 'Error desconocido';
      print('Error al reconectar Socket.IO: $errorStr');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onReconnectFailed((_) {
      print('Socket.IO: Falló la reconexión después de todos los intentos');
      _updateState(SocketConnectionState.error);
    });
  }

  /// Actualizar el estado de conexión
  void _updateState(SocketConnectionState state) {
    _connectionState.value = state;
    _connectionStateController.add(state);
  }

  /// Lista de eventos registrados para poder limpiarlos
  final List<String> _registeredEvents = [
    'pedido.creado',
    'pedido.actualizado',
    'pedido.cancelado',
    'alerta.demora',
    'alerta.cancelacion',
    'alerta.modificacion',
    'alerta.caja',
    'alerta.cocina',
    'alerta.mesa',
    'alerta.pago',
    'cocina.alerta',
    'pago.creado',
    'pago.actualizado',
    'mesa.creada',
    'mesa.actualizada',
    'mesa.eliminada',
    'ticket.creado',
    'ticket.impreso',
    'ticket.actualizado',
    'cierre.creado',
    'cierre.actualizado',
    'cuenta.enviada',
    'connected',
  ];

  /// Desconectar del servidor y limpiar el socket actual
  void disconnect() {
    if (_socket != null) {
      print('🔌 Socket: Desconectando socket actual...');
      for (final eventName in _registeredEvents) {
        _socket!.off(eventName);
      }
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = null;
    _listenerCounts.clear();
    _updateState(SocketConnectionState.disconnected);
    print('✅ Socket: Desconectado completamente');
  }

  /// Desconectar completamente y limpiar TODO
  void disconnectCompletely() {
    print('🔄 Socket: Desconectando completamente y limpiando todo...');

    // Desconectar y limpiar el socket actual
    if (_socket != null) {
      print('   🔌 Desconectando socket actual...');
      try {
        // Remover todos los listeners primero
        for (final eventName in _registeredEvents) {
          _socket!.off(eventName);
        }
        _socket!.clearListeners();

        // Desconectar el socket
        if (_socket!.connected) {
          _socket!.disconnect();
        }

        // Dispose del socket
        _socket!.dispose();
      } catch (e) {
        print('   ⚠️ Error al desconectar socket: $e');
      }
      _socket = null;
    }

    // Limpiar todos los listeners y contadores
    _pendingListeners.clear();
    _activeListeners.clear();
    _listenerCounts.clear();

    // Limpiar datos del usuario conectado
    _clearConnectedUserData();

    _updateState(SocketConnectionState.disconnected);
    print('✅ Socket: Desconexión completa finalizada');
  }

  /// Reconectar manualmente
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await connect();
  }

  /// Forzar reconexión completa
  ///
  /// NOTA: Este método ahora simplemente llama a disconnectCompletely() y luego connect()
  /// ya que connect() ya maneja correctamente la limpieza de sockets anteriores
  Future<void> forceReconnect() async {
    print('🔄 Socket: Iniciando reconexión forzada...');

    // Desconectar completamente y limpiar todo
    disconnectCompletely();

    // Esperar suficiente tiempo para que la desconexión se complete completamente
    await Future.delayed(const Duration(milliseconds: 800));

    // Conectar con el nuevo token (connect() ya lee del storage y valida)
    await connect();
  }

  /// Escuchar eventos de órdenes - usa el sistema robusto de listeners
  void onOrderCreated(Function(dynamic) callback) {
    on('pedido.creado', (data) {
      print('📦 Socket: Evento pedido.creado recibido');
      callback(data);
    });
  }

  void onOrderUpdated(Function(dynamic) callback) {
    on('pedido.actualizado', (data) {
      print('📦 Socket: Evento pedido.actualizado recibido');
      callback(data);
    });
  }

  void onOrderCancelled(Function(dynamic) callback) {
    on('pedido.cancelado', (data) {
      print('📦 Socket: Evento pedido.cancelado recibido');
      callback(data);
    });
  }

  /// Enviar alerta de cocina
  void emitKitchenAlert(Map<String, dynamic> payload) {
    print(
      '📤 Socket: Emitiendo alerta a cocina - Tipo: ${payload['tipo']}, Mensaje: ${payload['mensaje']}',
    );
    // Usar el emisor genérico para asegurar conexión y reintentos
    emit('cocina.alerta', payload);
  }

  /// Escuchar alertas en tiempo real - usa el sistema robusto de listeners
  void onAlertaDemora(Function(dynamic) callback) {
    on('alerta.demora', callback);
  }

  void onAlertaCancelacion(Function(dynamic) callback) {
    on('alerta.cancelacion', callback);
  }

  void onAlertaModificacion(Function(dynamic) callback) {
    on('alerta.modificacion', callback);
  }

  void onAlertaCaja(Function(dynamic) callback) {
    on('alerta.caja', callback);
  }

  void onAlertaCocina(Function(dynamic) callback) {
    on('alerta.cocina', (data) {
      print('🔔 Socket: Evento alerta.cocina recibido');
      print('🔔 Socket: Datos completos de alerta.cocina: $data');
      try {
        callback(data);
      } catch (e, stackTrace) {
        print('❌ Error en callback de alerta.cocina: $e');
        print('❌ Stack trace: $stackTrace');
      }
    });
  }

  /// Escuchar alertas de cocina (evento emitido por otros clientes)
  void onCocinaAlerta(Function(dynamic) callback) {
    print('👂 Socket: Registrando listener para cocina.alerta');
    on('cocina.alerta', (data) {
      print('📥 Socket: Evento cocina.alerta recibido - Datos: $data');
      callback(data);
    });
  }

  void onAlertaMesa(Function(dynamic) callback) {
    on('alerta.mesa', callback);
  }

  void onAlertaPago(Function(dynamic) callback) {
    on('alerta.pago', callback);
  }

  /// Escuchar eventos de pagos
  void onPaymentCreated(Function(dynamic) callback) {
    on('pago.creado', (data) {
      print('💳 Socket: Evento pago.creado recibido');
      callback(data);
    });
  }

  void onPaymentUpdated(Function(dynamic) callback) {
    on('pago.actualizado', (data) {
      print('💳 Socket: Evento pago.actualizado recibido');
      callback(data);
    });
  }

  /// Escuchar eventos de mesas
  void onTableCreated(Function(dynamic) callback) {
    on('mesa.creada', callback);
  }

  void onTableUpdated(Function(dynamic) callback) {
    on('mesa.actualizada', callback);
  }

  void onTableDeleted(Function(dynamic) callback) {
    on('mesa.eliminada', callback);
  }

  /// Escuchar eventos de tickets - usa el sistema robusto de listeners
  void onTicketCreated(Function(dynamic) callback) {
    on('ticket.creado', (data) {
      print('🎫 Socket: Evento ticket.creado recibido');
      callback(data);
    });
  }

  void onTicketPrinted(Function(dynamic) callback) {
    on('ticket.impreso', (data) {
      print('🖨️ Socket: Evento ticket.impreso recibido');
      callback(data);
    });
  }

  void onTicketUpdated(Function(dynamic) callback) {
    on('ticket.actualizado', (data) {
      print('🎫 Socket: Evento ticket.actualizado recibido');
      callback(data);
    });
  }

  /// Escuchar eventos de cierres de caja - usa el sistema robusto de listeners
  void onCashClosureCreated(Function(dynamic) callback) {
    on('cierre.creado', (data) {
      print('💰 Socket: Evento cierre.creado recibido');
      callback(data);
    });
  }

  void onCashClosureUpdated(Function(dynamic) callback) {
    on('cierre.actualizado', (data) {
      print('💰 Socket: Evento cierre.actualizado recibido');
      callback(data);
    });
  }

  /// Escuchar cualquier tipo de alerta
  void onAlerta(Function(String tipo, dynamic data) callback) {
    final tipos = [
      'alerta.demora',
      'alerta.cancelacion',
      'alerta.modificacion',
      'alerta.caja',
      'alerta.cocina',
      'alerta.mesa',
      'alerta.pago',
      'cocina.alerta', // Evento emitido por clientes y re-emitido por backend
      'ticket.creado',
      'ticket.impreso',
      'ticket.actualizado',
      'cierre.creado',
      'cierre.actualizado',
    ];

    // Usar el método on() que maneja listeners pendientes y activos correctamente
    for (final tipo in tipos) {
      _listenerCounts[tipo] = (_listenerCounts[tipo] ?? 0) + 1;
      on(tipo, (data) {
        try {
          if (data != null) {
            callback(tipo, data);
          }
        } catch (e) {
          print('❌ Error en callback onAlerta para $tipo: $e');
        }
      });
    }
  }

  /// Unirse a una sala específica
  void joinRoom(String room) {
    _socket?.emit('join', room);
  }

  /// Salir de una sala
  void leaveRoom(String room) {
    _socket?.emit('leave', room);
  }

  /// Lista de listeners pendientes que se registrarán cuando el socket se conecte
  final Map<String, List<Function(dynamic)>> _pendingListeners = {};

  /// Lista de listeners ACTIVOS que se preservan para reconexiones
  /// Esto asegura que los listeners se re-registren después de una reconexión
  final Map<String, List<Function(dynamic)>> _activeListeners = {};

  /// Emitir evento personalizado
  void emit(String eventName, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      print(
        '⚠️ Socket: No conectado, intentando conectar para emitir $eventName...',
      );
      connect()
          .then((_) {
            if (_socket != null && _socket!.connected) {
              final eventNameStr = eventName?.toString() ?? 'unknown';
              print('✅ Socket: Conectado, emitiendo $eventNameStr');
              try {
                _socket!.emit(eventNameStr, data);
              } catch (e) {
                final errorMsg = e?.toString() ?? 'Error desconocido';
                print('❌ Socket: Error al emitir $eventNameStr: $errorMsg');
              }
            } else {
              final eventNameStr = eventName?.toString() ?? 'unknown';
              print('❌ Socket: No se pudo conectar para emitir $eventNameStr');
            }
          })
          .catchError((e) {
            final errorMsg = e?.toString() ?? 'Error desconocido';
            final eventNameStr = eventName?.toString() ?? 'unknown';
            print(
              '❌ Socket: Error al conectar para emitir $eventNameStr: $errorMsg',
            );
          });
      return;
    }

    try {
      print('📤 Socket: Emitiendo evento $eventName');
      _socket!.emit(eventName, data);
    } catch (e) {
      print('❌ Socket: Error al emitir evento $eventName: $e');
    }
  }

  /// Escuchar evento personalizado
  void on(String eventName, Function(dynamic) callback) {
    // Guardar en activeListeners para reconexiones futuras
    _activeListeners[eventName] ??= [];
    if (!_activeListeners[eventName]!.contains(callback)) {
      _activeListeners[eventName]!.add(callback);
    }

    // Si ya está conectado, registrar inmediatamente
    if (_socket != null && _socket!.connected) {
      _registerListener(eventName, callback);
      return;
    }

    // Si no está conectado, guardar como pendiente
    _pendingListeners[eventName] ??= [];
    if (!_pendingListeners[eventName]!.contains(callback)) {
      _pendingListeners[eventName]!.add(callback);
    }

    // Intentar conectar si no hay socket
    if (_socket == null &&
        _connectionState.value != SocketConnectionState.connecting) {
      connect();
    }
  }

  /// Registrar un listener específico
  void _registerListener(String eventName, Function(dynamic) callback) {
    if (_socket == null || !_socket!.connected) {
      print(
        '⚠️ Socket: No se puede registrar listener para $eventName (socket no conectado)',
      );
      return;
    }

    // IMPORTANTE: No remover el listener anterior si ya existe, solo agregar el nuevo
    // Esto evita que se pierdan listeners cuando se reconecta
    // En su lugar, usar una función wrapper que llame a todos los callbacks registrados

    // Registrar el listener directamente en el socket
    // Socket.IO permite múltiples listeners para el mismo evento, así que cada callback
    // se ejecutará cuando llegue el evento. No necesitamos verificar si ya existe.
    _socket!.on(eventName, (data) {
      try {
        // Validar eventName antes de imprimir para evitar nulls
        final eventNameStr = eventName?.toString() ?? 'unknown';
        print('📥 Socket: Evento $eventNameStr recibido');
        callback(data);
      } catch (e) {
        // Validar error antes de imprimir
        final errorMsg = e?.toString() ?? 'Error desconocido';
        final eventNameStr = eventName?.toString() ?? 'unknown';
        print('❌ Error en callback para $eventNameStr: $errorMsg');
      }
    });

    print('✅ Socket: Listener registrado para $eventName');
  }

  /// Registrar todos los listeners pendientes y activos
  void _registerPendingListeners() {
    if (_socket == null || !_socket!.connected) {
      print(
        '⚠️ Socket: No se pueden registrar listeners (socket no conectado)',
      );
      return;
    }

    final totalActive = _activeListeners.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final totalPending = _pendingListeners.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    print(
      '🔧 Socket: Registrando listeners - Activos: $totalActive, Pendientes: $totalPending',
    );

    // Registrar listeners activos (para reconexiones)
    _activeListeners.forEach((eventName, callbacks) {
      for (final callback in callbacks) {
        _registerListener(eventName, callback);
      }
    });

    // Registrar listeners pendientes (primera conexión)
    _pendingListeners.forEach((eventName, callbacks) {
      for (final callback in callbacks) {
        _registerListener(eventName, callback);
      }
    });

    _pendingListeners.clear();
    print('✅ Socket: Todos los listeners registrados');
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _pendingListeners.clear();
    _activeListeners.clear();
    _connectionStateController.close();
    _connectionState.dispose();
  }
}
