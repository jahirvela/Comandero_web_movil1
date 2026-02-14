/// Utilidades para cierres de caja

/// Elimina partes repetidas en las notas del cierre.
/// Ejemplo: "Enviando cierre | Enviando cierre | Otros ingresos: X" → "Enviando cierre | Otros ingresos: X"
String deduplicateNoteParts(String? note) {
  if (note == null || note.isEmpty) return note ?? '';
  final parts = note.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final seen = <String>{};
  final unique = <String>[];
  for (final p in parts) {
    if (!seen.contains(p)) {
      seen.add(p);
      unique.add(p);
    }
  }
  return unique.join(' | ');
}
