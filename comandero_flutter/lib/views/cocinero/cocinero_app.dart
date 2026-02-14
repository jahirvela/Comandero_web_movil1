import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../widgets/logout_button.dart';
import '../../services/kitchen_order_service.dart';
import '../../services/socket_service.dart';
import 'ingredient_consumption_view.dart';
import 'critical_notes_view.dart';
import 'station_management_view.dart';
import 'staff_management_view.dart';

// El tipo de alerta (OldKitchenAlert) está definido en CocineroController
// Como no podemos importarlo directamente, usamos el tipo que devuelve controller.alerts
// que es List<OldKitchenAlert>, así que el tipo se infiere automáticamente

class CocineroApp extends StatelessWidget {
  const CocineroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final controller = CocineroController();
            // Registrar controller en el servicio para recibir pedidos
            KitchenOrderService().registerCocineroController(controller);
            return controller;
          },
        ),
      ],
      child: Consumer2<CocineroController, AuthController>(
        builder: (context, cocineroController, authController, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth > 900;

              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: _buildAppBar(
                  context,
                  cocineroController,
                  authController,
                  isTablet,
                ),
                body: _buildBody(
                  context,
                  cocineroController,
                  isTablet,
                  isDesktop,
                ),
                floatingActionButton: _buildFloatingStatusButton(isTablet),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CocineroController cocineroController,
    AuthController authController,
    bool isTablet,
  ) {
    final filteredOrders = cocineroController.filteredOrders;

    return AppBar(
      title: Row(
        children: [
          Container(
            width: isTablet ? 40.0 : 32.0,
            height: isTablet ? 40.0 : 32.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.error],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: isTablet ? 20.0 : 16.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros de Cocina - Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${authController.userName} • Cocinero',
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Text(
            '${filteredOrders.length} pedidos',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: LogoutButton(
            isTablet: isTablet,
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
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 2,
    );
  }

  Widget _buildBody(
    BuildContext context,
    CocineroController cocineroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Consumer<CocineroController>(
      builder: (context, controller, child) {
        switch (controller.currentView) {
          case 'main':
            return _buildMainView(context, controller, isTablet, isDesktop);
          case 'ingredients':
            return const IngredientConsumptionView();
          case 'notes':
            return const CriticalNotesView();
          case 'stations':
            return const StationManagementView();
          case 'staff':
            return const StaffManagementView();
          default:
            return _buildMainView(context, controller, isTablet, isDesktop);
        }
      },
    );
  }

  Widget _buildMainView(
    BuildContext context,
    CocineroController cocineroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          _buildFiltersCard(context, cocineroController, isTablet),
          const SizedBox(height: 24),

          // Estadísticas rápidas
          _buildStatsCards(cocineroController, isTablet),
          const SizedBox(height: 24),

          // Sección de Alertas
          _buildAlertsSection(context, cocineroController, isTablet),
          const SizedBox(height: 24),

          // Lista de pedidos
          _buildOrdersList(context, cocineroController, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(
    BuildContext context,
    CocineroController cocineroController,
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
                  'Filtros de Cocina',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtros en fila
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStationFilter(
                          cocineroController,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusFilter(cocineroController, isTablet),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildShowFilter(cocineroController, isTablet),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAlertFilter(cocineroController, isTablet),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildStationFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildStatusFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildShowFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildAlertFilter(cocineroController, isTablet),
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

  Widget _buildStationFilter(CocineroController controller, bool isTablet) {
    return Column(
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
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedStation,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedStation(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Todas las Estaciones',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.tacos,
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tacos',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.consomes,
                  child: Row(
                    children: [
                      Icon(Icons.soup_kitchen, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Consomes',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.bebidas,
                  child: Row(
                    children: [
                      Icon(Icons.local_drink, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bebidas',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(CocineroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedStatus,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedStatus(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Text('Todos los Estados'),
                ),
                DropdownMenuItem(
                  value: OrderStatus.pendiente,
                  child: Text('Pendientes'),
                ),
                DropdownMenuItem(
                  value: OrderStatus.enPreparacion,
                  child: Text('En Preparación'),
                ),
                DropdownMenuItem(
                  value: OrderStatus.listo,
                  child: Text('Listos'),
                ),
                DropdownMenuItem(
                  value: OrderStatus.listoParaRecoger,
                  child: Text('Listos para Recoger'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowFilter(CocineroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mostrar',
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedShow,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedShow(value);
                }
              },
              items: [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(
                  value: 'para_llevar',
                  child: Text('Solo para llevar'),
                ),
                DropdownMenuItem(value: 'mesas', child: Text('Mesas')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertFilter(CocineroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas',
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedAlert,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedAlert(value);
                }
              },
              items: [
                DropdownMenuItem(value: 'todas', child: Text('Todas')),
                DropdownMenuItem(value: 'demoras', child: Text('Demoras')),
                DropdownMenuItem(
                  value: 'canceladas',
                  child: Text('Canceladas'),
                ),
                DropdownMenuItem(value: 'cambios', child: Text('Cambios')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(CocineroController controller, bool isTablet) {
    final stats = controller.getOrderStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            stats['pendiente']!,
            Colors.red,
            isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'En Preparación',
            stats['en_preparacion']!,
            Colors.orange,
            isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Listos',
            stats['listo']! + stats['listo_para_recoger']!,
            Colors.green,
            isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    CocineroController controller,
    bool isTablet,
  ) {
    final socketService = SocketService();
    // Obtener todas las alertas (sin filtrar) para mostrar siempre que haya alertas
    final allAlerts = controller.alerts;
    final filteredAlerts = controller.filteredAlerts;

    // Mostrar las alertas filtradas si hay filtro activo, sino mostrar todas
    final alertsToShow =
        controller.selectedAlert != 'todas' && filteredAlerts.isNotEmpty
        ? filteredAlerts
        : allAlerts;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.warning.withValues(alpha: 0.05),
        ),
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alertas (${alertsToShow.length})',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<SocketConnectionState>(
                  valueListenable: socketService.connectionState,
                  builder: (context, state, _) {
                    final connected = state == SocketConnectionState.connected;
                    final color = connected ? Colors.green : Colors.grey;
                    final label = connected ? 'En vivo' : 'Sin conexión';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            connected
                                ? Icons.podcasts
                                : Icons.podcasts_outlined,
                            size: isTablet ? 12.0 : 10.0,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: isTablet ? 10.0 : 9.0,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    // Limpiar todas las alertas
                    for (final alert in alertsToShow) {
                      await controller.removeAlert(alert.id);
                    }
                  },
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Limpiar todas'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alertsToShow.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.textSecondary,
                      size: isTablet ? 16.0 : 14.0,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:                     Text(
                      'Sin alertas pendientes. Seguimos escuchando en tiempo real.',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ),
                  ],
                ),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...alertsToShow
                          .take(3)
                          .map((alert) => _buildAlertCard(context, alert, controller, isTablet)),
                      if (alertsToShow.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Y ${alertsToShow.length - 3} alerta(s) más...',
                            style: TextStyle(
                              fontSize: isTablet ? 11.0 : 10.0,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // El tipo de alert se infiere automáticamente desde controller.alerts
  // que es List<OldKitchenAlert>
  Widget _buildAlertCard(
    BuildContext context,
    alert, // Tipo inferido: OldKitchenAlert desde CocineroController
    CocineroController controller,
    bool isTablet,
  ) {
    final priorityColor =
        alert.priority == 'high' || alert.priority == 'urgente'
        ? AppColors.error
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getAlertIcon(alert.type),
              color: priorityColor,
              size: isTablet ? 20.0 : 18.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.type,
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.priority == 'high' || alert.priority == 'urgente'
                            ? 'URGENTE'
                            : 'NORMAL',
                        style: TextStyle(
                          fontSize: isTablet ? 9.0 : 8.0,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.reason,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 11.0,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert.details != null && alert.details!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert.details!,
                    style: TextStyle(
                      fontSize: isTablet ? 11.0 : 10.0,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      size: isTablet ? 12.0 : 11.0,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.tableNumber == 'Para llevar'
                          ? 'Para llevar'
                          : 'Mesa: ${alert.tableNumber}',
                      style: TextStyle(
                        fontSize: isTablet ? 11.0 : 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.receipt_long,
                      size: isTablet ? 12.0 : 11.0,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.orderId,
                      style: TextStyle(
                        fontSize: isTablet ? 11.0 : 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (alert.sentBy != null) ...[
                      const SizedBox(width: 10),
                      Icon(
                        alert.sentByRole == 'capitan' ? Icons.shield : Icons.person,
                        size: isTablet ? 12.0 : 11.0,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.sentBy!,
                        style: TextStyle(
                          fontSize: isTablet ? 11.0 : 10.0,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (alert.sentByRole != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: alert.sentByRole == 'capitan' 
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            alert.sentByRole == 'capitan' ? 'Capitán' : 'Mesero',
                            style: TextStyle(
                              fontSize: isTablet ? 9.0 : 8.0,
                              color: alert.sentByRole == 'capitan' 
                                  ? Colors.purple
                                  : Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    Text(
                      _formatAlertTime(alert.timestamp),
                      style: TextStyle(
                        fontSize: isTablet ? 10.0 : 9.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Botón de acción según el tipo de alerta y motivo
                if (_shouldShowActionButton(alert.type, alert.reason)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(context, alert, controller, isTablet),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textSecondary,
            onPressed: () {
              controller.removeAlert(alert.id);
            },
            tooltip: 'Cerrar alerta',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'demora':
        return Icons.timer_off;
      case 'cancelación':
      case 'cancelacion':
        return Icons.cancel;
      case 'cambio':
      case 'cambio en orden':
        return Icons.edit;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatAlertTime(DateTime timestamp) {
    // Asegurar que el timestamp esté en hora local
    final alertTime = timestamp.toLocal();
    
    // Formatear como HH:mm (formato 24 horas)
    final hour = alertTime.hour.toString().padLeft(2, '0');
    final minute = alertTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }

  // Verificar si se debe mostrar un botón de acción según el tipo de alerta
  bool _shouldShowActionButton(String alertType, String? reason) {
    final typeLower = alertType.toLowerCase();
    final reasonLower = (reason ?? '').toLowerCase();
    
    // Motivos válidos para cancelar (independientemente del tipo de alerta)
    final motivosValidosParaCancelar = [
      'cliente se retiró',
      'cliente se retiro',
      'cliente cambió pedido',
      'cliente cambio pedido',
      'error en comanda',
      'error comanda',
    ];
    
    // Verificar si el motivo es válido para cancelar
    final motivoValido = motivosValidosParaCancelar.any(
      (motivo) => reasonLower.contains(motivo)
    );
    
    // Mostrar botón de cancelar si:
    // 1. El tipo de alerta es "Cancelación" (cualquier motivo)
    // 2. El tipo de alerta es "Cambio en orden" Y el motivo es válido para cancelar
    // 3. El motivo es válido para cancelar (independientemente del tipo)
    final esCancelacion = typeLower == 'cancelación' || 
                          typeLower == 'cancelacion' ||
                          typeLower.contains('cancelación') ||
                          typeLower.contains('cancelacion');
    
    final esCambioEnOrden = typeLower.contains('cambio') ||
                           typeLower.contains('modific');
    
    // NO mostrar para "Demora" u otros tipos que no sean cancelación o cambio
    final esDemora = typeLower.contains('demora') ||
                    typeLower.contains('tiempo de espera') ||
                    typeLower.contains('mucho tiempo');
    
    if (esDemora) {
      return false; // Nunca mostrar para demoras
    }
    
    // Mostrar si es cancelación (cualquier motivo)
    if (esCancelacion) {
      return true;
    }
    
    // Mostrar si es cambio en orden Y el motivo es válido para cancelar
    if (esCambioEnOrden && motivoValido) {
      return true;
    }
    
    // Mostrar si el motivo es válido para cancelar (aunque el tipo no sea específico)
    if (motivoValido) {
      return true;
    }
    
    return false;
  }

  // Construir botón de acción según el tipo de alerta
  Widget _buildActionButton(
    BuildContext context,
    dynamic alert,
    CocineroController controller,
    bool isTablet,
  ) {
    final alertType = alert.type.toLowerCase();
    final reason = (alert.reason ?? '').toLowerCase();
    
    // Determinar si es cancelación o cambio válido para cancelar
    final esCancelacion = alertType.contains('cancelación') || 
                         alertType.contains('cancelacion') || 
                         alertType.contains('cancel');
    
    final esCambioValido = alertType.contains('cambio') ||
                          alertType.contains('modific');
    
    final motivosValidos = [
      'cliente se retiró',
      'cliente se retiro',
      'cliente cambió pedido',
      'cliente cambio pedido',
      'error en comanda',
      'error comanda',
    ];
    
    final motivoValido = motivosValidos.any((m) => reason.contains(m));
    
    // Mostrar botón si es cancelación o cambio válido
    if (esCancelacion || (esCambioValido && motivoValido) || motivoValido) {
      // Determinar el texto del botón según el contexto
      String buttonText = 'Cancelar Orden';
      if (esCambioValido && motivoValido) {
        buttonText = 'Cancelar y Corregir';
      }
      
      return ElevatedButton.icon(
        onPressed: () => _showCancelOrderDialog(context, alert, controller),
        icon: const Icon(Icons.cancel, size: 18),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16.0 : 12.0,
            vertical: isTablet ? 10.0 : 8.0,
          ),
          textStyle: TextStyle(
            fontSize: isTablet ? 13.0 : 12.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Para otros tipos de alertas, retornar un SizedBox vacío
    return const SizedBox.shrink();
  }

  // Mostrar diálogo de confirmación para cancelar orden
  Future<void> _showCancelOrderDialog(
    BuildContext context,
    dynamic alert,
    CocineroController controller,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Confirmar Cancelación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.type.toLowerCase().contains('cambio') 
                  ? '¿Estás seguro de que deseas cancelar esta orden para que el mesero envíe la orden correcta?'
                  : '¿Estás seguro de que deseas cancelar esta orden?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Orden: ${alert.orderId}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Mesa: ${alert.tableNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (alert.reason != null && alert.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Motivo del mesero:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.reason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, Cancelar Orden'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // El usuario confirmó la cancelación
      try {
        await controller.cancelOrder(alert.orderId, reason: alert.reason);
        // Remover la alerta después de cancelar
        controller.removeAlert(alert.id);
        
        // Mostrar mensaje de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Orden ${alert.orderId} cancelada exitosamente',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Mostrar mensaje de error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error al cancelar la orden: $e',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Widget _buildStatCard(String title, int count, Color color, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
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
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    CocineroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final orders = controller.filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyOrders(isTablet);
    }

    // Para desktop mostrar en tarjetas ajustables tipo wrap; móvil/tablet lista vertical
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedidos (${orders.length})',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              const maxItemWidth = 360.0;
              final availableWidth = constraints.maxWidth;
              final crossAxisCount = (availableWidth / (maxItemWidth + spacing))
                  .floor()
                  .clamp(1, 4);
              final spacingTotal =
                  spacing * (crossAxisCount > 1 ? crossAxisCount - 1 : 0);
              final itemWidth =
                  (availableWidth - spacingTotal) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: orders
                    .map(
                      (order) => SizedBox(
                        width: itemWidth,
                        child: _buildOrderCard(
                          context,
                          order,
                          controller,
                          isTablet,
                          withBottomMargin: false,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedidos (${orders.length})',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...orders.map(
          (order) => _buildOrderCard(context, order, controller, isTablet),
        ),
      ],
    );
  }

  Widget _buildEmptyOrders(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí cuando lleguen',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    CocineroController controller,
    bool isTablet, {
    bool withBottomMargin = true,
  }) {
    final statusColor = controller.getStatusColor(order.status);
    // Usar StreamBuilder para actualizar el tiempo en tiempo real
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => date_utils.AppDateUtils.nowCdmx()),
      builder: (context, snapshot) {
        final elapsedTime = controller.formatElapsedTime(order.orderTime);

    // Obtener texto del estado
    String statusText = OrderStatus.getStatusText(order.status).toUpperCase();
    if (statusText == 'PENDIENTE') {
      statusText = 'PENDIENTE';
    } else if (statusText == 'EN PREPARACIÓN') {
      statusText = 'EN PREPARACION';
    } else if (statusText == 'LISTO PARA RECOGER') {
      statusText = 'LISTO PARA RECOGER';
    }

    return Card(
      margin: EdgeInsets.only(
        bottom: withBottomMargin ? (isTablet ? 20.0 : 16.0) : 0,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: order.priority == OrderPriority.alta
              ? Colors.red.withValues(alpha: 0.5)
              : statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetailModal(context, order, controller, isTablet);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges de estado y prioridad
                Row(
                  children: [
                    _buildStatusBadge(
                      order.priority == OrderPriority.alta
                          ? 'URGENTE'
                          : 'Normal',
                      order.priority == OrderPriority.alta
                          ? Colors.red
                          : Colors.blue,
                      isTablet,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(statusText, statusColor, isTablet),
                  ],
                ),
                const SizedBox(height: 12),

                // Información del pedido
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.isTakeaway
                                ? 'Para llevar'
                                : 'Mesa ${order.tableNumber}',
                            style: TextStyle(
                              fontSize: isTablet ? 16.0 : 14.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            order.id,
                            style: TextStyle(
                              fontSize: isTablet ? 14.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order.isTakeaway && order.customerPhone != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Solo para llevar - ${order.customerName ?? ''}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12.0 : 10.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.customerPhone!,
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 10.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nombre de persona (si es cuenta dividida)
                if (!order.isTakeaway && order.customerName != null && order.customerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: isTablet ? 14.0 : 12.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pedido de ${order.customerName}',
                          style: TextStyle(
                            fontSize: isTablet ? 13.0 : 11.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Tiempo y mesero
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isTablet ? 16.0 : 14.0,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsedTime,
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                  ],
                ),
                const SizedBox(height: 12),

                // Tiempo de salida clickeable
                Row(
                  children: [
                    Text(
                      'Tiempo de Salida:',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        _showEditTimeDialog(
                          context,
                          order,
                          controller,
                          isTablet,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${order.estimatedTime} min',
                              style: TextStyle(
                                fontSize: isTablet ? 14.0 : 12.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Items del pedido
                ...order.items.map(
                  (item) => _buildOrderItem(item, controller, isTablet),
                ),
                const SizedBox(height: 16),

                // Botones de acción
                _buildActionButtons(context, order, controller, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10.0 : 8.0,
        vertical: isTablet ? 6.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 12.0 : 10.0,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOrderItem(
    OrderItem item,
    CocineroController controller,
    bool isTablet,
  ) {
    final isCritical = controller.isCriticalNote(item.notes);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.1),
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
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
                    fontSize: isTablet ? 15.0 : 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  KitchenStation.getStationName(item.station),
                  style: TextStyle(
                    fontSize: isTablet ? 11.0 : 9.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildNoteWidget(item.notes, isCritical, isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteWidget(String notes, bool isCritical, bool isTablet) {
    if (isCritical) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 10.0 : 8.0),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: isTablet ? 20.0 : 18.0,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Nota crítica',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notes,
              style: TextStyle(
                fontSize: isTablet ? 13.0 : 11.0,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: isTablet ? 14.0 : 12.0,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mostrar siempre',
                  style: TextStyle(
                    fontSize: isTablet ? 11.0 : 9.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(isTablet ? 8.0 : 6.0),
        decoration: BoxDecoration(
          color: Colors.yellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(
              'Nota:',
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    OrderModel order,
    CocineroController controller,
    bool isTablet,
  ) {
    return Row(
      children: [
        if (order.status == OrderStatus.pendiente) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await controller.updateOrderStatus(
                    order.id,
                    OrderStatus.enPreparacion,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pedido ${order.id} en preparación'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al actualizar pedido: ${e.toString()}',
                        ),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Iniciar',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (order.status == OrderStatus.enPreparacion) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final newStatus = order.isTakeaway
                      ? OrderStatus.listoParaRecoger
                      : OrderStatus.listo;
                  await controller.updateOrderStatus(order.id, newStatus);

                  // La alerta en tiempo real se envía automáticamente desde el backend
                  // cuando se actualiza el estado a "listo"

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          order.isTakeaway
                              ? 'Pedido ${order.id} listo para recoger'
                              : 'Pedido ${order.id} listo',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
                  final esFaltanteIngredientes = msg.contains('faltan ingredientes') ||
                      msg.contains('No se puede marcar como listo');
                  if (esFaltanteIngredientes) {
                    // Mensaje entendible: quitar "Error del servidor (400):" y códigos técnicos
                    final msgLimpia = msg
                        .replaceFirst(RegExp(r'^Error del servidor\s*\(\d+\):\s*'), '')
                        .replaceFirst(RegExp(r'^Error\s*\(\d+\):\s*'), '')
                        .trim();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Faltan ingredientes'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msgLimpia),
                              const SizedBox(height: 16),
                              Text(
                                'Forzar igual: marca el pedido como listo sin descontar inventario. Úsalo solo si repusiste ingredientes por otro medio o es una excepción.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(ctx).hintColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Entendido'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              try {
                                final newStatus = order.isTakeaway
                                    ? OrderStatus.listoParaRecoger
                                    : OrderStatus.listo;
                                await controller.updateOrderStatus(
                                  order.id,
                                  newStatus,
                                  forzarSinStock: true,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        order.isTakeaway
                                            ? 'Pedido ${order.id} listo para recoger'
                                            : 'Pedido ${order.id} listo',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e2) {
                                if (context.mounted) {
                                  final errMsg = e2.toString()
                                      .replaceFirst(RegExp(r'^Exception:\s*'), '')
                                      .replaceFirst(RegExp(r'^Error del servidor\s*\(\d+\):\s*'), '')
                                      .replaceFirst(RegExp(r'^Error\s*\(\d+\):\s*'), '');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $errMsg'),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Forzar igual'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar pedido: $msg'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: Text(
                order.isTakeaway ? 'Listo para recoger' : 'Listo',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (order.status == OrderStatus.listo ||
            order.status == OrderStatus.listoParaRecoger) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle),
              label: Text(
                order.isTakeaway ? 'Listo para recoger' : 'Pedido completado',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
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

  void _showOrderDetailModal(
    BuildContext context,
    OrderModel order,
    CocineroController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getStatusColor(order.status);
    final priorityColor = controller.getPriorityColor(order.priority);
    final elapsedTime = controller.formatElapsedTime(order.orderTime);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: statusColor,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del Pedido',
                            style: TextStyle(
                              fontSize: isTablet ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            order.id,
                            style: TextStyle(
                              fontSize: isTablet ? 16.0 : 14.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del pedido
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Estado',
                              OrderStatus.getStatusText(order.status),
                              statusColor,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'Prioridad',
                              OrderPriority.getPriorityText(order.priority),
                              priorityColor,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (order.isTakeaway) ...[
                        _buildDetailItem(
                          'Para Llevar',
                          '${order.customerName}${order.customerPhone != null ? '\n${order.customerPhone}' : ''}',
                          AppColors.primary,
                          isTablet,
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        _buildDetailItem(
                          'Mesa',
                          '${order.tableNumber}',
                          AppColors.textPrimary,
                          isTablet,
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Tiempo transcurrido',
                              elapsedTime,
                              AppColors.textSecondary,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailItem(
                              'Tiempo estimado',
                              '${order.estimatedTime} min',
                              AppColors.primary,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildDetailItem(
                        'Mesero',
                        order.waiter,
                        AppColors.textSecondary,
                        isTablet,
                      ),
                      const SizedBox(height: 24),

                      // Items del pedido
                      Text(
                        'Items del Pedido',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: TextStyle(
                                        fontSize: isTablet ? 14.0 : 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: isTablet ? 16.0 : 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      KitchenStation.getStationName(
                                        item.station,
                                      ),
                                      style: TextStyle(
                                        fontSize: isTablet ? 10.0 : 8.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 8.0 : 6.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: isTablet ? 14.0 : 12.0,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.notes,
                                          style: TextStyle(
                                            fontSize: isTablet ? 12.0 : 10.0,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con acciones
              Container(
                padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: _buildActionButtons(
                  context,
                  order,
                  controller,
                  isTablet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    Color color,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTimeDialog(
    BuildContext context,
    OrderModel order,
    CocineroController controller,
    bool isTablet,
  ) {
    int selectedMinutes = order.estimatedTime;
    bool isCustom = false;
    final customController = TextEditingController(
      text: selectedMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Modificar Tiempo de Salida',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 400 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualiza el tiempo estimado de salida para esta orden',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Opciones rápidas',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickTimeOption(
                      '5 min',
                      5,
                      selectedMinutes,
                      isCustom,
                      () {
                        setState(() {
                          selectedMinutes = 5;
                          isCustom = false;
                        });
                      },
                      isTablet,
                    ),
                    _buildQuickTimeOption(
                      '15 min',
                      15,
                      selectedMinutes,
                      isCustom,
                      () {
                        setState(() {
                          selectedMinutes = 15;
                          isCustom = false;
                        });
                      },
                      isTablet,
                    ),
                    _buildQuickTimeOption(
                      '30 min',
                      30,
                      selectedMinutes,
                      isCustom,
                      () {
                        setState(() {
                          selectedMinutes = 30;
                          isCustom = false;
                        });
                      },
                      isTablet,
                    ),
                    _buildQuickTimeOption(
                      '45 min',
                      45,
                      selectedMinutes,
                      isCustom,
                      () {
                        setState(() {
                          selectedMinutes = 45;
                          isCustom = false;
                        });
                      },
                      isTablet,
                    ),
                    _buildQuickTimeOption(
                      '1 h',
                      60,
                      selectedMinutes,
                      isCustom,
                      () {
                        setState(() {
                          selectedMinutes = 60;
                          isCustom = false;
                        });
                      },
                      isTablet,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: isCustom,
                      onChanged: (value) {
                        setState(() {
                          isCustom = value ?? false;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isCustom = !isCustom;
                        });
                      },
                      child: Text(
                        'Personalizado',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minutos',
                      hintText: 'Ej: 10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          selectedMinutes = parsed;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTime = isCustom
                    ? int.tryParse(customController.text) ?? selectedMinutes
                    : selectedMinutes;
                if (newTime > 0 && newTime <= 120) {
                  controller.updateEstimatedTime(order.id, newTime);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tiempo estimado actualizado a $newTime minutos',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'El tiempo debe estar entre 1 y 120 minutos',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Actualizar Tiempo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimeOption(
    String label,
    int minutes,
    int selectedMinutes,
    bool isCustom,
    VoidCallback onTap,
    bool isTablet,
  ) {
    final isSelected = !isCustom && selectedMinutes == minutes;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 12.0,
          vertical: isTablet ? 10.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
