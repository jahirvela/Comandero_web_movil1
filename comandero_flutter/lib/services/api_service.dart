import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../config/api_config.dart';
import 'auth_storage.dart';

/// Servicio base para todas las peticiones HTTP al backend
/// 
/// Incluye:
/// - Reintentos automáticos ante errores de red
/// - Refresh automático de tokens
/// - Manejo robusto de errores
/// - Timeouts configurables
/// - Configuración optimizada para Flutter Web
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
    _setupInterceptors();
  }

  late final Dio _dio;
  final AuthStorage _storage = AuthStorage();

  /// Evita varias renovaciones en paralelo cuando muchas peticiones reciben 401 a la vez.
  Future<bool>? _ongoingRefresh;

  static const String _retriedAfterRefreshKey = 'retriedAfterRefresh';

  /// Inicializar Dio con configuración optimizada
  void _initializeDio() {
    final baseUrl = ApiConfig.baseUrl;
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Configuración específica para Flutter Web
      followRedirects: true,
      // Solo 2xx como éxito: si tratamos 401 como éxito, onError no corre y el refresh JWT nunca se ejecuta.
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ));

    // Configuración adicional para Flutter Web
    if (kIsWeb) {
      _dio.options.extra['withCredentials'] = true;
    }
  }

  /// Obtener el token de acceso almacenado
  Future<String?> _getAccessToken() async {
    return await _storage.read('accessToken');
  }

  /// Guardar el token de acceso
  Future<void> _saveAccessToken(String token) async {
    await _storage.write('accessToken', token);
  }

  /// Guardar el refresh token
  Future<void> _saveRefreshToken(String token) async {
    await _storage.write('refreshToken', token);
  }

  /// Limpiar tokens almacenados
  Future<void> clearTokens() async {
    await _storage.delete('accessToken');
    await _storage.delete('refreshToken');
  }

  /// Verificar si un error es recuperable (debe reintentar)
  bool _isRetryableError(DioException error) {
    // Errores de conexión que pueden recuperarse
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500); // Errores del servidor
  }

  /// Reintentar una petición con backoff exponencial
  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request, {
    int retryCount = 0,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      // Si no es un error recuperable o se agotaron los reintentos
      if (!_isRetryableError(e) || retryCount >= ApiConfig.maxRetries) {
        rethrow;
      }

      // Esperar antes de reintentar (backoff exponencial)
      final delay = Duration(
        milliseconds: ApiConfig.retryDelay.inMilliseconds * (retryCount + 1),
      );
      await Future.delayed(delay);

      // Reintentar
      return await _retryRequest(request, retryCount: retryCount + 1);
    }
  }

  /// Configurar el interceptor para agregar el token automáticamente
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login y refresh no deben llevar Bearer (evita confusión y bucles raros en el servidor).
          final path = options.uri.path;
          final skipBearer = path.contains('/auth/login') ||
              path.contains('/auth/refresh');
          if (!skipBearer) {
            final token = await _getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          if (kDebugMode) {
            print('📤 ${options.method} ${options.uri}');
          }
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // Si el token expiró (401), intentar refrescar
          if (error.response?.statusCode == 401) {
            final opts = error.requestOptions;
            if (opts.extra[_retriedAfterRefreshKey] == true) {
              return handler.next(error);
            }
            final path = opts.uri.path;
            if (path.contains('/auth/login') || path.contains('/auth/refresh')) {
              return handler.next(error);
            }
            try {
              final refreshToken = await _storage.read('refreshToken');
              if (refreshToken != null) {
                final refreshed = await _refreshTokenLocked(refreshToken);
                if (refreshed) {
                  // Reintentar la petición original una sola vez tras renovar
                  final retry = opts.copyWith(
                    headers: Map<String, dynamic>.from(opts.headers),
                  );
                  retry.extra = Map<String, dynamic>.from(opts.extra);
                  retry.extra[_retriedAfterRefreshKey] = true;
                  final token = await _getAccessToken();
                  retry.headers['Authorization'] = 'Bearer $token';
                  final response = await _dio.fetch(retry);
                  return handler.resolve(response);
                }
              }
            } catch (e) {
              // Si falla el refresh, limpiar tokens
              await clearTokens();
              if (kDebugMode) {
                print('⚠️ Refresh de token falló, sesión cerrada. Error: $e');
              }
              // Propagar el 401 al caller para que la UI muestre error y no se quede colgada
              return handler.next(error);
            }
            // Refresh no disponible o no logró refrescar: propagar error
            return handler.next(error);
          }
          
          if (kDebugMode) {
            final statusCode = error.response?.statusCode?.toString() ?? 'N/A';
            final uri = error.requestOptions.uri.toString();
            print('❌ Error $statusCode: $uri');
            if (error.response != null) {
              final responseData = error.response?.data;
              if (responseData != null) {
                final responseStr = responseData.toString();
                print('   Response: $responseStr');
              } else {
                print('   Response: (vacío)');
              }
            } else {
              final errorMsg = error.message;
              if (errorMsg != null && errorMsg.isNotEmpty) {
                print('   Error: $errorMsg');
              } else {
                print('   Error: Error desconocido');
              }
            }
          }
          
          handler.next(error);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ ${response.statusCode} ${response.requestOptions.uri}');
          }
          handler.next(response);
        },
      ),
    );
  }

  Future<bool> _refreshTokenLocked(String refreshToken) {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }
    _ongoingRefresh = _refreshTokenImpl(refreshToken).whenComplete(() {
      _ongoingRefresh = null;
    });
    return _ongoingRefresh!;
  }

  /// Refrescar el token de acceso (cliente sin interceptores para evitar recursión).
  Future<bool> _refreshTokenImpl(String refreshToken) async {
    try {
      final dioWithoutInterceptors = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ));

      if (kIsWeb) {
        dioWithoutInterceptors.options.extra['withCredentials'] = true;
      }

      final response = await dioWithoutInterceptors.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['tokens'] != null) {
          final tokens = data['tokens'] as Map;
          final access = tokens['accessToken']?.toString() ?? '';
          final refresh = tokens['refreshToken']?.toString() ?? '';
          if (access.isNotEmpty && refresh.isNotEmpty) {
            await _saveAccessToken(access);
            await _saveRefreshToken(refresh);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error al refrescar token: $e');
      }
      return false;
    }
  }

  /// Verificar conectividad con el servidor
  Future<bool> checkConnection() async {
    try {
      // SIEMPRE imprimir la URL que se está usando (incluso en release para debugging)
      print('🔍 Verificando conexión con el backend...');
      print('   URL: ${ApiConfig.baseUrl}');
      print('   Socket URL: ${ApiConfig.socketUrl}');
      print('   IsWeb: $kIsWeb');
      if (kDebugMode) {
        print('   Debug mode: ON');
      }
      
      // Crear un cliente simple sin interceptores para la verificación
      final testDio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20), // Aumentado para web
        receiveTimeout: const Duration(seconds: 20), // Aumentado para web
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ));

      // Para Flutter Web, asegurar que las credenciales se envíen
      if (kIsWeb) {
        testDio.options.extra['withCredentials'] = true;
      }
      
      final response = await testDio.get('/health');
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Conexión exitosa con el backend');
          print('   Response: ${response.data}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️  Backend respondió con status ${response.statusCode}');
        }
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error de conexión: ${e.type}');
        print('   URL intentada: ${ApiConfig.baseUrl}/health');
        if (e.type == DioExceptionType.connectionError) {
          print('   No se pudo conectar al servidor');
          print('   Verifica que:');
          print('   1. El backend esté corriendo: cd backend && npm run dev');
          print('   2. El backend esté en ${ApiConfig.baseUrl}');
          print('   3. CORS esté configurado para permitir localhost:*');
          print('   4. No haya firewall bloqueando la conexión');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          print('   Timeout: El backend no respondió a tiempo');
        }
        if (e.response != null) {
          print('   Status: ${e.response?.statusCode}');
          print('   Data: ${e.response?.data}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inesperado al verificar conexión: $e');
      }
      return false;
    }
  }

  /// Inicializar el servicio
  void initialize() {
    ApiConfig.printConfig();
    
    // Verificar conexión al iniciar (solo en debug y después de un delay más largo)
    // En web, hacerlo de forma completamente asíncrona para no bloquear el inicio
    if (kDebugMode) {
      // En web, esperar más tiempo y hacerlo completamente en background
      final delay = kIsWeb ? const Duration(seconds: 2) : const Duration(milliseconds: 500);
      
      Future.delayed(delay, () {
        // Ejecutar en background sin bloquear
        checkConnection().then((connected) {
          if (connected) {
            print('✅ Conexión con el backend verificada');
          } else {
            print('⚠️  No se pudo conectar al backend');
            print('   Verifica que esté corriendo en ${ApiConfig.baseUrl}');
          }
        }).catchError((e) {
          // Ignorar errores en la verificación para no bloquear
          if (kDebugMode) {
            print('⚠️  Error al verificar conexión: $e');
          }
        });
      });
    }
  }

  /// GET request con reintentos automáticos.
  /// [options] permite override de timeout (p. ej. para configuración: 12s en vez de 45s).
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _retryRequest(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
    );
  }

  /// POST request con reintentos automáticos
  Future<Response> post(String path, {dynamic data}) async {
    return await _retryRequest(() => _dio.post(path, data: data));
  }

  /// PUT request con reintentos automáticos
  Future<Response> put(String path, {dynamic data}) async {
    return await _retryRequest(() => _dio.put(path, data: data));
  }

  /// PATCH request con reintentos automáticos
  Future<Response> patch(String path, {dynamic data}) async {
    return await _retryRequest(() => _dio.patch(path, data: data));
  }

  /// DELETE request con reintentos automáticos
  Future<Response> delete(String path) async {
    return await _retryRequest(() => _dio.delete(path));
  }

  /// Obtener mensaje de error amigable para el usuario
  static String getErrorMessage(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data?['message'] ?? 'Error en la petición';
      
      switch (statusCode) {
        case 400:
          return 'Datos inválidos: $message';
        case 401:
          return 'Sesión expirada. Por favor, inicia sesión nuevamente.';
        case 403:
          return 'No tienes permisos para realizar esta acción.';
        case 404:
          return 'Recurso no encontrado.';
        case 500:
        case 502:
        case 503:
          return 'El servidor no está disponible. Intenta más tarde.';
        default:
          return message;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión a Internet.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor. Verifica que el backend esté corriendo.';
    }

    return 'Error de conexión. Verifica tu conexión a Internet.';
  }
}
