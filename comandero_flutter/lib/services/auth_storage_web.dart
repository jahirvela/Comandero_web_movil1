import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento de auth en web: SharedPreferences (FlutterSecureStorage falla en muchos navegadores).
class AuthStorage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> read(String key) async {
    final prefs = await _instance;
    return prefs.getString(key);
  }

  Future<void> write(String key, String value) async {
    final prefs = await _instance;
    await prefs.setString(key, value);
  }

  Future<void> delete(String key) async {
    final prefs = await _instance;
    await prefs.remove(key);
  }
}
