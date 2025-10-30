import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/table_model.dart';
import '../../utils/app_colors.dart';

class FloorView extends StatelessWidget {
  const FloorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        final stats = controller.getOccupancyStats();
        final occupancyRate = controller.getOccupancyRate();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isDesktop = constraints.maxWidth > 900;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, occupancyRate, isTablet),
                    const SizedBox(height: 16),

                    // Leyenda de estados
                    _buildStatusLegend(isTablet),
                    const SizedBox(height: 24),

                    // Grid de mesas
                    _buildTablesGrid(context, controller, isTablet, isDesktop),
                    const SizedBox(height: 24),

                    // Estadísticas rápidas
                    _buildQuickStats(stats, isTablet),
                    const SizedBox(height: 16),

                    // Info del puesto
                    _buildRestaurantInfo(isTablet),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double occupancyRate,
    bool isTablet,
  ) {
    final now = DateTime.now();
    final dateStr = '${now.day} de ${_getMonthName(now.month)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plano de Mesas',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${occupancyRate.toInt()}%',
              style: TextStyle(
                fontSize: isTablet ? 28.0 : 24.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Ocupación',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusLegend(bool isTablet) {
    final legendItems = [
      {'icon': '🟢', 'text': 'Libre', 'color': AppColors.success},
      {'icon': '🔴', 'text': 'Ocupada', 'color': AppColors.error},
      {'icon': '⚪', 'text': 'En Limpieza', 'color': Colors.grey},
      {'icon': '🟡', 'text': 'Reservada', 'color': AppColors.warning},
    ];

    return Container(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: isTablet ? 16.0 : 12.0,
        runSpacing: 8.0,
        children: legendItems.map((item) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12.0 : 10.0,
              vertical: isTablet ? 8.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (item['color'] as Color).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['icon'] as String,
                  style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
                ),
                const SizedBox(width: 4),
                Text(
                  item['text'] as String,
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: item['color'] as Color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTablesGrid(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 6;
    } else if (isTablet) {
      crossAxisCount = 4;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isTablet ? 16.0 : 12.0,
        mainAxisSpacing: isTablet ? 16.0 : 12.0,
        childAspectRatio: 0.8,
      ),
      itemCount: controller.tables.length,
      itemBuilder: (context, index) {
        final table = controller.tables[index];
        return _buildTableCard(context, table, controller, isTablet);
      },
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    MeseroController controller,
    bool isTablet,
  ) {
    final statusColor = _getStatusColor(table.status);
    final statusText = TableStatus.getStatusText(table.status);
    final statusIcon = TableStatus.getStatusIcon(table.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.1), width: 2),
      ),
      child: InkWell(
        onTap: () => controller.selectTable(table),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: statusColor.withValues(alpha: 0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono y número de mesa
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    statusIcon,
                    style: TextStyle(fontSize: isTablet ? 20.0 : 16.0),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mesa ${table.number}',
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Información adicional
              Column(
                children: [
                  Text(
                    '${table.seats} lugares',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (table.customers != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${table.customers} comensales',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                  if (table.orderValue != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${table.orderValue!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  if (table.reservation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      table.reservation!.split(' - ').last,
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Selector de estado
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: table.status,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: statusColor,
                    ),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        controller.changeTableStatus(table.id, newStatus);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: TableStatus.libre,
                        child: Text('Libre'),
                      ),
                      DropdownMenuItem(
                        value: TableStatus.ocupada,
                        child: Text('Ocupada'),
                      ),
                      DropdownMenuItem(
                        value: TableStatus.enLimpieza,
                        child: Text('En Limpieza'),
                      ),
                      DropdownMenuItem(
                        value: TableStatus.reservada,
                        child: Text('Reservada'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> stats, bool isTablet) {
    final statCards = [
      {'label': 'Libres', 'count': stats['libre']!, 'color': AppColors.success},
      {
        'label': 'Ocupadas',
        'count': stats['ocupada']!,
        'color': AppColors.error,
      },
      {
        'label': 'Limpieza',
        'count': stats['en-limpieza']!,
        'color': Colors.grey,
      },
      {
        'label': 'Reservadas',
        'count': stats['reservada']!,
        'color': AppColors.warning,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: isTablet ? 16.0 : 12.0,
      mainAxisSpacing: isTablet ? 16.0 : 12.0,
      childAspectRatio: 1.2,
      children: statCards.map((stat) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (stat['color'] as Color).withValues(alpha: 0.1),
              border: Border.all(
                color: (stat['color'] as Color).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${stat['count']}',
                  style: TextStyle(
                    fontSize: isTablet ? 24.0 : 20.0,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    color: stat['color'] as Color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantInfo(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary.withValues(alpha: 0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.primary,
                  size: isTablet ? 24.0 : 20.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Puesto de Barbacoa Abierto',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Horario: 8:00 AM - 6:00 PM • Especialidad: Barbacoa de res',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case TableStatus.libre:
        return AppColors.success;
      case TableStatus.ocupada:
        return AppColors.error;
      case TableStatus.enLimpieza:
        return Colors.grey;
      case TableStatus.reservada:
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month - 1];
  }
}

