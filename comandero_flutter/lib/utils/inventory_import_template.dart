import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'date_utils.dart';

/// Encabezados recomendados para importar ajustes de inventario (CSV).
const List<String> kInventoryImportCsvHeaders = [
  'id',
  'codigoBarras',
  'cantidadActual',
  'stockMinimo',
  'stockMaximo',
  'costoUnitario',
];

/// Contenido CSV de ejemplo (UTF-8 sin BOM; el helper web añade BOM al descargar).
String buildInventoryImportCsvTemplateContent() {
  const converter = ListToCsvConverter();
  final body = converter.convert([
    kInventoryImportCsvHeaders,
    ['123', '', '10', '2', '20', '25.50'],
    ['', '7501234567890', '5', '', '', ''],
  ]);
  return '$body\n\nGenerado (CDMX),${AppDateUtils.formatDateTimeWithAmPm(AppDateUtils.nowCdmx())}';
}

Future<Uint8List> buildInventoryImportTemplatePdfBytes() async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          'Plantilla de importacion de inventario',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'El archivo debe ser CSV (coma o punto y coma segun tu Excel). Primera fila: encabezados.',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Por cada fila de datos:',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Bullet(
          text:
              'Indica al menos id (numero de la columna ID en la tabla web) O codigoBarras (si el producto lo tiene).',
        ),
        pw.Bullet(
          text:
              'Indica al menos uno de: cantidadActual (o stock), stockMinimo (o minimo), stockMaximo (o maximo), costoUnitario (o costo).',
        ),
        pw.Bullet(
          text:
              'Si pones id y codigoBarras, se usa solo el id para localizar el producto.',
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Ejemplo de filas:',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _templatePdfTable(),
        pw.SizedBox(height: 16),
        pw.Text(
          'Descarga la plantilla CSV desde la misma ventana de importacion para editarla en Excel.',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Generado el ${AppDateUtils.formatDateTimeWithAmPm(AppDateUtils.nowCdmx())} (CDMX)',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return await doc.save();
}

pw.Widget _templatePdfTable() {
  pw.Widget cell(String t, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        t,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(1),
      1: const pw.FlexColumnWidth(1.4),
      2: const pw.FlexColumnWidth(1.1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        children: [
          cell('id', header: true),
          cell('codigoBarras', header: true),
          cell('cantidadActual', header: true),
          cell('stockMinimo', header: true),
          cell('stockMaximo', header: true),
          cell('costoUnitario', header: true),
        ],
      ),
      pw.TableRow(
        children: [
          cell('123'),
          cell('(vacio)'),
          cell('10'),
          cell('2'),
          cell('20'),
          cell('25.50'),
        ],
      ),
      pw.TableRow(
        children: [
          cell('(vacio)'),
          cell('7501234567890'),
          cell('5'),
          cell(''),
          cell(''),
          cell(''),
        ],
      ),
    ],
  );
}
