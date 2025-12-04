import 'package:dio/dio.dart';
import 'api_service.dart';

/// Servicio para gestionar inventario
class InventarioService {
  final ApiService _api = ApiService();

  /// Obtener todos los items de inventario
  Future<List<dynamic>> getItems() async {
    try {
      final response = await _api.get('/inventario/items');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener items de inventario: $e');
      return [];
    }
  }

  /// Obtener un item por ID
  Future<Map<String, dynamic>?> getItem(int id) async {
    try {
      final response = await _api.get('/inventario/items/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener item: $e');
      return null;
    }
  }

  /// Crear un nuevo item
  Future<Map<String, dynamic>?> createItem(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/inventario/items', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó el item creado');
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
      throw Exception('Error al crear item: $e');
    }
  }

  /// Actualizar un item
  Future<Map<String, dynamic>?> updateItem(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/inventario/items/$id', data: data);
      if (response.statusCode == 200) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó el item actualizado');
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
      throw Exception('Error al actualizar item: $e');
    }
  }

  /// Obtener movimientos de inventario
  Future<List<dynamic>> getMovimientos() async {
    try {
      final response = await _api.get('/inventario/movimientos');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener movimientos: $e');
      return [];
    }
  }

  /// Registrar un movimiento
  Future<Map<String, dynamic>?> registrarMovimiento(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/inventario/movimientos', data: data);
      if (response.statusCode == 201) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al registrar movimiento: $e');
      return null;
    }
  }

  /// Obtener categorías únicas del inventario
  Future<List<String>> getCategories() async {
    try {
      final response = await _api.get('/inventario/categorias');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  /// Eliminar un item de inventario (DELETE)
  Future<bool> eliminarItem(int id) async {
    try {
      final response = await _api.delete('/inventario/items/$id');
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
      throw Exception('Error al eliminar item: $e');
    }
  }
}

