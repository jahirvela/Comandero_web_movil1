import 'package:flutter/foundation.dart';

/// Utilidad de logging optimizada para Flutter Web
/// Solo imprime en modo debug para mejorar el rendimiento en producción
class AppLogger {
  static bool get _isDebugMode => kDebugMode;

  /// Log de información (solo en debug)
  static void info(String message) {
    if (_isDebugMode) {
      print('ℹ️ $message');
    }
  }

  /// Log de éxito (solo en debug)
  static void success(String message) {
    if (_isDebugMode) {
      print('✅ $message');
    }
  }

  /// Log de advertencia (solo en debug)
  static void warn(String message) {
    if (_isDebugMode) {
      print('⚠️ $message');
    }
  }

  /// Log de error (siempre se muestra)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Los errores siempre se muestran, incluso en producción
    print('❌ $message');
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null && _isDebugMode) {
      print('Stack trace: $stackTrace');
    }
  }

  /// Log de debug detallado (solo en debug)
  static void debug(String message) {
    if (_isDebugMode) {
      print('🔍 $message');
    }
  }

  /// Log simple (solo en debug)
  static void log(String message) {
    if (_isDebugMode) {
      print(message);
    }
  }
}

