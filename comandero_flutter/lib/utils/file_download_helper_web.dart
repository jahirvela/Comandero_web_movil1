import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Helper para descargar archivos en Flutter (Web)
class FileDownloadHelper {
  /// Descarga un archivo CSV directamente con codificación UTF-8 BOM para Excel
  static Future<void> downloadCSV(String content, String filename) async {
    try {
      // Agregar BOM UTF-8 para que Excel reconozca correctamente la codificación
      final utf8Bom = '\uFEFF';
      final contentWithBom = utf8Bom + content;
      
      // Convertir a bytes UTF-8
      final bytes = utf8.encode(contentWithBom);
      
      // Para web, descargar directamente usando dart:html
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Error al descargar archivo CSV: $e');
    }
  }

  /// Descarga un PDF (bytes).
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Error al descargar PDF: $e');
    }
  }
}

