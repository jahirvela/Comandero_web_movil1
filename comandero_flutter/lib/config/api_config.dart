import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Configuración de la API del backend
/// 
/// Soporta tres modos:
/// - Desarrollo local (localhost/10.0.2.2)
/// - Producción (URL del VPS)
/// - Personalizado (mediante variables de entorno o configuración)
class ApiConfig {
  // ============================================
  // CONFIGURACIÓN POR AMBIENTE
  // ============================================
  
  /// Modo de ejecución: 'development', 'production', o 'custom'
  /// 
  /// En desarrollo: usa localhost/10.0.2.2
  /// En producción: usa la URL del VPS
  /// Custom: permite configurar manualmente
  static const String _environment = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'development',
  );

  /// URL base del servidor en producción
  /// 
  /// IMPORTANTE: Cambiar esta URL cuando se tenga el dominio/IP del VPS
  /// Ejemplo: 'https://api.comandix.com' o 'https://192.168.1.100:3000'
  static const String _productionApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.comandix.com',
  );

  /// URL base del servidor en desarrollo
  static String get _developmentApiUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      // Android emulator usa 10.0.2.2 para localhost
      // iOS simulator usa localhost
      // Dispositivo físico: usar IP de tu máquina
      return 'http://10.0.2.2:3000/api';
    }
  }

  /// URL personalizada (para testing o configuraciones especiales)
  static const String _customApiUrl = String.fromEnvironment(
    'CUSTOM_API_URL',
    defaultValue: '',
  );

  // ============================================
  // URL BASE DE LA API
  // ============================================
  
  /// URL base del backend
  static String get baseUrl {
    // Si hay una URL personalizada, usarla
    if (_customApiUrl.isNotEmpty) {
      return _customApiUrl;
    }

    // En producción, usar la URL del VPS
    if (_environment == 'production') {
      return _productionApiUrl;
    }

    // En desarrollo, usar localhost/10.0.2.2
    return _developmentApiUrl;
  }

  // ============================================
  // URL DE SOCKET.IO
  // ============================================
  
  /// URL para Socket.IO
  /// 
  /// En producción, debe ser la misma base que baseUrl pero sin /api
  static String get socketUrl {
    // Si hay una URL personalizada, derivar Socket.IO de ella
    if (_customApiUrl.isNotEmpty) {
      // Remover /api si existe
      final url = _customApiUrl.replaceAll('/api', '');
      return url;
    }

    // En producción, usar la URL del VPS sin /api
    if (_environment == 'production') {
      // Remover /api si existe en la URL de producción
      return _productionApiUrl.replaceAll('/api', '');
    }

    // En desarrollo, usar localhost/10.0.2.2 sin /api
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  // ============================================
  // CONFIGURACIÓN DE TIMEOUTS
  // ============================================
  
  /// Timeout para peticiones HTTP
  /// 
  /// En producción con internet móvil, usar timeouts más largos
  static Duration get timeout {
    if (_environment == 'production') {
      // Internet móvil puede ser más lento
      return const Duration(seconds: 45);
    }
    // Desarrollo local es más rápido
    return const Duration(seconds: 30);
  }

  /// Número de reintentos para peticiones fallidas
  static int get maxRetries {
    if (_environment == 'production') {
      // En producción, más reintentos por cortes de red
      return 3;
    }
    return 2;
  }

  /// Delay entre reintentos (en segundos)
  static Duration get retryDelay {
    if (_environment == 'production') {
      // En producción, esperar más entre reintentos
      return const Duration(seconds: 2);
    }
    return const Duration(seconds: 1);
  }

  // ============================================
  // HEADERS COMUNES
  // ============================================
  
  /// Headers comunes para todas las peticiones
  static Map<String, String> getHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================
  // INFORMACIÓN DE DEBUG
  // ============================================
  
  /// Información de configuración actual (solo en debug)
  static Map<String, dynamic> get debugInfo {
    if (!kDebugMode) {
      return {};
    }

    return {
      'environment': _environment,
      'baseUrl': baseUrl,
      'socketUrl': socketUrl,
      'timeout': timeout.inSeconds,
      'maxRetries': maxRetries,
      'isWeb': kIsWeb,
    };
  }

  /// Imprimir información de configuración (solo en debug)
  static void printConfig() {
    if (kDebugMode) {
      print('=== ApiConfig ===');
      print('Environment: $_environment');
      print('Base URL: $baseUrl');
      print('Socket URL: $socketUrl');
      print('Timeout: ${timeout.inSeconds}s');
      print('Max Retries: $maxRetries');
      print('================');
    }
  }
}
