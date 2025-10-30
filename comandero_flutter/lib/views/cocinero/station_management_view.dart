import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../utils/app_colors.dart';

class StationManagementView extends StatefulWidget {
  const StationManagementView({super.key});

  @override
  State<StationManagementView> createState() => _StationManagementViewState();
}

class _StationManagementViewState extends State<StationManagementView> {
  String selectedStation = 'Todas';

  final List<Map<String, dynamic>> stations = [
    {
      'id': 'tacos',
      'name': 'Estación Tacos',
      'icon': Icons.restaurant,
      'status': 'Activa',
      'currentOrders': 3,
      'pendingOrders': 2,
      'completedOrders': 8,
      'estimatedTime': '15 min',
      'color': AppColors.primary,
      'staff': ['Juan Martínez', 'María García'],
      'equipment': ['Plancha', 'Estufa', 'Tabla de cortar'],
    },
    {
      'id': 'consomes',
      'name': 'Estación Consomes',
      'icon': Icons.soup_kitchen,
      'status': 'Activa',
      'currentOrders': 1,
      'pendingOrders': 1,
      'completedOrders': 5,
      'estimatedTime': '20 min',
      'color': AppColors.info,
      'staff': ['Carlos López'],
      'equipment': ['Olla grande', 'Cuchara de madera', 'Colador'],
    },
    {
      'id': 'bebidas',
      'name': 'Estación Bebidas',
      'icon': Icons.local_drink,
      'status': 'Activa',
      'currentOrders': 2,
      'pendingOrders': 3,
      'completedOrders': 12,
      'estimatedTime': '5 min',
      'color': AppColors.success,
      'staff': ['Ana Martínez'],
      'equipment': ['Licuadora', 'Jarras', 'Hielera'],
    },
    {
      'id': 'carnes',
      'name': 'Estación Carnes',
      'icon': Icons.local_fire_department,
      'status': 'Mantenimiento',
      'currentOrders': 0,
      'pendingOrders': 4,
      'completedOrders': 6,
      'estimatedTime': '30 min',
      'color': AppColors.warning,
      'staff': ['Roberto Silva'],
      'equipment': ['Horno', 'Asador', 'Termómetro'],
    },
  ];

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
                      // Resumen general
                      _buildGeneralSummary(isTablet),
                      const SizedBox(height: 24),

                      // Selector de estación
                      _buildStationSelector(isTablet),
                      const SizedBox(height: 24),

                      // Grid de estaciones
                      _buildStationsGrid(isTablet, isDesktop),
                      const SizedBox(height: 24),

                      // Estadísticas detalladas
                      _buildDetailedStats(isTablet),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Botón flotante de estado
          floatingActionButton: _buildFloatingStatusButton(isTablet),
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
                  context.read<CocineroController>().setCurrentView('main');
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
                      'Gestión de Estaciones',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Juan Martínez • Cocinero',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de configuración
              IconButton(
                onPressed: () {
                  _showStationSettingsDialog(context);
                },
                icon: const Icon(Icons.settings, color: Colors.white),
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
    final totalOrders = stations.fold<int>(
      0,
      (sum, station) => sum + (station['currentOrders'] as int),
    );
    final totalPending = stations.fold<int>(
      0,
      (sum, station) => sum + (station['pendingOrders'] as int),
    );
    final totalCompleted = stations.fold<int>(
      0,
      (sum, station) => sum + (station['completedOrders'] as int),
    );
    final activeStations = stations
        .where((station) => station['status'] == 'Activa')
        .length;

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
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: isTablet ? 24.0 : 20.0,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen General',
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
                    'Estaciones Activas',
                    '$activeStations/${stations.length}',
                    AppColors.success,
                    Icons.check_circle,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Órdenes Actuales',
                    '$totalOrders',
                    AppColors.warning,
                    Icons.restaurant_menu,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pendientes',
                    '$totalPending',
                    AppColors.info,
                    Icons.schedule,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Completadas',
                    '$totalCompleted',
                    AppColors.success,
                    Icons.check,
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildStationSelector(bool isTablet) {
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
              'Filtrar por Estación',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStationChip('Todas', isTablet),
                  const SizedBox(width: 8),
                  ...stations.map(
                    (station) => _buildStationChip(station['name'], isTablet),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationChip(String name, bool isTablet) {
    final isSelected = selectedStation == name;

    return FilterChip(
      label: Text(
        name,
        style: TextStyle(
          fontSize: isTablet ? 14.0 : 12.0,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStation = name;
        });
      },
      backgroundColor: AppColors.secondary,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStationsGrid(bool isTablet, bool isDesktop) {
    final filteredStations = selectedStation == 'Todas'
        ? stations
        : stations
              .where((station) => station['name'] == selectedStation)
              .toList();

    final crossAxisCount = isDesktop ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estaciones de Cocina',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isTablet ? 16.0 : 12.0,
            mainAxisSpacing: isTablet ? 16.0 : 12.0,
            childAspectRatio: isDesktop ? 1.2 : 1.0,
          ),
          itemCount: filteredStations.length,
          itemBuilder: (context, index) {
            return _buildStationCard(filteredStations[index], isTablet);
          },
        ),
      ],
    );
  }

