import 'package:csv/csv.dart';

/// Normaliza encabezados CSV (minúsculas, sin espacios ni guiones bajos).
String normalizeInventoryCsvHeader(String h) {
  return h
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('_', '');
}

/// Convierte texto CSV en filas como mapas clave→valor (claves normalizadas).
/// Omite líneas completamente vacías.
List<Map<String, String>> parseInventoryImportCsv(String raw) {
  var text = raw.trim();
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  if (text.isEmpty) return [];

  const converter = CsvToListConverter(shouldParseNumbers: false);
  final rows = converter.convert(text);
  if (rows.isEmpty) return [];

  final headers = rows.first
      .map((e) => normalizeInventoryCsvHeader(e.toString()))
      .toList();

  final out = <Map<String, String>>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final map = <String, String>{};
    for (var j = 0; j < headers.length && j < row.length; j++) {
      map[headers[j]] = row[j].toString().trim();
    }
    if (map.values.every((v) => v.isEmpty)) continue;
    out.add(map);
  }
  return out;
}
