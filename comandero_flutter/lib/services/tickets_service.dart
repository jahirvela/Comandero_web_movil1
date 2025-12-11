import 'api_service.dart';
import '../models/payment_model.dart';
import '../utils/date_utils.dart' as date_utils;

class TicketsService {
  final ApiService _api = ApiService();

  /// Obtiene la lista de todos los tickets
  /// 
  /// Retorna una lista de BillModel con los tickets disponibles
  Future<List<BillModel>> listarTickets() async {
    try {
      print('🔍 TicketsService: Cargando tickets desde /tickets...');
      final response = await _api.get('/tickets');
      print('✅ TicketsService: Respuesta recibida: ${response.statusCode}');
      
      // Manejar errores de autenticación
      if (response.statusCode == 401) {
        print('🔐 TicketsService: Error de autenticación (401) - Token inválido o expirado');
        return [];
      }
      
      if (response.statusCode == 403) {
        print('🚫 TicketsService: Error de autorización (403) - Sin permisos');
        return [];
      }
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Manejar diferentes estructuras de respuesta
        List<dynamic> data;
        if (responseData is Map<String, dynamic>) {
          // La respuesta viene como { success: true, data: [...] }
          final success = responseData['success'] as bool? ?? false;
          if (!success) {
            print('⚠️ TicketsService: Respuesta con success=false: ${responseData['error']}');
            return [];
          }
          data = responseData['data'] as List<dynamic>? ?? [];
          print('📋 TicketsService: ${data.length} tickets encontrados');
        } else if (responseData is List) {
          data = responseData;
          print('📋 TicketsService: ${data.length} tickets (lista directa)');
        } else {
          print('⚠️ TicketsService: Formato inesperado: ${responseData.runtimeType}');
          return [];
        }
        
        if (data.isEmpty) {
          print('ℹ️ TicketsService: No hay tickets (órdenes pagadas) en el sistema');
          return [];
        }
        
        final tickets = <BillModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final ticket = _mapBackendToBillModel(data[i] as Map<String, dynamic>);
            tickets.add(ticket);
          } catch (e) {
            print('⚠️ TicketsService: Error mapeando ticket $i: $e');
            // Continuar con el siguiente ticket en lugar de fallar todo
          }
        }
        
        print('✅ TicketsService: ${tickets.length} tickets cargados correctamente');
        return tickets;
      }
      
      print('⚠️ TicketsService: Status ${response.statusCode}: ${response.data}');
      return [];
    } catch (e, stackTrace) {
      print('❌ TicketsService: Error al listar tickets: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  /// Mapea los datos del backend a BillModel
  BillModel _mapBackendToBillModel(Map<String, dynamic> data) {
    // Convertir status del backend al formato del frontend
    String status = BillStatus.pending;
    final statusStr = (data['status'] as String?)?.toLowerCase() ?? 'pending';
    if (statusStr == 'printed') {
      status = BillStatus.printed;
    } else if (statusStr == 'delivered') {
      status = BillStatus.delivered;
    } else {
      status = BillStatus.pending;
    }

    // Crear items básicos (el backend no devuelve items detallados en la lista)
    // Si necesitas los items, deberías hacer una llamada adicional o modificar el backend
    final items = <BillItem>[];

    // Parsear fecha de creación y convertir a zona horaria local
    DateTime createdAt;
    if (data['createdAt'] != null) {
      createdAt = date_utils.AppDateUtils.parseToLocal(data['createdAt']);
    } else {
      createdAt = DateTime.now();
    }
    
    // Parsear fecha de impresión si existe
    DateTime? printedAt;
    if (data['printedAt'] != null) {
      printedAt = date_utils.AppDateUtils.parseToLocal(data['printedAt']);
    }

    // Determinar si es pedido para llevar (tiene customerName pero no tableNumber)
    final isTakeaway = data['customerName'] != null && 
                       data['customerName'].toString().isNotEmpty && 
                       (data['tableNumber'] == null || data['tableNumber'] == 0);

    // Detectar si es cuenta agrupada y extraer ordenIds
    final ticketId = data['id'] as String? ?? 'TICKET-${data['ordenId'] ?? 'UNKNOWN'}';
    final ordenIdsFromBackend = data['ordenIds'] as List<dynamic>?;
    List<int>? ordenIds;
    
    // Si el backend proporciona ordenIds directamente, usarlos
    if (ordenIdsFromBackend != null && ordenIdsFromBackend.isNotEmpty) {
      ordenIds = ordenIdsFromBackend.map((e) => (e as num).toInt()).toList();
    }
    // Si no, intentar extraerlos del ID del ticket (formato CUENTA-AGRUPADA-000084-000085-000086)
    else if (ticketId.startsWith('CUENTA-AGRUPADA-')) {
      final parts = ticketId.replaceFirst('CUENTA-AGRUPADA-', '').split('-');
      ordenIds = parts
          .map((part) => int.tryParse(part))
          .whereType<int>()
          .toList();
    }

    return BillModel(
      id: ticketId,
      ordenId: data['ordenId'] as int?,
      ordenIds: ordenIds, // Para cuentas agrupadas
      tableNumber: data['tableNumber'] as int?,
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      status: status,
      createdAt: createdAt,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      waiterName: data['waiterName'] as String?,
      isTakeaway: isTakeaway,
      isPrinted: data['isPrinted'] as bool? ?? false,
      printedBy: data['printedBy'] as String?,
      printedAt: printedAt,
      isGrouped: data['isGrouped'] as bool? ?? (ordenIds != null && ordenIds.length > 1),
    );
  }

  /// Imprime un ticket para una orden (o múltiples órdenes si es cuenta agrupada)
  /// 
  /// [ordenId] - ID de la orden principal a imprimir
  /// [ordenIds] - IDs de todas las órdenes (para cuentas agrupadas, opcional)
  /// [incluirCodigoBarras] - Si incluir código de barras en el ticket (default: true)
  /// 
  /// Retorna un mapa con:
  /// - success: bool - Si la impresión fue exitosa
  /// - data: Map con mensaje y rutaArchivo (si aplica)
  /// - error: String - Mensaje de error si falló
  Future<Map<String, dynamic>> imprimirTicket({
    required int ordenId,
    List<int>? ordenIds,
    bool incluirCodigoBarras = true,
  }) async {
    try {
      final data = <String, dynamic>{
        'ordenId': ordenId,
        'incluirCodigoBarras': incluirCodigoBarras,
      };
      
      // Si hay múltiples ordenIds (cuenta agrupada), incluirlos
      if (ordenIds != null && ordenIds.length > 1) {
        data['ordenIds'] = ordenIds;
      }

      final response = await _api.post(
        '/tickets/imprimir',
        data: data,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }

      return {
        'success': false,
        'error': response.data['error'] ?? 'Error desconocido al imprimir',
      };
    } catch (e) {
      print('Error al imprimir ticket: $e');
      return {
        'success': false,
        'error': 'No se pudo conectar con la impresora. Verifica la conexión.',
      };
    }
  }
}

