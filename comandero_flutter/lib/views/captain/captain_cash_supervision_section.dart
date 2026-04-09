import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/captain_controller.dart';
import '../../models/admin_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/cash_ui_responsive.dart';
import '../../utils/date_utils.dart' as date_utils;

String _tipoEventoCapitan(CashCloseModel c) {
  if (c.eventoTipo == 'apertura') return 'Apertura';
  if (c.eventoTipo == 'cierre') return 'Cierre';
  if (c.efectivoInicial > 0 && c.totalNeto < 1) return 'Apertura';
  if (c.totalNeto >= 1) return 'Cierre';
  return '—';
}

String _turnoTexto(CashCloseModel c) {
  final a = (c.turnoLabel ?? '').trim();
  if (a.isNotEmpty) return a;
  final b = (c.turnoCodigo ?? '').trim();
  return b.isEmpty ? '—' : b;
}

/// Supervisión de caja (solo lectura): modo diario/turnos, apertura activa y eventos del día.
class CaptainCashSupervisionSection extends StatelessWidget {
  const CaptainCashSupervisionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptainController>(
      builder: (context, c, _) {
        final opening = c.todayActiveCashOpening;
        final hoyList = c.cashClosuresToday;
        final loading = c.isLoadingCashSupervision;
        final sw = MediaQuery.sizeOf(context).width;
        final tablet = CashUiResponsive.isTabletOrWider(sw);
        final pad = tablet ? 20.0 : 16.0;
        final useWideEventRow = sw >= CashUiResponsive.tabletMin;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: tablet ? 26 : 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Supervisión de caja',
                        style: TextStyle(
                          fontSize: tablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (loading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: () => c.loadCashSupervision(),
                        icon: const Icon(Icons.refresh, size: 22),
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Misma lógica que cajero: modo ${c.cajaModoLabel.toLowerCase()}. Solo lectura.',
                  style: TextStyle(
                    fontSize: tablet ? 13.0 : 12.0,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (c.cajaPorTurnos && c.cajaTurnos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: c.cajaTurnos
                        .map(
                          (t) => Chip(
                            label: Text(
                              '${t.nombre} (${t.inicio}–${t.fin})',
                              style: TextStyle(
                                fontSize: tablet ? 11.0 : 10.0,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                if (opening != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_open,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Caja abierta',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                                fontSize: tablet ? 15.0 : 14.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _kv(
                          'Cajero',
                          opening.usuario,
                          tablet,
                          sw,
                        ),
                        if (_turnoTexto(opening) != '—')
                          _kv('Turno', _turnoTexto(opening), tablet, sw),
                        _kv(
                          'Efectivo inicial',
                          c.formatCurrency(opening.efectivoInicial),
                          tablet,
                          sw,
                        ),
                        _kv(
                          'Apertura',
                          date_utils.AppDateUtils.formatDateTimeWithAmPm(
                            opening.fecha,
                          ),
                          tablet,
                          sw,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.orange.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.cajaPorTurnos
                                ? 'Sin apertura activa para el turno vigente (o la caja está cerrada).'
                                : 'Sin apertura de caja activa hoy (o el día ya quedó cerrado).',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: tablet ? 14.0 : 13.0,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Eventos de hoy (aperturas y cierres)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: tablet ? 15.0 : 14.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (hoyList.isEmpty)
                  Text(
                    loading
                        ? 'Cargando…'
                        : 'No hay registros de caja hoy.',
                    style: TextStyle(
                      fontSize: tablet ? 14.0 : 13.0,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  ...hoyList.take(12).map((ev) {
                    if (useWideEventRow) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                date_utils.AppDateUtils.formatDateTimeWithAmPm(
                                  ev.fecha,
                                ),
                                style: TextStyle(
                                  fontSize: tablet ? 12.0 : 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _tipoEventoCapitan(ev),
                                style: TextStyle(
                                  fontSize: tablet ? 12.0 : 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _turnoTexto(ev),
                                style: TextStyle(
                                  fontSize: tablet ? 12.0 : 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                ev.usuario,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: tablet ? 12.0 : 11.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                c.formatCurrency(ev.totalNeto),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: tablet ? 12.0 : 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      date_utils.AppDateUtils
                                          .formatDateTimeWithAmPm(ev.fecha),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    c.formatCurrency(ev.totalNeto),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _tipoEventoCapitan(ev),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_turnoTexto(ev) != '—')
                                    Text(
                                      'Turno: ${_turnoTexto(ev)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ev.usuario,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (hoyList.length > 12)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '… y ${hoyList.length - 12} más',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v, bool tablet, double width) {
    final fs = tablet ? 13.0 : 12.0;
    final narrow = width < 400;
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k,
              style: TextStyle(
                fontSize: fs,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              v,
              style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              k,
              style: TextStyle(
                fontSize: fs,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
