import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento de auth en móvil/desktop: seguro (FlutterSecureStorage).
class AuthStorage {
  static const _storage = FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
