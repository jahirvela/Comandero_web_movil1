import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_model.dart';
import '../../utils/app_colors.dart';
import 'web/inventory_web_view.dart';
import 'web/cash_closures_web_view.dart';
import 'web/real_time_sales_web_view.dart';
import 'web/users_reports_web_view.dart';

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
  String _currentView = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AdminController())],
      child: Consumer2<AdminController, AuthController>(
        builder: (context, adminController, authController, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1200;
              final isTablet = constraints.maxWidth > 800;

              return Scaffold(
                backgroundColor: AppColors.background,
                body: Row(
                  children: [
                    // Sidebar
                    _buildSidebar(
                      context,
                      adminController,
                      authController,
                      isTablet,
                      isDesktop,
                    ),

                    // Main content
                    Expanded(
                      child: _buildMainContent(
                        context,
                        adminController,
                        isTablet,
                        isDesktop,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AdminController adminController,
    AuthController authController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      width: isDesktop ? 280.0 : (isTablet ? 240.0 : 200.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(context, authController, isTablet, isDesktop),

          // Navigation
          Expanded(
            child: _buildSidebarNavigation(
              context,
              adminController,
              isTablet,
              isDesktop,
            ),
          ),

          // Footer
          _buildSidebarFooter(context, authController, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(
    BuildContext context,
    AuthController authController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: isDesktop ? 60.0 : (isTablet ? 50.0 : 40.0),
            height: isDesktop ? 60.0 : (isTablet ? 50.0 : 40.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: isDesktop ? 30.0 : (isTablet ? 25.0 : 20.0),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comandix Admin',
            style: TextStyle(
              fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            authController.userName,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavigation(
    BuildContext context,
    AdminController adminController,
    bool isTablet,
    bool isDesktop,
  ) {
    final menuItems = [
      {'id': 'dashboard', 'name': 'Dashboard', 'icon': Icons.dashboard},
      {'id': 'inventory', 'name': 'Inventario', 'icon': Icons.inventory},
      {
        'id': 'cash_closures',
        'name': 'Cortes de Caja',
        'icon': Icons.account_balance_wallet,
      },
      {
        'id': 'real_time_sales',
        'name': 'Ventas en Tiempo Real',
        'icon': Icons.trending_up,
      },
      {
        'id': 'users_reports',
        'name': 'Usuarios/Reportes',
        'icon': Icons.people_alt,
      },
    ];

    return ListView(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      children: menuItems
          .map(
            (item) => _buildNavItem(
              context,
              item['id'] as String,
              item['name'] as String,
              item['icon'] as IconData,
              isTablet,
              isDesktop,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String id,
    String name,
    IconData icon,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentView = id;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0),
              vertical: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
            ),
            decoration: BoxDecoration(
              color: _currentView == id
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _currentView == id
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                  color: _currentView == id
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                    fontWeight: FontWeight.w500,
                    color: _currentView == id
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(
    BuildContext context,
    AuthController authController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0)),
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
                  Icons.security,
                  size: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acceso Total',
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await authController.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: Icon(
                Icons.logout,
                size: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              ),
              label: Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0),
                  vertical: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AdminController adminController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      children: [
        // Top bar
        _buildTopBar(context, adminController, isTablet, isDesktop),

        // Content
        Expanded(
          child: _buildContent(context, adminController, isTablet, isDesktop),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AdminController adminController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sistema Activo',
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminController adminController,
    bool isTablet,
    bool isDesktop,
  ) {
    switch (_currentView) {
      case 'dashboard':
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard stats
              _buildDashboardStats(adminController, isTablet, isDesktop),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context, adminController, isTablet, isDesktop),
              const SizedBox(height: 24),

              // Alerts and notifications
              _buildAlertsSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
              const SizedBox(height: 24),

              // Charts and analytics
              _buildAnalyticsSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
            ],
          ),
        );
      case 'inventory':
        return const InventoryWebView();
      case 'cash_closures':
        return const CashClosuresWebView();
      case 'real_time_sales':
        return const RealTimeSalesWebView();
      case 'users_reports':
        return const UsersReportsWebView();
      default:
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard stats
              _buildDashboardStats(adminController, isTablet, isDesktop),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context, adminController, isTablet, isDesktop),
              const SizedBox(height: 24),

              // Alerts and notifications
              _buildAlertsSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
              const SizedBox(height: 24),

              // Charts and analytics
              _buildAnalyticsSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboardStats(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final stats = controller.dashboardStats;

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
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen del Día',
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
                if (constraints.maxWidth > 1000) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Ventas Hoy',
                          stats.todaySales,
                          Colors.green,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Crecimiento',
                          '${stats.salesGrowth.toStringAsFixed(1)}%',
                          Colors.blue,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Órdenes',
                          stats.totalOrders.toDouble(),
                          Colors.orange,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Ticket Promedio',
                          stats.averageTicket,
                          AppColors.primary,
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
                              'Ventas Hoy',
                              stats.todaySales,
                              Colors.green,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Crecimiento',
                              '${stats.salesGrowth.toStringAsFixed(1)}%',
                              Colors.blue,
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
                              'Órdenes',
                              stats.totalOrders.toDouble(),
                              Colors.orange,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Ticket Promedio',
                              stats.averageTicket,
                              AppColors.primary,
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
    dynamic value,
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
            value is String ? value : '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
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
                  Icons.flash_on,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Acciones Rápidas',
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
                        child: _buildActionButton(
                          'Usuarios',
                          Icons.people,
                          Colors.blue,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Inventario',
                          Icons.inventory,
                          Colors.orange,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Menú',
                          Icons.restaurant_menu,
                          Colors.green,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Mesas',
                          Icons.table_bar,
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
                            child: _buildActionButton(
                              'Usuarios',
                              Icons.people,
                              Colors.blue,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              'Inventario',
                              Icons.inventory,
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
                            child: _buildActionButton(
                              'Menú',
                              Icons.restaurant_menu,
                              Colors.green,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              'Mesas',
                              Icons.table_bar,
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

  Widget _buildActionButton(
    String title,
    IconData icon,
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
          Icon(
            icon,
            size: isDesktop ? 40.0 : (isTablet ? 32.0 : 28.0),
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final lowStockItems = controller.getLowStockItems();
    final outOfStockItems = controller.getOutOfStockItems();
    final totalAlerts = lowStockItems.length + outOfStockItems.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Alertas del Sistema',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (totalAlerts > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalAlerts',
                      style: TextStyle(
                        fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            if (totalAlerts == 0)
              _buildNoAlerts(isTablet, isDesktop)
            else
              Row(
                children: [
                  if (outOfStockItems.isNotEmpty)
                    Expanded(
                      child: _buildAlertCard(
                        'Sin Stock',
                        outOfStockItems.length,
                        Colors.red,
                        isTablet,
                        isDesktop,
                      ),
                    ),
                  if (lowStockItems.isNotEmpty)
                    Expanded(
                      child: _buildAlertCard(
                        'Stock Bajo',
                        lowStockItems.length,
                        Colors.orange,
                        isTablet,
                        isDesktop,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlerts(bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 60.0 : (isTablet ? 40.0 : 30.0)),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: isDesktop ? 64.0 : (isTablet ? 48.0 : 40.0),
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay alertas pendientes',
            style: TextStyle(
              fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    int count,
    Color color,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning,
            size: isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0),
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count items',
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

  Widget _buildAnalyticsSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final stats = controller.dashboardStats;

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
                  'Análisis de Ventas',
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
                        child: _buildTopProducts(
                          stats.topProducts,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: _buildSalesByHour(
                          stats.salesByHour,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTopProducts(stats.topProducts, isTablet, isDesktop),
                      const SizedBox(height: 20),
                      _buildSalesByHour(stats.salesByHour, isTablet, isDesktop),
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

  Widget _buildTopProducts(
    List<SalesItem> products,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos Más Vendidos',
          style: TextStyle(
            fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...products
            .take(5)
            .map((product) => _buildProductItem(product, isTablet, isDesktop)),
      ],
    );
  }

  Widget _buildProductItem(SalesItem product, bool isTablet, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${product.quantity} vendidos',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${product.revenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesByHour(
    Map<String, double> salesByHour,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas por Hora',
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
            itemCount: salesByHour.length,
            itemBuilder: (context, index) {
              final entry = salesByHour.entries.elementAt(index);
              final maxValue = salesByHour.values.reduce(
                (a, b) => a > b ? a : b,
              );
              final height =
                  (entry.value / maxValue) *
                  (isDesktop ? 160.0 : (isTablet ? 120.0 : 80.0));

              return Container(
                width: isDesktop ? 50.0 : (isTablet ? 40.0 : 30.0),
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: height,
                      width: isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0),
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
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
