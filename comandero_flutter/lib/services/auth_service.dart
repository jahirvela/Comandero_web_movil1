import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'auth_storage.dart';

/// Servicio de autenticación que se conecta al backend
class AuthService {
  final ApiService _api = ApiService();
  final AuthStorage _storage = AuthStorage();

  /// Login con username y password
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // El backend devuelve directamente { user: {...}, tokens: {...} }
        // Verificar que tenga la estructura esperada
        if (data != null && data['user'] != null && data['tokens'] != null) {
          // Extraer tokens como String no nulos (evita "Null check operator" en web/storage)
          final tokens = data['tokens'] as Map<String, dynamic>?;
          final accessToken = tokens?['accessToken']?.toString() ?? '';
          final refreshToken = tokens?['refreshToken']?.toString() ?? '';
          if (accessToken.isEmpty || refreshToken.isEmpty) {
            print('❌ Error: Respuesta del servidor sin accessToken o refreshToken');
            return null;
          }

          // CRÍTICO: Limpiar tokens anteriores ANTES de guardar los nuevos
          print('🔄 AuthService: Limpiando tokens anteriores antes de guardar nuevos...');
          try {
            await _storage.delete('accessToken');
            await _storage.delete('refreshToken');
            await _storage.delete('userId');
            await _storage.delete('userRole');
            await _storage.delete('userName');
            await _storage.delete('userNombre');
            await _storage.delete('isLoggedIn');
            await Future.delayed(const Duration(milliseconds: 200));
          } catch (e) {
            print('⚠️ AuthService: Error al limpiar storage (continuando): $e');
          }
          
          // Guardar los nuevos tokens (en web usamos SharedPreferences por fallos de FlutterSecureStorage)
          print('💾 AuthService: Guardando nuevos tokens...');
          try {
            await _storage.write('accessToken', accessToken);
            await _storage.write('refreshToken', refreshToken);
          } catch (e) {
            print('❌ AuthService: Error al guardar tokens: $e');
            throw Exception('No se pudo guardar la sesión en este navegador. Prueba en modo incógnito o otro navegador.');
          }
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          final savedToken = await _storage.read('accessToken');
          if (savedToken == null || savedToken != accessToken) {
            print('⚠️ AuthService: El token no se guardó correctamente, reintentando...');
            try {
              await _storage.write('accessToken', accessToken);
              await Future.delayed(const Duration(milliseconds: 300));
            } catch (e) {
              print('⚠️ AuthService: Reintento de guardado falló: $e');
            }
            final savedToken2 = await _storage.read('accessToken');
            if (savedToken2 == null || savedToken2 != accessToken) {
              print('❌ AuthService: No se pudo guardar el token después de múltiples intentos');
              throw Exception('Error: No se pudo guardar el token en storage');
            }
          }

          final tokenToVerify = savedToken ?? await _storage.read('accessToken');
          try {
            final parts = (tokenToVerify ?? '').split('.');
            if (parts.length >= 2) {
              final payload = parts[1];
              final base64Payload = payload.replaceAll('-', '+').replaceAll('_', '/');
              final paddedPayload = base64Payload + '=' * (4 - base64Payload.length % 4);
              final decoded = utf8.decode(base64Decode(paddedPayload));
              final payloadJson = jsonDecode(decoded) as Map<String, dynamic>;
              final tokenUserId = payloadJson['sub']?.toString();
              final tokenUsername = payloadJson['username']?.toString();
              print('✅ AuthService: Token guardado y verificado - userId: $tokenUserId, username: $tokenUsername');
            }
          } catch (e) {
            print('⚠️ AuthService: No se pudo decodificar el token para verificación: $e');
          }

          print('✅ AuthService: Tokens guardados correctamente');
          return data;
        } else {
          print('❌ Error: Respuesta del servidor no tiene la estructura esperada');
          print('Data recibida: $data');
          print('Estructura esperada: { user: {...}, tokens: {...} }');
          return null;
        }
      }
      print('❌ Error: Status code ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      // Manejo específico de errores de Dio
      String errorMessage = 'Error al iniciar sesión';
      
      print('❌ Error en login (DioException):');
      print('   Tipo: ${e.type}');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        if (statusCode == 401) {
          errorMessage = responseData['message'] ?? 'Credenciales incorrectas';
          print('   Error 401: Credenciales inválidas');
        } else if (statusCode == 403) {
          errorMessage = responseData['message'] ?? 'Usuario deshabilitado';
          print('   Error 403: Usuario deshabilitado');
        } else if (statusCode == 400) {
          errorMessage = responseData['message'] ?? 'Datos inválidos';
          print('   Error 400: Datos inválidos');
        } else if (statusCode == 429) {
          errorMessage = responseData['message'] ?? 'Demasiados intentos de inicio de sesión. Espera un momento e intenta de nuevo.';
          print('   Error 429: Rate limit excedido');
        } else {
          errorMessage = responseData['message'] ?? 'Error en el servidor';
          print('   Error $statusCode: $errorMessage');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tiempo de espera agotado. Verifica tu conexión.';
        print('   Error: Timeout de conexión');
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No se pudo conectar al servidor. Verifica que el backend esté disponible en ${ApiConfig.baseUrl}';
        print('   Error: No se pudo conectar al servidor');
        print('   URL intentada: ${ApiConfig.baseUrl}/auth/login');
      } else {
        print('   Error desconocido: ${e.type}');
      }
      
      print('   Mensaje final: $errorMessage');
      rethrow;
    } catch (e) {
      print('Error inesperado en login: $e');
      rethrow;
    }
  }

  /// Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _api.get('/auth/me');
      if (response.statusCode == 200) {
        // El endpoint /auth/me devuelve el objeto directamente, no envuelto en 'data'
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  /// Refresh token
  Future<bool> refreshToken(String refreshToken) async {
    try {
      final response = await _api.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final access = tokens?['accessToken']?.toString() ?? '';
        final refresh = tokens?['refreshToken']?.toString() ?? '';
        if (access.isNotEmpty && refresh.isNotEmpty) {
          await _storage.write('accessToken', access);
          await _storage.write('refreshToken', refresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error al refrescar token: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _api.clearTokens();
  }
}

