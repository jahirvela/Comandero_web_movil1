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

  /// Obtener un ítem por código de barras (para escanear y ajustar cantidad).
  Future<Map<String, dynamic>?> getItemByCodigoBarras(String codigo) async {
    try {
      final c = Uri.encodeComponent(codigo.trim());
      final response = await _api.get('/inventario/items/por-codigo-barras?codigo=$c');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return null;
      print('Error al obtener item por código de barras: $e');
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

  /// Obtener movimientos de inventario.
  /// [itemId] opcional: filtra por ítem. [desde]/[hasta] en UTC. [limit] hasta 50000 en servidor.
  Future<List<dynamic>> getMovimientos({
    int? itemId,
    DateTime? desde,
    DateTime? hasta,
    int? limit,
  }) async {
    try {
      final qs = <String>[];
      if (itemId != null) qs.add('itemId=$itemId');
      if (desde != null) {
        qs.add('desde=${Uri.encodeComponent(desde.toUtc().toIso8601String())}');
      }
      if (hasta != null) {
        qs.add('hasta=${Uri.encodeComponent(hasta.toUtc().toIso8601String())}');
      }
      if (limit != null) qs.add('limit=$limit');
      final path = qs.isEmpty
          ? '/inventario/movimientos'
          : '/inventario/movimientos?${qs.join('&')}';
      final response = await _api.get(path);
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

  static List<String> _parseCategoryList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  /// Obtener categorías únicas del inventario (incluye las guardadas en backend)
  Future<List<String>> getCategories() async {
    try {
      final response = await _api.get('/inventario/categorias');
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        print('Error al obtener categorías: HTTP $status');
        return [];
      }
      if (status == 200) {
        final raw = response.data;
        final parsed = _parseCategoryList(raw is Map ? raw['data'] : null);
        return parsed;
      }
      return [];
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  /// Crea categoría. [duplicate] es true si ya existía (409); la lista refleja el servidor o un refetch.
  Future<({List<String> categorias, bool duplicate})> createCategory(String nombre) async {
    final trimmed = nombre.trim();
    try {
      final response = await _api.post(
        '/inventario/categorias',
        data: {'nombre': trimmed},
      );
      final status = response.statusCode ?? 0;
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      // validateStatus del ApiService acepta 4xx como "respuesta" sin lanzar DioException
      if (status >= 400 && status != 409) {
        final msg = body['message'] ?? body['error'] ?? 'Error al crear categoría';
        throw Exception(msg.toString());
      }

      final duplicate = status == 409;
      var list = _parseCategoryList(body['data']);

      if (list.isEmpty) {
        list = await getCategories();
      }

      if (list.isEmpty && (status == 200 || status == 201) && trimmed.isNotEmpty) {
        list = [trimmed];
      }
      if (list.isEmpty && duplicate && trimmed.isNotEmpty) {
        list = [trimmed];
      }

      if (list.isEmpty) {
        throw Exception(
          duplicate
              ? 'Ya existe una categoría con ese nombre'
              : 'El servidor no devolvió la lista de categorías',
        );
      }

      return (categorias: list, duplicate: duplicate);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final map = body is Map ? body as Map<String, dynamic> : <String, dynamic>{};
      final list = _parseCategoryList(map['data']);
      if (status == 409) {
        if (list.isNotEmpty) {
          return (categorias: list, duplicate: true);
        }
        final fallback = await getCategories();
        if (fallback.isNotEmpty) {
          return (categorias: fallback, duplicate: true);
        }
        if (trimmed.isNotEmpty) {
          return (categorias: [trimmed], duplicate: true);
        }
      }
      if (e.response != null) {
        final msg = map['message'] ?? map['error'] ?? 'Error al crear categoría';
        throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Eliminar categoría de inventario por nombre (falla si hay ítems o si es «Todos»).
  Future<List<String>> deleteCategory(String nombre) async {
    try {
      final encoded = Uri.encodeComponent(nombre.trim());
      final response = await _api.delete('/inventario/categorias/$encoded');
      final status = response.statusCode ?? 0;
      final raw = response.data;
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (status == 200) {
        final data = map['data'];
        if (data is List) {
          return data.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
        return [];
      }
      if (status == 403 || status == 409) {
        final msg =
            map['message']?.toString() ??
            map['error']?.toString() ??
            'No se puede eliminar la categoría';
        throw Exception(msg);
      }
      if (status >= 400) {
        final msg = map['message']?.toString() ?? 'Error al eliminar categoría';
        throw Exception(msg);
      }
      throw Exception('El servidor no devolvió la lista de categorías');
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        final map = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
        final msg = map['message'] ?? map['error'] ?? 'Error al eliminar categoría';
        throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  /// Renombrar categoría (ítems + registro en catálogo).
  Future<List<String>> renameCategory(String nombreActual, String nombreNuevo) async {
    try {
      final encoded = Uri.encodeComponent(nombreActual.trim());
      final response = await _api.put(
        '/inventario/categorias/$encoded',
        data: {'nuevoNombre': nombreNuevo.trim()},
      );
      final status = response.statusCode ?? 0;
      final raw = response.data;
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (status == 200) {
        final data = map['data'];
        if (data is List) {
          return data.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
        return await getCategories();
      }
      if (status >= 400) {
        final msg = map['message']?.toString() ?? map['error']?.toString() ?? 'Error al renombrar';
        throw Exception(msg);
      }
      return await getCategories();
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        final map = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
        final msg = map['message'] ?? map['error'] ?? 'Error al renombrar categoría';
        throw Exception(msg.toString());
      }
      rethrow;
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

