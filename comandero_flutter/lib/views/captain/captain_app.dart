import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/captain_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/captain_model.dart';
import '../../utils/app_colors.dart';

class CaptainApp extends StatelessWidget {
  const CaptainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CaptainController())],
      child: Consumer2<CaptainController, AuthController>(
        builder: (context, captainController, authController, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth > 900;

              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: _buildAppBar(
                  context,
                  captainController,
                  authController,
                  isTablet,
                ),
                body: _buildBody(
                  context,
                  captainController,
                  isTablet,
                  isDesktop,
                ),
                floatingActionButton: _buildFloatingActionButton(
                  context,
                  captainController,
                  isTablet,
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CaptainController captainController,
    AuthController authController,
    bool isTablet,
  ) {
    final unreadAlerts = captainController.getUnreadAlerts().length;

    return AppBar(
      title: Row(
        children: [
          Container(
            width: isTablet ? 40.0 : 32.0,
            height: isTablet ? 40.0 : 32.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shield,
              size: isTablet ? 20.0 : 16.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Capitán - Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${authController.userName} • Capitán',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Solo lectura',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ),
        if (unreadAlerts > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications,
                  size: isTablet ? 16.0 : 14.0,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$unreadAlerts',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await authController.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          icon: Icon(Icons.logout, size: isTablet ? 24.0 : 20.0),
        ),
        const SizedBox(width: 8),
      ],
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 2,
    );
  }

  Widget _buildBody(
    BuildContext context,
    CaptainController captainController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas del día
          _buildDailyStats(captainController, isTablet),
          const SizedBox(height: 24),

          // Alertas
          _buildAlertsSection(context, captainController, isTablet),
          const SizedBox(height: 24),

          // Filtros
          _buildFiltersCard(context, captainController, isTablet),
          const SizedBox(height: 24),

          // Tabs para mesas y órdenes
          _buildTabsSection(context, captainController, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildDailyStats(CaptainController controller, bool isTablet) {
    final stats = controller.stats;

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
                  Icons.trending_up,
                  color: AppColors.primary,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas del Día',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Ventas Hoy',
                          stats.todaySales,
                          Colors.green,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Variación',
                          stats.variation,
                          Colors.blue,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Ticket Promedio',
                          stats.avgTicket,
                          Colors.orange,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Órdenes',
                          stats.totalOrders.toDouble(),
                          AppColors.primary,
                          isTablet,
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
                              'Ventas Hoy',
                              stats.todaySales,
                              Colors.green,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Variación',
                              stats.variation,
                              Colors.blue,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Ticket Promedio',
                              stats.avgTicket,
                              Colors.orange,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Órdenes',
                              stats.totalOrders.toDouble(),
                              AppColors.primary,
                              isTablet,
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
    dynamic value,
    Color color,
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
          Text(
            value is String ? value : '\$${value.toStringAsFixed(2)}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
  ) {
    final alerts = controller.filteredAlerts;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alertas',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            if (alerts.isEmpty)
              _buildEmptyAlerts(isTablet)
            else
              ...alerts.map(
                (alert) =>
                    _buildAlertCard(context, alert, controller, isTablet),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAlerts(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 40.0 : 30.0),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: isTablet ? 48.0 : 40.0,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay alertas pendientes',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    CaptainAlert alert,
    CaptainController controller,
    bool isTablet,
  ) {
    final priorityColor = controller.getPriorityColor(alert.priority);
    final isUnread = !alert.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: isUnread
            ? priorityColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnread
              ? priorityColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          width: isUnread ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AlertType.getTypeIcon(alert.type),
                size: isTablet ? 20.0 : 18.0,
                color: priorityColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  AlertPriority.getPriorityText(alert.priority),
                  style: TextStyle(
                    fontSize: isTablet ? 10.0 : 8.0,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${alert.minutes} min de retraso',
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isUnread)
                ElevatedButton(
                  onPressed: () => controller.markAlertAsRead(alert.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: priorityColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Marcar como leída',
                    style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
  ) {
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
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTableStatusFilter(controller, isTablet),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOrderStatusFilter(controller, isTablet),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPriorityFilter(controller, isTablet),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTableStatusFilter(controller, isTablet),
                      const SizedBox(height: 12),
                      _buildOrderStatusFilter(controller, isTablet),
                      const SizedBox(height: 12),
                      _buildPriorityFilter(controller, isTablet),
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

  Widget _buildTableStatusFilter(CaptainController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de Mesa',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedTableStatus,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedTableStatus(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Text('Todas las Mesas'),
                ),
                DropdownMenuItem(
                  value: CaptainTableStatus.disponible,
                  child: Text('Disponibles'),
                ),
                DropdownMenuItem(
                  value: CaptainTableStatus.ocupada,
                  child: Text('Ocupadas'),
                ),
                DropdownMenuItem(
                  value: CaptainTableStatus.cuenta,
                  child: Text('Cuenta'),
                ),
                DropdownMenuItem(
                  value: CaptainTableStatus.reservada,
                  child: Text('Reservadas'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusFilter(CaptainController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de Orden',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedOrderStatus,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedOrderStatus(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Text('Todas las Órdenes'),
                ),
                DropdownMenuItem(
                  value: CaptainOrderStatus.preparando,
                  child: Text('Preparando'),
                ),
                DropdownMenuItem(
                  value: CaptainOrderStatus.listo,
                  child: Text('Listo'),
                ),
                DropdownMenuItem(
                  value: CaptainOrderStatus.entregado,
                  child: Text('Entregado'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityFilter(CaptainController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridad',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedPriority,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedPriority(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Text('Todas las Prioridades'),
                ),
                DropdownMenuItem(
                  value: AlertPriority.high,
                  child: Text('Alta'),
                ),
                DropdownMenuItem(
                  value: AlertPriority.medium,
                  child: Text('Media'),
                ),
                DropdownMenuItem(value: AlertPriority.low, child: Text('Baja')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSection(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_bar, size: isTablet ? 20.0 : 18.0),
                    const SizedBox(width: 8),
                    Text(
                      'Mesas',
                      style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: isTablet ? 20.0 : 18.0),
                    const SizedBox(width: 8),
                    Text(
                      'Órdenes',
                      style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: isDesktop ? 500 : (isTablet ? 400 : 300),
            child: TabBarView(
              children: [
                _buildTablesView(context, controller, isTablet, isDesktop),
                _buildOrdersView(context, controller, isTablet, isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesView(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final tables = controller.filteredTables;

    if (tables.isEmpty) {
      return _buildEmptyTables(isTablet);
    }

    return GridView.builder(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
        crossAxisSpacing: isTablet ? 16.0 : 12.0,
        mainAxisSpacing: isTablet ? 16.0 : 12.0,
        childAspectRatio: isDesktop ? 1.2 : (isTablet ? 1.0 : 0.8),
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return _buildTableCard(context, table, controller, isTablet);
      },
    );
  }

  Widget _buildOrdersView(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final orders = controller.filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyOrders(isTablet);
    }

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order, controller, isTablet);
      },
    );
  }

  Widget _buildEmptyTables(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_bar,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay mesas para mostrar',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisa los filtros aplicados',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrders(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay órdenes activas',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisa los filtros aplicados',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    CaptainTable table,
    CaptainController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getTableStatusColor(table.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withValues(alpha: 0.05),
        ),
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mesa ${table.number}',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    CaptainTableStatus.getStatusText(table.status),
                    style: TextStyle(
                      fontSize: isTablet ? 10.0 : 8.0,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (table.customers != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table.customers} personas',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (table.waiter != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    table.waiter!,
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (table.currentTotal != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.formatCurrency(table.currentTotal!),
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (table.notes != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Text(
                  table.notes!,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    CaptainOrder order,
    CaptainController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getOrderStatusColor(order.status);
    final priorityColor = controller.getPriorityColor(order.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: order.isUrgent
              ? Colors.red
              : statusColor.withValues(alpha: 0.1),
          width: order.isUrgent ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: order.isUrgent
              ? Colors.red.withValues(alpha: 0.1)
              : statusColor.withValues(alpha: 0.1),
        ),
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        CaptainOrderStatus.getStatusText(order.status),
                        style: TextStyle(
                          fontSize: isTablet ? 10.0 : 8.0,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (order.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'URGENTE',
                          style: TextStyle(
                            fontSize: isTablet ? 10.0 : 8.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.table_bar,
                  size: isTablet ? 16.0 : 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mesa ${order.tableNumber}',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: isTablet ? 16.0 : 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.formatElapsedTime(order.elapsedMinutes),
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  controller.formatCurrency(order.total),
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.person,
                  size: isTablet ? 16.0 : 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order.waiter,
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    AlertPriority.getPriorityText(order.priority),
                    style: TextStyle(
                      fontSize: isTablet ? 10.0 : 8.0,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items de la orden
            ...order.items.map((item) => _buildOrderItem(item, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CaptainOrderItem item, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(isTablet ? 8.0 : 6.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontSize: isTablet ? 10.0 : 8.0,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            item.station,
            style: TextStyle(
              fontSize: isTablet ? 10.0 : 8.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          controller.markAllAlertsAsRead();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas las alertas marcadas como leídas'),
              backgroundColor: Colors.green,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mark_email_read),
        label: Text(
          isTablet ? 'Marcar Alertas' : 'Alertas',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }
}
