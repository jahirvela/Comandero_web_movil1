import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import 'ingredient_consumption_view.dart';
import 'critical_notes_view.dart';
import 'station_management_view.dart';
import 'staff_management_view.dart';

class CocineroApp extends StatelessWidget {
  const CocineroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CocineroController())],
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
          // Navegación rápida
          _buildQuickNavigation(context, cocineroController, isTablet),
          const SizedBox(height: 24),

          // Filtros
          _buildFiltersCard(context, cocineroController, isTablet),
          const SizedBox(height: 24),

          // Estadísticas rápidas
          _buildStatsCards(cocineroController, isTablet),
          const SizedBox(height: 24),

          // Lista de pedidos
          _buildOrdersList(context, cocineroController, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation(
    BuildContext context,
    CocineroController controller,
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
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Navegación Rápida',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
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
                  child: _buildNavigationCard(
                    'Consumo de Ingredientes',
                    Icons.inventory,
                    AppColors.warning,
                    () => controller.setCurrentView('ingredients'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Notas Críticas',
                    Icons.warning,
                    AppColors.error,
                    () => controller.setCurrentView('notes'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Gestión de Estaciones',
                    Icons.restaurant,
                    AppColors.info,
                    () => controller.setCurrentView('stations'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Gestión de Personal',
                    Icons.people,
                    AppColors.success,
                    () => controller.setCurrentView('staff'),
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

  Widget _buildNavigationCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
              title,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                        child: _buildTakeawayFilter(
                          cocineroController,
                          isTablet,
                        ),
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
                      _buildTakeawayFilter(cocineroController, isTablet),
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
                      Text('Todas las Estaciones'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.tacos,
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Text('Tacos'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.consomes,
                  child: Row(
                    children: [
                      Icon(Icons.soup_kitchen, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Text('Consomes'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: KitchenStation.bebidas,
                  child: Row(
                    children: [
                      Icon(Icons.local_drink, size: isTablet ? 16.0 : 14.0),
                      const SizedBox(width: 8),
                      Text('Bebidas'),
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

  Widget _buildTakeawayFilter(CocineroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Para Llevar',
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
              value: controller.showTakeawayOnly.toString(),
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setShowTakeawayOnly(value == 'true');
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'false',
                  child: Text('Todos los Pedidos'),
                ),
                DropdownMenuItem(
                  value: 'true',
                  child: Text('Solo Para Llevar'),
                ),
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
    bool isTablet,
  ) {
    final statusColor = controller.getStatusColor(order.status);
    final priorityColor = controller.getPriorityColor(order.priority);
    final elapsedTime = controller.formatElapsedTime(order.orderTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del pedido
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (order.isTakeaway) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Para Llevar - ${order.customerName}',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mesa ${order.tableNumber}',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          OrderStatus.getStatusText(order.status),
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                          OrderPriority.getPriorityText(order.priority),
                          style: TextStyle(
                            fontSize: isTablet ? 10.0 : 8.0,
                            fontWeight: FontWeight.w500,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items del pedido
              ...order.items.map((item) => _buildOrderItem(item, isTablet)),
              const SizedBox(height: 16),

              // Información adicional
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tiempo: $elapsedTime',
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
              const SizedBox(height: 16),

              // Botones de acción
              _buildActionButtons(context, order, controller, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
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
                fontSize: isTablet ? 12.0 : 10.0,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nota: ${item.notes}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              KitchenStation.getStationName(item.station),
              style: TextStyle(
                fontSize: isTablet ? 10.0 : 8.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
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
              onPressed: () {
                controller.updateOrderStatus(
                  order.id,
                  OrderStatus.enPreparacion,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pedido ${order.id} en preparación'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Comenzar',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
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
              onPressed: () {
                final newStatus = order.isTakeaway
                    ? OrderStatus.listoParaRecoger
                    : OrderStatus.listo;
                controller.updateOrderStatus(order.id, newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pedido ${order.id} listo'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: Text(
                'Marcar Listo',
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
        ],
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implementar editar tiempo estimado
          },
          icon: const Icon(Icons.timer),
          label: Text(
            'Tiempo: ${order.estimatedTime}min',
            style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
}
