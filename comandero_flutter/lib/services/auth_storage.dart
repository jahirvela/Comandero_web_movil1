// En web usa SharedPreferences; en móvil/desktop usa FlutterSecureStorage.
// Evita el fallo "Null check operator" de FlutterSecureStorage en navegadores.
export 'auth_storage_io.dart' if (dart.library.html) 'auth_storage_web.dart';
