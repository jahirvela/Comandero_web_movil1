import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

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

  /// Guarda el PDF en temporal y abre el selector para compartir / guardar.
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: filename);
    } catch (e) {
      throw Exception('Error al compartir PDF: $e');
    }
  }
}

