import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../services/usuarios_service.dart';
import '../../services/ordenes_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;

class StaffManagementView extends StatefulWidget {
  const StaffManagementView({super.key});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  String selectedShift = 'Todos';
  String selectedStation = 'Todas';
  List<Map<String, dynamic>> staff = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final usuariosService = UsuariosService();
      final ordenesService = OrdenesService();

      // Obtener todos los usuarios
      final usuarios = await usuariosService.listarUsuarios();

      // Filtrar solo cocineros
      final cocineros = usuarios
          .where(
            (u) => u.roles.contains('cocinero') || u.roles.contains('Cocinero'),
          )
          .toList();

      // Obtener órdenes para calcular estadísticas
      final ordenes = await ordenesService.getOrdenes();
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);

      // Calcular órdenes completadas por cocinero (simplificado)
      final ordenesHoy = ordenes.where((o) {
        final creadoEn = o['creadoEn'] != null
            ? date_utils.AppDateUtils.parseToLocal(o['creadoEn'])
            : null;
        return creadoEn != null && creadoEn.isAfter(inicioDia);
      }).toList();

      // Mapear cocineros a formato de staff
      staff = cocineros.map((cocinero) {
        // Calcular órdenes completadas (simplificado - contar órdenes del día)
        final ordersCompleted = cocineros.isNotEmpty
            ? ordenesHoy.length ~/ cocineros.length
            : 0;

        // Determinar turno basado en hora actual
        final hora = hoy.hour;
        String shift = 'Mañana';
        String startTime = '08:00';
        String endTime = '16:00';

        if (hora >= 14 && hora < 22) {
          shift = 'Tarde';
          startTime = '14:00';
          endTime = '22:00';
        } else if (hora >= 22 || hora < 6) {
          shift = 'Noche';
          startTime = '22:00';
          endTime = '06:00';
        }

        // Determinar estación basada en rol o asignación (simplificado)
        final station = 'Estación Cocina'; // Por defecto

        // Calcular eficiencia (simplificado)
        final efficiency = (85 + (ordersCompleted * 2)).clamp(70, 100);

        return {
          'id': cocinero.id,
          'name': cocinero.name,
          'role': cocinero.roles.contains('cocinero') ? 'Cocinero' : 'Chef',
          'station': station,
          'shift': shift,
          'status': cocinero.isActive ? 'Activo' : 'Inactivo',
          'startTime': startTime,
          'endTime': endTime,
          'ordersCompleted': ordersCompleted,
          'efficiency': efficiency,
          'avatar': '👨‍🍳',
          'phone': cocinero.phone ?? 'N/A',
          'email': '${cocinero.username}@comandero.com',
          'experience': 'Experiencia',
          'specialties': ['Cocina'],
          'color': AppColors.primary,
        };
      }).toList();
    } catch (e) {
      print('Error al cargar datos de staff: $e');
      // Mantener lista vacía si hay error
      staff = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _mockStaff = [
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

  final List<String> availableRoles = [
    'Chef Principal',
    'Cocinera',
    'Ayudante de cocina',
    'Bartender',
    'Encargado de estación',
  ];

  final List<String> availableStations = [
    'Estación Tacos',
    'Estación Consomes',
    'Estación Bebidas',
    'Estación Carnes',
    'Estación Salsas',
  ];

  final List<String> availableShifts = ['Mañana', 'Tarde', 'Noche'];

  final List<String> specialtiesCatalog = [
    'Tacos',
    'Barbacoa',
    'Salsas',
    'Quesadillas',
    'Consomes',
    'Caldos',
    'Bebidas',
    'Licuados',
    'Carnes',
    'Asados',
    'Postres',
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
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
    final avgEfficiency = staff.isEmpty
        ? 0.0
        : staff.fold<double>(0, (sum, person) => sum + person['efficiency']) /
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
                        initialValue: selectedShift,
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
                        initialValue: selectedStation,
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = availableRoles.first;
    String selectedStation = availableStations.first;
    String selectedShift = availableShifts.first;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final Set<String> selectedSpecialties = {};
    bool valid = false;

    Future<void> pickTime({
      required bool isStart,
      required void Function(void Function()) setModalState,
    }) async {
      final initial = isStart
          ? startTime ?? const TimeOfDay(hour: 8, minute: 0)
          : endTime ?? const TimeOfDay(hour: 16, minute: 0);
      final result = await showTimePicker(
        context: context,
        initialTime: initial,
        helpText: 'Seleccionar hora',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
        builder: (context, child) {
          return Localizations.override(
            context: context,
            locale: const Locale('es', 'MX'),
            child: child!,
          );
        },
      );
      if (result != null) {
        setModalState(() {
          if (isStart) {
            startTime = result;
          } else {
            endTime = result;
          }
        });
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            valid =
                nameController.text.trim().isNotEmpty &&
                phoneController.text.trim().isNotEmpty &&
                startTime != null &&
                endTime != null;

            return AlertDialog(
              title: const Text('Agregar Personal'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de contacto *',
                        hintText: '+52 55 0000 0000',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Rol',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final role in availableRoles)
                                DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedRole = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedStation,
                            decoration: const InputDecoration(
                              labelText: 'Estación',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final station in availableStations)
                                DropdownMenuItem(
                                  value: station,
                                  child: Text(station),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedStation = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedShift,
                            decoration: const InputDecoration(
                              labelText: 'Turno',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final shift in availableShifts)
                                DropdownMenuItem(
                                  value: shift,
                                  child: Text(shift),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedShift = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horario *',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => pickTime(
                                        isStart: true,
                                        setModalState: setModalState,
                                      ),
                                      child: Text(
                                        startTime != null
                                            ? _formatTimeOfDay(startTime!)
                                            : 'Inicio',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => pickTime(
                                        isStart: false,
                                        setModalState: setModalState,
                                      ),
                                      child: Text(
                                        endTime != null
                                            ? _formatTimeOfDay(endTime!)
                                            : 'Fin',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Especialidades',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specialtiesCatalog
                          .map(
                            (specialty) => FilterChip(
                              label: Text(specialty),
                              selected: selectedSpecialties.contains(specialty),
                              onSelected: (value) {
                                setModalState(() {
                                  if (value) {
                                    selectedSpecialties.add(specialty);
                                  } else {
                                    selectedSpecialties.remove(specialty);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: valid
                      ? () {
                          final newStaff = {
                            'id': _generateStaffId(nameController.text),
                            'name': nameController.text.trim(),
                            'role': selectedRole,
                            'station': selectedStation,
                            'shift': selectedShift,
                            'status': 'Activo',
                            'startTime': _formatTimeOfDay(startTime!),
                            'endTime': _formatTimeOfDay(endTime!),
                            'ordersCompleted': 0,
                            'efficiency': 100,
                            'avatar': _getAvatarForRole(selectedRole),
                            'phone': phoneController.text.trim(),
                            'email': '',
                            'experience': 'Nuevo ingreso',
                            'specialties': selectedSpecialties.isNotEmpty
                                ? selectedSpecialties.toList()
                                : [
                                    selectedStation.replaceFirst(
                                      'Estación ',
                                      '',
                                    ),
                                  ],
                            'color': _getStationColor(selectedStation),
                          };

                          setState(() {
                            staff.add(newStaff);
                          });

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Personal agregado: ${newStaff['name']}',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
    });
  }

  String _generateStaffId(String name) {
    final base = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${base}_$timestamp';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getAvatarForRole(String role) {
    switch (role) {
      case 'Chef Principal':
        return '👨‍🍳';
      case 'Bartender':
        return '🍹';
      case 'Ayudante de cocina':
        return '🧑‍🍳';
      case 'Encargado de estación':
        return '🧑‍🔧';
      default:
        return '👩‍🍳';
    }
  }

  Color _getStationColor(String station) {
    switch (station) {
      case 'Estación Tacos':
        return AppColors.primary;
      case 'Estación Consomes':
        return AppColors.info;
      case 'Estación Bebidas':
        return AppColors.warning;
      case 'Estación Carnes':
        return AppColors.error;
      case 'Estación Salsas':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
