import 'dart:io' show InternetAddressType, NetworkInterface;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración de la API del backend
///
/// Soporta tres modos:
/// - Desarrollo local (localhost/10.0.2.2/IP local)
/// - Producción (URL del VPS)
/// - Personalizado (mediante variables de entorno o configuración)
class ApiConfig {
  // ============================================
  // CONFIGURACIÓN POR AMBIENTE
  // ============================================

  /// Modo de ejecución: 'development', 'production', o 'custom'
  ///
  /// En desarrollo: usa localhost/10.0.2.2/IP local
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

  /// Normaliza una URL para que siempre tenga protocolo y host correctos.
  /// - "https:/api.dominio.com" -> "https://api.dominio.com"
  /// - "https:/.dominio.com" (falta "api") -> "https://api.dominio.com"
  /// - "https://https:/.dominio.com" (doble protocolo) -> "https://api.dominio.com"
  /// - "https" solo (sin host) no se considera válida; se devuelve vacía para que se use el default.
  static String _normalizeUrl(String url) {
    if (url.isEmpty) return url;
    String t = url.trim();
    // Quitar doble protocolo (ej. "https://https:" o "http://http:")
    if (t.contains('https://https:') || t.contains('http://http:')) {
      t = t
          .replaceFirst('https://https:', 'https:')
          .replaceFirst('http://http:', 'http:');
    }
    // Corregir "https:/" o "http:/" (una barra) a "https://" o "http://"
    if (t.startsWith('https:/') && !t.startsWith('https://')) {
      t = 'https://${t.substring(7)}';
    } else if (t.startsWith('http:/') && !t.startsWith('http://')) {
      t = 'http://${t.substring(6)}';
    }
    // Si el host empieza con punto (ej. "https://.comancleth.com"), anteponer "api"
    final protoEnd = t.indexOf('://');
    if (protoEnd != -1) {
      final afterProto = t.substring(protoEnd + 3);
      if (afterProto.startsWith('.') && afterProto.contains('.')) {
        t = '${t.substring(0, protoEnd)}://api$afterProto';
      }
      // Rechazar URL cuyo "host" sea solo el esquema (ej. "https://https" o "https://http")
      final hostPart = afterProto.split('/').first.split(':').first;
      if (hostPart.isEmpty ||
          hostPart == 'http' ||
          hostPart == 'https') {
        return '';
      }
    } else {
      // Sin "://" (ej. solo "https" o "http") -> no es una URL válida
      return '';
    }
    return t;
  }

  /// Extrae el origen (scheme + host + port) de una URL base para usar en Socket.IO.
  /// Evita construir URLs inválidas como "https://https" cuando base está mal formada.
  static String _originFromBase(String base) {
    if (base.isEmpty) return '';
    final normalized = base.trim();
    final protoEnd = normalized.indexOf('://');
    if (protoEnd == -1) return '';
    final scheme = normalized.substring(0, protoEnd);
    final afterProto = normalized.substring(protoEnd + 3);
    final hostPart = afterProto.split('/').first;
    if (hostPart.isEmpty) return '';
    final host = hostPart.split(':').first;
    final portPart = hostPart.contains(':') ? hostPart.split(':').last : null;
    if (host == 'http' || host == 'https') return '';
    final port = portPart != null && portPart.isNotEmpty ? ':$portPart' : '';
    return '$scheme://$host$port';
  }

  /// IP local detectada automáticamente (para dispositivos físicos Android)
  /// Se detecta en tiempo de ejecución la primera vez que se accede
  static String? _cachedLocalIp;

