import 'api_service.dart';
import '../models/admin_model.dart';
import '../utils/date_utils.dart' as date_utils;

class CierresService {
  final ApiService _api = ApiService();

  /// Obtiene la lista de cierres de caja
  /// 
  /// [fechaInicio] - Fecha de inicio del rango (opcional)
  /// [fechaFin] - Fecha de fin del rango (opcional)
  /// [cajeroId] - ID del cajero para filtrar (opcional, solo admin)
  /// 
  /// Retorna una lista de CashCloseModel
  Future<List<CashCloseModel>> listarCierresCaja({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? cajeroId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
      }
      if (cajeroId != null) {
        queryParams['cajeroId'] = cajeroId.toString();
      }

      print('🔍 CierresService: Cargando cierres con parámetros: $queryParams');
      final response = await _api.get('/cierres', queryParameters: queryParams);
      print('✅ CierresService: Respuesta recibida: ${response.statusCode}');
      print('📦 CierresService: Estructura de respuesta: ${response.data.runtimeType}');
      
      // Manejar errores de autenticación
      if (response.statusCode == 401) {
        print('🔐 CierresService: Error de autenticación (401) - Token inválido o expirado');
        return [];
      }
      
      if (response.statusCode == 403) {
        print('🚫 CierresService: Error de autorización (403) - Sin permisos');
        return [];
      }
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('📋 CierresService: response.data tipo: ${responseData.runtimeType}');
        
        // Manejar diferentes estructuras de respuesta
        List<dynamic> data;
        if (responseData is Map<String, dynamic>) {
          data = responseData['data'] as List<dynamic>? ?? [];
          print('📋 CierresService: Datos extraídos del campo "data": ${data.length} elementos');
        } else if (responseData is List) {
          data = responseData;
          print('📋 CierresService: Datos son una lista directa: ${data.length} elementos');
        } else {
          print('⚠️ CierresService: Formato de respuesta inesperado: ${responseData.runtimeType}');
          data = [];
        }
        
        if (data.isEmpty) {
          print('⚠️ CierresService: No hay cierres en la respuesta');
          return [];
        }
        
        print('🔄 CierresService: Mapeando ${data.length} cierres...');
        final cierres = data.map((cierre) {
          try {
            print('🔄 CierresService: Mapeando cierre: $cierre');
            final mapped = _mapBackendToCashCloseModel(cierre as Map<String, dynamic>);
            print('✅ CierresService: Cierre mapeado - ID: ${mapped.id}, Usuario: ${mapped.usuario}, Total: ${mapped.totalNeto}');
            return mapped;
          } catch (e, stackTrace) {
            print('❌ CierresService: Error al mapear cierre: $e');
            print('Stack trace: $stackTrace');
            print('Cierre que falló: $cierre');
            rethrow;
          }
        }).toList();
        
        print('✅ CierresService: ${cierres.length} cierres mapeados correctamente');
        return cierres;
      }
      
