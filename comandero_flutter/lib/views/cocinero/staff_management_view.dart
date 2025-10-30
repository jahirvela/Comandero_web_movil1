import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../utils/app_colors.dart';

class StaffManagementView extends StatefulWidget {
  const StaffManagementView({super.key});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  String selectedShift = 'Todos';
  String selectedStation = 'Todas';

  final List<Map<String, dynamic>> staff = [
    {
      'id': 'juan_martinez',
      'name': 'Juan Martínez',
      'role': 'Chef Principal',
      'station': 'Estación Tacos',
      'shift': 'Mañana',
      'status': 'Activo',
      'startTime': '08:00',
      'endTime': '16:00',
      'ordersCompleted': 12,
      'efficiency': 95,
      'avatar': '👨‍🍳',
      'phone': '+52 55 1234 5678',
      'email': 'juan.martinez@comandero.com',
      'experience': '5 años',
      'specialties': ['Tacos', 'Barbacoa', 'Salsas'],
      'color': AppColors.primary,
    },
    {
      'id': 'maria_garcia',
      'name': 'María García',
      'role': 'Cocinera',
      'station': 'Estación Tacos',
      'shift': 'Mañana',
      'status': 'Activo',
      'startTime': '08:00',
      'endTime': '16:00',
      'ordersCompleted': 8,
      'efficiency': 88,
      'avatar': '👩‍🍳',
      'phone': '+52 55 2345 6789',
      'email': 'maria.garcia@comandero.com',
      'experience': '3 años',
      'specialties': ['Tacos', 'Quesadillas'],
      'color': AppColors.info,
    },
    {
      'id': 'carlos_lopez',
      'name': 'Carlos López',
      'role': 'Cocinero',
      'station': 'Estación Consomes',
      'shift': 'Tarde',
      'status': 'Activo',
      'startTime': '14:00',
      'endTime': '22:00',
      'ordersCompleted': 6,
      'efficiency': 92,
      'avatar': '👨‍🍳',
      'phone': '+52 55 3456 7890',
      'email': 'carlos.lopez@comandero.com',
      'experience': '4 años',
      'specialties': ['Consomes', 'Caldos'],
      'color': AppColors.success,
    },
    {
      'id': 'ana_martinez',
      'name': 'Ana Martínez',
      'role': 'Bartender',
      'station': 'Estación Bebidas',
      'shift': 'Tarde',
      'status': 'Activo',
      'startTime': '14:00',
      'endTime': '22:00',
      'ordersCompleted': 15,
      'efficiency': 98,
      'avatar': '👩‍🍳',
      'phone': '+52 55 4567 8901',
      'email': 'ana.martinez@comandero.com',
      'experience': '2 años',
      'specialties': ['Bebidas', 'Licuados'],
      'color': AppColors.warning,
    },
    {
      'id': 'roberto_silva',
      'name': 'Roberto Silva',
      'role': 'Cocinero',
      'station': 'Estación Carnes',
      'shift': 'Noche',
      'status': 'Descanso',
      'startTime': '22:00',
      'endTime': '06:00',
      'ordersCompleted': 4,
      'efficiency': 85,
      'avatar': '👨‍🍳',
      'phone': '+52 55 5678 9012',
      'email': 'roberto.silva@comandero.com',
      'experience': '6 años',
      'specialties': ['Carnes', 'Asados'],
      'color': AppColors.error,
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

                      // Filtros
                      _buildFilters(isTablet),
                      const SizedBox(height: 24),

                      // Lista de personal
                      _buildStaffList(isTablet, isDesktop),
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
                      'Gestión de Personal',
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

              // Botón de agregar personal
              IconButton(
                onPressed: () {
                  _showAddStaffDialog(context);
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
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
    final activeStaff = staff
        .where((person) => person['status'] == 'Activo')
        .length;
    final totalStaff = staff.length;
    final totalOrders = staff.fold<int>(
      0,
      (sum, person) => sum + (person['ordersCompleted'] as int),
    );
    final avgEfficiency =
        staff.fold<double>(0, (sum, person) => sum + person['efficiency']) /
        staff.length;

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
                  Icons.people,
                  color: AppColors.primary,
                  size: isTablet ? 24.0 : 20.0,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen del Personal',
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
                    'Personal Activo',
                    '$activeStaff/$totalStaff',
                    AppColors.success,
                    Icons.check_circle,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Órdenes Completadas',
                    '$totalOrders',
                    AppColors.warning,
                    Icons.restaurant_menu,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Eficiencia Promedio',
                    '${avgEfficiency.toStringAsFixed(0)}%',
                    AppColors.info,
                    Icons.trending_up,
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Turnos Activos',
                    '3',
                    AppColors.primary,
                    Icons.schedule,
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
                        'Turno',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedShift,
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
                            value: 'Mañana',
                            child: Text('Mañana'),
                          ),
                          DropdownMenuItem(
                            value: 'Tarde',
                            child: Text('Tarde'),
                          ),
                          DropdownMenuItem(
                            value: 'Noche',
                            child: Text('Noche'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedShift = value!;
                          });
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
                        'Estación',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedStation,
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
                            value: 'Todas',
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem(
                            value: 'Estación Tacos',
                            child: Text('Estación Tacos'),
                          ),
                          DropdownMenuItem(
                            value: 'Estación Consomes',
                            child: Text('Estación Consomes'),
                          ),
                          DropdownMenuItem(
                            value: 'Estación Bebidas',
                            child: Text('Estación Bebidas'),
                          ),
                          DropdownMenuItem(
                            value: 'Estación Carnes',
                            child: Text('Estación Carnes'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStation = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(bool isTablet, bool isDesktop) {
    final filteredStaff = staff.where((person) {
      final shiftMatch =
          selectedShift == 'Todos' || person['shift'] == selectedShift;
      final stationMatch =
          selectedStation == 'Todas' || person['station'] == selectedStation;
      return shiftMatch && stationMatch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal de Cocina',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredStaff.length,
          itemBuilder: (context, index) {
            return _buildStaffCard(filteredStaff[index], isTablet);
          },
        ),
      ],
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> person, bool isTablet) {
    final statusColor = person['color'] as Color;
    final statusIcon = _getStatusIcon(person['status']);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
              // Header del personal
              Row(
                children: [
                  // Avatar
                  Container(
                    width: isTablet ? 60.0 : 50.0,
                    height: isTablet ? 60.0 : 50.0,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        person['avatar'],
                        style: TextStyle(fontSize: isTablet ? 24.0 : 20.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información básica
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person['name'],
                          style: TextStyle(
                            fontSize: isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          person['role'],
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          person['station'],
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estado
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
                          person['status'],
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

              // Información del turno
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Turno',
                      person['shift'],
                      Icons.schedule,
                      AppColors.info,
                      isTablet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Horario',
                      '${person['startTime']} - ${person['endTime']}',
                      Icons.access_time,
                      AppColors.warning,
                      isTablet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Experiencia',
                      person['experience'],
                      Icons.work,
                      AppColors.success,
                      isTablet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estadísticas de rendimiento
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceStat(
                      'Órdenes Completadas',
                      '${person['ordersCompleted']}',
                      AppColors.warning,
                      Icons.restaurant_menu,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPerformanceStat(
                      'Eficiencia',
                      '${person['efficiency']}%',
                      AppColors.success,
                      Icons.trending_up,
                      isTablet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Especialidades
              Text(
                'Especialidades:',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (person['specialties'] as List<String>).map((
                  specialty,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      specialty,
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
                        _showStaffDetails(person);
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
                        _showStaffSchedule(person);
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        'Horarios',
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showStaffPerformance(person);
                      },
                      icon: const Icon(Icons.analytics),
                      label: Text(
                        'Rendimiento',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
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

  Widget _buildPerformanceStat(
    String label,
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
          Icon(icon, color: color, size: isTablet ? 20.0 : 18.0),
          const SizedBox(height: 8),
          Text(
            value,
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

  Widget _buildFloatingStatusButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar cambio de estado del personal
        },
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.people),
        label: Text(
          isTablet ? 'Personal Activo' : 'Activo',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Activo':
        return '✅';
      case 'Descanso':
        return '😴';
      case 'Ausente':
        return '❌';
      default:
        return '❓';
    }
  }

  void _showStaffDetails(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rol: ${person['role']}'),
              Text('Estación: ${person['station']}'),
              Text('Turno: ${person['shift']}'),
              Text('Horario: ${person['startTime']} - ${person['endTime']}'),
              Text('Experiencia: ${person['experience']}'),
              const SizedBox(height: 16),
              Text('Teléfono: ${person['phone']}'),
              Text('Email: ${person['email']}'),
              const SizedBox(height: 16),
              const Text(
                'Especialidades:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(person['specialties'] as List<String>).map(
                (specialty) => Text('• $specialty'),
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

  void _showStaffSchedule(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Horarios - ${person['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lunes: 08:00 - 16:00'),
            Text('Martes: 08:00 - 16:00'),
            Text('Miércoles: 08:00 - 16:00'),
            Text('Jueves: 08:00 - 16:00'),
            Text('Viernes: 08:00 - 16:00'),
            Text('Sábado: 14:00 - 22:00'),
            Text('Domingo: Descanso'),
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

  void _showStaffPerformance(Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rendimiento - ${person['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Órdenes completadas: 12'),
            Text('Eficiencia: 95%'),
            Text('Tiempo promedio por orden: 8 min'),
            Text('Órdenes retrasadas: 0'),
            Text('Calificación promedio: 4.8/5'),
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

  void _showAddStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Personal'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Nombre completo'),
            Text('• Rol y estación'),
            Text('• Turno y horarios'),
            Text('• Especialidades'),
            Text('• Información de contacto'),
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
