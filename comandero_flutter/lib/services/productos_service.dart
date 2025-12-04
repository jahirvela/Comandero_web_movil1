import 'package:dio/dio.dart';
import 'api_service.dart';

/// Servicio para gestionar productos
class ProductosService {
  final ApiService _api = ApiService();

  /// Obtener todos los productos
  Future<List<dynamic>> getProductos() async {
    try {
      final response = await _api.get('/productos');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener productos: $e');
      return [];
    }
  }

  /// Obtener un producto por ID
  Future<Map<String, dynamic>?> getProducto(int id) async {
    try {
      final response = await _api.get('/productos/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener producto: $e');
      return null;
    }
  }

  /// Crear un nuevo producto
  Future<Map<String, dynamic>?> createProducto(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/productos', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó el producto creado');
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
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Actualizar un producto
  Future<Map<String, dynamic>?> updateProducto(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/productos/$id', data: data);
      if (response.statusCode == 200) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó el producto actualizado');
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
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Obtener productos por categoría
  Future<List<dynamic>> getProductosPorCategoria(int categoriaId) async {
    try {
      final response = await _api.get('/productos?categoriaId=$categoriaId');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener productos por categoría: $e');
      return [];
    }
  }

  /// Desactivar un producto (DELETE)
  Future<bool> desactivarProducto(int id) async {
    try {
      final response = await _api.delete('/productos/$id');
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
      throw Exception('Error al desactivar producto: $e');
    }
  }
}

