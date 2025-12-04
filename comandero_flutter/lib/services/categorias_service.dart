import 'package:dio/dio.dart';
import 'api_service.dart';

/// Servicio para gestionar categorías
class CategoriasService {
  final ApiService _api = ApiService();

  /// Obtener todas las categorías
  Future<List<dynamic>> getCategorias() async {
    try {
      final response = await _api.get('/categorias');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data == null) {
          return [];
        }
        if (data is! List) {
          throw Exception('El backend retornó un formato de datos inválido para categorías');
        }
        return data;
      }
      return [];
    } catch (e) {
      print('Error al obtener categorías: $e');
      rethrow;
    }
  }

  /// Obtener una categoría por ID
  Future<Map<String, dynamic>?> getCategoria(int id) async {
    try {
      final response = await _api.get('/categorias/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener categoría: $e');
      return null;
    }
  }

  /// Crear una nueva categoría
  Future<Map<String, dynamic>?> createCategoria(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/categorias', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la categoría creada');
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
      throw Exception('Error al crear categoría: $e');
    }
  }

  /// Actualizar una categoría
  Future<Map<String, dynamic>?> updateCategoria(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/categorias/$id', data: data);
      if (response.statusCode == 200) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la categoría actualizada');
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
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  /// Eliminar una categoría (DELETE)
  Future<bool> eliminarCategoria(int id) async {
    try {
      final response = await _api.delete('/categorias/$id');
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
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}