  Widget _buildStationCard(Map<String, dynamic> station, bool isTablet) {
    final statusColor = station['color'] as Color;
    final statusIcon = _getStatusIcon(station['status']);

    return Card(
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
              // Header de la estación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        station['icon'],
                        color: statusColor,
                        size: isTablet ? 24.0 : 20.0,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          station['name'],
                          style: TextStyle(
                            fontSize: isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          station['status'],
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estadísticas de órdenes
              Row(
                children: [
                  Expanded(
                    child: _buildOrderStat(
                      'Actuales',
                      station['currentOrders'],
                      AppColors.warning,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOrderStat(
                      'Pendientes',
                      station['pendingOrders'],
                      AppColors.info,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOrderStat(
                      'Completadas',
                      station['completedOrders'],
                      AppColors.success,
                      isTablet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tiempo estimado
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tiempo estimado: ${station['estimatedTime']}',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Personal asignado
              Text(
                'Personal:',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (station['staff'] as List<String>).map((person) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      person,
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showStationDetails(station);
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showStationOrders(station);
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text(
                        'Órdenes',
                        style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStat(String label, int count, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: isTablet ? 10.0 : 8.0, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(bool isTablet) {
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
              'Estadísticas Detalladas',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...stations.map(
              (station) => _buildStationStatRow(station, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationStatRow(Map<String, dynamic> station, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            station['icon'],
            color: station['color'],
            size: isTablet ? 20.0 : 18.0,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              station['name'],
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${station['currentOrders']} actuales',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${station['pendingOrders']} pendientes',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${station['completedOrders']} completadas',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStatusButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar cambio de estado de la cocina
        },
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.restaurant),
        label: Text(
          isTablet ? 'Cocina Activa' : 'Activa',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Activa':
        return '✅';
      case 'Mantenimiento':
        return '🔧';
      case 'Inactiva':
        return '❌';
      default:
        return '❓';
    }
  }

  void _showStationDetails(Map<String, dynamic> station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estado: ${station['status']}'),
              Text('Tiempo estimado: ${station['estimatedTime']}'),
              const SizedBox(height: 16),
              const Text(
                'Personal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(station['staff'] as List<String>).map(
                (person) => Text('• $person'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Equipo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(station['equipment'] as List<String>).map(
                (equipment) => Text('• $equipment'),
              ),
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

  void _showStationOrders(Map<String, dynamic> station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Órdenes - ${station['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ORD-034 - Taco Barbacoa - En preparación'),
            Text('ORD-029 - Mix Barbacoa - Pendiente'),
            Text('ORD-025 - Quesadilla - Lista'),
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

  void _showStationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Estaciones'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Asignación automática de personal'),
            Text('• Tiempos estimados por estación'),
            Text('• Alertas de mantenimiento'),
            Text('• Notificaciones de estado'),
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
