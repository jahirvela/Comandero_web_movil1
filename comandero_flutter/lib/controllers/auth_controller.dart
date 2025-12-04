import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthController extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  String _userRole = '';
  String _userName = '';
  String _userId = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userId => _userId;

  /// Login con el backend real
  Future<bool> login(String username, String password) async {
    try {
      print('Intentando login con usuario: $username');
      final response = await _authService.login(username, password);

      if (response != null && response['user'] != null) {
        final user = response['user'];
        
        print('Login exitoso. Usuario: ${user['username']}');
        
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

        // Guardar información adicional
        await _storage.write(key: 'isLoggedIn', value: 'true');
        await _storage.write(key: 'userRole', value: _userRole);
        await _storage.write(key: 'userName', value: _userName);
        await _storage.write(key: 'userId', value: _userId);
        await _storage.write(key: 'userNombre', value: user['nombre'] ?? '');

        // Conectar Socket.IO después del login exitoso
        try {
          await SocketService().connect();
        } catch (e) {
          print('Error al conectar Socket.IO: $e');
          // No fallar el login si Socket.IO falla
        }

        notifyListeners();
        return true;
      }
      print('Error: Respuesta del login no contiene usuario');
      return false;
    } catch (e) {
      print('Error en login: $e');
      // Re-lanzar el error para que la UI pueda mostrar el mensaje
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userRole = '';
    _userName = '';
    _userId = '';

    // Desconectar Socket.IO completamente (limpia todos los listeners activos y pendientes)
    // Esto es importante para que al iniciar sesión con otro rol,
    // los listeners se registren frescos sin duplicados
    print('🚪 Logout: Desconectando Socket.IO completamente...');
    SocketService().disconnectCompletely();

    await _authService.logout();
    
    // Preservar flags importantes antes de limpiar storage
    final clearedHistory = await _storage.read(key: 'cleared_table_history');
    final completedOrders = await _storage.read(key: 'cocinero_completed_orders');
    final sentToCashierOrders = await _storage.read(key: 'mesero_sent_to_cashier_orders');
    
    // Limpiar todo el storage
    await _storage.deleteAll();
    
    // Restaurar flags que deben persistir entre sesiones
    if (clearedHistory != null && clearedHistory != '{}') {
      await _storage.write(key: 'cleared_table_history', value: clearedHistory);
      print('💾 Logout: Preservado cleared_table_history');
    }
    if (completedOrders != null && completedOrders != '[]') {
      await _storage.write(key: 'cocinero_completed_orders', value: completedOrders);
      print('💾 Logout: Preservado cocinero_completed_orders');
    }
    if (sentToCashierOrders != null && sentToCashierOrders.isNotEmpty) {
      await _storage.write(key: 'mesero_sent_to_cashier_orders', value: sentToCashierOrders);
      print('💾 Logout: Preservado mesero_sent_to_cashier_orders: $sentToCashierOrders');
    }
    
    notifyListeners();
    print('✅ Logout completado');
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _storage.read(key: 'isLoggedIn');
      final userRole = await _storage.read(key: 'userRole');
      final userName = await _storage.read(key: 'userName');
      final userId = await _storage.read(key: 'userId');
      final accessToken = await _storage.read(key: 'accessToken');

      if (isLoggedIn == 'true' && userRole != null && accessToken != null) {
        _isLoggedIn = true;
        _userRole = userRole;
        _userName = userName ?? '';
        _userId = userId ?? '';
        
        // Reconectar Socket.IO si hay token válido
        try {
          await SocketService().connect();
        } catch (e) {
          print('Error al reconectar Socket.IO: $e');
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error al verificar estado de autenticación: $e');
    }
  }
}

