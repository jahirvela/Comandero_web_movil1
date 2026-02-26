import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/table_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;
import 'mesero_tables_management_view.dart';

class FloorView extends StatefulWidget {
  const FloorView({super.key});

  @override
  State<FloorView> createState() => _FloorViewState();
}

class _FloorViewState extends State<FloorView> {
  /// Filtro de área: null o 'Todos' = todas las mesas; si no, nombre del área.
  String? _selectedAreaFilter;

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
                    const SizedBox(height: 16),

                    // Chips de filtro por área (igual que Administrador; áreas según lo que admin agregue/elimine)
                    _buildAreaFilterChips(context, controller, isTablet),
                    const SizedBox(height: 20),

                    // Grid de mesas
                    _buildTablesGrid(context, controller, isTablet, isDesktop),
                    const SizedBox(height: 24),

                    // Sección Para Llevar
                    _buildTakeawaySection(context, controller, isTablet),
                    const SizedBox(height: 24),

                    // Estadísticas rápidas
                    _buildQuickStats(stats, isTablet),
                    // Espacio inferior para que el FAB "Abierto" no tape el contenido
                    SizedBox(height: isTablet ? 100 : 88),
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
    final now = date_utils.AppDateUtils.nowCdmx();
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Gestionar mesas (agregar, editar)',
              onPressed: () {
                final controller = context.read<MeseroController>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ChangeNotifierProvider<MeseroController>.value(
                      value: controller,
                      child: const MeseroTablesManagementView(),
                    ),
                  ),
                );
              },
              color: AppColors.primary,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(occupancyRate.isNaN || occupancyRate.isInfinite ? 0.0 : occupancyRate).toInt()}%',
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

  /// Fila de chips: Todas + una chip por cada área (las que existan según administrador).
  /// Al estar seleccionado (Todas o un área) se usa un naranja más claro.
  Widget _buildAreaFilterChips(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    const todosLabel = 'Todas';
    final areas = controller.tableAreas;
    final isTodos = _selectedAreaFilter == null || _selectedAreaFilter == todosLabel;
    final selectedChipColor = Color.lerp(AppColors.primary, Colors.white, 0.25)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todas" (una sola palomita en el label; sin checkmark por defecto para no duplicar)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTodos) Icon(Icons.check, size: isTablet ? 18 : 16, color: Colors.white),
                  if (isTodos) const SizedBox(width: 6),
                  const Text('Todas'),
                ],
              ),
              selected: isTodos,
              selectedColor: selectedChipColor,
              onSelected: (_) => setState(() => _selectedAreaFilter = null),
            ),
          ),
          // Una chip por cada área (mismo naranja claro al seleccionar)
          ...areas.map((area) {
            final selected = _selectedAreaFilter == area;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(area),
                selected: selected,
                selectedColor: selectedChipColor,
                checkmarkColor: Colors.white,
                onSelected: (_) => setState(() => _selectedAreaFilter = area),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTablesGrid(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    const defaultArea = 'Área Principal';
    final filtered = _selectedAreaFilter == null ||
            _selectedAreaFilter == 'Todas' ||
            _selectedAreaFilter!.isEmpty
        ? controller.tables
        : controller.tables.where((t) {
            final section = (t.section != null && t.section!.trim().isNotEmpty)
                ? t.section!.trim()
                : defaultArea;
            return section == _selectedAreaFilter;
          }).toList();

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
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final table = filtered[index];
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y nombre de mesa (nombre completo, puede ocupar hasta 2 líneas)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusIcon,
                    style: TextStyle(fontSize: isTablet ? 20.0 : 16.0),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      table.displayLabel,
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Información adicional
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${table.seats} lugares',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (table.reservation != null && table.reservation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      () {
                        final reservation = table.reservation!;
                        final parts = reservation.split(' - ');
                        return parts.isNotEmpty ? parts.last : reservation;
                      }(),
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Selector de estado
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
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
                        onChanged: (newStatus) async {
                          if (newStatus != null) {
                            try {
                              await controller.changeTableStatus(table.id, newStatus);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Estado de mesa actualizado'),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al actualizar estado: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: TableStatus.libre,
                            child: Text(
                              'Libre',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: TableStatus.ocupada,
                            child: Text(
                              'Ocupada',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: TableStatus.enLimpieza,
                            child: Text(
                              'En Limpieza',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: TableStatus.reservada,
                            child: Text(
                              'Reservada',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> stats, bool isTablet) {
    // En móvil usar etiquetas cortas para que no se corten en los cuadros
    final statCards = [
      {'label': 'Libres', 'shortLabel': 'Libres', 'count': stats['libre']!, 'color': AppColors.success},
      {
        'label': 'Ocupadas',
        'shortLabel': 'Ocup.',
        'count': stats['ocupada']!,
        'color': AppColors.error,
      },
      {
        'label': 'Limpieza',
        'shortLabel': 'Limp.',
        'count': stats['en-limpieza']!,
        'color': Colors.grey,
      },
      {
        'label': 'Reservadas',
        'shortLabel': 'Reserv.',
        'count': stats['reservada']!,
        'color': AppColors.warning,
      },
    ];

    final crossCount = isTablet ? 4 : 4;
    final label = isTablet ? 'label' : 'shortLabel';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: isTablet ? 16.0 : 8.0,
      mainAxisSpacing: isTablet ? 16.0 : 8.0,
      childAspectRatio: isTablet ? 1.2 : 1.05,
      children: statCards.map((stat) {
        final text = stat[label] as String;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 10.0),
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
                    fontSize: isTablet ? 24.0 : 18.0,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 11.0,
                      color: stat['color'] as Color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTakeawaySection(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    // Obtener órdenes para llevar pendientes (ya filtradas por el controller)
    final takeawayOrders = controller.getTakeawayOrderHistory();
    final pendingCount = takeawayOrders.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => controller.selectTakeawayView(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16.0 : 12.0,
            vertical: isTablet ? 12.0 : 10.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.warning.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                padding: EdgeInsets.all(isTablet ? 10.0 : 8.0),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  size: isTablet ? 24.0 : 20.0,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: isTablet ? 12.0 : 10.0),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Para Llevar',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      pendingCount > 0 
                          ? '$pendingCount pendiente${pendingCount > 1 ? 's' : ''}'
                          : 'Sin pedidos',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: pendingCount > 0 ? AppColors.warning : AppColors.textSecondary,
                        fontWeight: pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge de pendientes
              if (pendingCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Flecha
              Icon(
                Icons.arrow_forward_ios,
                size: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
            ],
          ),
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