  /// Detectar IP local de la red
  ///
  /// Intenta encontrar la IP local de la máquina en la red
  /// Retorna null si no se puede detectar
  static Future<String?> _detectLocalIp() async {
    if (_cachedLocalIp != null) {
      return _cachedLocalIp;
    }

    try {
      // Obtener todas las interfaces de red
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      // Buscar la IP local (192.168.x.x o 10.x.x.x)
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Filtrar IPs locales comunes
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.16.') ||
              ip.startsWith('172.17.') ||
              ip.startsWith('172.18.') ||
              ip.startsWith('172.19.') ||
              ip.startsWith('172.20.') ||
              ip.startsWith('172.21.') ||
              ip.startsWith('172.22.') ||
              ip.startsWith('172.23.') ||
              ip.startsWith('172.24.') ||
              ip.startsWith('172.25.') ||
              ip.startsWith('172.26.') ||
              ip.startsWith('172.27.') ||
              ip.startsWith('172.28.') ||
              ip.startsWith('172.29.') ||
              ip.startsWith('172.30.') ||
              ip.startsWith('172.31.')) {
            // Evitar localhost
            if (ip != '127.0.0.1' && !ip.startsWith('169.254.')) {
              _cachedLocalIp = ip;
              if (kDebugMode) {
                print('🔍 IP local detectada: $ip');
              }
              return ip;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  No se pudo detectar IP local: $e');
      }
    }

    return null;
  }

  /// IP guardada manualmente por el usuario (persistente)
  static String? _savedManualIp;

  /// IP local configurada manualmente (para casos donde la detección automática falla)
  /// Se puede establecer mediante variable de entorno LOCAL_IP o guardada por el usuario
  static String? get _manualLocalIp {
    // Primero verificar si hay IP guardada por el usuario
    if (_savedManualIp != null && _savedManualIp!.isNotEmpty) {
      return _savedManualIp;
    }
    // Luego verificar variable de entorno (solo en compilación)
    const ip = String.fromEnvironment('LOCAL_IP', defaultValue: '');
    return ip.isEmpty ? null : ip;
  }

