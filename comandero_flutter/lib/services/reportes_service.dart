import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReportesService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  /// Descarga un archivo (PDF o CSV) desde el backend
  Future<String?> _descargarArchivo(String url, String filename) async {
    try {
      final token = await _getAccessToken();
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Guardar archivo en directorio temporal
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      print('Error al descargar archivo: $e');
      return null;
    }
  }

  /// Abre o comparte un archivo
  Future<void> _abrirOCompartir(String? filePath, String filename) async {
    if (filePath == null) {
      throw Exception('No se pudo descargar el archivo');
    }

    try {
      // Intentar abrir el archivo
      await OpenFile.open(filePath);
    } catch (e) {
      // Si no se puede abrir, compartir
      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: filename,
        );
      } catch (e2) {
        print('Error al abrir/compartir archivo: $e2');
        rethrow;
      }
    }
  }

  /// Genera y descarga reporte de ventas en PDF
  Future<void> generarReporteVentasPDF({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/ventas/pdf?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr';
    final filename = 'reporte-ventas-$fechaInicioStr-$fechaFinStr.pdf';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga reporte de ventas en CSV
  Future<void> generarReporteVentasCSV({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/ventas/csv?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr';
    final filename = 'reporte-ventas-$fechaInicioStr-$fechaFinStr.csv';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga top productos en PDF
  Future<void> generarTopProductosPDF({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int limite = 10,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/top-productos/pdf?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr&limite=$limite';
    final filename = 'top-productos-$fechaInicioStr-$fechaFinStr.pdf';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga top productos en CSV
  Future<void> generarTopProductosCSV({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int limite = 10,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/top-productos/csv?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr&limite=$limite';
    final filename = 'top-productos-$fechaInicioStr-$fechaFinStr.csv';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga corte de caja en PDF
  Future<void> generarCorteCajaPDF({
    required DateTime fecha,
    int? cajeroId,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final url = cajeroId != null
        ? '${ApiConfig.baseUrl}/reportes/corte-caja/pdf?fecha=$fechaStr&cajeroId=$cajeroId'
        : '${ApiConfig.baseUrl}/reportes/corte-caja/pdf?fecha=$fechaStr';
    final filename = 'corte-caja-$fechaStr.pdf';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga corte de caja en CSV
  Future<void> generarCorteCajaCSV({
    required DateTime fecha,
    int? cajeroId,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final url = cajeroId != null
        ? '${ApiConfig.baseUrl}/reportes/corte-caja/csv?fecha=$fechaStr&cajeroId=$cajeroId'
        : '${ApiConfig.baseUrl}/reportes/corte-caja/csv?fecha=$fechaStr';
    final filename = 'corte-caja-$fechaStr.csv';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga reporte de inventario en PDF
  Future<void> generarReporteInventarioPDF({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/inventario/pdf?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr';
    final filename = 'reporte-inventario-$fechaInicioStr-$fechaFinStr.pdf';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }

  /// Genera y descarga reporte de inventario en CSV
  Future<void> generarReporteInventarioCSV({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
    final fechaFinStr = fechaFin.toIso8601String().split('T')[0];
    final url =
        '${ApiConfig.baseUrl}/reportes/inventario/csv?fechaInicio=$fechaInicioStr&fechaFin=$fechaFinStr';
    final filename = 'reporte-inventario-$fechaInicioStr-$fechaFinStr.csv';

    final filePath = await _descargarArchivo(url, filename);
    await _abrirOCompartir(filePath, filename);
  }
}

