import 'package:dio/dio.dart';
import 'api_service.dart';

/// Servicio para gestionar mesas
class MesasService {
  final ApiService _api = ApiService();

  /// Obtener todas las mesas
  Future<List<dynamic>> getMesas() async {
    try {
      final response = await _api.get('/mesas');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener mesas: $e');
      return [];
    }
  }

  /// Obtener una mesa por ID
  Future<Map<String, dynamic>?> getMesa(int id) async {
    try {
      final response = await _api.get('/mesas/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener mesa: $e');
      return null;
    }
  }

  /// Crear una nueva mesa
  Future<Map<String, dynamic>?> createMesa(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/mesas', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la mesa creada');
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
      throw Exception('Error al crear mesa: $e');
    }
  }

  /// Actualizar una mesa
  Future<Map<String, dynamic>?> updateMesa(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/mesas/$id', data: data);
      if (response.statusCode == 200) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la mesa actualizada');
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
      throw Exception('Error al actualizar mesa: $e');
    }
  }

  /// Cambiar estado de una mesa
  Future<bool> cambiarEstadoMesa(int id, int estadoMesaId, {String? nota}) async {
    try {
      final response = await _api.patch(
        '/mesas/$id/estado',
        data: {
          'estadoMesaId': estadoMesaId,
          if (nota != null) 'nota': nota,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Error del servidor (${response.statusCode})');
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
      throw Exception('Error al cambiar estado de mesa: $e');
    }
  }

  /// Obtener estados de mesa disponibles
  Future<List<dynamic>> getEstadosMesa() async {
    try {
      final response = await _api.get('/mesas/estados');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) {
          return [];
        }
        if (data is! List) {
          throw Exception('El backend retornó un formato de datos inválido para estados de mesa');
        }
        return data;
      }
      return [];
    } catch (e) {
      print('Error al obtener estados de mesa: $e');
      rethrow;
    }
  }

  /// Eliminar una mesa (DELETE)
  Future<bool> eliminarMesa(int id) async {
    try {
      final response = await _api.delete('/mesas/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
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
      throw Exception('Error al eliminar mesa: $e');
    }
  }
}

