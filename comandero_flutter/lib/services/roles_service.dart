import 'package:dio/dio.dart';
import '../models/admin_model.dart';
import 'api_service.dart';

/// Servicio para gestionar roles y permisos a través del backend
class RolesService {
  final ApiService _api = ApiService();

  /// Listar todos los roles
  Future<List<Role>> listarRoles() async {
    try {
      final response = await _api.get('/roles');
      
      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
      
      final data = response.data['data'];
      if (data == null) {
        return [];
      }
      if (data is! List) {
        throw Exception('El backend retornó un formato de datos inválido para roles');
      }
      
      return data
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final errorMsg = e.response!.data?['message'] ?? 'Error del servidor';
        throw Exception('Error (${e.response!.statusCode}): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al listar roles: $e');
    }
  }

  /// Obtener un rol por ID
  Future<Role> obtenerRol(int id) async {
    try {
      final response = await _api.get('/roles/$id');
      
      if (response.statusCode == 404) {
        throw Exception('Rol no encontrado');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('Rol no encontrado');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el rol');
      }
      return Role.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Rol no encontrado');
      }
      if (e.response != null) {
        final errorMsg = e.response!.data?['message'] ?? 'Error del servidor';
        throw Exception('Error (${e.response!.statusCode}): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al obtener rol: $e');
    }
  }

  /// Crear un nuevo rol
  Future<Role> crearRol({
    required String nombre,
    String? descripcion,
    required List<int> permisos,
  }) async {
    try {
      final body = {
        'nombre': nombre,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'permisos': permisos,
      };

      final response = await _api.post('/roles', data: body);
      
      if (response.statusCode != 201) {
        final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('El backend no retornó el rol creado');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el rol creado');
      }
      return Role.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? 
                        e.response!.data?['error'] ?? 
                        'Error del servidor';
        if (statusCode == 400) {
          throw Exception('Datos inválidos: $errorMsg');
        } else if (statusCode == 401) {
          throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para crear roles.');
        } else if (statusCode == 409) {
          throw Exception('El nombre del rol ya existe.');
        } else {
          throw Exception('Error del servidor ($statusCode): $errorMsg');
        }
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al crear rol: $e');
    }
  }

  /// Actualizar un rol existente
  Future<Role> actualizarRol({
    required int id,
    String? nombre,
    String? descripcion,
    List<int>? permisos,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (nombre != null) body['nombre'] = nombre;
      if (descripcion != null) body['descripcion'] = descripcion.isEmpty ? null : descripcion;
      if (permisos != null) body['permisos'] = permisos;

      final response = await _api.put('/roles/$id', data: body);
      
      if (response.statusCode != 200) {
        final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('El backend no retornó el rol actualizado');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el rol actualizado');
      }
      return Role.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        if (statusCode == 404) {
          throw Exception('Rol no encontrado');
        } else if (statusCode == 400) {
          throw Exception('Datos inválidos: $errorMsg');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para actualizar roles.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al actualizar rol: $e');
    }
  }

  /// Eliminar un rol
  Future<void> eliminarRol(int id) async {
    try {
      final response = await _api.delete('/roles/$id');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        if (statusCode == 404) {
          throw Exception('Rol no encontrado');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para eliminar roles.');
        } else if (statusCode == 409) {
          throw Exception('No se puede eliminar el rol porque está asignado a usuarios.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al eliminar rol: $e');
    }
  }

  /// Listar todos los permisos disponibles
  Future<List<Permiso>> listarPermisos() async {
    try {
      final response = await _api.get('/roles/permisos');
      
      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
      
      final data = response.data['data'];
      if (data == null) {
        return [];
      }
      if (data is! List) {
        throw Exception('El backend retornó un formato de datos inválido para permisos');
      }
      
      return data
          .map((json) => Permiso.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final errorMsg = e.response!.data?['message'] ?? 'Error del servidor';
        throw Exception('Error (${e.response!.statusCode}): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al listar permisos: $e');
    }
  }
}

