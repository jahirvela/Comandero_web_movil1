import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/date_utils.dart' as date_utils;

/// Servicio para gestionar órdenes
class OrdenesService {
  final ApiService _api = ApiService();

  /// Obtener todas las órdenes
  Future<List<dynamic>> getOrdenes() async {
    try {
      final response = await _api.get('/ordenes');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener órdenes: $e');
      return [];
    }
  }

  /// Obtener una orden por ID
  Future<Map<String, dynamic>?> getOrden(int id) async {
    try {
      final response = await _api.get('/ordenes/$id');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener orden: $e');
      return null;
    }
  }

  /// Crear una nueva orden
  Future<Map<String, dynamic>?> createOrden(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/ordenes', data: data);
      if (response.statusCode == 201) {
        final result = response.data['data'];
        if (result == null) {
          throw Exception('El backend no retornó la orden creada');
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
      throw Exception('Error al crear orden: $e');
    }
  }

  /// Actualizar una orden
  Future<Map<String, dynamic>?> updateOrden(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/ordenes/$id', data: data);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al actualizar orden: $e');
      return null;
    }
  }

  /// Agregar items a una orden
  Future<Map<String, dynamic>?> agregarItems(int id, List<Map<String, dynamic>> items) async {
    try {
      final response = await _api.post(
        '/ordenes/$id/items',
        data: {'items': items},
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Error al agregar items: $e');
      return null;
    }
  }

  /// Obtener órdenes de cocina (filtradas para cocina)
  Future<List<dynamic>> getOrdenesCocina() async {
    try {
      final response = await _api.get('/ordenes/cocina');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener órdenes de cocina: $e');
      return [];
    }
  }

  /// Cambiar estado de una orden
  Future<bool> cambiarEstado(int id, int estadoOrdenId) async {
    try {
      final response = await _api.patch(
        '/ordenes/$id/estado',
        data: {'estadoOrdenId': estadoOrdenId},
      );
      if (response.statusCode == 200) {
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
      throw Exception('Error al cambiar estado de orden: $e');
    }
  }

  /// Obtener estados de orden disponibles
  Future<List<dynamic>> getEstadosOrden() async {
    try {
      final response = await _api.get('/ordenes/estados');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error al obtener estados de orden: $e');
      return [];
    }
  }

  /// Obtener órdenes con estado "listo" del día actual que NO han sido pagadas
  /// Se usa para cargar notificaciones pendientes cuando el mesero hace login
  Future<List<dynamic>> getOrdenesListas() async {
    try {
      final response = await _api.get('/ordenes');
      if (response.statusCode == 200) {
        final ordenes = response.data['data'] as List<dynamic>? ?? [];
        final hoy = DateTime.now();
        
        // Filtrar solo órdenes de hoy con estado "listo" que NO estén pagadas
        return ordenes.where((orden) {
          final estadoNombre = (orden['estadoNombre'] as String?)?.toLowerCase() ?? '';
          final esListo = estadoNombre.contains('listo') || estadoNombre.contains('ready');
          
          // Excluir órdenes pagadas, canceladas o cerradas
          final esPagadaOCerrada = estadoNombre.contains('pagada') || 
                                   estadoNombre.contains('cancelada') ||
                                   estadoNombre.contains('cerrada');
          
          if (esPagadaOCerrada) return false;
          
          // Verificar que sea de hoy
          final fechaCreacion = orden['creadoEn'] as String?;
          if (fechaCreacion != null) {
            try {
              final fecha = date_utils.AppDateUtils.parseToLocal(fechaCreacion);
              final esDeHoy = fecha.year == hoy.year && 
                              fecha.month == hoy.month && 
                              fecha.day == hoy.day;
              return esListo && esDeHoy;
            } catch (_) {
              return false;
            }
          }
          return false;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener órdenes listas: $e');
      return [];
    }
  }
}

