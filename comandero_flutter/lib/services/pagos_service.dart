import 'package:dio/dio.dart';
import 'api_service.dart';

/// Servicio para gestionar pagos
class PagosService {
  final ApiService _api = ApiService();

  /// Obtener todos los pagos
  Future<List<dynamic>> getPagos() async {
    try {
      final response = await _api.get('/pagos');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener pagos: $e');
      return [];
    }
  }

  /// Obtener un pago por ID
  Future<Map<String, dynamic>?> getPago(int id) async {
    try {
      final response = await _api.get('/pagos/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener pago: $e');
      return null;
    }
  }

  /// Registrar un pago
  Future<Map<String, dynamic>?> registrarPago(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/pagos', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó el pago registrado');
        }
        if (result is! Map) {
          throw Exception('El backend retornó un formato de datos inválido');
        }
        return result as Map<String, dynamic>;
      }
      final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
      throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        throw Exception('Error (${e.response!.statusCode}): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al registrar pago: $e');
    }
  }

  /// Registrar una propina
  Future<Map<String, dynamic>?> registrarPropina(int ordenId, double monto) async {
    try {
      final response = await _api.post(
        '/pagos/propinas',
        data: {
          'ordenId': ordenId,
          'monto': monto,
        },
      );
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la propina registrada');
        }
        if (result is! Map) {
          throw Exception('El backend retornó un formato de datos inválido');
        }
        return result as Map<String, dynamic>;
      }
      final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
      throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        throw Exception('Error (${e.response!.statusCode}): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al registrar propina: $e');
    }
  }

  /// Obtener formas de pago disponibles
  Future<List<dynamic>> getFormasPago() async {
    try {
      final response = await _api.get('/pagos/formas');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener formas de pago: $e');
      return [];
    }
  }

  /// Obtener propinas
  Future<List<dynamic>> getPropinas() async {
    try {
      final response = await _api.get('/pagos/propinas');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener propinas: $e');
      return [];
    }
  }
}

