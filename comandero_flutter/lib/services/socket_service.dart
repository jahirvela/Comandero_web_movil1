import 'dart:async';
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

  /// Conectar al servidor Socket.IO
  Future<void> connect() async {
    // Si ya está conectado o conectando, no hacer nada
    if (_socket != null) {
      if (_socket!.connected) {
        return; // Ya está conectado
      }
      if (_connectionState.value == SocketConnectionState.connecting ||
          _connectionState.value == SocketConnectionState.reconnecting) {
        return; // Ya está intentando conectar
      }
    }

    try {
      _updateState(SocketConnectionState.connecting);

      final token = await _storage.read(key: 'accessToken');
      final station = await _storage.read(
        key: 'station',
      ); // Para estaciones de cocina

      if (token == null) {
        print('Socket.IO: No hay token de acceso, no se puede conectar');
        _updateState(SocketConnectionState.error);
        return;
      }

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports([
              'websocket',
            ]) // Solo WebSocket para mejor rendimiento
            .setAuth({'token': token, 'station': station})
            .enableAutoConnect() // Reconexión automática
            .enableReconnection() // Habilitar reconexión
            .setReconnectionAttempts(10) // Intentar hasta 10 veces
            .setReconnectionDelay(1000) // Esperar 1 segundo entre intentos
            .setReconnectionDelayMax(5000) // Máximo 5 segundos entre intentos
            .setTimeout(
              20000,
            ) // Timeout de 20 segundos (más tolerante para móvil)
            .build(),
      );

      _setupEventHandlers();
    } catch (e) {
      print('Error al conectar Socket.IO: $e');
      _updateState(SocketConnectionState.error);
    }
  }

  /// Configurar manejadores de eventos
  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('✅ Socket.IO conectado exitosamente (socket id: ${_socket?.id})');
      _updateState(SocketConnectionState.connected);
      // Registrar listeners pendientes cuando se conecte
      print('🔄 Procesando listeners pendientes después de conexión...');
      _registerPendingListeners();
    });

    _socket!.on('connected', (data) {
      print('Socket.IO: Confirmación de conexión recibida: $data');
    });

    _socket!.onDisconnect((reason) {
      print('Socket.IO desconectado: $reason');
      _updateState(SocketConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      print('Error de conexión Socket.IO: $error');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onError((error) {
      print('Error en Socket.IO: $error');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onReconnect((attemptNumber) {
      print('Socket.IO reconectando (intento $attemptNumber)');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      print('Socket.IO: Intento de reconexión $attemptNumber');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnectError((error) {
      print('Error al reconectar Socket.IO: $error');
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
  /// NOTA: NO limpiamos _pendingListeners para que se re-registren
  /// cuando el usuario haga login de nuevo (los controladores no se recrean)
  void disconnect() {
    print('🔌 Socket.IO: Desconectando socket...');

    // Remover todos los listeners del socket actual
    if (_socket != null) {
      for (final eventName in _registeredEvents) {
        _socket!.off(eventName);
      }
      // Limpiar listeners de conexión del socket
      _socket!.clearListeners();
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listenerCounts.clear(); // Limpiar contadores al desconectar
    // NO limpiar _pendingListeners - se re-registrarán cuando el socket se reconecte
    // Esto es importante porque los controladores no se recrean al hacer logout/login
    _updateState(SocketConnectionState.disconnected);

    print(
      '✅ Socket.IO: Socket desconectado (listeners activos preservados: ${_activeListeners.length}, pendientes: ${_pendingListeners.length})',
    );
  }

  /// Desconectar completamente y limpiar TODO (incluyendo listeners activos y pendientes)
  /// Usar solo cuando se cierra completamente la aplicación o cambia de usuario
  void disconnectCompletely() {
    print('🔌 Socket.IO: Desconectando completamente y limpiando TODO...');
    disconnect();
    _pendingListeners.clear();
    _activeListeners.clear();
    print('✅ Socket.IO: Desconectado y completamente limpio');
  }

  /// Reconectar manualmente (útil al cambiar de rol)
  Future<void> reconnect() async {
    print('🔄 Socket.IO: Reconectando...');
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
    print('✅ Socket.IO: Reconexión completada');
  }

  /// Forzar reconexión completa (desconectar, limpiar y volver a conectar)
  /// Usar cuando se cambia de usuario/rol
  Future<void> forceReconnect() async {
    print('🔄 Socket.IO: Forzando reconexión completa para cambio de rol...');
    disconnect();
    // Esperar un poco más para asegurar limpieza completa
    await Future.delayed(const Duration(milliseconds: 800));
    await connect();
    print('✅ Socket.IO: Reconexión forzada completada');
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
    _socket?.emit('cocina.alerta', payload);
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
    on('cocina.alerta', callback);
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
      'cocina.alerta', // Evento emitido por clientes
      'ticket.creado',
      'ticket.impreso',
      'ticket.actualizado',
      'cierre.creado',
      'cierre.actualizado',
    ];

    if (_socket == null || !_socket!.connected) {
      connect().then((_) {
        for (final tipo in tipos) {
          _listenerCounts[tipo] = (_listenerCounts[tipo] ?? 0) + 1;
          _socket?.on(tipo, (data) {
            try {
              if (data != null) {
                callback(tipo, data);
              }
            } catch (e) {
              print('Error en callback onAlerta para $tipo: $e');
            }
          });
        }
      });
      return;
    }

    for (final tipo in tipos) {
      _listenerCounts[tipo] = (_listenerCounts[tipo] ?? 0) + 1;
      _socket!.on(tipo, (data) {
        try {
          if (data != null) {
            callback(tipo, data);
          }
        } catch (e) {
          print('Error en callback onAlerta para $tipo: $e');
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
      print('🔌 Socket no conectado, conectando para emitir $eventName...');
      connect().then((_) {
        if (_socket != null && _socket!.connected) {
          print('✅ Socket conectado, emitiendo $eventName');
          _socket!.emit(eventName, data);
        } else {
          print('❌ Socket no se pudo conectar para emitir $eventName');
        }
      });
      return;
    }
    print('📤 Emitiendo evento: $eventName');
    _socket!.emit(eventName, data);
  }

  /// Escuchar evento personalizado - versión robusta
  /// Los listeners se registran inmediatamente si el socket está conectado,
  /// o se guardan como pendientes para registrarse cuando el socket se conecte
  /// IMPORTANTE: Los listeners se preservan en _activeListeners para reconexiones
  void on(String eventName, Function(dynamic) callback) {
    // Siempre guardar en activeListeners para reconexiones futuras
    _activeListeners[eventName] ??= [];
    // Evitar duplicados
    if (!_activeListeners[eventName]!.contains(callback)) {
      _activeListeners[eventName]!.add(callback);
    }

    // Si ya está conectado, registrar inmediatamente
    if (_socket != null && _socket!.connected) {
      print(
        '📌 Socket conectado, registrando listener para $eventName inmediatamente',
      );
      _registerListener(eventName, callback);
      return;
    }

    // Si no está conectado, guardar como pendiente
    _pendingListeners[eventName] ??= [];
    if (!_pendingListeners[eventName]!.contains(callback)) {
      _pendingListeners[eventName]!.add(callback);
    }
    print(
      '⏳ Socket no conectado, listener para $eventName guardado como pendiente',
    );

    // Intentar conectar si no hay socket
    if (_socket == null &&
        _connectionState.value != SocketConnectionState.connecting) {
      print('🔌 Iniciando conexión de socket...');
      connect();
      // No llamamos _registerPendingListeners() aquí porque onConnect lo hará
    }
  }

  /// Registrar un listener específico
  void _registerListener(String eventName, Function(dynamic) callback) {
    _socket?.on(eventName, (data) {
      try {
        print('📥 Evento recibido: $eventName');
        callback(data);
      } catch (e) {
        print('❌ Error en callback para $eventName: $e');
      }
    });
  }

  /// Registrar todos los listeners pendientes y activos
  /// Los pendientes se limpian después de registrar
  /// Los activos se preservan para futuras reconexiones
  void _registerPendingListeners() {
    // Primero registrar los listeners activos (para reconexiones)
    if (_activeListeners.isNotEmpty) {
      final totalActive = _activeListeners.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      print(
        '🔄 Re-registrando $totalActive listeners activos de ${_activeListeners.length} tipos de eventos...',
      );

      _activeListeners.forEach((eventName, callbacks) {
        for (final callback in callbacks) {
          _registerListener(eventName, callback);
        }
      });
      print('✅ Listeners activos re-registrados');
    }

    // Luego registrar los pendientes (primera conexión)
    if (_pendingListeners.isNotEmpty) {
      final totalPending = _pendingListeners.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      print(
        '📬 Registrando $totalPending callbacks pendientes de ${_pendingListeners.length} tipos de eventos...',
      );

      _pendingListeners.forEach((eventName, callbacks) {
        for (final callback in callbacks) {
          _registerListener(eventName, callback);
        }
      });

      // Solo limpiar pendientes, NO activos
      _pendingListeners.clear();
      print('✅ Listeners pendientes registrados y limpiados');
    }

    if (_activeListeners.isEmpty && _pendingListeners.isEmpty) {
      print('📭 No hay listeners para registrar');
    }
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
