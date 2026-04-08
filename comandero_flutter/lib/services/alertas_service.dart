import '../utils/date_utils.dart' as date_utils;
import 'socket_service.dart';
import 'auth_service.dart';
import 'api_service.dart';

/// Servicio para manejar alertas con el backend y Socket.IO
class AlertasService {
  final ApiService _api = ApiService();
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();

  /// Crear alerta y enviarla al backend y por Socket.IO
  Future<void> crearAlerta({
    required String tipo,
    required String mensaje,
    int? ordenId,
    int? mesaId,
    int? productoId,
    String prioridad = 'media',
    String? estacion,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Obtener usuario actual
      final usuarioData = await _authService.getProfile();
      if (usuarioData == null) {
        throw Exception('Usuario no autenticado');
      }

      final usuarioId = usuarioData['id'] as int? ?? 0;
      final username = usuarioData['username'] as String? ?? 'Usuario';
      final roles =
          (usuarioData['roles'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          ['mesero'];

      // Preparar payload para el backend
      final payload = {
        'tipo': tipo,
        'mensaje': mensaje,
        if (ordenId != null) 'ordenId': ordenId,
        if (mesaId != null) 'mesaId': mesaId,
        if (productoId != null) 'productoId': productoId,
        'prioridad': prioridad,
        if (estacion != null) 'estacion': estacion,
        'emisor': {
          'id': usuarioId,
          'username': username,
          'rol': roles.isNotEmpty ? roles.first : 'mesero',
        },
        'timestamp': date_utils.AppDateUtils.nowCdmx().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      // Enviar al backend (guarda en BD)
      // NOTA: baseUrl ya incluye /api, así que solo usar /alertas
      try {
        await _api.post('/alertas', data: payload);
      } catch (e) {
        print('Error al guardar alerta en backend: $e');
        // Continuar aunque falle el guardado en BD
      }

      // Enviar por Socket.IO para tiempo real
      _socketService.emitKitchenAlert({
        'mensaje': mensaje,
        if (estacion != null) 'estacion': estacion,
        'tipo': tipo,
        'ordenId': ordenId,
        'mesaId': mesaId,
        'prioridad': prioridad,
        'emisor': {'id': usuarioId, 'username': username},
        'timestamp': date_utils.AppDateUtils.nowCdmx().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      });

      print('Alerta enviada: $tipo - $mensaje');
    } catch (e) {
      print('Error al crear alerta: $e');
      rethrow;
    }
  }

  /// Mapear tipo de alerta del frontend al tipo del backend
  String _mapearTipoAlerta(String tipoFrontend) {
    switch (tipoFrontend.toLowerCase()) {
      case 'demora':
        return 'alerta.demora';
      case 'cancelación':
      case 'cancelacion':
        return 'alerta.cancelacion';
      case 'cambio en orden':
      case 'cambio':
        return 'alerta.modificacion';
      case 'otra':
      default:
        return 'alerta.cocina';
    }
  }

  /// Mapear prioridad del frontend al backend
  String _mapearPrioridad(String prioridadFrontend) {
    switch (prioridadFrontend.toLowerCase()) {
      case 'urgente':
        return 'urgente';
      case 'normal':
        return 'media';
      default:
        return 'media';
    }
  }

  /// Obtener alertas no leídas desde el backend
  /// Se usa para cargar alertas que llegaron mientras el usuario estaba desconectado
  Future<List<Map<String, dynamic>>> obtenerAlertasNoLeidas() async {
    try {
      print('📡 AlertasService: Obteniendo alertas desde /alertas...');
      // El backend filtra automáticamente por rol (mesero = solo alerta.cocina)
      // NOTA: baseUrl ya incluye /api, así que solo usar /alertas
      final response = await _api.get('/alertas');

      print('📡 AlertasService: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print(
          '📡 AlertasService: Tipo de respuesta: ${responseData.runtimeType}',
        );
        print('📡 AlertasService: Contenido de respuesta: $responseData');

        List<dynamic> alertas;

        if (responseData is Map<String, dynamic>) {
          alertas = responseData['data'] as List<dynamic>? ?? [];
          print('📡 AlertasService: Alertas desde data: ${alertas.length}');
        } else if (responseData is List) {
          alertas = responseData;
          print(
            '📡 AlertasService: Alertas desde lista directa: ${alertas.length}',
          );
        } else {
          print('⚠️ AlertasService: Formato de respuesta desconocido');
          return [];
        }

        print(
          '📡 AlertasService: Total de alertas recibidas: ${alertas.length}',
        );

        // Filtrar solo alertas no leídas (el backend ya filtró por tipo)
        final alertasNoLeidas = alertas
            .where((alerta) {
              final leida =
                  alerta['leido'] as bool? ?? alerta['leida'] as bool? ?? false;
              final esNoLeida = !leida;
              if (!esNoLeida) {
                print(
                  '🚫 AlertasService: Alerta ${alerta['id']} filtrada (ya leída)',
                );
              }
              return esNoLeida;
            })
            .map((alerta) {
              final alertaMapeada = {
                'id': alerta['id'],
                'tipo': alerta['tipo'],
                'mensaje': alerta['mensaje'],
                'ordenId': alerta['ordenId'],
                'mesaId': alerta['mesaId'],
                'prioridad': alerta['prioridad'] ?? 'media',
                'creadoEn': alerta['creadoEn'],
                'metadata': alerta['metadata'] ?? {},
              };
              print(
                '✅ AlertasService: Alerta mapeada - ID: ${alertaMapeada['id']}, OrdenId: ${alertaMapeada['ordenId']}, Mensaje: ${alertaMapeada['mensaje']}',
              );
              return alertaMapeada;
            })
            .toList();

        print(
          '📡 AlertasService: Alertas no leídas finales: ${alertasNoLeidas.length}',
        );
        return alertasNoLeidas;
      }

      print('⚠️ AlertasService: Status code no es 200: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error al obtener alertas no leídas: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Marcar una alerta como leída
  Future<void> marcarAlertaLeida(int alertaId) async {
    try {
      await _api.patch('/alertas/$alertaId/leida');
    } catch (e) {
      print('Error al marcar alerta como leída: $e');
      // No rethrow, no es crítico
    }
  }

  /// Marcar todas las alertas como leídas en el backend
  /// Esto asegura que no vuelvan a aparecer cuando se recarguen desde la BD
  Future<int> marcarTodasLasAlertasComoLeidas() async {
    try {
      print(
        '📡 AlertasService: Marcando todas las alertas como leídas en el backend...',
      );
      final response = await _api.post('/alertas/marcar-todas-leidas');

      if (response.statusCode == 200) {
        final alertasMarcadas =
            response.data['data']?['alertasMarcadas'] as int? ?? 0;
        print(
          '✅ AlertasService: $alertasMarcadas alertas marcadas como leídas',
        );
        return alertasMarcadas;
      }

      return 0;
    } catch (e) {
      print('❌ Error al marcar todas las alertas como leídas: $e');
      return 0;
    }
  }

  /// Enviar alerta desde el modal del mesero
  Future<void> enviarAlertaDesdeModal({
    required String tableNumber,
    required String orderId,
    required String alertType,
    required String reason,
    String? details,
    String priority = 'Normal',
  }) async {
    try {
      // Extraer ordenId numérico del string (ej: "ORD-000003" -> 3)
      final ordenIdMatch = RegExp(r'ORD-(\d+)').firstMatch(orderId);
      final ordenId = ordenIdMatch != null
          ? int.tryParse(ordenIdMatch.group(1) ?? '')
          : null;

      // Extraer mesaId del número de mesa
      final mesaId = int.tryParse(tableNumber);

      // Construir mensaje completo
      final mensaje =
          '$alertType: $reason${details != null && details.isNotEmpty ? ' - $details' : ''}';

      // Mapear tipos y prioridades
      final tipoBackend = _mapearTipoAlerta(alertType);
      final prioridadBackend = _mapearPrioridad(priority);

      // Crear la alerta
      await crearAlerta(
        tipo: tipoBackend,
        mensaje: mensaje,
        ordenId: ordenId,
        mesaId: mesaId,
        prioridad: prioridadBackend,
        metadata: {
          'tableNumber': tableNumber,
          'orderId': orderId,
          'alertType': alertType,
          'reason': reason,
          if (details != null) 'details': details,
        },
      );
    } catch (e) {
      print('Error al enviar alerta desde modal: $e');
      rethrow;
    }
  }

  /// Enviar alerta a cocina desde mesero (endpoint específico)
  /// Este método usa el endpoint POST /alertas/cocina que centraliza la creación y emisión
  /// El backend obtiene la mesa real de la orden automáticamente
  Future<Map<String, dynamic>> enviarAlertaACocina({
    required int ordenId,
    required String tipoAlerta, // 'alerta.demora', 'alerta.cancelacion', etc.
    required String mensaje,
  }) async {
    try {
      print('📤 AlertasService: Enviando alerta a cocina - OrdenId: $ordenId, Tipo: $tipoAlerta, Mensaje: $mensaje');
      
      // Mapear tipo al formato del backend
      String tipoBackend = tipoAlerta.toLowerCase();
      if (tipoBackend == 'cambio en orden' || tipoBackend == 'cambio') {
        tipoBackend = 'alerta.modificacion';
      } else if (tipoBackend == 'cancelación' || tipoBackend == 'cancelacion') {
        tipoBackend = 'alerta.cancelacion';
      } else if (tipoBackend == 'demora') {
        tipoBackend = 'alerta.demora';
      } else {
        // Si no tiene prefijo 'alerta.', agregarlo
        if (!tipoBackend.startsWith('alerta.')) {
          tipoBackend = 'alerta.$tipoBackend';
        }
      }

      // Preparar payload (NO incluir mesaId - el backend lo obtiene de la orden)
      final payload = {
        'ordenId': ordenId,
        'tipo': tipoBackend,
        'mensaje': mensaje.trim(),
      };

      print('📤 AlertasService: Payload: $payload');
      print('📤 AlertasService: URL: /alertas/cocina (baseUrl ya incluye /api)');

      // Hacer POST a "/alertas/cocina" (baseUrl ya incluye /api)
      final response = await _api.post('/alertas/cocina', data: payload);

      print('✅ AlertasService: Alerta enviada exitosamente - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = response.data;
        final alertaData = responseData['data'] as Map<String, dynamic>? ?? responseData;
        
        print('✅ AlertasService: Alerta creada - ID: ${alertaData['id']}');
        
        return alertaData;
      } else {
        throw Exception('Error al enviar alerta: Status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al enviar alerta a cocina: $e');
      rethrow;
    }
  }
}
