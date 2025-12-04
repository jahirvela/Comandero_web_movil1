import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Servicio de autenticación que se conecta al backend
class AuthService {
  final ApiService _api = ApiService();

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
          // Guardar tokens
          final storage = const FlutterSecureStorage();
          await storage.write(
            key: 'accessToken',
            value: data['tokens']['accessToken'],
          );
          await storage.write(
            key: 'refreshToken',
            value: data['tokens']['refreshToken'],
          );

          print('✅ Tokens guardados correctamente');
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
        errorMessage = 'No se pudo conectar al servidor. Verifica que el backend esté corriendo en http://localhost:3000';
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
        if (data['tokens'] != null) {
          final storage = const FlutterSecureStorage();
          await storage.write(
            key: 'accessToken',
            value: data['tokens']['accessToken'],
          );
          await storage.write(
            key: 'refreshToken',
            value: data['tokens']['refreshToken'],
          );
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

