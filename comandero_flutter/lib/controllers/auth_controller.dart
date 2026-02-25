import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/auth_storage.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';

class AuthController extends ChangeNotifier {
  final AuthStorage _storage = AuthStorage();
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  String _userRole = '';
  String _userName = '';
  String _userId = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userId => _userId;

  /// Login con el backend real (optimizado para rendimiento)
  Future<bool> login(String username, String password) async {
    try {
      AppLogger.info('Intentando login con usuario: $username');
      final response = await _authService.login(username, password);

      if (response != null && response['user'] != null) {
        final user = response['user'];
        
        AppLogger.success('Login exitoso. Usuario: ${user['username']}');
        
        _isLoggedIn = true;
        _userName = user['username'] ?? username;
        _userId = user['id']?.toString() ?? '';
        
        // Obtener el primer rol (el backend devuelve roles como array)
        final roles = user['roles'] as List<dynamic>?;
        if (roles != null && roles.isNotEmpty) {
          _userRole = roles[0].toString().toLowerCase();
          // Mapear nombres de roles del backend a los del frontend
          if (_userRole == 'administrador') {
            _userRole = 'admin';
          }
        } else {
          _userRole = 'mesero'; // Por defecto
        }

        // Desconectar socket anterior ANTES de guardar datos de usuario
        AppLogger.debug('Desconectando socket anterior...');
        SocketService().disconnectCompletely();
        
        // Guardar información del usuario en paralelo
        AppLogger.debug('Guardando información del usuario...');
        await Future.wait([
          _storage.write('isLoggedIn', 'true'),
          _storage.write('userRole', _userRole),
          _storage.write('userName', _userName),
          _storage.write('userId', _userId),
          _storage.write('userNombre', user['nombre'] ?? ''),
        ]);

        // Verificar token una sola vez (optimizado)
        final currentToken = await _storage.read('accessToken');
        if (currentToken == null || currentToken.isEmpty) {
          AppLogger.error('Token no disponible después del login');
          throw Exception('Error: Token no disponible después del login');
        }

        // Conectar Socket.IO (sin delays innecesarios - el storage ya guardó)
        AppLogger.debug('Conectando Socket.IO...');
        try {
          await SocketService().connect();
          AppLogger.success('Socket.IO conectado exitosamente');
        } catch (e) {
          AppLogger.error('Error al conectar Socket.IO', e);
          // No fallar el login si Socket.IO falla
        }

        notifyListeners();
        return true;
      }
      AppLogger.warn('Respuesta del login no contiene usuario');
      return false;
    } catch (e) {
      AppLogger.error('Error en login', e);
      rethrow;
    }
  }

  Future<void> logout() async {
    AppLogger.info('Iniciando proceso de cierre de sesión...');
    
    // Resetear estado en memoria PRIMERO
    _isLoggedIn = false;
    _userRole = '';
    _userName = '';
    _userId = '';

    // Preservar flags importantes ANTES de limpiar
    final clearedHistory = await _storage.read('cleared_table_history');
    final completedOrders = await _storage.read('cocinero_completed_orders');
    final sentToCashierOrders = await _storage.read('mesero_sent_to_cashier_orders');

    // Desconectar Socket.IO y limpiar en paralelo (optimizado)
    AppLogger.debug('Desconectando Socket.IO y limpiando storage...');
    SocketService().disconnectCompletely();
    await _authService.logout();
    
    // Eliminar datos de autenticación en paralelo
    await Future.wait([
      _storage.delete('accessToken'),
      _storage.delete('refreshToken'),
      _storage.delete('userId'),
      _storage.delete('userRole'),
      _storage.delete('userName'),
      _storage.delete('userNombre'),
      _storage.delete('isLoggedIn'),
      _storage.delete('station'),
    ]);
    
    // Restaurar flags que deben persistir entre sesiones (si existían)
    final restoreOps = <Future>[];
    if (clearedHistory != null && clearedHistory.isNotEmpty && clearedHistory != '{}') {
      restoreOps.add(_storage.write('cleared_table_history', clearedHistory));
    }
    if (completedOrders != null && completedOrders.isNotEmpty && completedOrders != '[]') {
      restoreOps.add(_storage.write('cocinero_completed_orders', completedOrders));
    }
    if (sentToCashierOrders != null && sentToCashierOrders.isNotEmpty) {
      restoreOps.add(_storage.write('mesero_sent_to_cashier_orders', sentToCashierOrders));
    }
    if (restoreOps.isNotEmpty) {
      await Future.wait(restoreOps);
    }
    
    notifyListeners();
    AppLogger.success('Logout completado - Sesión cerrada completamente');
  }

  Future<void> checkAuthStatus() async {
    try {
      // Leer todas las claves en paralelo (optimizado)
      final values = await Future.wait([
        _storage.read('isLoggedIn'),
        _storage.read('userRole'),
        _storage.read('userName'),
        _storage.read('userId'),
        _storage.read('accessToken'),
      ]);

      final isLoggedIn = values[0];
      final userRole = values[1];
      final userName = values[2];
      final userId = values[3];
      final accessToken = values[4];

      if (isLoggedIn == 'true' && userRole != null && accessToken != null) {
        _isLoggedIn = true;
        _userRole = userRole;
        _userName = userName ?? '';
        _userId = userId ?? '';
        
        // NO reconectar Socket.IO aquí automáticamente
        // La conexión se debe hacer explícitamente después del login
        // o cuando el usuario navegue a una vista que requiera socket
        // Esto evita conexiones duplicadas y problemas de autenticación
        
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error al verificar estado de autenticación', e);
    }
  }
}

