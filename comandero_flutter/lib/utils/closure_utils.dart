/// Utilidades para cierres de caja

import '../models/admin_model.dart';

/// `true` si el registro es una apertura de caja (según backend o heurística legado).
bool cashCloseEsApertura(CashCloseModel c) {
  final t = c.eventoTipo?.toLowerCase();
  if (t == 'apertura') return true;
  if (t == 'cierre' || t == 'cierre_dia') return false;
  return c.totalNeto < 0.01 && c.efectivoInicial > 0;
}

/// Etiqueta corta para tablas y chips.
String cashCloseTipoEtiqueta(CashCloseModel c) =>
    cashCloseEsApertura(c) ? 'Apertura' : 'Cierre';

String _cashCloseDedupeKey(CashCloseModel c) {
  if (c.cierreId != null) return 'id:${c.cierreId}';
  if (c.id.startsWith('calc-')) return 'calc:${c.id}';
  final t = cashCloseEsApertura(c) ? 'apertura' : 'cierre';
  final note = deduplicateNoteParts(c.notaCajero);
  final bucket = c.fecha.millisecondsSinceEpoch ~/ 60000;
  return 'fp:$t|${c.usuario}|$bucket|${c.totalNeto.toStringAsFixed(2)}|'
      '${c.efectivoInicial.toStringAsFixed(2)}|${c.efectivo.toStringAsFixed(2)}|'
      '${c.tarjeta.toStringAsFixed(2)}|$note';
}

/// Evita filas duplicadas (mismo [cierreId], mismo `calc-*`, o mismo evento duplicado en BD).
List<CashCloseModel> dedupeCashClosuresForDisplay(List<CashCloseModel> list) {
  if (list.length <= 1) return list;
  final sorted = [...list]..sort((a, b) => b.fecha.compareTo(a.fecha));
  final seen = <String>{};
  final out = <CashCloseModel>[];
  for (final c in sorted) {
    final key = _cashCloseDedupeKey(c);
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(c);
  }
  out.sort((a, b) => b.fecha.compareTo(a.fecha));
  return out;
}

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