      print('⚠️ CierresService: Status code no es 200: ${response.statusCode}');
      print('📦 CierresService: Respuesta: ${response.data}');
      return [];
    } catch (e, stackTrace) {
      print('❌ CierresService: Error al listar cierres de caja: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Crea/envía un cierre de caja al backend
  /// 
  /// [cierre] - El modelo de cierre de caja a enviar
  /// 
  /// Retorna el cierre creado
  Future<CashCloseModel> crearCierreCaja(CashCloseModel cierre) async {
    try {
      final dataToSend = {
        'fecha': cierre.fecha.toIso8601String(),
        'efectivoInicial': cierre.efectivoInicial,
        'efectivoFinal': cierre.efectivoContado,
        'totalPagos': cierre.totalNeto,
        'totalEfectivo': cierre.efectivo,
        'totalTarjeta': cierre.tarjeta,
        'notas': cierre.notaCajero ?? '',
        if (cierre.notaCajero != null) 'notaCajero': cierre.notaCajero,
        'otrosIngresos': cierre.otrosIngresos,
        'otrosIngresosTexto': cierre.otrosIngresosTexto,
        'efectivoContado': cierre.efectivoContado,
        'totalDeclarado': cierre.totalDeclarado,
      };
      
      print('📤 CierresService.crearCierreCaja: Enviando datos al backend...');
      print('📤 CierresService.crearCierreCaja: Data: $dataToSend');
      
      final response = await _api.post('/cierres', data: dataToSend);
      
      print('📥 CierresService.crearCierreCaja: Respuesta recibida - Status: ${response.statusCode}');
      print('📥 CierresService.crearCierreCaja: Response data: ${response.data}');

      // Aceptar tanto 201 (creado) como 200 (actualizado)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          print('✅ CierresService.crearCierreCaja: Cierre creado exitosamente');
          // Mapear la respuesta del backend al modelo
          return _mapBackendToCashCloseModel(data);
        } else {
          print('⚠️ CierresService.crearCierreCaja: response.data["data"] es null');
        }
      } else {
        print('⚠️ CierresService.crearCierreCaja: Status code inesperado: ${response.statusCode}');
      }

      // Si no se puede mapear, devolver el cierre original
      print('⚠️ CierresService.crearCierreCaja: Devolviendo cierre original');
      return cierre;
    } catch (e, stackTrace) {
      print('❌ Error al crear cierre de caja: $e');
      print('❌ Stack trace: $stackTrace');
      // Si es un error 409 (conflicto), intentar obtener el cierre existente
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        print('⚠️ Cierre duplicado detectado, el backend debería haberlo actualizado');
        // El backend ahora maneja esto con ON DUPLICATE KEY UPDATE
        // Si llegamos aquí, es porque hubo un error inesperado
      }
      rethrow;
    }
  }

  /// Actualiza el estado de un cierre de caja
  /// 
  /// [cierreId] - ID del cierre de caja (número real de la BD)
  /// [estado] - Nuevo estado: 'approved', 'rejected', 'clarification'
  /// [comentarioRevision] - Comentario opcional del administrador
  /// 
  /// Retorna el cierre actualizado
  Future<CashCloseModel> actualizarEstadoCierre({
    required int cierreId,
    required String estado,
    String? comentarioRevision,
  }) async {
    try {
      final response = await _api.patch(
        '/cierres/$cierreId/estado',
        data: {
          'estado': estado,
          if (comentarioRevision != null && comentarioRevision.isNotEmpty)
            'comentarioRevision': comentarioRevision,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return _mapBackendToCashCloseModel(data);
        }
      }

      throw Exception('Error al actualizar estado del cierre');
    } catch (e) {
      print('Error al actualizar estado del cierre: $e');
      rethrow;
    }
  }

  /// Mapea los datos del backend a CashCloseModel
  CashCloseModel _mapBackendToCashCloseModel(Map<String, dynamic> data) {
    // Parsear fecha usando AppDateUtils para convertir correctamente a zona horaria local
    DateTime fecha = date_utils.AppDateUtils.parseToLocal(data['fecha']);
    
    print('📅 CierresService: Fecha parseada: $fecha (año: ${fecha.year}, mes: ${fecha.month}, día: ${fecha.day}, hora: ${fecha.hour}:${fecha.minute})');
    
    // Obtener datos del backend (estructura de CierreCajaItem)
    final totalVentas = (data['totalVentas'] as num?)?.toDouble() ?? 0.0;
    final totalEfectivo = (data['totalEfectivo'] as num?)?.toDouble() ?? 0.0;
    final totalTarjeta = (data['totalTarjeta'] as num?)?.toDouble() ?? 0.0;
    final totalOtros = (data['totalOtros'] as num?)?.toDouble() ?? 0.0;
    final totalPropinas = (data['totalPropinas'] as num?)?.toDouble() ?? 0.0;
    final numeroOrdenes = (data['numeroOrdenes'] as num?)?.toInt() ?? 0;
    
    // Usar propinas reales por tipo desde el backend (calculadas desde pagos)
    final propinasEfectivo = (data['propinasEfectivo'] as num?)?.toDouble() ?? (totalPropinas * 0.5);
    final propinasTarjeta = (data['propinasTarjeta'] as num?)?.toDouble() ?? (totalPropinas * 0.5);
    
    // Determinar período usando hora CDMX
    final now = date_utils.AppDateUtils.now();
    String periodo;
    if (fecha.year == now.year && fecha.month == now.month && fecha.day == now.day) {
      periodo = 'Hoy';
    } else {
      final ayer = now.subtract(const Duration(days: 1));
      if (fecha.year == ayer.year && fecha.month == ayer.month && fecha.day == ayer.day) {
        periodo = 'Ayer';
      } else {
        periodo = date_utils.AppDateUtils.formatDate(fecha);
      }
    }

    // Obtener efectivo contado del backend (efectivoFinal si existe, sino usar totalEfectivo)
    final efectivoContado = (data['efectivoFinal'] as num?)?.toDouble() ?? 
                           (data['efectivoContado'] as num?)?.toDouble() ?? 
                           totalEfectivo;
    
    // Obtener efectivo inicial del backend
    final efectivoInicial = (data['efectivoInicial'] as num?)?.toDouble() ?? 0.0;
    
    // Obtener total de pagos del backend (totalVentas incluye todo)
    final totalPagos = totalVentas;
    
    // Obtener nombre del cajero
    final cajeroNombre = data['cajeroNombre'] as String? ?? 
                        data['creadoPorUsuarioNombre'] as String? ?? 
                        'Sin asignar';
    
    // Obtener estado - por defecto 'pending' si no se especifica
    final statusRaw = (data['status'] as String?)?.toLowerCase() ?? 'pending';
    final status = statusRaw == 'cerrado' ? 'pending' : statusRaw; // Normalizar 'cerrado' a 'pending'
    
    // Extraer el ID real del cierre si viene como "cierre-{id}"
    int? cierreIdReal;
    final idStr = data['id']?.toString() ?? '';
    if (idStr.startsWith('cierre-')) {
      final idPart = idStr.substring(7); // Extraer después de "cierre-"
      cierreIdReal = int.tryParse(idPart);
    } else if (data['cierreId'] != null) {
      cierreIdReal = (data['cierreId'] as num?)?.toInt();
    }
    
    return CashCloseModel(
      id: idStr.isNotEmpty ? idStr : 'CIERRE-${fecha.toIso8601String()}',
      fecha: fecha,
      periodo: periodo,
      usuario: cajeroNombre,
      totalNeto: totalPagos,
      efectivo: totalEfectivo,
      tarjeta: totalTarjeta,
      propinasTarjeta: propinasTarjeta,
      propinasEfectivo: propinasEfectivo,
      pedidosParaLlevar: numeroOrdenes, // Usar número de órdenes como aproximación
      estado: status,
      efectivoContado: efectivoContado,
      totalTarjeta: totalTarjeta,
      otrosIngresos: totalOtros,
      totalDeclarado: totalPagos + totalPropinas,
      otrosIngresosTexto: data['otrosIngresosTexto'] as String?,
      notaCajero: data['notas'] as String? ?? data['notaCajero'] as String?,
      auditLog: [], // Se puede poblar después si hay información
      cierreId: cierreIdReal,
      comentarioRevision: data['comentarioRevision'] as String?,
      efectivoInicial: efectivoInicial,
    );
  }
}

