import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/admin_model.dart';
import '../utils/date_utils.dart' as date_utils;
import 'api_service.dart';

/// Modelo de rol del backend
class RolBackend {
  final int id;
  final String nombre;
  final String? descripcion;

  RolBackend({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory RolBackend.fromJson(Map<String, dynamic> json) {
    return RolBackend(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }
}

/// Modelo de usuario del backend
class UsuarioBackend {
  final int id;
  final String nombre;
  final String username;
  final String? telefono;
  final bool activo;
  final DateTime? ultimoAcceso;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<String> roles;
  final String? password; // Contraseña en texto plano (solo cuando se crea/modifica)

  UsuarioBackend({
    required this.id,
    required this.nombre,
    required this.username,
    this.telefono,
    required this.activo,
    this.ultimoAcceso,
    required this.creadoEn,
    required this.actualizadoEn,
    required this.roles,
    this.password,
  });

  factory UsuarioBackend.fromJson(Map<String, dynamic> json) {
    return UsuarioBackend(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      username: json['username'] as String,
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool,
      ultimoAcceso: json['ultimoAcceso'] != null
          ? date_utils.AppDateUtils.parseToLocal(json['ultimoAcceso'])
          : null,
      creadoEn: date_utils.AppDateUtils.parseToLocal(json['creadoEn']),
      actualizadoEn: date_utils.AppDateUtils.parseToLocal(json['actualizadoEn']),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
      password: json['password'] as String?, // Contraseña en texto plano (solo cuando se crea/modifica)
    );
  }

  /// Convertir a AdminUser del frontend
  AdminUser toAdminUser() {
    // Mapear roles del backend al formato del frontend
    final rolesMapeados = roles.map((rol) {
      // El backend devuelve "administrador" pero el frontend espera "admin"
      if (rol.toLowerCase() == 'administrador') {
        return 'admin';
      }
      // Los demás roles ya están en el formato correcto
      return rol.toLowerCase();
    }).toList();

    return AdminUser(
      id: id.toString(),
      name: nombre,
      username: username,
      password: password ?? '', // Usar contraseña del backend si está disponible
      phone: telefono,
      roles: rolesMapeados,
      isActive: activo,
      createdAt: creadoEn,
      lastLogin: ultimoAcceso,
      createdBy: null,
    );
  }
}

/// Servicio para gestionar usuarios a través del backend
class UsuariosService {
  final ApiService _api = ApiService();

  /// Mapeo de nombres de roles del frontend a nombres del backend
  final Map<String, String> _roleNameMapping = {
    'admin': 'Administrador',
    'mesero': 'Mesero',
    'cocinero': 'Cocinero',
    'cajero': 'Cajero',
    'capitan': 'Capitán',
  };

  /// Obtener catálogo de roles del backend
  Future<List<RolBackend>> obtenerRoles() async {
    try {
      final response = await _api.get('/usuarios/roles/catalogo');
      
      // Verificar status code
      if (response.statusCode != 200) {
        throw Exception('El backend retornó un código de estado ${response.statusCode}. Respuesta: ${response.data}');
      }
      
      // Verificar que la respuesta tenga el formato esperado
      if (response.data == null) {
        throw Exception('El backend no retornó ninguna respuesta');
      }
      
      // Verificar que tenga el campo 'data'
      if (response.data is! Map || !(response.data as Map).containsKey('data')) {
        throw Exception('El backend no retornó el campo "data" en la respuesta. Respuesta recibida: ${response.data}');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('El backend retornó null en el campo "data". Respuesta completa: ${response.data}');
      }
      
      if (data is! List) {
        throw Exception('El backend retornó un formato de datos inválido para roles. Tipo recibido: ${data.runtimeType}, Valor: $data');
      }
      
      if (data.isEmpty) {
        throw Exception('El backend retornó una lista vacía de roles. Asegúrate de que haya roles en la base de datos.');
      }
      
      return data
          .map((json) {
            try {
              if (json is! Map) {
                throw Exception('El rol no es un objeto Map. Tipo: ${json.runtimeType}, Valor: $json');
              }
              return RolBackend.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              throw Exception('Error al parsear rol: $e. Datos del rol: $json');
            }
          })
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté disponible en ${ApiConfig.baseUrl}');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        if (statusCode == 401) {
          throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para ver roles.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al obtener roles: $e');
    }
  }

  /// Mapear nombres de roles del frontend a IDs del backend
  Future<List<int>> mapearRolesAIds(List<String> roleNames) async {
    if (roleNames.isEmpty) {
      return [];
    }

    try {
      final roles = await obtenerRoles();
      
      if (roles.isEmpty) {
        throw Exception('No se encontraron roles en el sistema. Asegúrate de que haya roles configurados en la base de datos.');
      }

      // Crear mapas para búsqueda flexible (por nombre exacto, minúsculas, y mapeo)
      final roleMapExact = {for (var r in roles) r.nombre: r.id};
      final roleMapLower = {for (var r in roles) r.nombre.toLowerCase(): r.id};

      final ids = <int>[];
      final errores = <String>[];

      for (final roleName in roleNames) {
        if (roleName.isEmpty) continue;

        final roleNameLower = roleName.toLowerCase().trim();
        int? id;

        // 1. Intentar mapeo usando el diccionario de mapeo
        final backendRoleName = _roleNameMapping[roleNameLower];
        if (backendRoleName != null) {
          id = roleMapExact[backendRoleName];
        }

        // 2. Si no funcionó, buscar por nombre exacto (case-insensitive)
        if (id == null) {
          id = roleMapLower[roleNameLower];
        }

        // 3. Si aún no funciona, buscar por coincidencia parcial
        if (id == null) {
          try {
            final found = roles.firstWhere(
              (r) {
                final rNombreLower = r.nombre.toLowerCase();
                return rNombreLower == roleNameLower ||
                    rNombreLower.contains(roleNameLower) ||
                    roleNameLower.contains(rNombreLower);
              },
              orElse: () => throw Exception('No encontrado'),
            );
            id = found.id;
          } catch (e) {
            errores.add(roleName);
          }
        }

        if (id != null) {
          ids.add(id);
        } else {
          errores.add(roleName);
        }
      }

      if (errores.isNotEmpty) {
        final rolesDisponibles = roles.map((r) => r.nombre).join(', ');
        throw Exception(
          'Roles no encontrados: ${errores.join(', ')}. '
          'Roles disponibles en el sistema: $rolesDisponibles'
        );
      }

      return ids;
    } catch (e) {
      // Re-lanzar el error con más contexto
      if (e.toString().contains('Error al obtener roles')) {
        rethrow;
      }
      throw Exception('Error al mapear roles a IDs: $e');
    }
  }

  /// Listar todos los usuarios
  Future<List<AdminUser>> listarUsuarios() async {
    try {
      final response = await _api.get('/usuarios');
      
      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
      
      final data = response.data['data'];
      if (data == null) {
        return [];
      }
      if (data is! List) {
        throw Exception('El backend retornó un formato de datos inválido para usuarios');
      }
      return data
          .map((json) => UsuarioBackend.fromJson(json as Map<String, dynamic>).toAdminUser())
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
      throw Exception('Error al listar usuarios: $e');
    }
  }

  /// Obtener un usuario por ID
  Future<AdminUser> obtenerUsuario(int id) async {
    try {
      final response = await _api.get('/usuarios/$id');
      
      if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode})');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('Usuario no encontrado');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el usuario');
      }
      return UsuarioBackend.fromJson(data as Map<String, dynamic>).toAdminUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Usuario no encontrado');
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
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Crear un nuevo usuario
  Future<AdminUser> crearUsuario({
    required String nombre,
    required String username,
    required String password,
    String? telefono,
    required List<String> roles,
    bool activo = true,
  }) async {
    try {
      // Validar que se hayan proporcionado roles
      if (roles.isEmpty) {
        throw Exception('Debe seleccionar al menos un rol para el usuario');
      }

      // Validar nombre y username
      if (nombre.trim().isEmpty) {
        throw Exception('El nombre no puede estar vacío');
      }
      if (username.trim().isEmpty) {
        throw Exception('El nombre de usuario no puede estar vacío');
      }
      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      // Mapear roles a IDs
      final roleIds = await mapearRolesAIds(roles);

      if (roleIds.isEmpty) {
        throw Exception('No se pudieron mapear los roles seleccionados. Verifica que los roles existan en el sistema.');
      }

      final body = {
        'nombre': nombre.trim(),
        'username': username.trim().toLowerCase(),
        'password': password,
        if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
        'activo': activo,
        'roles': roleIds,
      };

      final response = await _api.post('/usuarios', data: body);
      
      // Verificar status code
      if (response.statusCode != 201) {
        final errorMsg = response.data?['message'] ?? 
                        response.data?['error'] ?? 
                        response.data?.toString() ?? 
                        'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('El backend no retornó el usuario creado. Respuesta: ${response.data}');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el usuario creado. Tipo: ${data.runtimeType}');
      }
      return UsuarioBackend.fromJson(data as Map<String, dynamic>).toAdminUser();
    } on DioException catch (e) {
      // Manejar errores de conexión específicamente
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      // Manejar errores de respuesta del servidor
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        final errorMsg = errorData?['message'] ?? 
                        errorData?['error'] ?? 
                        errorData?.toString() ?? 
                        'Error del servidor';
        
        // Mensajes más específicos según el código de error
        if (statusCode == 400) {
          // Error de validación de Zod
          if (errorMsg.toString().contains('nombre') && errorMsg.toString().contains('min')) {
            throw Exception('El nombre debe tener al menos 3 caracteres');
          } else if (errorMsg.toString().contains('username') && errorMsg.toString().contains('min')) {
            throw Exception('El nombre de usuario debe tener al menos 3 caracteres');
          } else if (errorMsg.toString().contains('password') && errorMsg.toString().contains('min')) {
            throw Exception('La contraseña debe tener al menos 6 caracteres');
          } else if (errorMsg.toString().contains('Roles inválidos')) {
            throw Exception('Uno o más roles seleccionados no son válidos. Verifica que los roles existan en el sistema.');
          }
          throw Exception('Datos inválidos: $errorMsg');
        } else if (statusCode == 401) {
          throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para crear usuarios.');
        } else if (statusCode == 409) {
          throw Exception('El nombre de usuario "$username" ya existe. Por favor, elige otro.');
        } else {
          throw Exception('Error del servidor ($statusCode): $errorMsg');
        }
      }
      throw Exception('Error de conexión: ${e.message ?? "Error desconocido"}');
    } catch (e) {
      // Si ya es una Exception con mensaje claro, re-lanzarla
      if (e is Exception) {
        final errorStr = e.toString();
        // Evitar duplicar "Exception: Exception:"
        if (!errorStr.contains('Exception: Exception:')) {
          rethrow;
        }
        // Extraer el mensaje real si está duplicado
        final match = RegExp(r'Exception:\s*(.+?)(?:Exception:|$)').firstMatch(errorStr);
        if (match != null) {
          throw Exception(match.group(1)?.trim() ?? 'Error al crear usuario');
        }
      }
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Actualizar un usuario existente
  Future<AdminUser> actualizarUsuario({
    required int id,
    String? nombre,
    String? telefono,
    bool? activo,
    String? password,
    List<String>? roles,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (nombre != null) body['nombre'] = nombre;
      if (telefono != null) body['telefono'] = telefono.isEmpty ? null : telefono;
      if (activo != null) body['activo'] = activo;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (roles != null) {
        body['roles'] = await mapearRolesAIds(roles);
      }

      final response = await _api.put('/usuarios/$id', data: body);
      
      if (response.statusCode != 200) {
        final errorMsg = response.data?['message'] ?? response.data?['error'] ?? 'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
      
      final data = response.data['data'];
      if (data == null) {
        throw Exception('El backend no retornó el usuario actualizado');
      }
      if (data is! Map) {
        throw Exception('El backend retornó un formato de datos inválido para el usuario actualizado');
      }
      return UsuarioBackend.fromJson(data as Map<String, dynamic>).toAdminUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        if (statusCode == 404) {
          throw Exception('Usuario no encontrado');
        } else if (statusCode == 400) {
          throw Exception('Datos inválidos: $errorMsg');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para actualizar usuarios.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Eliminar (desactivar) un usuario
  Future<void> eliminarUsuario(int id) async {
    try {
      final response = await _api.delete('/usuarios/$id');
      
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
          throw Exception('Usuario no encontrado');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para eliminar usuarios.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Eliminar un usuario de forma permanente
  Future<void> eliminarUsuarioPermanente(int id) async {
    try {
      final response = await _api.delete('/usuarios/$id/permanente');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMsg = response.data?['message'] ??
            response.data?['error'] ??
            'Error desconocido';
        throw Exception('Error del servidor (${response.statusCode}): $errorMsg');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg =
            e.response!.data?['message'] ?? e.response!.data?['error'] ?? 'Error del servidor';
        if (statusCode == 404) {
          throw Exception('Usuario no encontrado');
        } else if (statusCode == 403) {
          throw Exception('No tienes permisos para eliminar usuarios.');
        }
        throw Exception('Error del servidor ($statusCode): $errorMsg');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is Exception && !e.toString().contains('Exception: Exception:')) {
        rethrow;
      }
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
