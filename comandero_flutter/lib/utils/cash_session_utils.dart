import '../models/admin_model.dart';
import 'date_utils.dart' as date_utils;

bool _esMismoDiaOperativoCdmx(DateTime cierreFecha, DateTime hoy) {
  final esHoy =
      cierreFecha.year == hoy.year &&
      cierreFecha.month == hoy.month &&
      cierreFecha.day == hoy.day;
  final ayer = hoy.subtract(const Duration(days: 1));
  final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final inicioAyer18h = DateTime(ayer.year, ayer.month, ayer.day, 18);
  final esAyerNoche =
      cierreFecha.isAfter(inicioAyer18h) && cierreFecha.isBefore(inicioHoy);
  return esHoy || esAyerNoche;
}

/// Apertura de caja (incluye registros legados marcados como `cierre` sin ventas).
bool esAperturaCaja(CashCloseModel c) {
  if (c.eventoTipo == 'apertura') return true;
  if (c.eventoTipo == 'cierre_dia') return false;
  if (c.eventoTipo == 'cierre') {
    // Compatibilidad con registros legados mal clasificados:
    // algunas aperturas antiguas quedaron como "cierre" pero con total ~0 y nota de apertura.
    final notas = (c.notaCajero ?? '').toLowerCase();
    final sinVentas = c.totalNeto <= 0.000001;
    final mantieneInicial =
        (c.efectivoContado - c.efectivoInicial).abs() <= 0.000001;
    return sinVentas && (mantieneInicial || notas.contains('apertura'));
  }
  return c.efectivoInicial > 0 && (c.totalNeto == 0 || c.totalNeto < 1.0);
}

bool _esCierreOperativo(CashCloseModel c) {
  if (c.eventoTipo == 'cierre') return c.totalNeto >= 0.5;
  if (c.eventoTipo == 'apertura') return false;
  return c.totalNeto >= 1.0;
}

bool _mismoTurno(CashCloseModel a, CashCloseModel b, bool modoTurnos) {
  if (!modoTurnos) return true;
  final ca = a.turnoCodigo ?? '';
  final cb = b.turnoCodigo ?? '';
  return ca == cb;
}

/// Apertura de caja vigente (día operativo CDMX). En modo turnos distingue por [turnoCodigo].
CashCloseModel? resolveActiveCashOpening(
  Iterable<CashCloseModel> closures, {
  required bool modoTurnos,
  String? turnoCodigoFiltro,
}) {
  final hoy = date_utils.AppDateUtils.nowCdmx();
  final delDia = closures
      .where((c) => _esMismoDiaOperativoCdmx(c.fecha, hoy))
      .toList()
    ..sort((a, b) => a.fecha.compareTo(b.fecha));

  CashCloseModel? candidato;
  for (final c in delDia) {
    if (esAperturaCaja(c)) {
      if (modoTurnos &&
          turnoCodigoFiltro != null &&
          turnoCodigoFiltro.isNotEmpty &&
          (c.turnoCodigo ?? '') != turnoCodigoFiltro) {
        continue;
      }
      candidato = c;
    } else if (_esCierreOperativo(c) &&
        candidato != null &&
        _mismoTurno(candidato, c, modoTurnos)) {
      candidato = null;
    }
  }
  return candidato;
}
