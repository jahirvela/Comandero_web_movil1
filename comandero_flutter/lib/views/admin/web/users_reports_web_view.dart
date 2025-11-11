import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../../../utils/app_colors.dart';

class UsersReportsWebView extends StatefulWidget {
  const UsersReportsWebView({super.key});

  @override
  State<UsersReportsWebView> createState() => _UsersReportsWebViewState();
}

class _UsersReportsWebViewState extends State<UsersReportsWebView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedUserType = 'todos';
  String _searchQuery = '';
  bool _showInactiveUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header con estadísticas
              _buildHeader(controller),

              // Controles y filtros
              _buildControlsSection(controller),

              // Tabs principales
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersTab(controller),
                    _buildReportsTab(controller),
                    _buildAnalyticsTab(controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AdminController controller) {
    // No mostrar header aquí, se mostrará en controls
    return const SizedBox.shrink();
  }

  Widget _buildControlsSection(AdminController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 800;

        return Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión de Usuarios',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 24.0
                                : (isTablet ? 20.0 : 18.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Administra los usuarios y sus permisos en el sistema',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 14.0
                                : (isTablet ? 12.0 : 10.0),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(controller),
                    icon: Icon(
                      Icons.add,
                      size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    ),
                    label: Text('Nuevo Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0),
                        vertical: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Usuarios', icon: Icon(Icons.people)),
                  Tab(text: 'Reportes', icon: Icon(Icons.analytics)),
                  Tab(text: 'Análisis', icon: Icon(Icons.bar_chart)),
                ],
              ),
              const SizedBox(height: 20),

              // Filtros y controles
              Row(
                children: [
                  // Búsqueda
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Buscar por nombre o usuario...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filtro de roles
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUserType,
                      decoration: InputDecoration(
                        labelText: 'Todos los roles',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos los roles'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administradores'),
                        ),
                        DropdownMenuItem(
                          value: 'mesero',
                          child: Text('Meseros'),
                        ),
                        DropdownMenuItem(
                          value: 'cocinero',
                          child: Text('Cocineros'),
                        ),
                        DropdownMenuItem(
                          value: 'cajero',
                          child: Text('Cajeros'),
                        ),
                        DropdownMenuItem(
                          value: 'capitan',
                          child: Text('Capitanes'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Filtro de estados
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _showInactiveUsers
                          ? 'inactivos'
                          : 'activos',
                      decoration: InputDecoration(
                        labelText: 'Todos los estados',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos los estados'),
                        ),
                        DropdownMenuItem(
                          value: 'activos',
                          child: Text('Activos'),
                        ),
                        DropdownMenuItem(
                          value: 'inactivos',
                          child: Text('Inactivos'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value == 'todos') {
                            _showInactiveUsers = true;
                          } else {
                            _showInactiveUsers = value == 'inactivos';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(AdminController controller) {
    final filteredUsers = _getFilteredUsers(controller);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acciones rápidas
          _buildQuickActions(controller),
          const SizedBox(height: 24),

          // Tabla de usuarios
          _buildUsersTable(controller, filteredUsers),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AdminController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 18,
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
                  child: _buildActionButton(
                    'Nuevo Usuario',
                    Icons.person_add,
                    Colors.blue,
                    () => _showAddUserDialog(controller),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Importar Usuarios',
                    Icons.upload_file,
                    Colors.green,
                    () => _showImportUsersDialog(controller),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Exportar Lista',
                    Icons.download,
                    Colors.orange,
                    () => _showExportUsersDialog(controller),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Configurar Roles',
                    Icons.admin_panel_settings,
                    Colors.purple,
                    () => _showRoleSettingsDialog(controller),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(AdminController controller, List<AdminUser> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 800;

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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppColors.primary,
                      size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lista de Usuarios (${users.length})',
                      style: TextStyle(
                        fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Tabla
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 1200
                          ? 1200
                          : constraints.maxWidth,
                    ),
                    child: DataTable(
                      columnSpacing: 24,
                      columns: [
                        DataColumn(
                          label: Text(
                            'Nombre completo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Contraseña',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Teléfono',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Roles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Estado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Fecha de creación',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop
                                  ? 14.0
                                  : (isTablet ? 12.0 : 10.0),
                            ),
                          ),
                        ),
                      ],
                      rows: users
                          .map(
                            (user) => _buildUserRow(
                              controller,
                              user,
                              isTablet,
                              isDesktop,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildUserRow(
    AdminController controller,
    AdminUser user,
    bool isTablet,
    bool isDesktop,
  ) {
    String formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
    }

    return DataRow(
      cells: [
        DataCell(
          Text(
            user.name,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            user.username,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          Text(
            user.password,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ),
        DataCell(
          Text(
            user.phone ?? '-',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: user.roles.map((role) {
              final roleColor = _getRoleColor(role);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: isDesktop ? 11.0 : (isTablet ? 10.0 : 9.0),
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isActive
                  ? Colors.green.shade700.withValues(alpha: 0.15)
                  : Colors.red.shade700.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isActive
                    ? Colors.green.shade700.withValues(alpha: 0.5)
                    : Colors.red.shade700.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Text(
              user.isActive ? 'ACTIVO' : 'INACTIVO',
              style: TextStyle(
                fontSize: isDesktop ? 11.0 : (isTablet ? 10.0 : 9.0),
                fontWeight: FontWeight.w600,
                color: user.isActive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            formatDate(user.createdAt),
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditUserDialog(controller, user);
              } else if (value == 'delete') {
                _showDeleteUserConfirmation(controller, user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(AdminController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gráficos de reportes
          _buildReportsCharts(controller),
          const SizedBox(height: 24),

          // Tabla de reportes detallados
          _buildReportsTable(controller),
        ],
      ),
    );
  }

  Widget _buildReportsCharts(AdminController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reportes de Usuarios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gráficos en fila
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    'Usuarios por Rol',
                    Icons.pie_chart,
                    _buildUsersByRoleChart(controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard(
                    'Actividad de Usuarios',
                    Icons.timeline,
                    _buildUserActivityChart(controller),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildUsersByRoleChart(AdminController controller) {
    final roleCounts = <String, int>{};
    for (final user in controller.users) {
      for (final role in user.roles) {
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
    }

    return Column(
      children: roleCounts.entries.map((entry) {
        final percentage = (entry.value / controller.users.length) * 100;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getRoleColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserActivityChart(AdminController controller) {
    // Simulación de datos de actividad
    final activityData = [
      {'hour': '08:00', 'users': 5},
      {'hour': '10:00', 'users': 12},
      {'hour': '12:00', 'users': 18},
      {'hour': '14:00', 'users': 15},
      {'hour': '16:00', 'users': 8},
      {'hour': '18:00', 'users': 20},
      {'hour': '20:00', 'users': 14},
    ];

    return Column(
      children: activityData.map((data) {
        final maxUsers = activityData
            .map((d) => d['users'] as int)
            .reduce((a, b) => a > b ? a : b);
        final percentage = (data['users'] as int) / maxUsers;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  data['hour'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data['users']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportsTable(AdminController controller) {
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reportes Detallados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Tabla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Período')),
                DataColumn(label: Text('Usuarios Activos')),
                DataColumn(label: Text('Nuevos Usuarios')),
                DataColumn(label: Text('Sesiones')),
                DataColumn(label: Text('Tiempo Promedio')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _getReportsData()
                  .map((report) => _buildReportRow(report))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildReportRow(Map<String, dynamic> report) {
    return DataRow(
      cells: [
        DataCell(Text(report['period'])),
        DataCell(Text(report['activeUsers'].toString())),
        DataCell(Text(report['newUsers'].toString())),
        DataCell(Text(report['sessions'].toString())),
        DataCell(Text(report['avgTime'])),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showReportDetails(report),
                icon: const Icon(Icons.visibility, size: 16),
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () => _exportReport(report),
                icon: const Icon(Icons.download, size: 16),
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(AdminController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Análisis avanzado
          _buildAdvancedAnalytics(controller),
          const SizedBox(height: 24),

          // Métricas de rendimiento
          _buildPerformanceMetrics(controller),
        ],
      ),
    );
  }

  Widget _buildAdvancedAnalytics(AdminController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Análisis Avanzado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Métricas en grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Eficiencia del Sistema',
                  '94.2%',
                  Icons.speed,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Tiempo de Respuesta',
                  '1.2s',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Disponibilidad',
                  '99.8%',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Satisfacción',
                  '4.7/5',
                  Icons.star,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(AdminController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Métricas de Rendimiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gráfico de rendimiento
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  'Gráfico de Rendimiento\n(Implementar con fl_chart)',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares
  List<AdminUser> _getFilteredUsers(AdminController controller) {
    var users = controller.users;

    // Filtrar por tipo de usuario
    if (_selectedUserType != 'todos') {
      users = users
          .where((user) => user.roles.contains(_selectedUserType))
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      users = users
          .where(
            (user) =>
                user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                user.username.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filtrar usuarios inactivos
    if (!_showInactiveUsers) {
      users = users.where((user) => user.isActive).toList();
    }

    return users;
  }

  List<Map<String, dynamic>> _getReportsData() {
    return [
      {
        'period': 'Hoy',
        'activeUsers': 15,
        'newUsers': 2,
        'sessions': 45,
        'avgTime': '2h 30m',
      },
      {
        'period': 'Esta Semana',
        'activeUsers': 18,
        'newUsers': 5,
        'sessions': 280,
        'avgTime': '2h 15m',
      },
      {
        'period': 'Este Mes',
        'activeUsers': 20,
        'newUsers': 8,
        'sessions': 1200,
        'avgTime': '2h 45m',
      },
    ];
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade700;
      case 'mesero':
        return Colors.blue.shade700;
      case 'cocinero':
        return Colors.orange.shade700;
      case 'cajero':
        return Colors.green.shade700;
      case 'capitan':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Métodos de diálogos y acciones
  void _showAddUserDialog(AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Usuario'),
        content: const Text('Funcionalidad de agregar usuario'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AdminController controller, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Text('Editar usuario: ${user.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserConfirmation(AdminController controller, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showImportUsersDialog(AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Usuarios'),
        content: const Text('Funcionalidad de importar usuarios'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showExportUsersDialog(AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Usuarios'),
        content: const Text('Funcionalidad de exportar usuarios'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showRoleSettingsDialog(AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Roles'),
        content: const Text('Funcionalidad de configuración de roles'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Reporte'),
        content: Text('Detalles del reporte: ${report['period']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _exportReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Reporte'),
        content: Text('Exportar reporte: ${report['period']}'),
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
