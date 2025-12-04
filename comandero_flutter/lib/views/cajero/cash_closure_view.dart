import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cajero_controller.dart';
import '../../utils/app_colors.dart';
import '../../models/admin_model.dart';
import '../../utils/date_utils.dart' as date_utils;

class CashClosureView extends StatefulWidget {
  const CashClosureView({super.key});

  @override
  State<CashClosureView> createState() => _CashClosureViewState();
}

class _CashClosureViewState extends State<CashClosureView> {
  String selectedPeriod = 'Día';
  String selectedStatus = 'Todos';
  DateTime? selectedDate; // Fecha seleccionada del calendario

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
                      'Juan Martínez • Cajero',
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
  }

  Widget _buildGeneralSummary(bool isTablet) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        final closures = controller.cashClosures;
        final pendingClosures = controller.getPendingClosures();
        final approvedClosures = closures
            .where((c) => c.estado == 'aprobado')
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
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        final filteredClosures = closures.where((closure) {
          // Filtro por período/fecha
          bool periodMatch = true;
          if (selectedDate != null) {
            // Si hay una fecha seleccionada, filtrar por esa fecha específica
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
            // Filtro por período predefinido
            final now = DateTime.now();
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
                // Calcular inicio de la semana (lunes)
                final daysFromMonday = today.weekday - 1; // 0 = lunes, 6 = domingo
                final weekStart = today.subtract(Duration(days: daysFromMonday));
                final weekEnd = weekStart.add(const Duration(days: 6));
                // Verificar si la fecha del cierre está entre el inicio y fin de semana (inclusive)
                periodMatch = closureDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                              closureDate.isBefore(weekEnd.add(const Duration(days: 1)));
                break;
              case 'Mes':
                periodMatch = closureDate.year == today.year &&
                             closureDate.month == today.month;
                break;
              default:
                periodMatch = true;
            }
          }

          // Filtro por estado
          bool statusMatch = true;
          if (selectedStatus != 'Todos') {
            final estadoLower = closure.estado.toLowerCase();
            switch (selectedStatus) {
              case 'Pendiente':
                statusMatch = estadoLower == 'pending';
                break;
              case 'Aprobado':
                statusMatch = estadoLower == 'approved';
                break;
              case 'Rechazado':
                statusMatch = estadoLower == 'rejected';
                break;
              case 'Aclaración':
                statusMatch = estadoLower == 'clarification';
                break;
              default:
                statusMatch = true;
            }
          }

          return periodMatch && statusMatch;
        }).toList();

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
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del corte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        closure.id,
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
                    ],
                  ),
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
                              closure.estado.toUpperCase(),
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
              Row(
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
              ),
              const SizedBox(height: 16),

              // Información adicional
              Row(
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
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    closure.usuario,
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (closure.estado == 'pendiente') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showEditClosureDialog(closure, controller);
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(
                          'Editar',
                          style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
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
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
        return '⏳';
      case 'aprobado':
        return '✅';
      case 'rechazado':
        return '❌';
      case 'aclaración':
        return '❓';
      default:
        return '❓';
    }
  }

  void _showClosureDetails(dynamic closure, CajeroController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles - ${closure.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Período: ${closure.periodo}'),
              Text('Usuario: ${closure.usuario}'),
              Text('Fecha: ${controller.formatDate(closure.fecha)}'),
              Text('Estado: ${closure.estado}'),
              const SizedBox(height: 16),
              Text('Efectivo: ${controller.formatCurrency(closure.efectivo)}'),
              Text('Tarjeta: ${controller.formatCurrency(closure.tarjeta)}'),
              Text(
                'Otros Ingresos: ${controller.formatCurrency(closure.otrosIngresos ?? 0)}',
              ),
              Text(
                'Total Neto: ${controller.formatCurrency(closure.totalNeto)}',
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

  void _showEditClosureDialog(dynamic closure, CajeroController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Corte - ${closure.id}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Modificar montos'),
            Text('• Actualizar notas'),
            Text('• Cambiar estado'),
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

  void _showAuditLog(dynamic closure) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial - ${closure.id}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Enviado por Cajero'),
            Text('• Revisado por Admin'),
            Text('• Aprobado por Admin'),
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
                              'Cierre ${cierre.id} - ${controller.formatDate(cierre.fecha)}',
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
                      SizedBox(
                        width: double.infinity,
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

  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Cortes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Total de cortes: 15'),
            Text('• Cortes aprobados: 12'),
            Text('• Cortes pendientes: 2'),
            Text('• Total generado: \$45,000'),
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
