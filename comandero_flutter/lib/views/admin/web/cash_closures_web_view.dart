import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../../../utils/app_colors.dart';

class CashClosuresWebView extends StatefulWidget {
  const CashClosuresWebView({super.key});

  @override
  State<CashClosuresWebView> createState() => _CashClosuresWebViewState();
}

class _CashClosuresWebViewState extends State<CashClosuresWebView> {
  String _selectedPeriod = 'hoy';
  String _selectedStatus = 'todas';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estadísticas
                  _buildHeader(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Filtros y controles
                  _buildFiltersSection(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Tabla de cierres de caja
                  _buildClosuresTable(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Gráficos y análisis
                  _buildAnalyticsSection(controller, isTablet, isDesktop),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final closures = controller.cashClosures;
    final pendingCount = closures
        .where((c) => c.estado == CashCloseStatus.pending)
        .length;
    final approvedCount = closures
        .where((c) => c.estado == CashCloseStatus.approved)
        .length;
    final totalAmount = closures.fold<double>(
      0.0,
      (sum, c) => sum + c.totalNeto,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gestión de Cortes de Caja',
                  style: TextStyle(
                    fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${closures.length} cierres',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Procesado',
                          '\$${totalAmount.toStringAsFixed(2)}',
                          Colors.green,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Pendientes',
                          '$pendingCount',
                          Colors.orange,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Aprobados',
                          '$approvedCount',
                          Colors.blue,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Promedio Diario',
                          '\$${(totalAmount / 7).toStringAsFixed(2)}',
                          Colors.purple,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Procesado',
                              '\$${totalAmount.toStringAsFixed(2)}',
                              Colors.green,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Pendientes',
                              '$pendingCount',
                              Colors.orange,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Aprobados',
                              '$approvedCount',
                              Colors.blue,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Promedio Diario',
                              '\$${(totalAmount / 7).toStringAsFixed(2)}',
                              Colors.purple,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtros y Controles',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      // Período
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPeriod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value!;
                              _updateDateRange();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Período',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                            DropdownMenuItem(
                              value: 'ayer',
                              child: Text('Ayer'),
                            ),
                            DropdownMenuItem(
                              value: 'semana',
                              child: Text('Esta Semana'),
                            ),
                            DropdownMenuItem(
                              value: 'mes',
                              child: Text('Este Mes'),
                            ),
                            DropdownMenuItem(
                              value: 'personalizado',
                              child: Text('Personalizado'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Estado
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'todas',
                              child: Text('Todos los estados'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pendientes'),
                            ),
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('Aprobados'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Rechazados'),
                            ),
                            DropdownMenuItem(
                              value: 'clarification',
                              child: Text('Aclaración'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Fecha inicio
                      Expanded(
                        child: TextFormField(
                          initialValue:
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          decoration: InputDecoration(
                            labelText: 'Fecha Inicio',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectStartDate(),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Fecha fin
                      Expanded(
                        child: TextFormField(
                          initialValue:
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          decoration: InputDecoration(
                            labelText: 'Fecha Fin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectEndDate(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPeriod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriod = value!;
                                  _updateDateRange();
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Período',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'hoy',
                                  child: Text('Hoy'),
                                ),
                                DropdownMenuItem(
                                  value: 'ayer',
                                  child: Text('Ayer'),
                                ),
                                DropdownMenuItem(
                                  value: 'semana',
                                  child: Text('Esta Semana'),
                                ),
                                DropdownMenuItem(
                                  value: 'mes',
                                  child: Text('Este Mes'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'todas',
                                  child: Text('Todos'),
                                ),
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pendientes'),
                                ),
                                DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Aprobados'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              decoration: InputDecoration(
                                labelText: 'Fecha Inicio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                              onTap: () => _selectStartDate(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              decoration: InputDecoration(
                                labelText: 'Fecha Fin',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                              onTap: () => _selectEndDate(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosuresTable(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final filteredClosures = _getFilteredClosures(controller);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: EdgeInsets.all(
              isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cortes de Caja (${filteredClosures.length} registros)',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showNewClosureDialog(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Cierre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Tabla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isDesktop ? 24.0 : (isTablet ? 16.0 : 12.0),
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.05),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Usuario',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Período',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Efectivo',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tarjeta',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Neto',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: filteredClosures
                  .map(
                    (closure) =>
                        _buildDataRow(closure, controller, isTablet, isDesktop),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    CashCloseModel closure,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    Color statusColor = Colors.grey;
    String statusText = 'Desconocido';
    IconData statusIcon = Icons.help;

    switch (closure.estado) {
      case CashCloseStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.pending;
        break;
      case CashCloseStatus.approved:
        statusColor = Colors.green;
        statusText = 'Aprobado';
        statusIcon = Icons.check_circle;
        break;
      case CashCloseStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rechazado';
        statusIcon = Icons.cancel;
        break;
      case CashCloseStatus.clarification:
        statusColor = Colors.blue;
        statusText = 'Aclaración';
        statusIcon = Icons.help_outline;
        break;
    }

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${closure.fecha.day}/${closure.fecha.month}/${closure.fecha.year}',
                style: TextStyle(
                  fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${closure.fecha.hour.toString().padLeft(2, '0')}:${closure.fecha.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            closure.usuario,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Text(
              closure.periodo,
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${closure.efectivo.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${closure.tarjeta.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${closure.totalNeto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(
                statusIcon,
                size: isDesktop ? 16.0 : 14.0,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () => _showClosureDetails(closure),
                icon: Icon(Icons.visibility, size: isDesktop ? 18.0 : 16.0),
                color: Colors.blue,
                tooltip: 'Ver Detalles',
              ),
              if (closure.estado == CashCloseStatus.pending) ...[
                IconButton(
                  onPressed: () => _approveClosure(closure, controller),
                  icon: Icon(Icons.check, size: isDesktop ? 18.0 : 16.0),
                  color: Colors.green,
                  tooltip: 'Aprobar',
                ),
                IconButton(
                  onPressed: () => _rejectClosure(closure, controller),
                  icon: Icon(Icons.close, size: isDesktop ? 18.0 : 16.0),
                  color: Colors.red,
                  tooltip: 'Rechazar',
                ),
              ],
              IconButton(
                onPressed: () => _showAuditLog(closure),
                icon: Icon(Icons.history, size: isDesktop ? 18.0 : 16.0),
                color: Colors.purple,
                tooltip: 'Auditoría',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Análisis de Cortes de Caja',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildClosuresChart(
                          controller,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _buildStatusSummary(
                          controller,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildClosuresChart(controller, isTablet, isDesktop),
                      const SizedBox(height: 20),
                      _buildStatusSummary(controller, isTablet, isDesktop),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosuresChart(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final closures = _getFilteredClosures(controller);
    final dailyTotals = <String, double>{};

    // Agrupar por día
    for (final closure in closures) {
      final dayKey = '${closure.fecha.day}/${closure.fecha.month}';
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + closure.totalNeto;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas por Día',
          style: TextStyle(
            fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isDesktop ? 200.0 : (isTablet ? 150.0 : 120.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dailyTotals.length,
            itemBuilder: (context, index) {
              final entry = dailyTotals.entries.elementAt(index);
              final maxValue = dailyTotals.values.reduce(
                (a, b) => a > b ? a : b,
              );
              final height =
                  (entry.value / maxValue) *
                  (isDesktop ? 160.0 : (isTablet ? 120.0 : 80.0));

              return Container(
                width: isDesktop ? 60.0 : (isTablet ? 50.0 : 40.0),
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: height,
                      width: isDesktop ? 50.0 : (isTablet ? 40.0 : 30.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isDesktop ? 10.0 : (isTablet ? 8.0 : 6.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummary(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final closures = _getFilteredClosures(controller);
    final statusCounts = <String, int>{};

    for (final closure in closures) {
      statusCounts[closure.estado] = (statusCounts[closure.estado] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen por Estado',
          style: TextStyle(
            fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...statusCounts.entries.map(
          (entry) =>
              _buildStatusItem(entry.key, entry.value, isTablet, isDesktop),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    String status,
    int count,
    bool isTablet,
    bool isDesktop,
  ) {
    Color color = Colors.grey;
    String text = 'Desconocido';
    IconData icon = Icons.help;

    switch (status) {
      case CashCloseStatus.pending:
        color = Colors.orange;
        text = 'Pendientes';
        icon = Icons.pending;
        break;
      case CashCloseStatus.approved:
        color = Colors.green;
        text = 'Aprobados';
        icon = Icons.check_circle;
        break;
      case CashCloseStatus.rejected:
        color = Colors.red;
        text = 'Rechazados';
        icon = Icons.cancel;
        break;
      case CashCloseStatus.clarification:
        color = Colors.blue;
        text = 'Aclaración';
        icon = Icons.help_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<CashCloseModel> _getFilteredClosures(AdminController controller) {
    var closures = controller.cashClosures;

    // Filtrar por estado
    if (_selectedStatus != 'todas') {
      closures = closures.where((closure) {
        switch (_selectedStatus) {
          case 'pending':
            return closure.estado == CashCloseStatus.pending;
          case 'approved':
            return closure.estado == CashCloseStatus.approved;
          case 'rejected':
            return closure.estado == CashCloseStatus.rejected;
          case 'clarification':
            return closure.estado == CashCloseStatus.clarification;
          default:
            return true;
        }
      }).toList();
    }

    // Filtrar por fecha
    closures = closures.where((closure) {
      return closure.fecha.isAfter(
            _startDate.subtract(const Duration(days: 1)),
          ) &&
          closure.fecha.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Ordenar por fecha descendente
    closures.sort((a, b) => b.fecha.compareTo(a.fecha));

    return closures;
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'hoy':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'ayer':
        final yesterday = now.subtract(const Duration(days: 1));
        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
        );
        break;
      case 'semana':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'mes':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
    }
    setState(() {});
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
      helpText: 'Seleccionar fecha inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
      helpText: 'Seleccionar fecha fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _showNewClosureDialog(AdminController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de nuevo cierre en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showClosureDetails(CashCloseModel closure) {
    final isTablet = MediaQuery.of(context).size.width > 800;
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: isDesktop ? 900 : (isTablet ? 700 : double.infinity),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(
                  isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles del Cierre de Caja',
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 22.0
                                  : (isTablet ? 20.0 : 18.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ID: ${closure.id} • ${closure.fecha.day}/${closure.fecha.month}/${closure.fecha.year}',
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado y usuario
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: closure.estado == CashCloseStatus.approved
                                  ? Colors.green.shade100
                                  : closure.estado == CashCloseStatus.pending
                                  ? Colors.orange.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    closure.estado == CashCloseStatus.approved
                                    ? Colors.green.shade700
                                    : closure.estado == CashCloseStatus.pending
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            child: Text(
                              closure.estado == CashCloseStatus.approved
                                  ? 'Aprobado'
                                  : closure.estado == CashCloseStatus.pending
                                  ? 'Pendiente'
                                  : 'Rechazado',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 14.0
                                    : (isTablet ? 12.0 : 10.0),
                                fontWeight: FontWeight.w600,
                                color:
                                    closure.estado == CashCloseStatus.approved
                                    ? Colors.green.shade700
                                    : closure.estado == CashCloseStatus.pending
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Usuario: ${closure.usuario}',
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Período: ${closure.periodo}',
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Cards de resumen
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Efectivo Contado',
                                    closure.efectivoContado,
                                    Colors.green,
                                    Icons.attach_money,
                                    isTablet,
                                    isDesktop,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Tarjeta',
                                    closure.totalTarjeta,
                                    Colors.blue,
                                    Icons.credit_card,
                                    isTablet,
                                    isDesktop,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Otros Ingresos',
                                    closure.otrosIngresos,
                                    Colors.purple,
                                    Icons.more_horiz,
                                    isTablet,
                                    isDesktop,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Declarado',
                                    closure.totalDeclarado,
                                    Colors.orange,
                                    Icons.calculate,
                                    isTablet,
                                    isDesktop,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Efectivo',
                                        closure.efectivoContado,
                                        Colors.green,
                                        Icons.attach_money,
                                        isTablet,
                                        isDesktop,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Tarjeta',
                                        closure.totalTarjeta,
                                        Colors.blue,
                                        Icons.credit_card,
                                        isTablet,
                                        isDesktop,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Otros',
                                        closure.otrosIngresos,
                                        Colors.purple,
                                        Icons.more_horiz,
                                        isTablet,
                                        isDesktop,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total',
                                        closure.totalDeclarado,
                                        Colors.orange,
                                        Icons.calculate,
                                        isTablet,
                                        isDesktop,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Información adicional si existe en el modelo
                      // (Nota: Estos campos pueden no estar disponibles en el modelo actual)

                      // Total neto destacado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade100,
                              Colors.orange.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Neto:',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 20.0
                                    : (isTablet ? 18.0 : 16.0),
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            Text(
                              '\$${closure.totalNeto.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 28.0
                                    : (isTablet ? 24.0 : 20.0),
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con botones
              Container(
                padding: EdgeInsets.all(
                  isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 12),
                    if (closure.estado == CashCloseStatus.pending)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _approveClosure(
                            closure,
                            Provider.of<AdminController>(
                              context,
                              listen: false,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    Color color,
    IconData icon,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 9.0),
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                icon,
                size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _approveClosure(CashCloseModel closure, AdminController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de aprobación en desarrollo'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectClosure(CashCloseModel closure, AdminController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de rechazo en desarrollo'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAuditLog(CashCloseModel closure) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de auditoría en desarrollo'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
