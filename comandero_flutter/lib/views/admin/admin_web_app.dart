import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_model.dart';
import '../../models/payment_model.dart' as payment_models;
import '../../services/payment_repository.dart';
import '../../utils/app_colors.dart';
import '../../widgets/logout_button.dart';
import 'web/inventory_web_view.dart';
import 'web/cash_closures_web_view.dart';
import 'web/real_time_sales_web_view.dart';
import 'web/users_reports_web_view.dart';
import 'web/configuracion_web_view.dart';

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
  String _currentView = 'dashboard';

  @override
  Widget build(BuildContext context) {
    // Guard: Verificar que estamos en web y el usuario es admin
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('Este panel solo está disponible en web')),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AdminController(
            paymentRepository: context.read<PaymentRepository>(),
          ),
        ),
      ],
      child: Consumer2<AdminController, AuthController>(
        builder: (context, adminController, authController, child) {
          // Verificar que el usuario es admin
          if (authController.userRole != 'admin') {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Acceso denegado. Solo administradores pueden acceder.',
                ),
              ),
            );
          }

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
      {'id': 'dashboard', 'name': 'Panel de Control', 'icon': Icons.dashboard},
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
      {
        'id': 'configuracion',
        'name': 'Configuración',
        'icon': Icons.settings,
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
            child: LogoutButton(
              isTablet: isTablet || isDesktop,
              label: 'Cerrar sesión',
              onPressed: () async {
                await authController.logout();
                if (context.mounted) {
                  // Usar go_router en lugar de Navigator.pushReplacementNamed
                  context.go('/login');
                }
              },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Si el ancho es muy pequeño, apilar elementos verticalmente
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 18.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de Control',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Resumen general',
                            style: TextStyle(
                              fontSize: 10.0,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 12.0,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Acceso Total',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LogoutButton(
                        isTablet: true,
                        label: 'Cerrar sesión',
                        onPressed: () async {
                          final authController = Provider.of<AuthController>(
                            context,
                            listen: false,
                          );
                          await authController.logout();
                          if (context.mounted) {
                            // Usar go_router en lugar de Navigator.pushReplacementNamed
                            context.go('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Layout horizontal para pantallas más grandes
          return Row(
            children: [
              Container(
                width: isDesktop ? 48.0 : (isTablet ? 40.0 : 36.0),
                height: isDesktop ? 48.0 : (isTablet ? 40.0 : 36.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Control',
                      style: TextStyle(
                        fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Resumen general de restaurante',
                      style: TextStyle(
                        fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Acceso Total',
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 14.0
                                : (isTablet ? 12.0 : 10.0),
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: LogoutButton(
                    isTablet: isTablet || isDesktop,
                    label: 'Cerrar sesión',
                    onPressed: () async {
                      final authController = Provider.of<AuthController>(
                        context,
                        listen: false,
                      );
                      await authController.logout();
                      if (context.mounted) {
                        // Usar go_router en lugar de Navigator.pushReplacementNamed
                  context.go('/login');
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
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
              // Consumo del Día
              _buildDailyConsumptionSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
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
      case 'configuracion':
        return const ConfiguracionWebView();
      default:
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consumo del Día
              _buildDailyConsumptionSection(
                context,
                adminController,
                isTablet,
                isDesktop,
              ),
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


  Widget _buildDailyConsumptionSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    // Usar métricas basadas en tickets en lugar de órdenes
    final localSales = controller.dailyLocalSales;
    final takeawaySales = controller.dailyTakeawaySales;
    final cashSales = controller.dailyCashSales;
    final pendingPayment = controller.dailyPendingPayment;
    final totalNet = controller.dailyTotalNet;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consumo del Día',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tarjetas de consumo
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildConsumptionCard(
                          'Ventas en Local',
                          '\$${localSales.toStringAsFixed(2)}',
                          Colors.green.shade700,
                          isTablet,
                          isDesktop,
                          subtitle: '${controller.dailyLocalOrdersCount} ${controller.dailyLocalOrdersCount == 1 ? 'orden' : 'órdenes'}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Ventas Para llevar',
                          '\$${takeawaySales.toStringAsFixed(2)}',
                          Colors.blue.shade700,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Ventas Efectivo',
                          '\$${cashSales.toStringAsFixed(2)}',
                          Colors.yellow.shade700,
                          isTablet,
                          isDesktop,
                          subtitle: 'Incluye pagos mixtos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Por cobrar',
                          '\$${pendingPayment.toStringAsFixed(2)}',
                          Colors.pink.shade700,
                          isTablet,
                          isDesktop,
                          subtitle: '${controller.dailyPendingTicketsCount} ${controller.dailyPendingTicketsCount == 1 ? 'ticket pendiente' : 'tickets pendientes'}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Total Neto',
                          '\$${totalNet.toStringAsFixed(2)}',
                          Colors.purple.shade700,
                          isTablet,
                          isDesktop,
                          subtitle: 'Incluye efectivo y tarjeta',
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
                            child: _buildConsumptionCard(
                              'Ventas en Local',
                              '\$${localSales.toStringAsFixed(2)}',
                              Colors.green.shade700,
                              isTablet,
                              isDesktop,
                              subtitle: '${controller.dailyLocalOrdersCount} ${controller.dailyLocalOrdersCount == 1 ? 'orden' : 'órdenes'}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Ventas Para llevar',
                              '\$${takeawaySales.toStringAsFixed(2)}',
                              Colors.blue.shade700,
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
                            child: _buildConsumptionCard(
                              'Ventas Efectivo',
                              '\$${cashSales.toStringAsFixed(2)}',
                              Colors.yellow.shade700,
                              isTablet,
                              isDesktop,
                              subtitle: 'Incluye pagos mixtos',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Por cobrar',
                              '\$${pendingPayment.toStringAsFixed(2)}',
                              Colors.pink.shade700,
                              isTablet,
                              isDesktop,
                              subtitle: '${controller.dailyPendingTicketsCount} ${controller.dailyPendingTicketsCount == 1 ? 'ticket pendiente' : 'tickets pendientes'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildConsumptionCard(
                        'Total Neto',
                        '\$${totalNet.toStringAsFixed(2)}',
                        Colors.purple.shade700,
                        isTablet,
                        isDesktop,
                        subtitle: 'Incluye efectivo y tarjeta',
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            // Filtros
            Row(
              children: [
                Text(
                  'Mostrar:',
                  style: TextStyle(
                    fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                for (final filter in ['todos', 'para_llevar', 'mesas'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: controller.selectedConsumptionFilter == filter,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.selectedConsumptionFilter == filter)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          if (controller.selectedConsumptionFilter == filter)
                            const SizedBox(width: 4),
                          Text(
                            const {
                              'todos': 'Todos',
                              'para_llevar': 'Solo para llevar',
                              'mesas': 'Mesas',
                            }[filter]!,
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        controller.setSelectedConsumptionFilter(filter);
                      },
                      selectedColor: Colors.orange.shade700,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: controller.selectedConsumptionFilter == filter
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight:
                            controller.selectedConsumptionFilter == filter
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Tabla de consumo (ahora muestra tickets)
            _buildConsumptionTable(
              controller.filteredDailyTickets,
              controller,
              isTablet,
              isDesktop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(
    String title,
    String value,
    Color color,
    bool isTablet,
    bool isDesktop, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 9.0),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsumptionTable(
    List<payment_models.BillModel> tickets,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    if (tickets.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0)),
        child: Center(
          child: Text(
            'No hay consumo registrado para el filtro seleccionado',
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
        headingRowColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.1),
        ),
        columns: [
          DataColumn(
            label: Text(
              'ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Origen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Productos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Método de pago',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Hora',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              ),
            ),
          ),
        ],
        rows: tickets.map((ticket) {
          // Determinar texto y color del estado
          String statusText;
          Color statusColor;
          if (ticket.paymentMethod != null && ticket.paymentMethod!.isNotEmpty) {
            statusText = payment_models.BillStatus.getStatusText(ticket.status);
            statusColor = payment_models.BillStatus.getStatusColor(ticket.status);
          } else {
            statusText = 'Por cobrar';
            statusColor = Colors.orange;
          }

          // Obtener descripción de productos
          final productsText = ticket.items.isNotEmpty
              ? ticket.items
                  .map((item) => '${item.quantity}x ${item.name}')
                  .join(', ')
              : 'Pedido para llevar';

          // Obtener ID de visualización
          final displayId = ticket.displayId;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  displayId,
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                  ),
                ),
              ),
              DataCell(
                Chip(
                  label: Text(
                    ticket.isTakeaway
                        ? (ticket.customerName ?? 'Para llevar')
                        : ticket.tableDisplayLabel,
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: ticket.isTakeaway
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12.0 : (isTablet ? 8.0 : 6.0),
                    vertical: isDesktop ? 8.0 : (isTablet ? 6.0 : 4.0),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: isDesktop ? 200.0 : (isTablet ? 150.0 : 100.0),
                  child: Text(
                    productsText,
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '\$${ticket.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              DataCell(
                Text(
                  ticket.paymentMethod ?? 'Pendiente',
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataCell(
                Chip(
                  label: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12.0 : (isTablet ? 8.0 : 6.0),
                    vertical: isDesktop ? 8.0 : (isTablet ? 6.0 : 4.0),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
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
    final chartData = salesByHour.entries.map((entry) {
      return SalesData(entry.key, entry.value);
    }).toList();

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
          height: isDesktop ? 250.0 : (isTablet ? 200.0 : 150.0),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                color: AppColors.textSecondary,
              ),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                color: AppColors.textSecondary,
              ),
              numberFormat: NumberFormat.currency(symbol: '\$'),
            ),
            series: <CartesianSeries>[
              ColumnSeries<SalesData, String>(
                dataSource: chartData,
                xValueMapper: (SalesData sales, _) => sales.hour,
                yValueMapper: (SalesData sales, _) => sales.amount,
                pointColorMapper: (SalesData sales, _) => AppColors.primary,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                dataLabelSettings: DataLabelSettings(
                  isVisible: isDesktop,
                  labelAlignment: ChartDataLabelAlignment.top,
                  textStyle: TextStyle(
                    fontSize: 10.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true),
          ),
        ),
      ],
    );
  }
}

// Clase auxiliar para los datos de la gráfica
class SalesData {
  final String hour;
  final double amount;

  SalesData(this.hour, this.amount);
}
