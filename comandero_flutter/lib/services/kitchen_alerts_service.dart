/**
 * Servicio para manejar alertas de cocina (nuevo sistema)
 * 
 * Este servicio encapsula toda la comunicación relacionada con alertas de cocina
 * usando el nuevo sistema de eventos Socket.IO:
 * - kitchen:alert:create (mesero → servidor)
 * - kitchen:alert:new (servidor → cocineros)
 * - kitchen:alert:created (servidor → mesero, ACK)
 * - kitchen:alert:error (servidor → cliente, errores)
 */

import '../models/kitchen_alert.dart';
import 'socket_service.dart';

class KitchenAlertsService {
  final SocketService _socketService;
  bool _disposed = false;

  KitchenAlertsService(this._socketService);

  /// Enviar una alerta desde el mesero hacia los cocineros
  /// 
  /// El backend procesará la alerta, determinará la estación si es necesario,
  /// y la emitirá a los rooms apropiados (room:kitchen:all y room:kitchen:{station}).
  Future<void> sendAlert(KitchenAlert alert) async {
    if (_disposed) {
      print('⚠️ KitchenAlertsService: Servicio ya fue dispose, no se puede enviar alerta');
      return;
    }

    try {
      final payload = alert.toJson();
      
      print('📤 KitchenAlertsService: Enviando alerta - OrderId: ${alert.orderId}, Type: ${alert.type.name}, Station: ${alert.station.name}');
      
      // Emitir evento al servidor
      _socketService.emit('kitchen:alert:create', payload);
      
      print('✅ KitchenAlertsService: Alerta enviada exitosamente');
    } catch (e) {
      print('❌ KitchenAlertsService: Error al enviar alerta: $e');
      rethrow;
    }
  }

