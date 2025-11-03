import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cocinero_controller.dart';
import '../../models/admin_model.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart' as payment_models;
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../cocinero/order_detail_modal.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => CocineroController()),
      ],
      child: Consumer3<AdminController, AuthController, CocineroController>(
        builder:
            (
              context,
              adminController,
              authController,
              cocineroController,
              child,
            ) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  final isDesktop = constraints.maxWidth > 900;

                  return Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: _buildAppBar(
                      context,
                      adminController,
                      authController,
                      isTablet,
                    ),
                    body: _buildBody(
                      context,
                      adminController,
                      cocineroController,
                      isTablet,
                      isDesktop,
                    ),
                    bottomNavigationBar: _buildBottomNavigationBar(
                      context,
                      adminController,
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
    AdminController adminController,
    AuthController authController,
    bool isTablet,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: isTablet ? 40.0 : 32.0,
            height: isTablet ? 40.0 : 32.0,
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
              size: isTablet ? 20.0 : 16.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Administrador - Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${authController.userName} • Administrador',
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
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Acceso Total',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              fontWeight: FontWeight.w600,
              color: Colors.red,
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
    AdminController adminController,
    CocineroController cocineroController,
    bool isTablet,
    bool isDesktop,
  ) {
    switch (adminController.currentView) {
      case 'dashboard':
        return _buildDashboardView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'tables':
        return _buildTablesManagementView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'menu':
        return _buildMenuManagementView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'inventory':
        return _buildInventoryManagementView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'users':
        return _buildUsersManagementView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'tickets':
        return _buildTicketsManagementView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'cash_closures':
        return _buildCashClosuresView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'review_cashiers':
        return _buildReviewCashiersClosuresView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
      case 'kitchen_filters':
        return _buildKitchenFiltersView(
          context,
          adminController,
          cocineroController,
          isTablet,
          isDesktop,
        );
      default:
        return _buildDashboardView(
          context,
          adminController,
          isTablet,
          isDesktop,
        );
    }
  }

  Widget _buildDashboardView(
    BuildContext context,
    AdminController adminController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del Panel de Control
          Text(
            'Panel de Control',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: AppTheme.fontWeightBold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Consumo del Día con Filtros
          _buildDailyConsumptionSection(
            context,
            adminController,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Estado de Mesas
          _buildTableStatusSection(context, adminController, isTablet),
          SizedBox(height: AppTheme.spacingXL),

          // Alertas de Inventario
          _buildInventoryAlertsSection(context, adminController, isTablet),
        ],
      ),
    );
  }

  // Sección de Consumo del Día
  Widget _buildDailyConsumptionSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consumo del Día',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Filtros: Todos, Solo para llevar, Mesas
                _buildConsumptionFilters(context, controller, isTablet),
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            // Tabla de consumo
            _buildConsumptionTable(context, controller, isTablet, isDesktop),
          ],
        ),
      ),
    );
  }

  // Filtros de consumo
  Widget _buildConsumptionFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final filterOptions = [
      {'value': 'todos', 'label': 'Todos'},
      {'value': 'para_llevar', 'label': 'Solo para llevar'},
      {'value': 'mesas', 'label': 'Mesas'},
    ];

    return Row(
      children: filterOptions.map((filter) {
        final isSelected =
            controller.selectedConsumptionFilter == filter['value'];
        return Padding(
          padding: EdgeInsets.only(right: AppTheme.spacingSM),
          child: FilterChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                fontSize: isTablet ? AppTheme.fontSizeSM : AppTheme.fontSizeXS,
                fontWeight: isSelected
                    ? AppTheme.fontWeightSemibold
                    : AppTheme.fontWeightNormal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.setSelectedConsumptionFilter(filter['value']!);
              }
            },
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Tabla de consumo del día
  Widget _buildConsumptionTable(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final orders = controller.filteredDailyConsumption;

    if (orders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Text(
            'No hay consumo registrado para el filtro seleccionado',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
          columns: [
            DataColumn(
              label: Text(
                'ID',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Tipo',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Mesa/Cliente',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Productos',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Mesero',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Hora',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                ),
              ),
            ),
          ],
          rows: orders.map((order) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    order.id,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(
                      order.isTakeaway ? 'Para llevar' : 'Mesa',
                      style: TextStyle(
                        fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: order.isTakeaway
                        ? Colors.blue
                        : Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    order.isTakeaway
                        ? (order.customerName ?? 'Cliente')
                        : 'Mesa ${order.tableNumber}',
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    order.items
                        .map((item) => '${item.quantity}x ${item.name}')
                        .join(', '),
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    order.waiter,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(_buildOrderStatusChip(order.status, isTablet)),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      // Vista móvil - lista de tarjetas
      return Column(
        children: orders.map((order) {
          return Card(
            margin: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.id,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTheme.fontWeightBold,
                        ),
                      ),
                      _buildOrderStatusChip(order.status, isTablet),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          order.isTakeaway
                              ? 'Para llevar'
                              : 'Mesa ${order.tableNumber}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXS,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: order.isTakeaway
                            ? Colors.blue
                            : Colors.green,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Text(
                        order.waiter,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(
                    order.items
                        .map((item) => '${item.quantity}x ${item.name}')
                        .join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(
                    'Hora: ${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  // Chip de estado de orden
  Widget _buildOrderStatusChip(String status, bool isTablet) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pendiente:
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case OrderStatus.enPreparacion:
        color = Colors.blue;
        text = 'En Preparación';
        break;
      case OrderStatus.listo:
        color = Colors.green;
        text = 'Listo';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? AppTheme.fontSizeXS : 10,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: AppTheme.spacingXS,
      ),
    );
  }

  // Sección de Estado de Mesas
  Widget _buildTableStatusSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final tables = controller.tables;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Mesas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontWeightBold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingLG),

            // Grid de mesas
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: AppTheme.spacingMD,
                    mainAxisSpacing: AppTheme.spacingMD,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return _buildTableCard(context, table, isTablet);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de mesa
  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    bool isTablet,
  ) {
    final statusColor = TableStatus.getStatusColor(table.status);
    final statusText = TableStatus.getStatusText(table.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mesa ${table.number}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontWeightBold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            if (table.customers != null) ...[
              SizedBox(height: AppTheme.spacingSM),
              Text(
                '${table.customers} comensales',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (table.waiter != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                table.waiter!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Sección de Alertas de Inventario
  Widget _buildInventoryAlertsSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final lowStockItems = controller.getLowStockItems();
    final outOfStockItems = controller.getOutOfStockItems();
    final totalAlerts = lowStockItems.length + outOfStockItems.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: isTablet ? 24.0 : 20.0,
                ),
                SizedBox(width: AppTheme.spacingSM),
                Text(
                  'Alertas de Inventario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (totalAlerts > 0) ...[
                  SizedBox(width: AppTheme.spacingSM),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: Text(
                      '$totalAlerts',
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: AppTheme.fontWeightBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppTheme.spacingLG),

            if (totalAlerts == 0)
              _buildNoInventoryAlerts(isTablet)
            else ...[
              if (outOfStockItems.isNotEmpty)
                _buildInventoryAlertList(
                  context,
                  'Stock Crítico',
                  outOfStockItems,
                  Colors.red,
                  isTablet,
                ),
              if (lowStockItems.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMD),
                _buildInventoryAlertList(
                  context,
                  'Stock Bajo',
                  lowStockItems,
                  Colors.orange,
                  isTablet,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Lista de alertas de inventario
  Widget _buildInventoryAlertList(
    BuildContext context,
    String title,
    List<InventoryItem> items,
    Color color,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, size: isTablet ? 18.0 : 16.0, color: color),
              SizedBox(width: AppTheme.spacingSM),
              Text(
                '$title (${items.length})',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeLG
                      : AppTheme.fontSizeSM,
                  fontWeight: AppTheme.fontWeightSemibold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        ...items.take(5).map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingSM),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: AppTheme.fontWeightMedium,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Stock: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (items.length > 5)
          Padding(
            padding: EdgeInsets.only(top: AppTheme.spacingSM),
            child: Text(
              'Y ${items.length - 5} más...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // Sin alertas de inventario
  Widget _buildNoInventoryAlerts(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: isTablet ? 48.0 : 40.0,
            color: Colors.green,
          ),
          SizedBox(height: AppTheme.spacingMD),
          Text(
            'No hay alertas de inventario',
            style: TextStyle(
              fontSize: isTablet ? AppTheme.fontSizeLG : AppTheme.fontSizeSM,
              fontWeight: AppTheme.fontWeightSemibold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Gestión de Mesas
  Widget _buildTablesManagementView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botón agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Mesas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddTableModal(context, controller, isTablet),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Mesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Filtros de área
          _buildAreaFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Grid de mesas
          _buildTablesGrid(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Filtros de área
  Widget _buildAreaFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final filterOptions = [
      {'value': 'todos', 'label': 'Todos'},
      {'value': 'area_principal', 'label': 'Área Principal'},
      {'value': 'area_lateral', 'label': 'Área Lateral'},
    ];

    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingSM,
      children: filterOptions.map((filter) {
        final isSelected = controller.selectedTableArea == filter['value'];
        return FilterChip(
          label: Text(
            filter['label']!,
            style: TextStyle(
              fontSize: isTablet ? AppTheme.fontSizeSM : AppTheme.fontSizeXS,
              fontWeight: isSelected
                  ? AppTheme.fontWeightSemibold
                  : AppTheme.fontWeightNormal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              controller.setSelectedTableArea(filter['value']!);
            }
          },
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  // Grid de mesas
  Widget _buildTablesGrid(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final tables = controller.filteredTables;

    if (tables.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.table_bar, size: 64, color: AppColors.textSecondary),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay mesas para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: AppTheme.spacingMD,
            mainAxisSpacing: AppTheme.spacingMD,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableManagementCard(
              context,
              table,
              controller,
              isTablet,
            );
          },
        );
      },
    );
  }

  // Tarjeta de mesa para gestión
  Widget _buildTableManagementCard(
    BuildContext context,
    TableModel table,
    AdminController controller,
    bool isTablet,
  ) {
    final statusColor = TableStatus.getStatusColor(table.status);
    final sectionText = table.section == 'area_principal'
        ? 'Área Principal'
        : table.section == 'area_lateral'
        ? 'Área Lateral'
        : 'Sin sección';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con número y acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mesa ${table.number}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: isTablet ? 20 : 18),
                      color: AppColors.primary,
                      onPressed: () => _showEditTableModal(
                        context,
                        table,
                        controller,
                        isTablet,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    IconButton(
                      icon: Icon(Icons.delete, size: isTablet ? 20 : 18),
                      color: Colors.red,
                      onPressed: () =>
                          _showDeleteTableDialog(context, table, controller),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Sección
            Chip(
              label: Text(
                sectionText,
                style: TextStyle(
                  fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.secondary,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Estado con dropdown
            DropdownButtonFormField<String>(
              value: table.status,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                filled: true,
                fillColor: statusColor.withValues(alpha: 0.1),
              ),
              items: [
                DropdownMenuItem(
                  value: TableStatus.libre,
                  child: Text(TableStatus.getStatusText(TableStatus.libre)),
                ),
                DropdownMenuItem(
                  value: TableStatus.ocupada,
                  child: Text(TableStatus.getStatusText(TableStatus.ocupada)),
                ),
                DropdownMenuItem(
                  value: TableStatus.reservada,
                  child: Text(TableStatus.getStatusText(TableStatus.reservada)),
                ),
                DropdownMenuItem(
                  value: TableStatus.enLimpieza,
                  child: Text(
                    TableStatus.getStatusText(TableStatus.enLimpieza),
                  ),
                ),
              ],
              onChanged: (newStatus) {
                if (newStatus != null) {
                  controller.updateTableStatus(table.id, newStatus);
                }
              },
              style: TextStyle(
                color: statusColor,
                fontWeight: AppTheme.fontWeightSemibold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Información adicional
            Text(
              '${table.seats} asientos',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (table.customers != null)
              Text(
                '${table.customers} comensales',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  // Modal para agregar mesa
  void _showAddTableModal(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final seatsController = TextEditingController();
    String selectedSection = 'area_principal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Mesa'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Mesa *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Debe ser un número válido';
                      }
                      if (controller.tableNumberExists(number)) {
                        return 'Ya existe una mesa con ese número';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: seatsController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Asientos *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      final seats = int.tryParse(value);
                      if (seats == null || seats <= 0) {
                        return 'Debe ser un número válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Sección *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'area_principal',
                        child: Text('Área Principal'),
                      ),
                      DropdownMenuItem(
                        value: 'area_lateral',
                        child: Text('Área Lateral'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSection = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newTable = TableModel(
                    id: controller.getNextTableId(),
                    number: int.parse(numberController.text),
                    status: TableStatus.libre,
                    seats: int.parse(seatsController.text),
                    section: selectedSection,
                  );
                  controller.addTable(newTable);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mesa agregada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear Mesa'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para editar mesa
  void _showEditTableModal(
    BuildContext context,
    TableModel table,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(
      text: table.number.toString(),
    );
    final seatsController = TextEditingController(text: table.seats.toString());
    String selectedSection = table.section ?? 'area_principal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editar Mesa'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Mesa *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Debe ser un número válido';
                      }
                      if (controller.tableNumberExists(
                        number,
                        excludeId: table.id,
                      )) {
                        return 'Ya existe una mesa con ese número';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: seatsController,
                    decoration: const InputDecoration(
                      labelText: 'Asientos *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      final seats = int.tryParse(value);
                      if (seats == null || seats <= 0) {
                        return 'Debe ser un número válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Sección *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'area_principal',
                        child: Text('Área Principal'),
                      ),
                      DropdownMenuItem(
                        value: 'area_lateral',
                        child: Text('Área Lateral'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSection = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedTable = table.copyWith(
                    number: int.parse(numberController.text),
                    seats: int.parse(seatsController.text),
                    section: selectedSection,
                  );
                  controller.updateTable(updatedTable);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mesa actualizada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para eliminar mesa
  void _showDeleteTableDialog(
    BuildContext context,
    TableModel table,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Mesa'),
        content: Text('¿Estás seguro de eliminar la Mesa ${table.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteTable(table.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mesa ${table.number} eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Vista de Gestión de Menú
  Widget _buildMenuManagementView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Menú',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isTablet || isDesktop)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddCategoryModal(context, controller, isTablet),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Categoría'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddProductModal(context, controller, isTablet),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Producto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (!isTablet && !isDesktop) ...[
            // Botones apilados en móvil
            SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddCategoryModal(context, controller, isTablet),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Categoría'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddProductModal(context, controller, isTablet),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppTheme.spacingXL),

          // Búsqueda y filtros
          _buildMenuSearchAndFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Lista de productos
          _buildMenuProductsList(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Búsqueda y filtros de menú
  Widget _buildMenuSearchAndFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
          ),
          onChanged: (value) => controller.setSearchQuery(value),
        ),
        SizedBox(height: AppTheme.spacingMD),

        // Filtros de categorías
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...controller.getAllCategories().map((category) {
                final isSelected = controller.selectedMenuCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: isSelected
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedMenuCategory(category);
                      }
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Lista de productos del menú
  Widget _buildMenuProductsList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final products = controller.filteredMenuItems;

    if (products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay productos para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppTheme.spacingMD,
          mainAxisSpacing: AppTheme.spacingMD,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildMenuProductCard(context, product, controller, isTablet);
        },
      );
    } else {
      return Column(
        children: products.map((product) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildMenuProductCard(
              context,
              product,
              controller,
              isTablet,
            ),
          );
        }).toList(),
      );
    }
  }

  // Tarjeta de producto del menú
  Widget _buildMenuProductCard(
    BuildContext context,
    MenuItem product,
    AdminController controller,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(
          color: product.isAvailable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: isTablet ? 20 : 18),
                      color: AppColors.primary,
                      onPressed: () => _showEditProductModal(
                        context,
                        product,
                        controller,
                        isTablet,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    IconButton(
                      icon: Icon(Icons.delete, size: isTablet ? 20 : 18),
                      color: Colors.red,
                      onPressed: () => _showDeleteProductDialog(
                        context,
                        product,
                        controller,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Categoría
            Chip(
              label: Text(
                product.category,
                style: TextStyle(
                  fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                  color: Colors.white,
                ),
              ),
              backgroundColor: MenuCategory.getCategoryColor(product.category),
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Precio o tamaños
            if (product.hasSizes &&
                product.sizes != null &&
                product.sizes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tamaños:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: AppTheme.fontWeightMedium,
                    ),
                  ),
                  ...product.sizes!.map((size) {
                    return Text(
                      '  • ${size.name}: \$${size.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }).toList(),
                ],
              )
            else if (product.price != null)
              Text(
                'Precio: \$${product.price!.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightSemibold,
                  color: AppColors.primary,
                ),
              ),
            SizedBox(height: AppTheme.spacingSM),

            // Descripción
            Text(
              product.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRecipeModal(
                      context,
                      product,
                      controller,
                      isTablet,
                    ),
                    icon: const Icon(Icons.restaurant_menu, size: 16),
                    label: const Text('Receta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        controller.toggleMenuItemAvailability(product.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isAvailable
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      product.isAvailable ? 'Deshabilitar' : 'Habilitar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal para agregar categoría
  void _showAddCategoryModal(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Categoría'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría *',
              border: OutlineInputBorder(),
              hintText: 'Ej: Postres, Ensaladas...',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obligatorio';
              }
              if (controller.getAllCategories().contains(value)) {
                return 'Ya existe una categoría con ese nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.addCustomCategory(nameController.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Categoría "${nameController.text}" agregada',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // Modal para agregar producto
  void _showAddProductModal(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedCategory;
    bool hasSizes = false;
    List<MenuSize> sizes = [];
    bool serveHot = false;
    bool isSpicy = false;
    bool allowSauces = false;
    bool allowExtraIngredients = false;
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Nuevo Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.getAllCategories().map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  SwitchListTile(
                    title: const Text('Tamaños (Sí/No)'),
                    value: hasSizes,
                    onChanged: (value) {
                      setState(() {
                        hasSizes = value;
                        if (!value) {
                          sizes = [];
                        }
                      });
                    },
                  ),
                  if (hasSizes) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    _buildSizesConfiguration(context, sizes, (newSizes) {
                      setState(() {
                        sizes = newSizes;
                      });
                    }, isTablet),
                  ] else ...[
                    SizedBox(height: AppTheme.spacingMD),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !hasSizes,
                      validator: hasSizes
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obligatorio';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Debe ser un número válido';
                              }
                              return null;
                            },
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  SwitchListTile(
                    title: const Text('Servir caliente'),
                    value: serveHot,
                    onChanged: (value) {
                      setState(() {
                        serveHot = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Picante'),
                    value: isSpicy,
                    onChanged: (value) {
                      setState(() {
                        isSpicy = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Permitir Salsas'),
                    value: allowSauces,
                    onChanged: (value) {
                      setState(() {
                        allowSauces = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Permitir Ingredientes extra'),
                    value: allowExtraIngredients,
                    onChanged: (value) {
                      setState(() {
                        allowExtraIngredients = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Disponible'),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (hasSizes && sizes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debe agregar al menos un tamaño'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final newProduct = MenuItem(
                    id: controller.getNextMenuItemId(),
                    name: nameController.text,
                    category: selectedCategory!,
                    description: descriptionController.text,
                    price: hasSizes ? null : double.parse(priceController.text),
                    isAvailable: isAvailable,
                    ingredients: [],
                    allergens: [],
                    preparationTime: 0,
                    createdAt: DateTime.now(),
                    hasSizes: hasSizes,
                    sizes: hasSizes ? sizes : null,
                    serveHot: serveHot,
                    isSpicy: isSpicy,
                    allowSauces: allowSauces,
                    allowExtraIngredients: allowExtraIngredients,
                  );
                  controller.addMenuItem(newProduct);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto agregado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear Producto'),
            ),
          ],
        ),
      ),
    );
  }

  // Configuración de tamaños
  Widget _buildSizesConfiguration(
    BuildContext context,
    List<MenuSize> sizes,
    Function(List<MenuSize>) onSizesChanged,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurar Tamaños',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontWeightSemibold,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        ...sizes.asMap().entries.map((entry) {
          final index = entry.key;
          final size = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingSM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Nombre (ej: Chico)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: TextEditingController(text: size.name),
                    onChanged: (value) {
                      sizes[index] = MenuSize(name: value, price: size.price);
                      onSizesChanged(sizes);
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: size.price.toStringAsFixed(0),
                    ),
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      sizes[index] = MenuSize(name: size.name, price: price);
                      onSizesChanged(sizes);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    sizes.removeAt(index);
                    onSizesChanged(sizes);
                  },
                ),
              ],
            ),
          );
        }).toList(),
        ElevatedButton.icon(
          onPressed: () {
            sizes.add(MenuSize(name: '', price: 0.0));
            onSizesChanged(sizes);
          },
          icon: const Icon(Icons.add),
          label: const Text('Añadir tamaño'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Modal para editar producto
  void _showEditProductModal(
    BuildContext context,
    MenuItem product,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(
      text: product.description,
    );
    final priceController = TextEditingController(
      text: product.price?.toStringAsFixed(0) ?? '',
    );
    String? selectedCategory = product.category;
    bool hasSizes = product.hasSizes;
    List<MenuSize> sizes = product.sizes?.toList() ?? [];
    bool serveHot = product.serveHot;
    bool isSpicy = product.isSpicy;
    bool allowSauces = product.allowSauces;
    bool allowExtraIngredients = product.allowExtraIngredients;
    bool isAvailable = product.isAvailable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editar Producto'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.getAllCategories().map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  SwitchListTile(
                    title: const Text('Tamaños (Sí/No)'),
                    value: hasSizes,
                    onChanged: (value) {
                      setState(() {
                        hasSizes = value;
                        if (!value) {
                          sizes = [];
                        }
                      });
                    },
                  ),
                  if (hasSizes) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    _buildSizesConfiguration(context, sizes, (newSizes) {
                      setState(() {
                        sizes = newSizes;
                      });
                    }, isTablet),
                  ] else ...[
                    SizedBox(height: AppTheme.spacingMD),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !hasSizes,
                      validator: hasSizes
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obligatorio';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Debe ser un número válido';
                              }
                              return null;
                            },
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  SwitchListTile(
                    title: const Text('Servir caliente'),
                    value: serveHot,
                    onChanged: (value) {
                      setState(() {
                        serveHot = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Picante'),
                    value: isSpicy,
                    onChanged: (value) {
                      setState(() {
                        isSpicy = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Permitir Salsas'),
                    value: allowSauces,
                    onChanged: (value) {
                      setState(() {
                        allowSauces = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Permitir Ingredientes extra'),
                    value: allowExtraIngredients,
                    onChanged: (value) {
                      setState(() {
                        allowExtraIngredients = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Disponible'),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (hasSizes && sizes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debe agregar al menos un tamaño'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final updatedProduct = product.copyWith(
                    name: nameController.text,
                    category: selectedCategory!,
                    description: descriptionController.text,
                    price: hasSizes ? null : double.parse(priceController.text),
                    isAvailable: isAvailable,
                    hasSizes: hasSizes,
                    sizes: hasSizes ? sizes : null,
                    serveHot: serveHot,
                    isSpicy: isSpicy,
                    allowSauces: allowSauces,
                    allowExtraIngredients: allowExtraIngredients,
                    updatedAt: DateTime.now(),
                  );
                  controller.updateMenuItem(updatedProduct);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para receta/ingredientes
  void _showRecipeModal(
    BuildContext context,
    MenuItem product,
    AdminController controller,
    bool isTablet,
  ) {
    List<RecipeIngredient> ingredients =
        product.recipeIngredients?.toList() ?? [];
    bool showCustomForm = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Receta / Ingredientes'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ingredients.isEmpty && !showCustomForm)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXL),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: AppTheme.spacingMD),
                          Text(
                            'No hay ingredientes configurados',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!showCustomForm && ingredients.isNotEmpty)
                  ...ingredients.map((ingredient) {
                    return Card(
                      margin: EdgeInsets.only(bottom: AppTheme.spacingSM),
                      child: ListTile(
                        title: Text(ingredient.name),
                        subtitle: Text(
                          '${ingredient.quantityPerPortion} ${ingredient.unit} por porción',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ingredients.remove(ingredient);
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                if (!showCustomForm) ...[
                  SizedBox(height: AppTheme.spacingMD),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showCustomForm = true;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar ingrediente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (showCustomForm)
                  _IngredientFormWidget(
                    controller: controller,
                    ingredients: ingredients,
                    onSave: (newIngredients) {
                      setState(() {
                        ingredients = newIngredients;
                        showCustomForm = false;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            if (showCustomForm)
              TextButton(
                onPressed: () {
                  setState(() {
                    showCustomForm = false;
                  });
                },
                child: const Text('Volver a sugeridos'),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ElevatedButton(
              onPressed: () {
                final updatedProduct = product.copyWith(
                  recipeIngredients: ingredients,
                  updatedAt: DateTime.now(),
                );
                controller.updateMenuItem(updatedProduct);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receta guardada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Receta'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para eliminar producto
  void _showDeleteProductDialog(
    BuildContext context,
    MenuItem product,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteMenuItem(product.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Producto "${product.name}" eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.0 : 16.0,
            vertical: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(
                'Dashboard',
                Icons.dashboard,
                controller.currentView == 'dashboard',
                isTablet,
                () {
                  controller.setCurrentView('dashboard');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Mesas',
                Icons.table_bar,
                controller.currentView == 'tables',
                isTablet,
                () {
                  controller.setCurrentView('tables');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Menú',
                Icons.restaurant_menu,
                controller.currentView == 'menu',
                isTablet,
                () {
                  controller.setCurrentView('menu');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Inventario',
                Icons.inventory_2,
                controller.currentView == 'inventory',
                isTablet,
                () {
                  controller.setCurrentView('inventory');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Usuarios',
                Icons.people,
                controller.currentView == 'users',
                isTablet,
                () {
                  controller.setCurrentView('users');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Tickets',
                Icons.receipt_long,
                controller.currentView == 'tickets',
                isTablet,
                () {
                  controller.setCurrentView('tickets');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Cierre',
                Icons.account_balance_wallet,
                controller.currentView == 'cash_closures' ||
                    controller.currentView == 'review_cashiers',
                isTablet,
                () {
                  controller.setCurrentView('cash_closures');
                },
              ),
              const SizedBox(width: 16),
              _buildNavItem(
                'Cocina',
                Icons.restaurant_menu,
                controller.currentView == 'kitchen_filters',
                isTablet,
                () {
                  controller.setCurrentView('kitchen_filters');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    IconData icon,
    bool isSelected,
    bool isTablet,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12.0 : 8.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 24.0 : 20.0,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 10.0 : 8.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vista de Gestión de Inventario
  Widget _buildInventoryManagementView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botón agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Inventario',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddInventoryModal(context, controller, isTablet),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Alertas de stock
          _buildInventoryAlerts(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Búsqueda y filtros
          _buildInventorySearchAndFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Lista de productos
          _buildInventoryItemsList(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Alertas de inventario
  Widget _buildInventoryAlerts(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final criticalItems = controller.inventory
        .where((item) => item.status == InventoryStatus.outOfStock)
        .toList();
    final lowStockItems = controller.inventory
        .where((item) => item.status == InventoryStatus.lowStock)
        .toList();

    if (criticalItems.isEmpty && lowStockItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (criticalItems.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    'Stock Crítico: ${criticalItems.length} producto(s)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: AppTheme.fontWeightSemibold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),
        ],
        if (lowStockItems.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    'Stock Bajo: ${lowStockItems.length} producto(s)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: AppTheme.fontWeightSemibold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Búsqueda y filtros de inventario
  Widget _buildInventorySearchAndFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar producto o proveedor...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
          ),
          onChanged: (value) => controller.setSearchQuery(value),
        ),
        SizedBox(height: AppTheme.spacingMD),

        // Filtros de categorías
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...[
                'todos',
                'Carne',
                'Tortillas',
                'Condimentos',
                'Bebidas',
                'Otros',
              ].map((category) {
                final isSelected =
                    controller.selectedInventoryCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      category == 'todos' ? 'Todos' : category,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: isSelected
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedInventoryCategory(category);
                      }
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Lista de productos de inventario
  Widget _buildInventoryItemsList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final items = controller.filteredInventory;

    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 64, color: AppColors.textSecondary),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay productos en inventario',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
          child: _buildInventoryItemCard(context, item, controller, isTablet),
        );
      }).toList(),
    );
  }

  // Tarjeta de producto de inventario
  Widget _buildInventoryItemCard(
    BuildContext context,
    InventoryItem item,
    AdminController controller,
    bool isTablet,
  ) {
    final statusColor = InventoryStatus.getStatusColor(item.status);
    final progress = (item.currentStock / item.maxStock).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botones de ajuste de stock
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.red,
                        size: isTablet ? 24 : 20,
                      ),
                      onPressed: () => _showAdjustStockModal(
                        context,
                        item,
                        controller,
                        isTablet,
                        isDecrease: true,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.green,
                        size: isTablet ? 24 : 20,
                      ),
                      onPressed: () => _showAdjustStockModal(
                        context,
                        item,
                        controller,
                        isTablet,
                        isDecrease: false,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    IconButton(
                      icon: Icon(Icons.edit, size: isTablet ? 20 : 18),
                      color: AppColors.primary,
                      onPressed: () => _showEditInventoryModal(
                        context,
                        item,
                        controller,
                        isTablet,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    IconButton(
                      icon: Icon(Icons.delete, size: isTablet ? 20 : 18),
                      color: Colors.red,
                      onPressed: () =>
                          _showDeleteInventoryDialog(context, item, controller),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Categoría
            Chip(
              label: Text(
                item.category,
                style: TextStyle(
                  fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.secondary,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Stock con barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Actual: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: AppTheme.fontWeightSemibold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingXS),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
                SizedBox(height: AppTheme.spacingXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mín: ${item.minStock.toStringAsFixed(1)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Máx: ${item.maxStock.toStringAsFixed(1)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Información adicional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio Total: \$${item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Costo Unitario: \$${item.unitPrice.toStringAsFixed(2)}/${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item.supplier != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Proveedor:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        item.supplier!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: AppTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (item.lastRestock != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                'Última actualización: ${_formatDate(item.lastRestock!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTheme.fontSizeXS,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Modal para agregar producto al inventario
  void _showAddInventoryModal(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    final maxStockController = TextEditingController();
    final costController = TextEditingController();
    final supplierController = TextEditingController();
    final unitController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar al Inventario'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        'Carne',
                        'Tortillas',
                        'Condimentos',
                        'Bebidas',
                        'Otros',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidad *',
                    border: OutlineInputBorder(),
                    hintText: 'kg, g, ml, unidades...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Actual *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: minStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Mínimo *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: maxStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Máximo *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Costo Unitario (\$) *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final stock = double.parse(stockController.text);
                final minStock = double.parse(minStockController.text);
                final maxStock = double.parse(maxStockController.text);
                final cost = double.parse(costController.text);
                final totalPrice = stock * cost;

                // Determinar status según stock
                String status;
                if (stock <= 0) {
                  status = InventoryStatus.outOfStock;
                } else if (stock < minStock) {
                  status = InventoryStatus.lowStock;
                } else {
                  status = InventoryStatus.available;
                }

                final newItem = InventoryItem(
                  id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  category: selectedCategory!,
                  currentStock: stock,
                  minStock: minStock,
                  maxStock: maxStock,
                  minimumStock: minStock,
                  unit: unitController.text,
                  cost: cost,
                  price: totalPrice,
                  unitPrice: cost,
                  supplier: supplierController.text.isEmpty
                      ? null
                      : supplierController.text,
                  lastRestock: DateTime.now(),
                  status: status,
                );
                controller.addInventoryItem(newItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Producto agregado al inventario exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar al Inventario'),
          ),
        ],
      ),
    );
  }

  // Modal para editar inventario
  void _showEditInventoryModal(
    BuildContext context,
    InventoryItem item,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final stockController = TextEditingController(
      text: item.currentStock.toStringAsFixed(1),
    );
    final minStockController = TextEditingController(
      text: item.minStock.toStringAsFixed(1),
    );
    final maxStockController = TextEditingController(
      text: item.maxStock.toStringAsFixed(1),
    );
    final costController = TextEditingController(
      text: item.cost.toStringAsFixed(2),
    );
    final supplierController = TextEditingController(text: item.supplier ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Editar ${item.name}'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  enabled:
                      false, // El nombre no se puede editar según las imágenes
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Actual *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: minStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Mínimo *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: maxStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Máximo *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final stock = double.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Costo (\$) *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final stock = double.parse(stockController.text);
                final minStock = double.parse(minStockController.text);
                final maxStock = double.parse(maxStockController.text);
                final cost = double.parse(costController.text);
                final totalPrice = stock * cost;

                // Determinar status según stock
                String status;
                if (stock <= 0) {
                  status = InventoryStatus.outOfStock;
                } else if (stock < minStock) {
                  status = InventoryStatus.lowStock;
                } else {
                  status = InventoryStatus.available;
                }

                final updatedItem = item.copyWith(
                  currentStock: stock,
                  minStock: minStock,
                  maxStock: maxStock,
                  minimumStock: minStock,
                  cost: cost,
                  price: totalPrice,
                  unitPrice: cost,
                  supplier: supplierController.text.isEmpty
                      ? null
                      : supplierController.text,
                  lastRestock: DateTime.now(),
                  status: status,
                );
                controller.updateInventoryItem(updatedItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inventario actualizado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
  }

  // Modal para ajustar stock
  void _showAdjustStockModal(
    BuildContext context,
    InventoryItem item,
    AdminController controller,
    bool isTablet, {
    required bool isDecrease,
  }) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDecrease ? 'Disminuir Stock' : 'Aumentar Stock'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Stock actual: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: AppTheme.spacingMD),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText:
                      'Cantidad ${isDecrease ? 'a disminuir' : 'a aumentar'} *',
                  border: const OutlineInputBorder(),
                  suffixText: item.unit,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Debe ser un número válido mayor a 0';
                  }
                  if (isDecrease && quantity > item.currentStock) {
                    return 'No puede disminuir más del stock actual';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantity = double.parse(quantityController.text);
                final newStock = isDecrease
                    ? item.currentStock - quantity
                    : item.currentStock + quantity;

                // Determinar status según nuevo stock
                String status;
                if (newStock <= 0) {
                  status = InventoryStatus.outOfStock;
                } else if (newStock < item.minStock) {
                  status = InventoryStatus.lowStock;
                } else {
                  status = InventoryStatus.available;
                }

                final updatedItem = item.copyWith(
                  currentStock: newStock,
                  price: newStock * item.unitPrice,
                  lastRestock: DateTime.now(),
                  status: status,
                );
                controller.updateInventoryItem(updatedItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isDecrease
                          ? 'Stock disminuido exitosamente'
                          : 'Stock aumentado exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDecrease ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isDecrease ? 'Disminuir' : 'Aumentar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para eliminar producto de inventario
  void _showDeleteInventoryDialog(
    BuildContext context,
    InventoryItem item,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de eliminar "${item.name}" del inventario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteInventoryItem(item.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Producto "${item.name}" eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Vista de Gestión de Usuarios
  Widget _buildUsersManagementView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botón agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Usuarios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showNewUserModal(context, controller, isTablet),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Búsqueda y filtros
          _buildUsersSearchAndFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Lista de usuarios
          _buildUsersList(context, controller, isTablet, isDesktop),

          // Paginación
          if (controller.totalUserPages > 1)
            _buildUsersPagination(context, controller, isTablet),
        ],
      ),
    );
  }

  // Búsqueda y filtros de usuarios
  Widget _buildUsersSearchAndFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o usuario...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
          ),
          onChanged: (value) => controller.setSearchQuery(value),
        ),
        SizedBox(height: AppTheme.spacingMD),

        // Filtros
        Row(
          children: [
            // Filtro de roles
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedUserRole,
                decoration: const InputDecoration(
                  labelText: 'Todos los roles',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items:
                    [
                      'todos',
                      UserRole.mesero,
                      UserRole.cocinero,
                      UserRole.capitan,
                      UserRole.cajero,
                      UserRole.admin,
                    ].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role == 'todos'
                              ? 'Todos los roles'
                              : UserRole.getRoleText(role),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.setSelectedUserRole(value);
                  }
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingMD),

            // Filtro de estados
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedUserStatus,
                decoration: const InputDecoration(
                  labelText: 'Todos los estados',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: ['todos', 'activos', 'inactivos'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'todos'
                          ? 'Todos los estados'
                          : status == 'activos'
                          ? 'Activo'
                          : 'Inactivo',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.setSelectedUserStatus(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Lista de usuarios
  Widget _buildUsersList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final users = controller.paginatedUsers;

    if (users.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay usuarios para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return Card(
        child: _buildUsersTable(context, users, controller, isTablet),
      );
    } else {
      return Column(
        children: users.map((user) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildUserCard(context, user, controller, isTablet),
          );
        }).toList(),
      );
    }
  }

  // Tabla de usuarios (para tablet/desktop)
  Widget _buildUsersTable(
    BuildContext context,
    List<AdminUser> users,
    AdminController controller,
    bool isTablet,
  ) {
    return DataTable(
      columns: [
        DataColumn(
          label: Text(
            'Usuario',
            style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
          ),
        ),
        DataColumn(
          label: Text(
            'Nombre',
            style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
          ),
        ),
        DataColumn(
          label: Text(
            'Roles',
            style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
          ),
        ),
        DataColumn(
          label: Text(
            'Estado',
            style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
          ),
        ),
        DataColumn(
          label: Text(
            'Acciones',
            style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
          ),
        ),
      ],
      rows: users.map((user) {
        return DataRow(
          cells: [
            DataCell(Text(user.username)),
            DataCell(Text(user.name)),
            DataCell(
              Wrap(
                spacing: 4,
                children: user.roles.map((role) {
                  return Chip(
                    label: Text(
                      UserRole.getRoleText(role),
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: UserRole.getRoleColor(
                      role,
                    ).withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ),
            DataCell(
              Chip(
                label: Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
                backgroundColor: (user.isActive ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
              ),
            ),
            DataCell(
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'change_password',
                    child: const Row(
                      children: [
                        Icon(Icons.lock, size: 18),
                        SizedBox(width: 8),
                        Text('Cambiar contraseña'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditUserModal(context, user, controller, isTablet);
                  } else if (value == 'change_password') {
                    _showChangePasswordModal(
                      context,
                      user,
                      controller,
                      isTablet,
                    );
                  } else if (value == 'delete') {
                    _showDeleteUserDialog(context, user, controller);
                  }
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Tarjeta de usuario (para móvil)
  Widget _buildUserCard(
    BuildContext context,
    AdminUser user,
    AdminController controller,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppTheme.fontWeightBold),
                      ),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'change_password',
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 18),
                          SizedBox(width: 8),
                          Text('Cambiar contraseña'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditUserModal(context, user, controller, isTablet);
                    } else if (value == 'change_password') {
                      _showChangePasswordModal(
                        context,
                        user,
                        controller,
                        isTablet,
                      );
                    } else if (value == 'delete') {
                      _showDeleteUserDialog(context, user, controller);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Roles
            Wrap(
              spacing: AppTheme.spacingXS,
              runSpacing: AppTheme.spacingXS,
              children: user.roles.map((role) {
                return Chip(
                  label: Text(
                    UserRole.getRoleText(role),
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: UserRole.getRoleColor(
                    role,
                  ).withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Estado y teléfono
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  backgroundColor: (user.isActive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                ),
                if (user.phone != null)
                  Text(
                    user.phone!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppTheme.spacingXS),
            Text(
              'Creado: ${_formatDate(user.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: AppTheme.fontSizeXS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Paginación de usuarios
  Widget _buildUsersPagination(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.currentUserPage > 1
                ? () => controller.previousUserPage()
                : null,
          ),
          ...List.generate(
            controller.totalUserPages > 5 ? 5 : controller.totalUserPages,
            (index) {
              int page;
              if (controller.totalUserPages <= 5) {
                page = index + 1;
              } else {
                // Mostrar páginas alrededor de la actual
                if (controller.currentUserPage <= 3) {
                  page = index + 1;
                } else if (controller.currentUserPage >=
                    controller.totalUserPages - 2) {
                  page = controller.totalUserPages - 4 + index;
                } else {
                  page = controller.currentUserPage - 2 + index;
                }
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TextButton(
                  onPressed: () => controller.setUserPage(page),
                  style: TextButton.styleFrom(
                    backgroundColor: controller.currentUserPage == page
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: controller.currentUserPage == page
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: controller.currentUserPage == page
                          ? AppTheme.fontWeightSemibold
                          : AppTheme.fontWeightNormal,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.currentUserPage < controller.totalUserPages
                ? () => controller.nextUserPage()
                : null,
          ),
        ],
      ),
    );
  }

  // Modal para nuevo usuario
  void _showNewUserModal(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    List<String> selectedRoles = [];
    bool isPasswordVisible = false;
    PasswordStrength? passwordStrength;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario *',
                      border: OutlineInputBorder(),
                      hintText: 'minúsculas, 3-20 caracteres',
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (value.length < 3 || value.length > 20) {
                        return 'Debe tener entre 3 y 20 caracteres';
                      }
                      if (value != value.toLowerCase()) {
                        return 'Solo se permiten minúsculas';
                      }
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                        return 'Solo letras, números y guiones bajos';
                      }
                      if (controller.usernameExists(value)) {
                        return 'El nombre de usuario ya existe';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Convertir a minúsculas automáticamente
                      if (value != value.toLowerCase()) {
                        usernameController.value = TextEditingValue(
                          text: value.toLowerCase(),
                          selection: TextSelection.collapsed(
                            offset: value.length,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña *',
                            border: const OutlineInputBorder(),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          obscureText: !isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obligatorio';
                            }
                            if (value.length < 8) {
                              return 'Mínimo 8 caracteres';
                            }
                            final strength = controller
                                .validatePasswordStrength(value);
                            if (strength == PasswordStrength.weak) {
                              return 'Contraseña débil';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              passwordStrength = controller
                                  .validatePasswordStrength(value);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      ElevatedButton(
                        onPressed: () {
                          final generated = controller.generatePassword();
                          passwordController.text = generated;
                          setState(() {
                            isPasswordVisible = true;
                            passwordStrength = controller
                                .validatePasswordStrength(generated);
                          });
                        },
                        child: const Text('Generar'),
                      ),
                    ],
                  ),
                  if (passwordStrength != null) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: passwordStrength == PasswordStrength.weak
                                ? 0.33
                                : passwordStrength == PasswordStrength.medium
                                ? 0.66
                                : 1.0,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              passwordStrength!.color,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSM),
                        Text(
                          passwordStrength!.text,
                          style: TextStyle(
                            color: passwordStrength!.color,
                            fontSize: 12,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Requisitos: mínimo 8 caracteres, mayúscula, minúscula, número',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                      hintText: 'Opcional',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  const Text(
                    'Roles *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  ...UserRole.allRoles.map((role) {
                    return CheckboxListTile(
                      title: Text(UserRole.getRoleText(role)),
                      value: selectedRoles.contains(role),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (selectedRoles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debe seleccionar al menos un rol'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final newUser = AdminUser(
                    id: controller.getNextUserId(),
                    name: nameController.text,
                    username: usernameController.text.toLowerCase(),
                    phone: phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    roles: selectedRoles,
                    isActive: true,
                    createdAt: DateTime.now(),
                    createdBy: 'current_admin',
                  );
                  controller.addUser(newUser);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario creado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear Usuario'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para editar usuario
  void _showEditUserModal(
    BuildContext context,
    AdminUser user,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user.username);
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    List<String> selectedRoles = List.from(user.roles);
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editar Usuario'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (value.length < 3 || value.length > 20) {
                        return 'Debe tener entre 3 y 20 caracteres';
                      }
                      if (value != value.toLowerCase()) {
                        return 'Solo se permiten minúsculas';
                      }
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                        return 'Solo letras, números y guiones bajos';
                      }
                      if (controller.usernameExists(
                        value,
                        excludeId: user.id,
                      )) {
                        return 'El nombre de usuario ya existe';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value != value.toLowerCase()) {
                        usernameController.value = TextEditingValue(
                          text: value.toLowerCase(),
                          selection: TextSelection.collapsed(
                            offset: value.length,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  const Text(
                    'Roles *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  ...UserRole.allRoles.map((role) {
                    return CheckboxListTile(
                      title: Text(UserRole.getRoleText(role)),
                      value: selectedRoles.contains(role),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRoles.add(role);
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    );
                  }).toList(),
                  SizedBox(height: AppTheme.spacingMD),
                  SwitchListTile(
                    title: const Text('Estado del usuario'),
                    subtitle: const Text('Puede acceder al sistema'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fecha de creación:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        _formatDate(user.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: AppTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Última actualización:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        DateTime.now().isAfter(user.createdAt)
                            ? _formatDate(DateTime.now())
                            : _formatDate(user.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: AppTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _showDeleteUserDialog(context, user, controller);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                // Restablecer - volver a valores originales
                Navigator.of(context).pop();
              },
              child: const Text('Restablecer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (selectedRoles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debe seleccionar al menos un rol'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final updatedUser = user.copyWith(
                    username: usernameController.text.toLowerCase(),
                    name: nameController.text,
                    phone: phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    roles: selectedRoles,
                    isActive: isActive,
                  );
                  controller.updateUser(updatedUser);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para cambiar contraseña
  void _showChangePasswordModal(
    BuildContext context,
    AdminUser user,
    AdminController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    PasswordStrength? passwordStrength;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como administrador, puedes establecer la contraseña sin conocer la contraseña anterior del usuario.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña *',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obligatorio';
                            }
                            if (value.length < 8) {
                              return 'Mínimo 8 caracteres';
                            }
                            final strength = controller
                                .validatePasswordStrength(value);
                            if (strength == PasswordStrength.weak) {
                              return 'Contraseña débil';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              passwordStrength = controller
                                  .validatePasswordStrength(value);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      ElevatedButton(
                        onPressed: () {
                          final generated = controller.generatePassword();
                          passwordController.text = generated;
                          setState(() {
                            isPasswordVisible = true;
                            passwordStrength = controller
                                .validatePasswordStrength(generated);
                          });
                        },
                        child: const Text('Generar'),
                      ),
                    ],
                  ),
                  if (passwordStrength != null) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    LinearProgressIndicator(
                      value: passwordStrength == PasswordStrength.weak
                          ? 0.33
                          : passwordStrength == PasswordStrength.medium
                          ? 0.66
                          : 1.0,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        passwordStrength!.color,
                      ),
                      minHeight: 4,
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nueva contraseña *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isConfirmPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      if (value != passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requisitos de contraseña:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: AppTheme.fontWeightSemibold,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXS),
                        _buildRequirementItem(
                          'Mínimo 8 caracteres',
                          passwordController.text.length >= 8,
                        ),
                        _buildRequirementItem(
                          'Una letra mayúscula',
                          passwordController.text.contains(RegExp(r'[A-Z]')),
                        ),
                        _buildRequirementItem(
                          'Una letra minúscula',
                          passwordController.text.contains(RegExp(r'[a-z]')),
                        ),
                        _buildRequirementItem(
                          'Un número',
                          passwordController.text.contains(RegExp(r'[0-9]')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  controller.changeUserPassword(
                    user.id,
                    passwordController.text,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Establecer contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para item de requisito de contraseña
  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.spacingXS),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : AppColors.textSecondary,
          ),
          SizedBox(width: AppTheme.spacingXS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXS,
              color: isMet ? Colors.green : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo para eliminar usuario
  void _showDeleteUserDialog(
    BuildContext context,
    AdminUser user,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar el usuario "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteUser(user.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usuario "${user.name}" eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Vista de Gestión de Tickets
  Widget _buildTicketsManagementView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botón exportar CSV
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Tickets',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  controller.exportTicketsToCSV();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exportando tickets a CSV...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Búsqueda y filtros
          _buildTicketsSearchAndFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Tabla/Lista de tickets
          _buildTicketsList(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Búsqueda y filtros de tickets
  Widget _buildTicketsSearchAndFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por ID, mesa, cuenta o impreso por...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
          ),
          onChanged: (value) => controller.setSearchQuery(value),
        ),
        SizedBox(height: AppTheme.spacingMD),

        // Filtro de estados
        DropdownButtonFormField<String>(
          value: controller.selectedTicketStatus,
          decoration: const InputDecoration(
            labelText: 'Todos los estados',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items:
              [
                    'todos',
                    payment_models.BillStatus.pending,
                    payment_models.BillStatus.printed,
                    payment_models.BillStatus.delivered,
                  ]
                  .map<String>((status) {
                    return status;
                  })
                  .map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status == 'todos'
                            ? 'Todos los estados'
                            : payment_models.BillStatus.getStatusText(status),
                      ),
                    );
                  })
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.setSelectedTicketStatus(value);
            }
          },
        ),
      ],
    );
  }

  // Lista de tickets
  Widget _buildTicketsList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final tickets = controller.filteredTickets;

    if (tickets.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay tickets para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return Card(
        child: _buildTicketsTable(context, tickets, controller, isTablet),
      );
    } else {
      return Column(
        children: tickets.map((ticket) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildTicketCard(context, ticket, controller, isTablet),
          );
        }).toList(),
      );
    }
  }

  // Tabla de tickets (para tablet/desktop)
  Widget _buildTicketsTable(
    BuildContext context,
    List<payment_models.BillModel> tickets,
    AdminController controller,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'ID',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Mesa',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Cuenta ID',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Impreso por',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Fecha/Hora',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Acciones',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
        ],
        rows: tickets.map((ticket) {
          return DataRow(
            cells: [
              DataCell(Text(ticket.id)),
              DataCell(Text(ticket.tableNumber?.toString() ?? 'N/A')),
              DataCell(Text(ticket.id)),
              DataCell(Text('\$${ticket.total.toStringAsFixed(2)}')),
              DataCell(
                Chip(
                  label: Text(
                    payment_models.BillStatus.getStatusText(ticket.status),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: payment_models.BillStatus.getStatusColor(
                    ticket.status,
                  ),
                ),
              ),
              DataCell(Text(ticket.printedBy ?? 'N/A')),
              DataCell(Text(_formatDate(ticket.createdAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      color: AppColors.primary,
                      onPressed: () =>
                          _showTicketDetailsModal(context, ticket, isTablet),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    if (ticket.status != payment_models.BillStatus.printed &&
                        ticket.status != payment_models.BillStatus.delivered)
                      IconButton(
                        icon: const Icon(Icons.print, size: 18),
                        color: AppColors.primary,
                        onPressed: () =>
                            _showPrintTicketDialog(context, ticket, controller),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    SizedBox(width: AppTheme.spacingXS),
                    if (ticket.status == payment_models.BillStatus.printed &&
                        ticket.status != payment_models.BillStatus.delivered)
                      IconButton(
                        icon: const Icon(Icons.check_circle, size: 18),
                        color: Colors.green,
                        onPressed: () =>
                            _markTicketAsDelivered(context, ticket, controller),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Tarjeta de ticket (para móvil)
  Widget _buildTicketCard(
    BuildContext context,
    payment_models.BillModel ticket,
    AdminController controller,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.id,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppTheme.fontWeightBold),
                      ),
                      if (ticket.tableNumber != null)
                        Text(
                          'Mesa ${ticket.tableNumber}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        )
                      else if (ticket.isTakeaway)
                        Text(
                          'Para llevar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    payment_models.BillStatus.getStatusText(ticket.status),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: payment_models.BillStatus.getStatusColor(
                    ticket.status,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${ticket.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: AppTheme.fontWeightSemibold,
                  ),
                ),
                Text(
                  _formatDate(ticket.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (ticket.printedBy != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                'Impreso por: ${ticket.printedBy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTheme.fontSizeXS,
                ),
              ),
            ],
            SizedBox(height: AppTheme.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  color: AppColors.primary,
                  onPressed: () =>
                      _showTicketDetailsModal(context, ticket, isTablet),
                ),
                if (ticket.status != payment_models.BillStatus.printed &&
                    ticket.status != payment_models.BillStatus.delivered) ...[
                  IconButton(
                    icon: const Icon(Icons.print),
                    color: AppColors.primary,
                    onPressed: () =>
                        _showPrintTicketDialog(context, ticket, controller),
                  ),
                ],
                if (ticket.status == payment_models.BillStatus.printed &&
                    ticket.status != payment_models.BillStatus.delivered) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    color: Colors.green,
                    onPressed: () =>
                        _markTicketAsDelivered(context, ticket, controller),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal de detalles del ticket
  void _showTicketDetailsModal(
    BuildContext context,
    payment_models.BillModel ticket,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Ticket'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mesa: ${ticket.tableNumber ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Total: \$${ticket.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMD),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingSM),
              ...ticket.items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacingXS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}'),
                      Text('\$${item.total.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para imprimir ticket
  void _showPrintTicketDialog(
    BuildContext context,
    payment_models.BillModel ticket,
    AdminController controller,
  ) {
    final tableText = ticket.tableNumber != null
        ? 'Mesa ${ticket.tableNumber}'
        : ticket.isTakeaway
        ? 'Para llevar'
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimir Ticket'),
        content: Text('¿Imprimir ticket para $tableText?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.printTicket(ticket.id, 'Admin');
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ticket impreso: $tableText. Notificación enviada al mesero.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  // Marcar ticket como entregado
  void _markTicketAsDelivered(
    BuildContext context,
    payment_models.BillModel ticket,
    AdminController controller,
  ) {
    controller.markTicketAsDelivered(ticket.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket marcado como entregado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Vista de Cierre de Caja
  Widget _buildCashClosuresView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cierre de Caja',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.exportCashClosuresToCSV();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exportando reporte en formato CSV...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exportar CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMD),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.generateCashClosuresPDF();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generando reporte en formato PDF...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Filtros de fecha
          _buildCashCloseDateFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Tabla/Lista de cierres
          _buildCashClosuresList(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Filtros de fecha para cierre de caja
  Widget _buildCashCloseDateFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Filtros de período
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...['hoy', 'ayer', 'semana', 'mes', 'personalizado'].map((
                period,
              ) {
                final isSelected = controller.selectedCashClosePeriod == period;
                final labels = {
                  'hoy': 'Hoy',
                  'ayer': 'Ayer',
                  'semana': 'Última semana',
                  'mes': 'Mes actual',
                  'personalizado': 'Rango personalizado',
                };
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      labels[period]!,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: isSelected
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedCashClosePeriod(period);
                      }
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Campos de fecha personalizada
        if (controller.selectedCashClosePeriod == 'personalizado') ...[
          SizedBox(height: AppTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          controller.cashCloseStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final endDate =
                          controller.cashCloseEndDate ?? DateTime.now();
                      controller.setCashCloseDateRange(date, endDate);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.cashCloseStartDate != null
                              ? _formatDate(controller.cashCloseStartDate!)
                              : 'Fecha inicio',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          controller.cashCloseEndDate ?? DateTime.now(),
                      firstDate:
                          controller.cashCloseStartDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final startDate =
                          controller.cashCloseStartDate ?? DateTime.now();
                      controller.setCashCloseDateRange(startDate, date);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.cashCloseEndDate != null
                              ? _formatDate(controller.cashCloseEndDate!)
                              : 'Fecha fin',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingMD),
              ElevatedButton(
                onPressed: () {
                  if (controller.cashCloseStartDate != null &&
                      controller.cashCloseEndDate != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filtro aplicado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Lista de cierres de caja
  Widget _buildCashClosuresList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final closures = controller.filteredCashClosures;

    if (closures.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay cierres de caja para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return Card(
        child: _buildCashClosuresTable(context, closures, controller, isTablet),
      );
    } else {
      return Column(
        children: closures.map((closure) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildCashCloseCard(context, closure, controller, isTablet),
          );
        }).toList(),
      );
    }
  }

  // Tabla de cierres de caja (para tablet/desktop)
  Widget _buildCashClosuresTable(
    BuildContext context,
    List<CashCloseModel> closures,
    AdminController controller,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Fecha/Periodo',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Usuario',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Tipo',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Neto',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Efectivo',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Tarjeta',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Propinas (T)',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Propinas (E)',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Para llevar',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Acciones',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
        ],
        rows: closures.map((closure) {
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(closure.fecha))),
              DataCell(Text(closure.usuario)),
              DataCell(Text(closure.periodo)),
              DataCell(Text('\$${closure.totalNeto.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.efectivo.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.tarjeta.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.propinasTarjeta.toStringAsFixed(2)}')),
              DataCell(
                Text('\$${closure.propinasEfectivo.toStringAsFixed(2)}'),
              ),
              DataCell(Text('${closure.pedidosParaLlevar}')),
              DataCell(
                Chip(
                  label: Text(
                    CashCloseStatus.getStatusText(closure.estado),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: CashCloseStatus.getStatusColor(
                    closure.estado,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  color: AppColors.primary,
                  onPressed: () => _showCashCloseDetailsModal(
                    context,
                    closure,
                    controller,
                    isTablet,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Tarjeta de cierre de caja (para móvil)
  Widget _buildCashCloseCard(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(closure.fecha),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppTheme.fontWeightBold),
                      ),
                      Text(
                        closure.usuario,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    CashCloseStatus.getStatusText(closure.estado),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: CashCloseStatus.getStatusColor(
                    closure.estado,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${closure.totalNeto.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppTheme.fontWeightSemibold,
                      ),
                    ),
                    Text(
                      'Efectivo: \$${closure.efectivo.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Tarjeta: \$${closure.tarjeta.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  color: AppColors.primary,
                  onPressed: () => _showCashCloseDetailsModal(
                    context,
                    closure,
                    controller,
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

  // Modal de detalles del cierre de caja
  void _showCashCloseDetailsModal(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
    bool isTablet,
  ) {
    final isPending = closure.estado == CashCloseStatus.pending;
    final isClarification = closure.estado == CashCloseStatus.clarification;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Detalle del cierre'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información básica
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cierre de caja: ${closure.id}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Chip(
                      label: Text(
                        CashCloseStatus.getStatusText(closure.estado),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: CashCloseStatus.getStatusColor(
                        closure.estado,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingSM),
                Text('Usuario: ${closure.usuario}'),
                Text('Tipo: ${closure.periodo}'),
                Text(
                  'Estado: ${CashCloseStatus.getStatusText(closure.estado)}',
                ),
                SizedBox(height: AppTheme.spacingMD),

                // Tarjetas de resumen
                Wrap(
                  spacing: AppTheme.spacingSM,
                  runSpacing: AppTheme.spacingSM,
                  children: [
                    _buildSummaryCard(
                      'Total Neto',
                      '\$${closure.totalNeto.toStringAsFixed(2)}',
                      AppColors.primary,
                      isTablet,
                    ),
                    _buildSummaryCard(
                      'Efectivo Contado',
                      '\$${closure.efectivoContado.toStringAsFixed(2)}',
                      Colors.green,
                      isTablet,
                    ),
                    _buildSummaryCard(
                      'Tarjeta Total',
                      '\$${closure.totalTarjeta.toStringAsFixed(2)}',
                      Colors.blue,
                      isTablet,
                    ),
                    _buildSummaryCard(
                      'Propinas Tarjeta',
                      '\$${closure.propinasTarjeta.toStringAsFixed(2)}',
                      Colors.purple,
                      isTablet,
                    ),
                    _buildSummaryCard(
                      'Propinas Efectivo',
                      '\$${closure.propinasEfectivo.toStringAsFixed(2)}',
                      Colors.orange,
                      isTablet,
                    ),
                    if (closure.otrosIngresos > 0)
                      _buildSummaryCard(
                        'Otros Ingresos',
                        '\$${closure.otrosIngresos.toStringAsFixed(2)}',
                        Colors.teal,
                        isTablet,
                      ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),

                // Movimientos individuales (simulado - en producción vendría de la BD)
                const Text(
                  'Movimientos Individuales',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppTheme.spacingSM),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Text(
                    'Los movimientos individuales se mostrarán aquí cuando estén disponibles.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Historial de auditoría
                if (closure.auditLog.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingMD),
                  const Text(
                    'Historial de Auditoría',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  ...closure.auditLog.map((log) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingXS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.primary),
                          SizedBox(width: AppTheme.spacingSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log.usuario}: ${log.mensaje}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  _formatDate(log.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: AppTheme.fontSizeXS,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                // Botones de acción si está pendiente
                if (isPending || isClarification) ...[
                  SizedBox(height: AppTheme.spacingMD),
                  if (isClarification)
                    ElevatedButton.icon(
                      onPressed: () {
                        final reasonController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Solicitar Aclaración'),
                            content: TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                labelText: 'Razón de la aclaración *',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (reasonController.text.isNotEmpty) {
                                    controller.requestCashCloseClarification(
                                      closure.id,
                                      reasonController.text,
                                    );
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Aclaración solicitada'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Enviar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Solicitar aclaración'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  SizedBox(width: AppTheme.spacingSM),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.markCashCloseAsVerified(closure.id);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cierre marcado como verificado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marcar verificado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                controller.generateCashClosuresPDF();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generando detalle en PDF...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir detalle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para tarjeta de resumen
  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    bool isTablet,
  ) {
    return Container(
      width: isTablet ? 150 : 120,
      padding: EdgeInsets.all(AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? AppTheme.fontSizeLG : AppTheme.fontSizeSM,
              fontWeight: AppTheme.fontWeightBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Revisar Cierres de Cajeros
  Widget _buildReviewCashiersClosuresView(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revisar Cierres de Cajeros',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: AppTheme.fontWeightBold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Filtros
          _buildReviewCashiersFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Tarjetas de resumen
          _buildReviewCashiersSummaryCards(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Lista de cierres
          _buildReviewCashiersList(context, controller, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Filtros para revisar cierres de cajeros
  Widget _buildReviewCashiersFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por cajero...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                onChanged: (value) => controller.setCashCloseSearchQuery(value),
              ),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedCashCloseStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                      'todos',
                      CashCloseStatus.pending,
                      CashCloseStatus.approved,
                      CashCloseStatus.clarification,
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status == 'todos'
                              ? 'Todos los estados'
                              : CashCloseStatus.getStatusText(status),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.setSelectedCashCloseStatus(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tarjetas de resumen para revisar cierres
  Widget _buildReviewCashiersSummaryCards(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final closures = controller.filteredCashClosures;
    final totalDeclarado = closures.fold(
      0.0,
      (sum, c) => sum + c.totalDeclarado,
    );
    final totalEfectivo = closures.fold(
      0.0,
      (sum, c) => sum + c.efectivoContado,
    );
    final totalTarjeta = closures.fold(0.0, (sum, c) => sum + c.totalTarjeta);
    final verifiedCount = closures
        .where((c) => c.estado == CashCloseStatus.approved)
        .length;
    final clarificationCount = closures
        .where((c) => c.estado == CashCloseStatus.clarification)
        .length;
    final pendingCount = closures
        .where((c) => c.estado == CashCloseStatus.pending)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Declarado',
            '\$${totalDeclarado.toStringAsFixed(2)}',
            AppColors.primary,
            isTablet,
          ),
        ),
        SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: _buildSummaryCard(
            'Efectivo Contado',
            '\$${totalEfectivo.toStringAsFixed(2)}',
            Colors.green,
            isTablet,
          ),
        ),
        SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: _buildSummaryCard(
            'Total Tarjeta',
            '\$${totalTarjeta.toStringAsFixed(2)}',
            Colors.blue,
            isTablet,
          ),
        ),
        SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingSM),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cierres Totales',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  '${closures.length}',
                  style: TextStyle(
                    fontSize: isTablet
                        ? AppTheme.fontSizeLG
                        : AppTheme.fontSizeSM,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  '✓ ${verifiedCount} | ⚠ ${clarificationCount} | ⏳ ${pendingCount}',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Lista de cierres de cajeros para revisar
  Widget _buildReviewCashiersList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final closures = controller.filteredCashClosures;

    if (closures.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay cierres para revisar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return Card(
        child: _buildReviewCashiersTable(
          context,
          closures,
          controller,
          isTablet,
        ),
      );
    } else {
      return Column(
        children: closures.map((closure) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildReviewCashierCard(
              context,
              closure,
              controller,
              isTablet,
            ),
          );
        }).toList(),
      );
    }
  }

  // Tabla para revisar cierres de cajeros
  Widget _buildReviewCashiersTable(
    BuildContext context,
    List<CashCloseModel> closures,
    AdminController controller,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Fecha',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Cajero',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Efectivo contado',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total tarjeta',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Otros ingresos',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total declarado',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
          DataColumn(
            label: Text(
              'Acciones',
              style: TextStyle(fontWeight: AppTheme.fontWeightSemibold),
            ),
          ),
        ],
        rows: closures.map((closure) {
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(closure.fecha))),
              DataCell(Text(closure.usuario)),
              DataCell(Text('\$${closure.efectivoContado.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.totalTarjeta.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.otrosIngresos.toStringAsFixed(2)}')),
              DataCell(Text('\$${closure.totalDeclarado.toStringAsFixed(2)}')),
              DataCell(
                Chip(
                  label: Text(
                    CashCloseStatus.getStatusText(closure.estado),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: CashCloseStatus.getStatusColor(
                    closure.estado,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  color: AppColors.primary,
                  onPressed: () => _showCashierClosureDetailsModal(
                    context,
                    closure,
                    controller,
                    isTablet,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Tarjeta de cierre de cajero (para móvil)
  Widget _buildReviewCashierCard(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingMD : AppTheme.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        closure.usuario,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppTheme.fontWeightBold),
                      ),
                      Text(
                        _formatDate(closure.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    CashCloseStatus.getStatusText(closure.estado),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: CashCloseStatus.getStatusColor(
                    closure.estado,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: \$${closure.totalDeclarado.toStringAsFixed(2)}'),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  color: AppColors.primary,
                  onPressed: () => _showCashierClosureDetailsModal(
                    context,
                    closure,
                    controller,
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

  // Modal de detalles del cierre de cajero
  void _showCashierClosureDetailsModal(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle del cierre'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información básica
              Text('Cierre de caja: ${closure.id}'),
              Text('Fecha: ${_formatDate(closure.fecha)}'),
              Text('Usuario: ${closure.usuario}'),
              Text('Tipo: ${closure.periodo}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estado:'),
                  Chip(
                    label: Text(
                      CashCloseStatus.getStatusText(closure.estado),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: CashCloseStatus.getStatusColor(
                      closure.estado,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMD),

              // Información del cierre
              const Text(
                'Información del Cierre',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingSM),
              _buildInfoRow(
                context,
                'Efectivo contado hoy',
                '\$${closure.efectivoContado.toStringAsFixed(2)}',
              ),
              _buildInfoRow(
                context,
                'Total tarjeta',
                '\$${closure.totalTarjeta.toStringAsFixed(2)}',
              ),
              if (closure.otrosIngresos > 0)
                _buildInfoRow(
                  context,
                  'Otros ingresos',
                  '\$${closure.otrosIngresos.toStringAsFixed(2)}',
                ),
              _buildInfoRow(
                context,
                'Total declarado',
                '\$${closure.totalDeclarado.toStringAsFixed(2)}',
              ),
              SizedBox(height: AppTheme.spacingMD),

              // Historial de auditoría
              const Text(
                'Historial de Auditoría',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingSM),
              ...closure.auditLog.map((log) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacingXS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (log.action == 'enviado')
                        Text(
                          'Cierre enviado por: ${log.usuario}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (log.action == 'aclaracion_solicitada')
                        Text(
                          'Aclaración solicitada por: ${log.usuario}\nRazón: ${log.mensaje}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        ),
                      if (log.action == 'verificado' ||
                          log.action == 'aprobado')
                        Text(
                          'Verificado por: ${log.usuario}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.green),
                        ),
                      Text(
                        _formatDate(log.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: AppTheme.fontSizeXS,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Botones de acción si requiere aclaración
              if (closure.estado == CashCloseStatus.clarification ||
                  closure.estado == CashCloseStatus.pending) ...[
                SizedBox(height: AppTheme.spacingMD),
                if (closure.estado == CashCloseStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () {
                      final reasonController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Solicitar Aclaración'),
                          content: TextField(
                            controller: reasonController,
                            decoration: const InputDecoration(
                              labelText: 'Razón de la aclaración *',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (reasonController.text.isNotEmpty) {
                                  controller.requestCashCloseClarification(
                                    closure.id,
                                    reasonController.text,
                                  );
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Aclaración solicitada'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Enviar'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Solicitar aclaración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                SizedBox(width: AppTheme.spacingSM),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.markCashCloseAsVerified(closure.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cierre marcado como verificado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marcar verificado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              controller.generateCashClosuresPDF();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generando detalle en PDF...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir detalle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para fila de información
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Filtros de Cocina (idéntica a la del Cocinero)
  Widget _buildKitchenFiltersView(
    BuildContext context,
    AdminController adminController,
    CocineroController cocineroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros de Cocina
          _buildKitchenFiltersCard(context, cocineroController, isTablet),
          const SizedBox(height: 24),

          // Estadísticas rápidas
          _buildKitchenStatsCards(cocineroController, isTablet),
          const SizedBox(height: 24),

          // Lista de pedidos
          _buildKitchenOrdersList(
            context,
            cocineroController,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenFiltersCard(
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
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildKitchenStationFilter(
                          cocineroController,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKitchenStatusFilter(
                          cocineroController,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKitchenShowFilter(
                          cocineroController,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKitchenAlertFilter(
                          cocineroController,
                          isTablet,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildKitchenStationFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildKitchenStatusFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildKitchenShowFilter(cocineroController, isTablet),
                      const SizedBox(height: 12),
                      _buildKitchenAlertFilter(cocineroController, isTablet),
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

  Widget _buildKitchenStationFilter(
    CocineroController controller,
    bool isTablet,
  ) {
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
                  child: Text('Todas las Estaciones'),
                ),
                DropdownMenuItem(value: 'tacos', child: Text('Tacos')),
                DropdownMenuItem(value: 'consomes', child: Text('Consomes')),
                DropdownMenuItem(value: 'bebidas', child: Text('Bebidas')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKitchenStatusFilter(
    CocineroController controller,
    bool isTablet,
  ) {
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKitchenShowFilter(CocineroController controller, bool isTablet) {
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

  Widget _buildKitchenAlertFilter(
    CocineroController controller,
    bool isTablet,
  ) {
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

  Widget _buildKitchenStatsCards(CocineroController controller, bool isTablet) {
    final stats = controller.getOrderStats();
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${stats['pendiente'] ?? 0}',
                    style: TextStyle(
                      fontSize: isTablet ? 24.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pendientes',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${stats['en_preparacion'] ?? 0}',
                    style: TextStyle(
                      fontSize: isTablet ? 24.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'En Preparación',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${(stats['listo'] ?? 0) + (stats['listo_para_recoger'] ?? 0)}',
                    style: TextStyle(
                      fontSize: isTablet ? 24.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listos',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKitchenOrdersList(
    BuildContext context,
    CocineroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final orders = controller.filteredOrders;

    if (orders.isEmpty) {
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
          (order) => Card(
            margin: EdgeInsets.only(bottom: isTablet ? 20.0 : 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                OrderDetailModal.show(
                  context,
                  order: order,
                  controller: controller,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.isTakeaway
                              ? 'Para llevar'
                              : 'Mesa ${order.tableNumber}',
                          style: TextStyle(
                            fontSize: isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: controller
                                .getStatusColor(order.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            OrderStatus.getStatusText(order.status),
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 10.0,
                              fontWeight: FontWeight.w600,
                              color: controller.getStatusColor(order.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hace ${controller.formatElapsedTime(order.orderTime)}',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget separado para el formulario de ingrediente
class _IngredientFormWidget extends StatefulWidget {
  final AdminController controller;
  final List<RecipeIngredient> ingredients;
  final Function(List<RecipeIngredient>) onSave;

  const _IngredientFormWidget({
    required this.controller,
    required this.ingredients,
    required this.onSave,
  });

  @override
  State<_IngredientFormWidget> createState() => _IngredientFormWidgetState();
}

class _IngredientFormWidgetState extends State<_IngredientFormWidget> {
  final formKey = GlobalKey<FormState>();
  String? selectedSuggested;
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final quantityController = TextEditingController();
  bool isCustom = false;
  bool autoDeduct = true;

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCustom
                ? 'Agregar ingrediente personalizado'
                : 'Agregar ingrediente',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: AppTheme.fontWeightSemibold,
            ),
          ),
          SizedBox(height: AppTheme.spacingMD),
          if (!isCustom)
            DropdownButtonFormField<String>(
              value: selectedSuggested,
              decoration: const InputDecoration(
                labelText: 'Ingrediente sugerido',
                border: OutlineInputBorder(),
              ),
              items: widget.controller.getSuggestedIngredients().map((
                ingredient,
              ) {
                return DropdownMenuItem(
                  value: ingredient,
                  child: Text(ingredient),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSuggested = value;
                  if (value != null) {
                    // Parsear nombre y unidad del sugerido
                    final parts = value.split(' ');
                    if (parts.length >= 2) {
                      nameController.text = parts
                          .sublist(0, parts.length - 1)
                          .join(' ');
                      unitController.text = parts.last;
                    }
                  }
                });
              },
            ),
          if (isCustom) ...[
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obligatorio';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unidad *',
                border: OutlineInputBorder(),
                hintText: 'ml, g, unidades...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obligatorio';
                }
                return null;
              },
            ),
          ],
          SizedBox(height: AppTheme.spacingMD),
          TextFormField(
            controller: quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad por porción *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obligatorio';
              }
              final quantity = double.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'Debe ser un número válido';
              }
              return null;
            },
          ),
          SizedBox(height: AppTheme.spacingMD),
          SwitchListTile(
            title: const Text('Descontar automáticamente'),
            value: autoDeduct,
            onChanged: (value) {
              setState(() {
                autoDeduct = value;
              });
            },
          ),
          SizedBox(height: AppTheme.spacingMD),
          if (!isCustom)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  isCustom = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar ingrediente personalizado'),
            ),
          SizedBox(height: AppTheme.spacingMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  nameController.clear();
                  unitController.clear();
                  quantityController.clear();
                  setState(() {
                    selectedSuggested = null;
                    isCustom = false;
                  });
                },
                child: const Text('Cancelar'),
              ),
              SizedBox(width: AppTheme.spacingSM),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (nameController.text.isEmpty ||
                        unitController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Debe completar todos los campos requeridos',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    final newIngredient = RecipeIngredient(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      unit: unitController.text,
                      quantityPerPortion: double.parse(quantityController.text),
                      autoDeduct: autoDeduct,
                      isCustom: isCustom,
                    );
                    final updatedIngredients = [
                      ...widget.ingredients,
                      newIngredient,
                    ];
                    widget.onSave(updatedIngredients);
                    nameController.clear();
                    unitController.clear();
                    quantityController.clear();
                    setState(() {
                      selectedSuggested = null;
                      isCustom = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
