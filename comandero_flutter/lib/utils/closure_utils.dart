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

/// Huella estable: colapsa varias filas en BD (mismo evento, IDs distintos por doble envío).
/// Los `calc-*` no se fusionan entre sí.
String cashCloseLogicalFingerprint(CashCloseModel c) {
  if (c.id.startsWith('calc-')) return 'calc:${c.id}';
  final evt = (c.eventoTipo ?? '').trim().toLowerCase();
  final turno = (c.turnoCodigo ?? '').trim().toLowerCase();
  final u = c.usuario.trim().toLowerCase();
  final bucket = c.fecha.millisecondsSinceEpoch ~/ 60000;
  final note = deduplicateNoteParts(c.notaCajero)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
  String cents(double x) => (x * 100).round().toString();
  final tipoTag = evt == 'apertura'
      ? 'A'
      : evt == 'cierre_dia'
          ? 'D'
          : 'C';
  return '$tipoTag|$evt|$turno|$u|$bucket|${cents(c.totalNeto)}|'
      '${cents(c.efectivoInicial)}|${cents(c.efectivo)}|${cents(c.tarjeta)}|$note';
}

/// Una fila por evento lógico; si hubo INSERTs duplicados en BD, queda el de **menor** [cierreId].
List<CashCloseModel> dedupeCashClosuresForDisplay(List<CashCloseModel> list) {
  if (list.length <= 1) return list;
  final groups = <String, List<CashCloseModel>>{};
  for (final c in list) {
    final k = cashCloseLogicalFingerprint(c);
    groups.putIfAbsent(k, () => []).add(c);
  }
  final out = <CashCloseModel>[];
  for (final group in groups.values) {
    if (group.length == 1) {
      out.add(group.first);
      continue;
    }
    group.sort((a, b) {
      final ida = a.cierreId ?? 2147483647;
      final idb = b.cierreId ?? 2147483647;
      if (ida != idb) return ida.compareTo(idb);
      return b.fecha.compareTo(a.fecha);
    });
    out.add(group.first);
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