  /// Escuchar nuevas alertas de cocina (para cocineros)
  /// 
  /// Cuando un mesero envía una alerta, todos los cocineros en los rooms apropiados
  /// recibirán este evento con el payload completo de la alerta.
  void listenNewAlerts(void Function(KitchenAlert alert) onNewAlert) {
    if (_disposed) {
      print('⚠️ KitchenAlertsService: Servicio ya fue dispose, no se puede registrar listener');
      return;
    }

    print('🎧 KitchenAlertsService: Registrando listener para kitchen:alert:new');
    print('   Socket conectado: ${_socketService.isConnected}');
    
    // Verificar que el socket esté conectado antes de registrar el listener
    if (!_socketService.isConnected) {
      print('⚠️ KitchenAlertsService: Socket no está conectado, el listener se registrará cuando se conecte');
    }
    
    _socketService.on('kitchen:alert:new', (data) {
      try {
        if (_disposed) {
          print('⚠️ KitchenAlertsService: Servicio dispose, ignorando alerta');
          return;
        }
        
        print('📥 KitchenAlertsService: Evento kitchen:alert:new recibido');
        print('   Tipo de datos: ${data.runtimeType}');
        print('   Datos completos: $data');
        
        // Convertir data a Map si no lo es
        final Map<String, dynamic> alertData;
        if (data is Map<String, dynamic>) {
          alertData = data;
        } else if (data is Map) {
          alertData = Map<String, dynamic>.from(data);
        } else {
          print('❌ KitchenAlertsService: Formato de datos inválido para alerta: ${data.runtimeType}');
          print('   Datos recibidos: $data');
          return;
        }

        print('📋 KitchenAlertsService: Parseando alerta desde JSON...');
        print('   orderId: ${alertData['orderId']}');
        print('   station: ${alertData['station']}');
        print('   type: ${alertData['type']}');
        print('   message: ${alertData['message']}');

        // Parsear la alerta
        final alert = KitchenAlert.fromJson(alertData);
        
        print('✅ KitchenAlertsService: Alerta parseada exitosamente');
        print('   OrderId: ${alert.orderId}');
        print('   Station: ${alert.station.name}');
        print('   Type: ${alert.type.name}');
        print('   Message: ${alert.message}');
        
        // Llamar al callback
        print('📞 KitchenAlertsService: Llamando callback con la alerta...');
        onNewAlert(alert);
        print('✅ KitchenAlertsService: Callback ejecutado exitosamente');
      } catch (e, stackTrace) {
        print('❌ KitchenAlertsService: Error al procesar nueva alerta: $e');
        print('   Tipo de error: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
        print('   Datos que causaron el error: $data');
      }
    });
    
    print('✅ KitchenAlertsService: Listener registrado para kitchen:alert:new');
  }

  /// Escuchar confirmación de creación de alerta (para mesero)
  /// 
  /// Cuando el backend procesa exitosamente una alerta, envía este ACK
  /// al mesero que la creó.
  void listenCreateAck(void Function(KitchenAlert alert) onAck) {
    if (_disposed) {
      print('⚠️ KitchenAlertsService: Servicio ya fue dispose, no se puede registrar listener');
      return;
    }

    print('🎧 KitchenAlertsService: Registrando listener para kitchen:alert:created');
    
    _socketService.on('kitchen:alert:created', (data) {
      try {
        if (_disposed) return;
        
        print('📥 KitchenAlertsService: ACK de alerta recibido - $data');
        
        // Convertir data a Map si no lo es
        final Map<String, dynamic> alertData;
        if (data is Map<String, dynamic>) {
          alertData = data;
        } else if (data is Map) {
          alertData = Map<String, dynamic>.from(data);
        } else {
          print('❌ KitchenAlertsService: Formato de datos inválido para ACK: ${data.runtimeType}');
          return;
        }

        // Parsear la alerta
        final alert = KitchenAlert.fromJson(alertData);
        
        print('✅ KitchenAlertsService: ACK parseado - OrderId: ${alert.orderId}');
        
        // Llamar al callback
        onAck(alert);
      } catch (e, stackTrace) {
        print('❌ KitchenAlertsService: Error al procesar ACK: $e');
        print('Stack trace: $stackTrace');
      }
    });
  }

  /// Escuchar errores relacionados con alertas
  /// 
  /// Si hay un problema al procesar una alerta (validación, BD, etc.),
  /// el backend enviará este evento con información del error.
  void listenErrors(void Function(String message, Map<String, dynamic>? details) onError) {
    if (_disposed) {
      print('⚠️ KitchenAlertsService: Servicio ya fue dispose, no se puede registrar listener');
      return;
    }

    print('🎧 KitchenAlertsService: Registrando listener para kitchen:alert:error');
    
    _socketService.on('kitchen:alert:error', (data) {
      try {
        if (_disposed) return;
        
        print('❌ KitchenAlertsService: Error recibido - $data');
        
        // Convertir data a Map si no lo es
        final Map<String, dynamic> errorData;
        if (data is Map<String, dynamic>) {
          errorData = data;
        } else if (data is Map) {
          errorData = Map<String, dynamic>.from(data);
        } else {
          print('❌ KitchenAlertsService: Formato de datos inválido para error: ${data.runtimeType}');
          onError('Error desconocido', null);
          return;
        }

        final message = errorData['message'] as String? ?? 'Error al procesar alerta';
        final details = errorData['details'] as Map<String, dynamic>?;
        
        print('❌ KitchenAlertsService: Error procesado - Message: $message');
        
        // Llamar al callback
        onError(message, details);
      } catch (e, stackTrace) {
        print('❌ KitchenAlertsService: Error al procesar error: $e');
        print('Stack trace: $stackTrace');
        onError('Error al procesar mensaje de error', null);
      }
    });
  }

  /// Enviar ACK de cocinero (opcional, para futuro)
  /// 
  /// En el futuro, los cocineros podrán confirmar que vieron una alerta.
  /// Por ahora este método está disponible pero no se usa activamente.
  void sendAck({int? alertId, required int orderId}) {
    if (_disposed) {
      print('⚠️ KitchenAlertsService: Servicio ya fue dispose, no se puede enviar ACK');
      return;
    }

    try {
      final payload = {
        if (alertId != null) 'alertId': alertId,
        'orderId': orderId,
      };
      
      print('📤 KitchenAlertsService: Enviando ACK de cocinero - OrderId: $orderId');
      
      _socketService.emit('kitchen:alert:ack', payload);
    } catch (e) {
      print('❌ KitchenAlertsService: Error al enviar ACK: $e');
    }
  }

  /// Limpiar listeners y recursos
  /// 
  /// IMPORTANTE: Llamar este método cuando se haga dispose del widget/service
  /// para evitar memory leaks.
  void dispose() {
    if (_disposed) {
      return;
    }

    print('🔄 KitchenAlertsService: Limpiando listeners...');
    
    // Nota: No podemos usar socketService.off() directamente porque SocketService
    // no expone ese método. En su lugar, confiamos en que SocketService limpie
    // los listeners cuando se desconecte completamente.
    // Si necesitamos limpiar listeners específicos, sería necesario agregar
    // un método en SocketService para hacerlo.
    
    _disposed = true;
    print('✅ KitchenAlertsService: Servicio dispose completado');
  }
}

