import 'api_service.dart';

class ComandasService {
  final ApiService _api = ApiService();

  /// Reimprime una comanda manualmente (desde mesero)
  /// 
  /// [ordenId] - ID de la orden a reimprimir
  /// 
  /// Retorna un mapa con el resultado de la impresión
  Future<Map<String, dynamic>> reimprimirComanda(int ordenId) async {
    try {
      print('🖨️ ComandasService: Reimprimiendo comanda para orden $ordenId');
      
      final response = await _api.post(
        '/comandas/reimprimir',
        data: {
          'ordenId': ordenId,
          'esReimpresion': true,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] as bool? ?? false;
          if (success) {
            final data = responseData['data'] as Map<String, dynamic>? ?? {};
            print('✅ ComandasService: Comanda reimpresa exitosamente');
            return {
              'exito': true,
              'mensaje': data['mensaje'] as String? ?? 'Comanda reimpresa exitosamente',
              'rutaArchivo': data['rutaArchivo'] as String?,
            };
          } else {
            final error = responseData['error'] as String? ?? 'Error desconocido';
            print('❌ ComandasService: Error al reimprimir: $error');
            return {
              'exito': false,
              'mensaje': error,
            };
          }
        }
      }

      print('⚠️ ComandasService: Respuesta inesperada: ${response.statusCode}');
      return {
        'exito': false,
        'mensaje': 'Error al reimprimir comanda',
      };
    } catch (e, stackTrace) {
      print('❌ ComandasService: Error al reimprimir comanda: $e');
      print('Stack: $stackTrace');
      return {
        'exito': false,
        'mensaje': 'Error de conexión al reimprimir comanda',
      };
    }
  }
}

