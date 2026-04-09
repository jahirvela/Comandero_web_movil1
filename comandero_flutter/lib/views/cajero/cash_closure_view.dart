import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cajero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/cash_ui_responsive.dart';
import '../../models/admin_model.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../services/cierres_service.dart';

String _tipoEventoCierreEtiquetaCajero(CashCloseModel c) {
  if (c.eventoTipo == 'apertura') return 'Apertura de caja';
  if (c.eventoTipo == 'cierre_dia') return 'Cierre general del día';
  if (c.eventoTipo == 'cierre') return 'Cierre de caja';
  if (c.efectivoInicial > 0 && c.totalNeto < 1) return 'Apertura de caja';
  if (c.totalNeto >= 1) return 'Cierre de caja';
  return '';
}

String _turnoLineCajero(CashCloseModel c) {
  final a = (c.turnoLabel ?? '').trim();
  if (a.isNotEmpty) return a;
  return (c.turnoCodigo ?? '').trim();
}

class CashClosureView extends StatefulWidget {
  const CashClosureView({super.key});

  @override
  State<CashClosureView> createState() => _CashClosureViewState();
}

class _CashClosureViewState extends State<CashClosureView> {
  String selectedPeriod = 'Día';
  String selectedStatus = 'Todos';
  DateTime? selectedDate; // Fecha seleccionada del calendario

  bool _matchesAnyStatus(CashCloseModel closure, List<String> aliases) {
    final estado = closure.estado.toLowerCase().trim();
    return aliases.contains(estado);
  }

  bool _matchesSelectedStatus(CashCloseModel closure) {
    if (selectedStatus == 'Todos') return true;
    switch (selectedStatus) {
      case 'Pendiente':
        return _matchesAnyStatus(closure, ['pending', 'pendiente']);
      case 'Aprobado':
        return _matchesAnyStatus(closure, ['approved', 'aprobado']);
      case 'Rechazado':
        return _matchesAnyStatus(closure, ['rejected', 'rechazado']);
      case 'Aclaración':
        return _matchesAnyStatus(closure, ['clarification', 'aclaracion']);
      default:
        return true;
    }
  }

