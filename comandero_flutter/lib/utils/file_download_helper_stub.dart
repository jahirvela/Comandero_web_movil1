import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show XFile;

/// Helper para descargar archivos en Flutter (Mobile)
class FileDownloadHelper {
  /// Descarga un archivo CSV directamente
  static Future<void> downloadCSV(String content, String filename) async {
    try {
      // Para móvil, guardar archivo temporalmente y compartir
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: filename);
    } catch (e) {
      throw Exception('Error al descargar archivo CSV: $e');
    }
  }
}

