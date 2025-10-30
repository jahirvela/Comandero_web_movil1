import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthController extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoggedIn = false;
  String _userRole = '';
  String _userName = '';
  String _userId = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userId => _userId;

  // Simular login (aquí se conectará con la API real)
  Future<bool> login(String username, String password) async {
    try {
      // Simulación de autenticación
      await Future.delayed(const Duration(seconds: 1));

      // Por ahora, aceptamos cualquier usuario con password "123"
      if (password == '123') {
        _isLoggedIn = true;
        _userName = username;
        _userId = '1';

        // Determinar rol basado en el username
        if (username.toLowerCase().contains('admin')) {
          _userRole = 'admin';
        } else if (username.toLowerCase().contains('mesero')) {
          _userRole = 'mesero';
        } else if (username.toLowerCase().contains('cocinero')) {
          _userRole = 'cocinero';
        } else if (username.toLowerCase().contains('cajero')) {
          _userRole = 'cajero';
        } else if (username.toLowerCase().contains('capitan')) {
          _userRole = 'capitan';
        } else {
          _userRole = 'mesero'; // Por defecto
        }

        // Guardar en almacenamiento seguro
        await _storage.write(key: 'isLoggedIn', value: 'true');
        await _storage.write(key: 'userRole', value: _userRole);
        await _storage.write(key: 'userName', value: _userName);
        await _storage.write(key: 'userId', value: _userId);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userRole = '';
    _userName = '';
    _userId = '';

    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _storage.read(key: 'isLoggedIn');
      final userRole = await _storage.read(key: 'userRole');
      final userName = await _storage.read(key: 'userName');
      final userId = await _storage.read(key: 'userId');

      if (isLoggedIn == 'true' && userRole != null) {
        _isLoggedIn = true;
        _userRole = userRole;
        _userName = userName ?? '';
        _userId = userId ?? '';
        notifyListeners();
      }
    } catch (e) {
      // Error al leer el almacenamiento
    }
  }
}