  List<CashCloseModel> _getFilteredClosures(List<CashCloseModel> closures) {
    return closures.where((closure) {
      bool periodMatch = true;
      if (selectedDate != null) {
        final closureDate = DateTime(
          closure.fecha.year,
          closure.fecha.month,
          closure.fecha.day,
        );
        final selectedDateOnly = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );
        periodMatch = closureDate.isAtSameMomentAs(selectedDateOnly);
      } else {
        final now = date_utils.AppDateUtils.nowCdmx();
        final closureDate = DateTime(
          closure.fecha.year,
          closure.fecha.month,
          closure.fecha.day,
        );
        final today = DateTime(now.year, now.month, now.day);

        switch (selectedPeriod) {
          case 'Día':
            periodMatch = closureDate.isAtSameMomentAs(today);
            break;
          case 'Semana':
            final daysFromMonday = today.weekday - 1;
            final weekStart = today.subtract(Duration(days: daysFromMonday));
            final weekEnd = weekStart.add(const Duration(days: 6));
            periodMatch =
                closureDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                closureDate.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case 'Mes':
            periodMatch =
                closureDate.year == today.year && closureDate.month == today.month;
            break;
          default:
            periodMatch = true;
        }
      }

      return periodMatch && _matchesSelectedStatus(closure);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Cargar cierres cuando se inicia la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<CajeroController>();
      controller.loadCashClosures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header
              _buildHeader(context, isTablet),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner de aclaraciones pendientes
                      _buildClarificationBanner(isTablet),
                      const SizedBox(height: 24),

                      // Resumen general
                      _buildGeneralSummary(isTablet),
                      const SizedBox(height: 24),

                      // Filtros
                      _buildFilters(isTablet),
                      const SizedBox(height: 24),

                      // Lista de cortes de caja
                      _buildCashClosuresList(isTablet, isDesktop),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final userName = authController.userName.isNotEmpty
            ? authController.userName
            : 'Cajero';
        
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: Row(
                children: [
                  // Botón de regreso
                  IconButton(
                    onPressed: () {
                      context.read<CajeroController>().setCurrentView('main');
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Título
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión de Cortes de Caja',
                          style: TextStyle(
                            fontSize: isTablet ? 24.0 : 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$userName • Cajero',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón de estadísticas
                  IconButton(
                    onPressed: () {
                      _showStatisticsDialog(context);
                    },
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralSummary(bool isTablet) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        final closures = controller.cashClosures;
        final pendingClosures = controller.getPendingClosures();
        final approvedClosures = closures
            .where((c) => _matchesAnyStatus(c, ['aprobado', 'approved']))
            .length;
        final totalAmount = closures.fold<double>(
          0,
          (sum, closure) => sum + closure.totalNeto,
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: isTablet ? 24.0 : 20.0,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Resumen de Cortes de Caja',
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Cortes Pendientes',
                        '${pendingClosures.length}',
                        AppColors.warning,
                        Icons.schedule,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Cortes Aprobados',
                        '$approvedClosures',
                        AppColors.success,
                        Icons.check_circle,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Generado',
                        controller.formatCurrency(totalAmount),
                        AppColors.info,
                        Icons.trending_up,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Cortes',
                        '${closures.length}',
                        AppColors.primary,
                        Icons.receipt_long,
                        isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isTablet ? 24.0 : 20.0),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: isTablet ? 12.0 : 10.0, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedDate != null ? 'Personalizado' : selectedPeriod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 12.0,
                            vertical: isTablet ? 16.0 : 12.0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Día', child: Text('Hoy')),
                          DropdownMenuItem(
                            value: 'Semana',
                            child: Text('Esta Semana'),
                          ),
                          DropdownMenuItem(value: 'Mes', child: Text('Este Mes')),
                          DropdownMenuItem(
                            value: 'Personalizado',
                            child: Text('Seleccionar Fecha'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == 'Personalizado') {
                            // Abrir calendario para seleccionar fecha
                            _selectDate(context);
                          } else {
                            setState(() {
                              selectedPeriod = value!;
                              selectedDate = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 12.0,
                            vertical: isTablet ? 16.0 : 12.0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'Pendiente',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem(
                            value: 'Aprobado',
                            child: Text('Aprobado'),
                          ),
                          DropdownMenuItem(
                            value: 'Rechazado',
                            child: Text('Rechazado'),
                          ),
                          DropdownMenuItem(
                            value: 'Aclaración',
                            child: Text('Aclaración'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Mostrar fecha seleccionada si hay una
            if (selectedDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fecha seleccionada: ${_formatDate(selectedDate!)}',
                      style: TextStyle(
                        fontSize: isTablet ? 13.0 : 11.0,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                          selectedPeriod = 'Día';
                        });
                      },
                      child: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? date_utils.AppDateUtils.nowCdmx(),
      firstDate: DateTime(2020),
      lastDate: date_utils.AppDateUtils.nowCdmx().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedPeriod = 'Personalizado';
      });
    }
  }

  String _formatDate(DateTime date) {
    // Asegurarse de que la fecha esté en zona horaria local
    final localDate = date.isUtc ? date.toLocal() : date;
    return date_utils.AppDateUtils.formatDateTime(localDate);
  }

  Widget _buildCashClosuresList(bool isTablet, bool isDesktop) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        final closures = controller.cashClosures;
        final filteredClosures = _getFilteredClosures(closures);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cortes de Caja (${filteredClosures.length})',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (filteredClosures.isEmpty)
              _buildEmptyState(isTablet)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredClosures.length,
                itemBuilder: (context, index) {
                  return _buildCashClosureCard(
                    filteredClosures[index],
                    controller,
                    isTablet,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cortes de caja',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los cortes de caja aparecerán aquí',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCashClosureCard(
    dynamic closure,
    CajeroController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getCashCloseStatusColor(closure.estado);
    final statusIcon = _getStatusIcon(closure.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withValues(alpha: 0.05),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final narrowDetails = maxW < CashUiResponsive.tabletMin;
            final compactBtns = CashUiResponsive.isCompactLayout(maxW);

            Widget detailRow() {
              if (narrowDetails) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDetailItem(
                      'Efectivo',
                      controller.formatCurrency(closure.efectivo),
                      Icons.money,
                      AppColors.success,
                      isTablet,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      'Tarjeta',
                      controller.formatCurrency(closure.tarjeta),
                      Icons.credit_card,
                      AppColors.info,
                      isTablet,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      'Otros',
                      controller.formatCurrency(closure.otrosIngresos ?? 0),
                      Icons.add,
                      AppColors.warning,
                      isTablet,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Efectivo',
                      controller.formatCurrency(closure.efectivo),
                      Icons.money,
                      AppColors.success,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      'Tarjeta',
                      controller.formatCurrency(closure.tarjeta),
                      Icons.credit_card,
                      AppColors.info,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      'Otros',
                      controller.formatCurrency(closure.otrosIngresos ?? 0),
                      Icons.add,
                      AppColors.warning,
                      isTablet,
                    ),
                  ),
                ],
              );
            }

            Widget metaLine() {
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isTablet ? 16.0 : 14.0,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.formatDate(closure.fecha),
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: isTablet ? 16.0 : 14.0,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW * 0.85),
                        child: Text(
                          closure.usuario,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            Widget actionButtons() {
              final ver = OutlinedButton.icon(
                onPressed: () {
                  _showClosureDetails(closure, controller);
                },
                icon: const Icon(Icons.visibility),
                label: Text(
                  'Ver Detalles',
                  style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              final hist = ElevatedButton.icon(
                onPressed: () {
                  _showAuditLog(closure);
                },
                icon: const Icon(Icons.history),
                label: Text(
                  'Historial',
                  style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              if (compactBtns) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ver,
                    const SizedBox(height: 8),
                    hist,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: ver),
                  const SizedBox(width: 8),
                  Expanded(child: hist),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del corte
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatClosureId(closure.id),
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Período: ${closure.periodo}',
                              style: TextStyle(
                                fontSize: isTablet ? 14.0 : 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_tipoEventoCierreEtiquetaCajero(closure)
                                .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _tipoEventoCierreEtiquetaCajero(closure),
                                style: TextStyle(
                                  fontSize: isTablet ? 12.0 : 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (_turnoLineCajero(closure).isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Turno: ${_turnoLineCajero(closure)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 12.0 : 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  statusIcon,
                                  style: TextStyle(
                                    fontSize: isTablet ? 12.0 : 10.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _translateStatus(closure.estado),
                                  style: TextStyle(
                                    fontSize: isTablet ? 12.0 : 10.0,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.formatCurrency(closure.totalNeto),
                            style: TextStyle(
                              fontSize: isTablet ? 16.0 : 14.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detalles del corte
                  detailRow(),
                  const SizedBox(height: 16),

                  // Información adicional
                  metaLine(),
                  const SizedBox(height: 16),

                  // Botones de acción
                  actionButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isTablet ? 16.0 : 14.0),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: isTablet ? 10.0 : 8.0, color: color),
          ),
        ],
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'pending':
        return '⏳';
      case 'aprobado':
      case 'approved':
        return '✅';
      case 'rechazado':
      case 'rejected':
        return '❌';
      case 'aclaración':
      case 'clarification':
        return '❓';
      default:
        return '❓';
    }
  }

  // Formatear ID del cierre: "cierre-13" -> "Cierre 13"
  String _formatClosureId(String id) {
    if (id.startsWith('cierre-')) {
      final number = id.substring(7);
      return 'Cierre $number';
    }
    return id;
  }

  // Traducir estado al español
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendiente':
        return 'PENDIENTE';
      case 'approved':
      case 'aprobado':
        return 'APROBADO';
      case 'rejected':
      case 'rechazado':
        return 'RECHAZADO';
      case 'clarification':
      case 'aclaración':
        return 'ACLARACIÓN';
      default:
        return status.toUpperCase();
    }
  }

  void _showClosureDetails(dynamic closure, CajeroController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles - ${_formatClosureId(closure.id)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información general
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Período', closure.periodo),
                    _buildDetailRow('Usuario', closure.usuario),
                    _buildDetailRow('Fecha', controller.formatDate(closure.fecha)),
                    _buildDetailRow('Estado', _translateStatus(closure.estado)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Resumen financiero
              Text(
                'Resumen Financiero',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (closure.efectivoInicial > 0)
                      _buildDetailRow(
                        'Efectivo Inicial',
                        controller.formatCurrency(closure.efectivoInicial),
                      ),
                    _buildDetailRow(
                      'Efectivo',
                      controller.formatCurrency(closure.efectivo),
                    ),
                    _buildDetailRow(
                      'Tarjeta',
                      controller.formatCurrency(closure.tarjeta),
                    ),
                    if ((closure.otrosIngresos ?? 0) > 0)
                      _buildDetailRow(
                        'Otros Ingresos',
                        controller.formatCurrency(closure.otrosIngresos ?? 0),
                      ),
                    if ((closure.propinasEfectivo ?? 0) > 0 ||
                        (closure.propinasTarjeta ?? 0) > 0) ...[
                      const Divider(),
                      _buildDetailRow(
                        'Propinas Efectivo',
                        controller.formatCurrency(closure.propinasEfectivo ?? 0),
                      ),
                      _buildDetailRow(
                        'Propinas Tarjeta',
                        controller.formatCurrency(closure.propinasTarjeta ?? 0),
                      ),
                    ],
                    const Divider(),
                    _buildDetailRow(
                      'Total Neto',
                      controller.formatCurrency(closure.totalNeto),
                      isBold: true,
                    ),
                    if (closure.efectivoContado != null &&
                        closure.efectivoContado! > 0)
                      _buildDetailRow(
                        'Efectivo Contado',
                        controller.formatCurrency(closure.efectivoContado!),
                      ),
                  ],
                ),
              ),
              if (closure.notaCajero != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu Nota:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${closure.notaCajero}'),
                    ],
                  ),
                ),
              ],
              if (closure.estado == CashCloseStatus.clarification && closure.comentarioRevision != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Solicitud de Aclaración del Administrador:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        closure.comentarioRevision!,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAuditLog(dynamic closure) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial - ${_formatClosureId(closure.id)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistoryItem(
                'Creado',
                'Creado por: ${closure.usuario}',
                closure.fecha,
                Icons.add_circle_outline,
                Colors.blue,
              ),
              if (closure.estado == CashCloseStatus.approved ||
                  closure.estado == CashCloseStatus.rejected ||
                  closure.estado == CashCloseStatus.clarification) ...[
                const SizedBox(height: 12),
                _buildHistoryItem(
                  'Revisado',
                  'Estado: ${_translateStatus(closure.estado)}',
                  null,
                  closure.estado == CashCloseStatus.approved
                      ? Icons.check_circle_outline
                      : closure.estado == CashCloseStatus.rejected
                          ? Icons.cancel_outlined
                          : Icons.help_outline,
                  closure.estado == CashCloseStatus.approved
                      ? Colors.green
                      : closure.estado == CashCloseStatus.rejected
                          ? Colors.red
                          : Colors.orange,
                ),
              ],
              if (closure.comentarioRevision != null &&
                  closure.comentarioRevision!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comentario de Revisión:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(closure.comentarioRevision!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String subtitle,
    DateTime? date,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
              if (date != null)
                Text(
                  date_utils.AppDateUtils.formatDateTime(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _dismissClarification(
    dynamic closure,
    CajeroController controller,
  ) async {
    // Confirmar eliminación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Aclaración'),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta aclaración?\n\n'
          'Cierre: ${_formatClosureId(closure.id)}\n'
          'Fecha: ${controller.formatDate(closure.fecha)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Obtener el ID real del cierre
      int? cierreId = closure.cierreId;
      
      // Si no hay cierreId, intentar extraerlo del ID
      if (cierreId == null) {
        final idStr = closure.id;
        if (idStr.startsWith('cierre-')) {
          final idPart = idStr.substring(7);
          cierreId = int.tryParse(idPart);
        }
      }
      
      if (cierreId == null) {
        throw Exception('No se pudo obtener el ID del cierre. ID: ${closure.id}');
      }

      // Actualizar el estado a "approved" para eliminar la aclaración
      final cierresService = CierresService();
      await cierresService.actualizarEstadoCierre(
        cierreId: cierreId,
        estado: 'approved',
        comentarioRevision: 'Aclaración descartada por el cajero',
      );

      // Recargar cierres para actualizar la vista
      await controller.loadCashClosures();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Aclaración eliminada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar aclaración: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildClarificationBanner(bool isTablet) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        final aclaraciones = controller.cashClosures
            .where((c) => c.estado == CashCloseStatus.clarification)
            .toList();

        if (aclaraciones.isEmpty) {
          return const SizedBox.shrink();
        }

        final screenIsTablet = MediaQuery.of(context).size.width > 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(screenIsTablet ? 20.0 : 16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade800,
                    size: isTablet ? 28.0 : 24.0,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aclaraciones Pendientes (${aclaraciones.length})',
                      style: TextStyle(
                        fontSize: screenIsTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...aclaraciones.map((cierre) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.blue.shade700,
                            size: screenIsTablet ? 20.0 : 18.0,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatClosureId(cierre.id)} - ${controller.formatDate(cierre.fecha)}',
                              style: TextStyle(
                                fontSize: screenIsTablet ? 16.0 : 14.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (cierre.notaCajero != null && cierre.notaCajero!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note_alt,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu nota: ${cierre.notaCajero}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13.0 : 11.0,
                                    color: Colors.amber.shade900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.message,
                              size: 18,
                              color: Colors.blue.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Solicitud del Administrador:',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cierre.comentarioRevision ?? 
                                    'El administrador necesita más información sobre este cierre. Por favor, revisa los detalles y proporciona la información solicitada.',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showClosureDetails(cierre, controller);
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Ver Detalles'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenIsTablet ? 14.0 : 12.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              _dismissClarification(cierre, controller);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: EdgeInsets.symmetric(
                                vertical: screenIsTablet ? 14.0 : 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog(BuildContext context) {
    final controller = context.read<CajeroController>();
    final filteredClosures = _getFilteredClosures(controller.cashClosures);
    final totalClosures = filteredClosures.length;
    final approvedCount = filteredClosures
        .where((c) => _matchesAnyStatus(c, ['aprobado', 'approved']))
        .length;
    final pendingCount = filteredClosures
        .where((c) => _matchesAnyStatus(c, ['pendiente', 'pending']))
        .length;
    final totalAmount = filteredClosures.fold<double>(
      0,
      (sum, closure) => sum + closure.totalNeto,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Cortes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Total de cortes: $totalClosures'),
            Text('• Cortes aprobados: $approvedCount'),
            Text('• Cortes pendientes: $pendingCount'),
            Text('• Total generado: ${controller.formatCurrency(totalAmount)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
