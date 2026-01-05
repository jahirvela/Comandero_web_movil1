// Este archivo usa importaciones condicionales
// En web, se usa file_download_helper_web.dart
// En móvil, se usa file_download_helper_stub.dart

export 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';