  /// Guardar IP manualmente configurada por el usuario
  static Future<void> saveManualIp(String? ip) async {
    _savedManualIp = ip;
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (ip != null && ip.isNotEmpty) {
          await prefs.setString('manual_server_ip', ip);
          print('✅ IP guardada manualmente: $ip');
        } else {
          await prefs.remove('manual_server_ip');
          print('✅ IP manual eliminada');
        }
      } catch (e) {
        print('⚠️  Error al guardar IP: $e');
      }
    }
  }

  /// Cargar IP guardada manualmente
  static Future<void> loadSavedManualIp() async {
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedIp = prefs.getString('manual_server_ip');
        if (savedIp != null && savedIp.isNotEmpty) {
          _savedManualIp = savedIp;
          print('✅ IP guardada cargada: $_savedManualIp');
        }
      } catch (e) {
        print('⚠️  Error al cargar IP guardada: $e');
      }
    }
  }

  /// IP del servidor detectada desde el backend (para APK móvil)
  static String? _serverIpFromBackend;

  /// Detectar IP del servidor consultando al backend
  /// Intenta detectar la IP probando rangos comunes de redes locales
  static Future<String?> _detectServerIp() async {
    if (_serverIpFromBackend != null) {
      return _serverIpFromBackend;
    }

    print('🔍 Iniciando detección automática de IP del servidor...');

    // Lista de IPs comunes a probar
    final commonIps = <String>[];

    // Si hay IP manual configurada, probarla primero
    final manualIp = _manualLocalIp;
    if (manualIp != null && manualIp.isNotEmpty) {
      commonIps.add(manualIp);
      print('   Probando IP manual primero: $manualIp');
    }

    // Obtener la IP local del dispositivo para determinar el rango de red
    String? deviceIp;
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if ((ip.startsWith('192.168.') ||
                  ip.startsWith('10.') ||
                  (ip.startsWith('172.') &&
                      int.parse(ip.split('.')[1]) >= 16 &&
                      int.parse(ip.split('.')[1]) <= 31)) &&
              ip != '127.0.0.1' &&
              !ip.startsWith('169.254.')) {
            deviceIp = ip;
            break;
          }
        }
        if (deviceIp != null) break;
      }
    } catch (e) {
      print('⚠️  No se pudo obtener IP del dispositivo: $e');
    }

    // Si tenemos la IP del dispositivo, generar IPs del mismo rango
    if (deviceIp != null) {
      final parts = deviceIp.split('.');
      if (parts.length == 4) {
        final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        print('   Red detectada: $networkPrefix.x');

        // Probar IPs cercanas primero (más probables)
        final baseIp = int.parse(parts[3]);
        for (int offset in [-10, -5, -2, -1, 1, 2, 5, 10, 20, 50, 100]) {
          final testIp = baseIp + offset;
          if (testIp >= 1 && testIp <= 254) {
            commonIps.add('$networkPrefix.$testIp');
          }
        }

        // También probar algunas IPs comunes del rango
        for (int i = 1; i <= 254; i++) {
          if (i % 10 == 0 || i == 1 || i == 100 || i == 254) {
            if (!commonIps.contains('$networkPrefix.$i')) {
              commonIps.add('$networkPrefix.$i');
            }
          }
        }
      }
    }

    // Agregar IPs comunes de otros rangos (por si cambió de red)
    commonIps.addAll([
      '192.168.1.1',
      '192.168.1.2',
      '192.168.1.10',
      '192.168.1.20',
      '192.168.1.24',
      '192.168.1.50',
      '192.168.1.100',
      '192.168.1.101',
      '192.168.1.254',
      '192.168.0.1',
      '192.168.0.10',
      '192.168.0.20',
      '192.168.0.100',
      '192.168.2.1',
      '192.168.2.10',
      '192.168.2.100',
      '10.0.0.1',
      '10.0.0.2',
      '10.0.0.10',
      '10.0.1.1',
      '10.0.1.10',
    ]);

    // Eliminar duplicados
    final uniqueIps = commonIps.toSet().toList();
    print('   Probando ${uniqueIps.length} IPs...');

    // Probar cada IP con timeout corto (en paralelo en grupos)
    const batchSize = 10;
    for (int i = 0; i < uniqueIps.length; i += batchSize) {
      final batch = uniqueIps.skip(i).take(batchSize).toList();
      final results = await Future.wait(
        batch.map((ip) => _testServerIp(ip)),
        eagerError: false,
      );

      for (final result in results) {
        if (result != null) {
          _serverIpFromBackend = result;
          print(
            '✅ IP del servidor detectada automáticamente: $_serverIpFromBackend',
          );
          return _serverIpFromBackend;
        }
      }
    }

    print('⚠️  No se pudo detectar automáticamente la IP del servidor');
    print('   Puedes configurarla manualmente desde la pantalla de login');
    return null;
  }

  /// Probar una IP específica
  static Future<String?> _testServerIp(String ip) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://$ip:3000',
          connectTimeout: const Duration(milliseconds: 600),
          receiveTimeout: const Duration(milliseconds: 600),
        ),
      );

      final response = await dio.get('/api/server-info');
      if (response.statusCode == 200 && response.data['serverIp'] != null) {
        return response.data['serverIp'] as String;
      }
    } catch (e) {
      // Ignorar errores, continuar probando
    }
    return null;
  }

  /// URL base del servidor en desarrollo
  /// Versión síncrona (para compatibilidad)
  /// Usa IP por defecto si no se ha detectado aún
  static String get _developmentApiUrlSync {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      // Prioridad 1: IP guardada manualmente por el usuario (más confiable)
      final manualIp = _manualLocalIp;
      if (manualIp != null && manualIp.isNotEmpty) {
        return 'http://$manualIp:3000/api';
      }

      // Prioridad 2: IP del servidor detectada automáticamente
      if (_serverIpFromBackend != null) {
        return 'http://$_serverIpFromBackend:3000/api';
      }

      // Prioridad 3: IP local detectada del dispositivo
      if (_cachedLocalIp != null) {
        return 'http://$_cachedLocalIp:3000/api';
      }

      // Por defecto, usar IP del servidor para pruebas locales
      // TODO: Cambiar esto por detección automática o configuración manual en producción
      return 'http://192.168.0.198:3000/api';
    }
  }

  /// URL personalizada (para testing o configuraciones especiales)
  static const String _customApiUrl = String.fromEnvironment(
    'CUSTOM_API_URL',
    defaultValue: '',
  );

  // ============================================
  // FALLBACK EN WEB (build con API_URL mal)
  // ============================================

  /// En web en producción: si la URL del build está mal, derivar desde el host actual del navegador.
  /// Así la app desplegada en comancleth.com usará https://api.comancleth.com sin recompilar.
  static String? get _webProductionFallbackBaseUrl {
    if (!kIsWeb || _environment != 'production') return null;
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost') return null;
    final scheme = Uri.base.scheme;
    return '$scheme://api.$host/api';
  }

  static String? get _webProductionFallbackSocketUrl {
    if (!kIsWeb || _environment != 'production') return null;
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost') return null;
    final scheme = Uri.base.scheme;
    return '$scheme://api.$host';
  }

  /// True si la URL está claramente mal formada (ej. "https://https" o "https:/.dominio").
  static bool _isUrlBroken(String url) {
    if (url.isEmpty) return true;
    return url.contains('https://https') ||
        url.contains('http://http') ||
        _originFromBase(url).isEmpty;
  }

  // ============================================
  // URL BASE DE LA API
  // ============================================

  /// URL base del backend
  static String get baseUrl {
    // Si hay una URL personalizada, usarla (normalizada)
    if (_customApiUrl.isNotEmpty) {
      final u = _normalizeUrl(_customApiUrl);
      if (u.isNotEmpty) return u;
    }

    // En producción, usar la URL del VPS (normalizada por si API_URL tiene typo)
    if (_environment == 'production') {
      final u = _normalizeUrl(_productionApiUrl);
      if (u.isNotEmpty && !_isUrlBroken(u)) return u;
      // Fallback en web: derivar desde el host actual (app en comancleth.com → api.comancleth.com)
      final webFallback = _webProductionFallbackBaseUrl;
      if (webFallback != null) return webFallback;
      return 'https://api.comandix.com/api';
    }

    // En desarrollo, usar localhost/10.0.2.2/IP local
    return _developmentApiUrlSync;
  }

  // ============================================
  // URL DE SOCKET.IO
  // ============================================

  /// URL para Socket.IO (origen: scheme + host + port, sin path).
  ///
  /// Se deriva de baseUrl de forma segura para no generar URLs inválidas
  /// como "wss://https/socket.io" cuando API_URL está mal (ej. solo "https").
  static String get socketUrl {
    // Si hay una URL personalizada, derivar origen de ella
    if (_customApiUrl.isNotEmpty) {
      final normalized = _normalizeUrl(_customApiUrl.replaceAll('/api', '').trim());
      final origin = _originFromBase(normalized.isEmpty ? _customApiUrl : normalized);
      return origin.isEmpty ? 'http://localhost:3000' : origin;
    }

    // En producción: derivar origen de baseUrl (nunca concatenar "https://" + url)
    if (_environment == 'production') {
      final base = baseUrl;
      final origin = _originFromBase(base);
      if (origin.isNotEmpty && !_isUrlBroken(origin)) {
        return origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
      }
      // Fallback en web: mismo host que la app (app en comancleth.com → api.comancleth.com)
      final webFallback = _webProductionFallbackSocketUrl;
      if (webFallback != null) return webFallback;
      return 'https://api.comandix.com';
    }

    // En desarrollo, usar localhost/10.0.2.2/IP local sin /api
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      final manualIp = _manualLocalIp;
      if (manualIp != null && manualIp.isNotEmpty) {
        return 'http://$manualIp:3000';
      }
      if (_serverIpFromBackend != null) {
        return 'http://$_serverIpFromBackend:3000';
      }
      if (_cachedLocalIp != null) {
        return 'http://$_cachedLocalIp:3000';
      }
      return 'http://192.168.0.198:3000';
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

  /// Inicializar detección de IP local (llamar al inicio de la app)
  static Future<void> detectLocalIp() async {
    if (!kIsWeb) {
      // Primero intentar detectar IP local del dispositivo
      await _detectLocalIp();
      // Luego intentar detectar IP del servidor consultando al backend
      await _detectServerIp();
    }
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
      if (_manualLocalIp != null) {
        print('Manual Local IP: $_manualLocalIp');
      }
      if (_cachedLocalIp != null) {
        print('Local IP detected: $_cachedLocalIp');
      }
      print('================');
    }
  }
}
