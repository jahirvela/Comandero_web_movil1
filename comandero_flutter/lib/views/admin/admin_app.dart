import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cocinero_controller.dart';
import '../../models/admin_model.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart' as payment_models;
import '../../services/payment_repository.dart';
import '../../utils/app_colors.dart';
import '../../widgets/logout_button.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../cocinero/order_detail_modal.dart';
import '../../services/ordenes_service.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  /// Helper para extraer mensajes de error más claros
  static String _extractErrorMessage(dynamic e) {
    final errorStr = e.toString();
    
    // Errores comunes
    if (errorStr.contains('Error al obtener roles')) {
      return 'Error al obtener roles del sistema. Verifica que el backend esté funcionando.';
    } else if (errorStr.contains('Rol no encontrado')) {
      return 'Uno de los roles seleccionados no existe en el sistema.';
    } else if (errorStr.contains('Categoría no encontrada')) {
      return 'La categoría seleccionada no existe en el sistema.';
    } else if (errorStr.contains('categoria') && (errorStr.contains('no existe') || errorStr.contains('Unknown column'))) {
      return 'La columna categoria no existe en la base de datos. El sistema intentará crearla automáticamente. Si el error persiste, ejecuta: npm run migrate:inventory-category en el backend';
    } else if (errorStr.contains('Error de conexión') || 
               errorStr.contains('No se pudo conectar') ||
               errorStr.contains('backend esté corriendo') ||
               errorStr.contains('connection')) {
      return 'No se pudo conectar al backend. Verifica que esté corriendo en http://localhost:3000';
    } else if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'No tienes permisos para realizar esta acción.';
    } else if (errorStr.contains('username') && errorStr.contains('ya existe')) {
      return 'El nombre de usuario ya existe.';
    } else if (errorStr.contains('El backend no retornó')) {
      // Extraer el mensaje específico
      final match = RegExp(r'El backend no retornó (.+?)\.').firstMatch(errorStr);
      if (match != null) {
        return 'Error del servidor: ${match.group(1)}';
      }
    }
    
    // Intentar extraer el mensaje más relevante
    final match = RegExp(r'Exception:\s*(.+?)(?:Exception:|$)').firstMatch(errorStr);
    if (match != null) {
      return match.group(1)?.trim() ?? 'Error desconocido';
    }
    
    // Si el mensaje es muy largo, truncarlo
    return errorStr.length > 150 
        ? '${errorStr.substring(0, 150)}...' 
        : errorStr;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AdminController(
            paymentRepository: context.read<PaymentRepository>(),
          ),
        ),
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
          SizedBox(height: AppTheme.spacingLG),

          // Resumen general del puesto
          _buildGeneralSummarySection(context, adminController, isTablet),
          SizedBox(height: AppTheme.spacingXL),

          // Información de apertura de caja
          _buildCashOpeningSection(context, adminController, isTablet),
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

  Widget _buildGeneralSummarySection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final cards = _getGeneralSummaryCards(controller);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen general del puesto de barbacoa',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontWeightBold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingLG),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final cardWidth = isTablet ? 220.0 : 200.0;
                final spacing = AppTheme.spacingMD;
                final crossAxisCount = (maxWidth / (cardWidth + spacing))
                    .floor()
                    .clamp(1, 4);
                final itemWidth =
                    (maxWidth -
                        spacing *
                            (crossAxisCount > 1 ? crossAxisCount - 1 : 0)) /
                    crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: itemWidth,
                        child: _SummaryCard(card: card, isTablet: isTablet),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_SummaryCardData> _getGeneralSummaryCards(AdminController controller) {
    // Calcular ventas del día
    final todaySales = controller.todayTotalSales;
    final salesGrowth = controller.salesGrowthPercentage;
    final salesGrowthText = salesGrowth >= 0 
        ? '+${salesGrowth.toStringAsFixed(1)}% vs ayer'
        : '${salesGrowth.toStringAsFixed(1)}% vs ayer';

    // Calcular órdenes activas
    final activeOrders = controller.activeOrders.length;
    final ordersInKitchen = controller.ordersInKitchen.length;
    final ordersText = ordersInKitchen > 0 
        ? '$ordersInKitchen en cocina'
        : 'Sin órdenes en cocina';

    // Calcular mesas ocupadas
    final occupiedTables = controller.occupiedTablesCount;
    final totalTables = controller.totalTablesCount;
    final occupancyRate = controller.tableOccupancyRate;
    final tablesText = '$occupiedTables/$totalTables';
    final occupancyText = '${occupancyRate.toStringAsFixed(1)}% ocupación';

    // Calcular stock crítico
    final criticalStock = controller.criticalStockItems.length;
    final stockItemsNames = controller.criticalStockItemsNames;
    final stockText = criticalStock > 0 
        ? stockItemsNames.length > 30 
            ? '${stockItemsNames.substring(0, 30)}...'
            : stockItemsNames
        : 'Ninguno';

    return [
      _SummaryCardData(
        title: 'Ventas del Día',
        value: '\$${todaySales.toStringAsFixed(2)}',
        subtitle: salesGrowthText,
        color: AppColors.success,
        icon: Icons.trending_up,
      ),
      _SummaryCardData(
        title: 'Órdenes Activas',
        value: '$activeOrders',
        subtitle: ordersText,
        color: AppColors.info,
        icon: Icons.receipt_long,
      ),
      _SummaryCardData(
        title: 'Mesas Ocupadas',
        value: tablesText,
        subtitle: occupancyText,
        color: AppColors.warning,
        icon: Icons.table_restaurant,
      ),
      _SummaryCardData(
        title: 'Stock Crítico',
        value: '$criticalStock',
        subtitle: stockText,
        color: AppColors.error,
        icon: Icons.warning_amber,
      ),
    ];
  }

  Widget _buildCashOpeningSection(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final apertura = controller.getTodayCashOpening();
    final isOpen = controller.isCashRegisterOpen();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: isOpen ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOpen ? Icons.lock_open : Icons.lock,
                      color: isOpen ? AppColors.success : AppColors.warning,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                    Text(
                      'Estado de Caja del Día',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTheme.fontWeightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.0 : 12.0,
                    vertical: isTablet ? 8.0 : 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOpen ? 'Caja Abierta' : 'Caja Cerrada',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            if (apertura != null) ...[
              SizedBox(height: AppTheme.spacingLG),
              Divider(color: AppColors.border),
              SizedBox(height: AppTheme.spacingMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Efectivo Inicial',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$${apertura.efectivoInicial.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isTablet ? 24.0 : 20.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cajero',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          apertura.usuario,
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fecha y Hora',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date_utils.AppDateUtils.formatDateTime(apertura.fecha),
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (apertura.notaCajero != null && apertura.notaCajero!.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: isTablet ? 18.0 : 16.0,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apertura.notaCajero!,
                          style: TextStyle(
                            fontSize: isTablet ? 13.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No se ha registrado una apertura de caja hoy',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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

            // Tarjetas de consumo
            _buildDailyConsumptionCards(context, controller, isTablet),
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
      children: [
        for (final filter in filterOptions)
          Padding(
            padding: EdgeInsets.only(right: AppTheme.spacingSM),
            child: FilterChip(
              label: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight:
                      controller.selectedConsumptionFilter == filter['value']
                      ? AppTheme.fontWeightSemibold
                      : AppTheme.fontWeightNormal,
                ),
              ),
              selected: controller.selectedConsumptionFilter == filter['value'],
              onSelected: (selected) {
                if (selected) {
                  controller.setSelectedConsumptionFilter(filter['value']!);
                }
              },
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: controller.selectedConsumptionFilter == filter['value']
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // Tabla de consumo del día
  Widget _buildConsumptionTable(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final records = _buildConsumptionRecords(controller);

    if (records.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay datos de consumo para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
              SizedBox(height: AppTheme.spacingXS),
              Text(
                'Los datos aparecerán aquí cuando se registren pagos',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          horizontalMargin: 16,
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 68,
          columns: [
            DataColumn(
              label: Text(
                'ID',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Origen',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Productos',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Método de pago',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Hora',
                style: TextStyle(
                  fontSize: isTablet
                      ? AppTheme.fontSizeSM
                      : AppTheme.fontSizeXS,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
          ],
          rows: records.map((record) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    record.id,
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
                      record.originLabel,
                      style: TextStyle(
                        fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: record.isTakeaway
                        ? Colors.blue
                        : Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 240,
                    child: Text(
                      record.products.isEmpty
                          ? 'Sin detalles'
                          : record.products.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    record.total,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    record.paymentMethod,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
                DataCell(_buildConsumptionStatusChip(record.status, isTablet)),
                DataCell(
                  Text(
                    record.time,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      // Vista móvil - lista de tarjetas
      return Column(
        children: records.map((record) {
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
                        record.id,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTheme.fontWeightBold,
                        ),
                      ),
                      _buildConsumptionStatusChip(record.status, isTablet),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          record.originLabel,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXS,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: record.isTakeaway
                            ? Colors.blue
                            : Colors.green,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Text(
                        record.waiter,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(
                    record.products.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(
                    'Total: ${record.total}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: AppTheme.fontWeightSemibold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Método de pago: ${record.paymentMethod}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Hora: ${record.time}',
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
  Widget _buildConsumptionStatusChip(String status, bool isTablet) {
    final normalized = status.toLowerCase();
    Color color;

    switch (normalized) {
      case 'cobrado':
        color = Colors.green;
        break;
      case 'pendiente':
        color = Colors.orange;
        break;
      case 'listo':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
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
          mainAxisSize: MainAxisSize.min,
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
                color: table.status == TableStatus.enLimpieza
                    ? Colors.grey.shade200  // Gris claro para "En limpieza"
                    : statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: table.status == TableStatus.enLimpieza
                      ? Colors.grey.shade800  // Texto oscuro para contraste con gris claro
                      : statusColor,
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
              Flexible(
                child: Text(
                  table.waiter!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
        for (final item in items.take(5))
          Padding(
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
          ),
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

  // Widget para construir un chip de área con botón de eliminar
  Widget _buildAreaFilterChip({
    required BuildContext context,
    required String label,
    required String value,
    required bool isSelected,
    required Function(bool) onSelected,
    required VoidCallback? onDelete,
    required bool isTablet,
  }) {
    return FilterChip(
      label: Text(
        label,
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
          onSelected(true);
        }
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      onDeleted: onDelete,
      deleteIcon: Icon(
        Icons.close,
        size: isTablet ? 16 : 14,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  // Filtros de área
  Widget _buildAreaFilters(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final filterOptions = controller.tableAreas.map((area) => {
      'value': area,
      'label': area == 'todos' ? 'Todos' : area,
    }).toList();

    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingSM,
      children: [
        for (final filter in filterOptions)
          _buildAreaFilterChip(
            context: context,
            label: filter['label']!,
            value: filter['value']!,
            isSelected: controller.selectedTableArea == filter['value'],
            onSelected: (selected) {
              if (selected) {
                controller.setSelectedTableArea(filter['value']!);
              }
            },
            onDelete: filter['value'] != 'todos'
                ? () => _showDeleteAreaDialog(context, controller, filter['value']!)
                : null,
            isTablet: isTablet,
          ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
          onPressed: () => _showAddAreaDialog(context, controller),
          tooltip: 'Agregar Área',
        ),
      ],
    );
  }

  // Diálogo para agregar área
  void _showAddAreaDialog(
    BuildContext context,
    AdminController controller,
  ) {
    final areaNameController = TextEditingController();
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar Área',
          style: TextStyle(fontSize: isTablet ? 20 : 18),
        ),
        contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
        content: SizedBox(
          width: isTablet ? 400 : double.infinity,
          child: TextField(
            controller: areaNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del área',
              hintText: 'Ej: Terraza, Patio, etc.',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final areaName = areaNameController.text.trim();
              if (areaName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un nombre para el área'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Verificar si el área ya existe (comparación exacta)
              if (controller.tableAreas.contains(areaName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El área "$areaName" ya existe'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              controller.addTableArea(areaName);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Área "$areaName" agregada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // Diálogo para confirmar eliminación de área
  void _showDeleteAreaDialog(
    BuildContext context,
    AdminController controller,
    String areaName,
  ) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    // Contar cuántas mesas usan esta área
    final mesasConArea = controller.tables.where((t) => t.section == areaName).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Área',
          style: TextStyle(fontSize: isTablet ? 20 : 18),
        ),
        content: Text(
          mesasConArea > 0
              ? '¿Estás seguro de que deseas eliminar el área "$areaName"?\n\n'
                  'Hay $mesasConArea mesa${mesasConArea > 1 ? 's' : ''} que usan esta área. '
                  'Se moverán a "${controller.tableAreas.where((a) => a != 'todos' && a != areaName).isNotEmpty ? controller.tableAreas.where((a) => a != 'todos' && a != areaName).first : 'Área Principal'}".'
              : '¿Estás seguro de que deseas eliminar el área "$areaName"?',
          style: TextStyle(fontSize: isTablet ? 16 : 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // El método ahora retorna inmediatamente después de actualizar localmente
                // No necesita mostrar diálogo de carga porque es instantáneo
                await controller.deleteTableArea(areaName);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Área "$areaName" eliminada exitosamente. Las mesas se están actualizando en segundo plano.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar área: ${_extractErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
        // Responsivo: más columnas en pantallas grandes
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1200) {
          // Desktop grande
          crossAxisCount = 5;
          childAspectRatio = 0.75;
        } else if (constraints.maxWidth > 900) {
          // Desktop/Tablet grande
          crossAxisCount = 4;
          childAspectRatio = 0.72;
        } else if (constraints.maxWidth > 600) {
          // Tablet
          crossAxisCount = 3;
          childAspectRatio = 0.70;
        } else {
          // Mobile
          crossAxisCount = 2;
          childAspectRatio = 0.68;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppTheme.spacingMD,
            mainAxisSpacing: AppTheme.spacingMD,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return KeyedSubtree(
              key: ValueKey('table_${table.id}_${table.status}'),
              child: _buildTableManagementCard(
                context,
                table,
                controller,
                isTablet,
              ),
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
    Color backgroundColor;
    Color textColor;

    switch (table.status) {
      case TableStatus.libre:
        backgroundColor = Colors.green.shade700;
        textColor = Colors.white;
        break;
      case TableStatus.ocupada:
        backgroundColor = Colors.red.shade700;
        textColor = Colors.white;
        break;
      case TableStatus.reservada:
        backgroundColor = Colors.yellow.shade700;
        textColor = Colors.black87;
        break;
      case TableStatus.enLimpieza:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade700;
        textColor = Colors.white;
    }

    final sectionText = table.section != null && table.section!.isNotEmpty
        ? table.section!
        : 'Sin sección';

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                Expanded(
                  child: Text(
                    'Mesa ${table.number}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                      color: textColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: isTablet ? 20 : 18),
                      color: textColor,
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
                      color: textColor,
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                sectionText,
                style: TextStyle(
                  fontSize: isTablet ? AppTheme.fontSizeXS : 10,
                  color: textColor,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Estado con dropdown
            Container(
              decoration: BoxDecoration(
                color: table.status == TableStatus.enLimpieza 
                    ? Colors.grey.shade200  // Gris claro para "En limpieza"
                    : (table.status == TableStatus.reservada
                        ? Colors.yellow.shade100
                        : textColor.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: DropdownButtonFormField<String>(
                value: table.status,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: textColor),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                dropdownColor: backgroundColor,
                items: [
                  DropdownMenuItem(
                    value: TableStatus.libre,
                    child: Text(
                      TableStatus.getStatusText(TableStatus.libre),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: TableStatus.ocupada,
                    child: Text(
                      TableStatus.getStatusText(TableStatus.ocupada),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: TableStatus.reservada,
                    child: Text(
                      TableStatus.getStatusText(TableStatus.reservada),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  DropdownMenuItem(
                    value: TableStatus.enLimpieza,
                    child: Text(
                      TableStatus.getStatusText(TableStatus.enLimpieza),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
                onChanged: (newStatus) async {
                  if (newStatus != null) {
                    try {
                      await controller.updateTableStatus(table.id, newStatus);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Estado de mesa actualizado'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar estado: ${_extractErrorMessage(e)}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                },
                style: TextStyle(
                  color: textColor,
                  fontWeight: AppTheme.fontWeightSemibold,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Información adicional
            Text(
              '${table.seats} asientos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
            if (table.customers != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                '${table.customers} comensales',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ],
            if (table.currentTotal != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                '\$${table.currentTotal!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
            ],
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
    // Obtener áreas disponibles (excluyendo 'todos')
    final availableAreas = controller.tableAreas.where((a) => a != 'todos').toList();
    String selectedSection = availableAreas.isNotEmpty ? availableAreas.first : 'Área Principal';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Agregar Mesa',
            style: TextStyle(fontSize: isTablet ? 20 : 18),
          ),
          contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
          content: SizedBox(
            width: isTablet ? 450 : double.infinity,
            child: Form(
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
                    items: availableAreas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )).toList(),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // El ID se asignará desde el backend
                  final newTable = TableModel(
                    id: 0, // Temporal, se actualizará desde el backend
                    number: int.parse(numberController.text),
                    status: TableStatus.libre,
                    seats: int.parse(seatsController.text),
                    section: selectedSection,
                  );
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await controller.addTable(newTable);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de creación
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesa agregada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear mesa: ${_extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
    // Obtener áreas disponibles (excluyendo 'todos')
    final availableAreas = controller.tableAreas.where((a) => a != 'todos').toList();
    String selectedSection = table.section ?? (availableAreas.isNotEmpty ? availableAreas.first : 'Área Principal');
    // Si el área de la mesa no está en la lista, usar la primera disponible
    if (!availableAreas.contains(selectedSection)) {
      selectedSection = availableAreas.isNotEmpty ? availableAreas.first : 'Área Principal';
    }
    final isTablet = MediaQuery.of(context).size.width > 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editar Mesa',
                style: TextStyle(fontSize: isTablet ? 20 : 18),
              ),
              IconButton(
                icon: Icon(Icons.close, size: isTablet ? 24 : 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
          content: SizedBox(
            width: isTablet ? 450 : double.infinity,
            child: Form(
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
                    items: availableAreas.map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    )).toList(),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    final updatedTable = table.copyWith(
                      number: int.parse(numberController.text),
                      seats: int.parse(seatsController.text),
                      section: selectedSection,
                    );
                    await controller.updateTable(updatedTable);
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de edición
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mesa actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar mesa: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
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
            onPressed: () async {
              // Mostrar indicador de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await controller.deleteTable(table.id);
                
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                // Cerrar diálogo de confirmación
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mesa ${table.number} eliminada'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar mesa: ${_extractErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
    // Cargar productos y categorías si no están cargados
    if (controller.menuItems.isEmpty) {
      controller.loadMenuItems();
    }
    if (controller.getAllCategories().isEmpty) {
      controller.loadCategorias();
    }
    
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
                        backgroundColor: AppColors.primary,
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
                      backgroundColor: AppColors.primary,
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
              // Botón "Todos" primero
              Padding(
                padding: EdgeInsets.only(right: AppTheme.spacingSM),
                child: FilterChip(
                  label: Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                      fontWeight: controller.selectedMenuCategory == 'todos'
                          ? AppTheme.fontWeightSemibold
                          : AppTheme.fontWeightNormal,
                    ),
                  ),
                  selected: controller.selectedMenuCategory == 'todos',
                  onSelected: (selected) {
                    if (selected) {
                      controller.setSelectedMenuCategory('todos');
                    }
                  },
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: controller.selectedMenuCategory == 'todos'
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              // Resto de categorías
              for (final category in controller.getAllCategories())
                Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: controller.selectedMenuCategory == category
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: controller.selectedMenuCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedMenuCategory(category);
                      }
                    },
                    onDeleted: () => _handleMenuCategoryDeletion(
                      context,
                      controller,
                      category,
                    ),
                    deleteIcon: Icon(
                      Icons.close,
                      size: isTablet ? 16 : 14,
                      color: AppColors.error,
                    ),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: controller.selectedMenuCategory == category
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
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

    // Agrupar productos por categoría (normalizando mayúsculas/minúsculas)
    final Map<String, List<MenuItem>> productsByCategory = {};
    for (final product in products) {
      // Normalizar categoría: primera letra mayúscula, resto minúsculas
      String category = product.category.isNotEmpty ? product.category : 'Otros';
      if (category.isNotEmpty) {
        category = category[0].toUpperCase() + category.substring(1).toLowerCase();
      }
      if (!productsByCategory.containsKey(category)) {
        productsByCategory[category] = [];
      }
      productsByCategory[category]!.add(product);
    }

    // Ordenar categorías
    final sortedCategories = productsByCategory.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.map((category) {
        final categoryProducts = productsByCategory[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de categoría
            Padding(
              padding: EdgeInsets.only(
                top: category == sortedCategories.first ? 0 : AppTheme.spacingXL,
                bottom: AppTheme.spacingMD,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSM),
                  Text(
                    '(${categoryProducts.length})',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Grid o lista de productos de esta categoría
            if (isDesktop || isTablet)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 2,
                  childAspectRatio: isDesktop ? 1.1 : 0.85,
                  crossAxisSpacing: AppTheme.spacingMD,
                  mainAxisSpacing: AppTheme.spacingMD,
                ),
                itemCount: categoryProducts.length,
                itemBuilder: (context, index) {
                  final product = categoryProducts[index];
                  return _buildMenuProductCard(context, product, controller, isTablet);
                },
              )
            else
              Column(
                children: categoryProducts.map((product) {
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
              ),
          ],
        );
      }).toList(),
    );
  }

  // Tarjeta de producto del menú
  Widget _buildMenuProductCard(
    BuildContext context,
    MenuItem product,
    AdminController controller,
    bool isTablet,
  ) {
    final hasSizes = product.hasSizes && (product.sizes?.isNotEmpty ?? false);
    final priceLabel = hasSizes
        ? 'Varios precios'
        : (product.price != null ? '\$${product.price!.toStringAsFixed(0)}' : 'Sin precio');

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
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: AppTheme.fontWeightBold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: hasSizes
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Text(
                    hasSizes ? 'Varios precios' : 'Precio: $priceLabel',
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      fontWeight: AppTheme.fontWeightSemibold,
                      color: hasSizes ? AppColors.warning : AppColors.primary,
                    ),
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

            // Categoría y estado
            Wrap(
              spacing: AppTheme.spacingSM,
              runSpacing: AppTheme.spacingXS,
              children: [
                Chip(
                  label: Text(
                    product.category,
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: MenuCategory.getCategoryColor(product.category),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                ),
                Chip(
                  label: Text(
                    product.isAvailable ? 'Disponible' : 'No disponible',
                    style: TextStyle(
                      fontSize: isTablet
                          ? AppTheme.fontSizeSM
                          : AppTheme.fontSizeXS,
                      color: product.isAvailable ? AppColors.success : AppColors.error,
                    ),
                  ),
                  backgroundColor: (product.isAvailable ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.15),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS,
                  ),
                ),
                if (product.serveHot)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
                    label: Text(
                      'Caliente',
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.warning,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                  ),
                if (product.isSpicy)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department_outlined, size: 16, color: Colors.white),
                    label: Text(
                      'Picante',
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),

            // Descripción
            if (product.description.isNotEmpty) ...[
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 14 : 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppTheme.spacingSM),
            ],

            if (product.recipeIngredients?.isNotEmpty ?? false) ...[
              Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: isTablet ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppTheme.spacingXS),
                  Text(
                    '${product.recipeIngredients!.length} ingredientes configurados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: AppTheme.fontWeightSemibold,
                        ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSM),
            ],

            // Precio o tamaños
            if (hasSizes)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tamaños disponibles:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: AppTheme.fontWeightSemibold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Wrap(
                    spacing: AppTheme.spacingSM,
                    runSpacing: AppTheme.spacingXS,
                    children: product.sizes!
                        .map(
                          (size) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSM,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${size.name}: \$${size.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? AppTheme.fontSizeSM
                                    : AppTheme.fontSizeXS,
                                fontWeight: AppTheme.fontWeightSemibold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            else
              Text(
                priceLabel == 'Sin precio'
                    ? 'Sin precio establecido'
                    : 'Precio: $priceLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: AppTheme.fontWeightBold,
                      color: AppColors.primary,
                    ),
              ),
            SizedBox(height: AppTheme.spacingMD),

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
                    onPressed: () async {
                      try {
                        await controller.toggleMenuItemAvailability(product.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                product.isAvailable
                                    ? 'Producto deshabilitado'
                                    : 'Producto habilitado',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${_extractErrorMessage(e)}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isAvailable
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      product.isAvailable ? 'Deshabilitar' : 'Habilitar',
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
                        fontWeight: AppTheme.fontWeightSemibold,
                      ),
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await controller.addCustomCategory(nameController.text);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de creación
                  if (context.mounted) Navigator.of(context).pop();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Categoría "${nameController.text}" agregada exitosamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _extractErrorMessage(e),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
    final List<TextEditingController> sizeNameControllers = [];
    final List<TextEditingController> sizePriceControllers = [];

    TextEditingController _createNameController(String text) {
      final controller = TextEditingController(text: text);
      sizeNameControllers.add(controller);
      return controller;
    }

    TextEditingController _createPriceController(double price) {
      final controller = TextEditingController(
        text: price > 0 ? (price % 1 == 0 ? price.toStringAsFixed(0) : price.toString()) : '',
      );
      sizePriceControllers.add(controller);
      return controller;
    }

    void addSizeEntry({String name = '', double price = 0.0}) {
      sizes = [
        ...sizes,
        MenuSize(name: name, price: price),
      ];
      _createNameController(name);
      _createPriceController(price);
    }

    void removeSizeEntry(int index) {
      if (index < 0 || index >= sizes.length) return;
      sizes = List<MenuSize>.from(sizes)..removeAt(index);
      final nameController = sizeNameControllers.removeAt(index);
      final priceController = sizePriceControllers.removeAt(index);
      nameController.dispose();
      priceController.dispose();
    }

    void clearSizeEntries() {
      sizes = [];
      for (final controller in [...sizeNameControllers, ...sizePriceControllers]) {
        controller.dispose();
      }
      sizeNameControllers.clear();
      sizePriceControllers.clear();
    }

    void ensureInitialSizeEntry() {
      if (sizes.isEmpty) {
        addSizeEntry();
      }
    }

    void disposeSizeControllers() {
      for (final controller in [...sizeNameControllers, ...sizePriceControllers]) {
        controller.dispose();
      }
    }
    bool serveHot = false;
    bool isSpicy = false;
    bool allowSauces = false;
    bool allowExtraIngredients = false;
    bool isAvailable = true;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                      textAlign: TextAlign.start,
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
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in controller.getAllCategories())
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
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
                        if (value) {
                          ensureInitialSizeEntry();
                        } else {
                          clearSizeEntries();
                        }
                      });
                    },
                  ),
                  if (hasSizes) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    _buildSizesConfiguration(
                      context,
                      sizes,
                      (newSizes) {
                        setState(() {
                          sizes = newSizes;
                        });
                      },
                      isTablet,
                      sizeNameControllers,
                      sizePriceControllers,
                      () {
                        setState(() {
                          addSizeEntry();
                        });
                      },
                      (index) {
                        setState(() {
                          removeSizeEntry(index);
                        });
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: AppTheme.spacingXS),
                      child: Text(
                        'Nota: El precio general se desactiva cuando usas tamaños. Cada tamaño debe tener un precio.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: AppTheme.spacingMD),
                    TextFormField(
                      controller: priceController,
                      textAlign: TextAlign.start,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !hasSizes,
                      validator: hasSizes
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obligatorio';
                              }
                              // Limpiar el valor antes de parsear
                              final cleanValue = value.trim().replaceAll(',', '.');
                              final price = double.tryParse(cleanValue);
                              if (price == null || price <= 0) {
                                return 'Debe ser un número válido mayor a 0';
                              }
                              return null;
                            },
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingMD),
                  TextFormField(
                    controller: descriptionController,
                    textAlign: TextAlign.start,
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
              onPressed: () {
                disposeSizeControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                  // El ID se asignará desde el backend
                  // Limpiar y validar el precio antes de parsear
                  double? precio;
                  if (!hasSizes) {
                    final precioTexto = priceController.text.trim().replaceAll(',', '.');
                    precio = double.tryParse(precioTexto);
                    if (precio == null || precio <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El precio debe ser un número válido mayor a 0'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                  }
                  
                  final newProduct = MenuItem(
                    id: 'temp', // Temporal, se actualizará desde el backend
                    name: nameController.text.trim(),
                    category: selectedCategory!,
                    description: descriptionController.text.trim(),
                    price: precio,
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
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    await controller.addMenuItem(newProduct);
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de creación
                    if (context.mounted) {
                      disposeSizeControllers();
                      Navigator.of(context).pop();
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto agregado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al crear producto: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
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
    List<TextEditingController> sizeNameControllers,
    List<TextEditingController> sizePriceControllers,
    VoidCallback onAddSize,
    void Function(int index) onRemoveSize,
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
        for (var index = 0; index < sizes.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingSM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      labelText: 'Nombre (ej: Chico)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: sizeNameControllers[index],
                    onChanged: (value) {
                      sizes[index] = MenuSize(
                        name: value.trim(),
                        price: sizes[index].price,
                      );
                      onSizesChanged(List<MenuSize>.from(sizes));
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.start,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: sizePriceControllers[index],
                    onChanged: (value) {
                      final cleanValue = value.trim().replaceAll(',', '.');
                      final price = double.tryParse(cleanValue) ?? 0.0;
                      sizes[index] = MenuSize(
                        name: sizes[index].name,
                        price: price,
                      );
                      onSizesChanged(List<MenuSize>.from(sizes));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    onRemoveSize(index);
                  },
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: onAddSize,
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
    final List<TextEditingController> sizeNameControllers = [];
    final List<TextEditingController> sizePriceControllers = [];

    TextEditingController _createNameController(String text) {
      final controller = TextEditingController(text: text);
      sizeNameControllers.add(controller);
      return controller;
    }

    TextEditingController _createPriceController(double price) {
      final controller = TextEditingController(
        text: price > 0 ? (price % 1 == 0 ? price.toStringAsFixed(0) : price.toString()) : '',
      );
      sizePriceControllers.add(controller);
      return controller;
    }

    void syncControllersWithSizes() {
      for (final controller in [...sizeNameControllers, ...sizePriceControllers]) {
        controller.dispose();
      }
      sizeNameControllers.clear();
      sizePriceControllers.clear();
      for (final size in sizes) {
        _createNameController(size.name);
        _createPriceController(size.price);
      }
    }

    void addSizeEntry({String name = '', double price = 0.0}) {
      sizes = [
        ...sizes,
        MenuSize(name: name, price: price),
      ];
      _createNameController(name);
      _createPriceController(price);
    }

    void removeSizeEntry(int index) {
      if (index < 0 || index >= sizes.length) return;
      sizes = List<MenuSize>.from(sizes)..removeAt(index);
      final nameController = sizeNameControllers.removeAt(index);
      final priceController = sizePriceControllers.removeAt(index);
      nameController.dispose();
      priceController.dispose();
    }

    void clearSizeEntries() {
      sizes = [];
      for (final controller in [...sizeNameControllers, ...sizePriceControllers]) {
        controller.dispose();
      }
      sizeNameControllers.clear();
      sizePriceControllers.clear();
    }

    void ensureInitialSizeEntry() {
      if (sizes.isEmpty) {
        addSizeEntry();
      }
    }

    syncControllersWithSizes();

    void disposeSizeControllers() {
      for (final controller in [...sizeNameControllers, ...sizePriceControllers]) {
        controller.dispose();
      }
    }
    bool serveHot = product.serveHot;
    bool isSpicy = product.isSpicy;
    bool allowSauces = product.allowSauces;
    bool allowExtraIngredients = product.allowExtraIngredients;
    bool isAvailable = product.isAvailable;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editar Producto'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  disposeSizeControllers();
                  Navigator.of(context).pop();
                },
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
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in controller.getAllCategories())
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
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
                        if (value) {
                          ensureInitialSizeEntry();
                        } else {
                          clearSizeEntries();
                        }
                      });
                    },
                  ),
                  if (hasSizes) ...[
                    SizedBox(height: AppTheme.spacingSM),
                    _buildSizesConfiguration(
                      context,
                      sizes,
                      (newSizes) {
                        setState(() {
                          sizes = newSizes;
                        });
                      },
                      isTablet,
                      sizeNameControllers,
                      sizePriceControllers,
                      () {
                        setState(() {
                          addSizeEntry();
                        });
                      },
                      (index) {
                        setState(() {
                          removeSizeEntry(index);
                        });
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: AppTheme.spacingXS),
                      child: Text(
                        'Nota: El precio general se reemplaza por los precios configurados aquí.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
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
              onPressed: () {
                disposeSizeControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                  
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    await controller.updateMenuItem(updatedProduct);
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de edición
                    if (context.mounted) {
                      disposeSizeControllers();
                      Navigator.of(context).pop();
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar producto: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
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
                  for (final ingredient in ingredients)
                    Card(
                      margin: EdgeInsets.only(bottom: AppTheme.spacingSM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            ingredient.inventoryItemId != null
                                ? Icons.inventory_2
                                : Icons.food_bank,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          ingredient.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ingredient.quantityPerPortion} ${ingredient.unit} por porción',
                            ),
                            SizedBox(height: AppTheme.spacingXS / 2),
                            Text(
                              'Categoría: ${ingredient.category ?? 'Otros'}'
                              '${ingredient.inventoryItemId != null ? ' • Inventario' : ' • Personalizado'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            SizedBox(height: AppTheme.spacingXS),
                            Wrap(
                              spacing: AppTheme.spacingXS,
                              runSpacing: AppTheme.spacingXS / 2,
                              children: [
                                Chip(
                                  label: Text(
                                    ingredient.inventoryItemId != null
                                        ? 'Inventario'
                                        : 'Personalizado',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: ingredient.inventoryItemId != null
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.secondary.withValues(alpha: 0.15),
                                ),
                                Chip(
                                  label: Text(
                                    ingredient.autoDeduct
                                        ? 'Descuenta stock'
                                        : 'Sin descuento',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: ingredient.autoDeduct
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ingredients.removeWhere((ing) => ing.id == ingredient.id);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
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
              onPressed: () async {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final updatedProduct = product.copyWith(
                    recipeIngredients: ingredients,
                    updatedAt: DateTime.now(),
                  );
                  await controller.updateMenuItem(updatedProduct);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de receta
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receta guardada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar receta: ${_extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
            onPressed: () async {
              // Mostrar indicador de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await controller.deleteMenuItem(product.id);
                
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                // Cerrar diálogo de confirmación
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto "${product.name}" eliminado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar producto: ${_extractErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
                'Panel de Control',
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
              for (final category in controller.inventoryCategories)
                Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      category == 'todos' ? 'Todos' : category,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight:
                            controller.selectedInventoryCategory == category
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: controller.selectedInventoryCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedInventoryCategory(category);
                      }
                    },
                    onDeleted: category != 'todos'
                        ? () => _handleInventoryCategoryDeletion(
                            context,
                            controller,
                            category,
                          )
                        : null,
                    deleteIcon: category != 'todos'
                        ? Icon(
                            Icons.close,
                            size: isTablet ? 16 : 14,
                            color: AppColors.error,
                          )
                        : null,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: controller.selectedInventoryCategory == category
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () => _showAddCategoryDialog(context, controller),
                tooltip: 'Agregar Categoría',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Diálogo para agregar categoría
  void _showAddCategoryDialog(
    BuildContext context,
    AdminController controller,
  ) {
    final categoryNameController = TextEditingController();
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar Categoría',
          style: TextStyle(fontSize: isTablet ? 20 : 18),
        ),
        contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
        content: SizedBox(
          width: isTablet ? 400 : double.infinity,
          child: TextField(
            controller: categoryNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Verduras, Lácteos, etc.',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final categoryName = categoryNameController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un nombre para la categoría'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Verificar si la categoría ya existe
              if (controller.inventoryCategories.contains(categoryName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La categoría "$categoryName" ya existe'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              controller.addInventoryCategory(categoryName);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Categoría "$categoryName" agregada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
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
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: _buildInventoryItemCard(context, item, controller, isTablet),
          ),
      ],
    );
  }

  // Tarjeta de producto de inventario
  // Helper para formatear números de stock sin decimales innecesarios
  String _formatStockNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

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
                      'Stock Actual: ${_formatStockNumber(item.currentStock)} ${item.unit}',
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
                      'Mín: ${_formatStockNumber(item.minStock)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Máx: ${_formatStockNumber(item.maxStock)} ${item.unit}',
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
    // Asegurarse de que la fecha esté en zona horaria local
    final localDate = date.isUtc ? date.toLocal() : date;
    return date_utils.AppDateUtils.formatDateTime(localDate);
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
        title: Text(
          'Agregar al Inventario',
          style: TextStyle(fontSize: isTablet ? 20 : 18),
        ),
        contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
        content: SizedBox(
          width: isTablet ? 500 : double.infinity,
          child: SingleChildScrollView(
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
                  items: controller.inventoryCategories
                      .where((cat) => cat != 'todos')
                      .map((category) {
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Validar que se haya seleccionado una categoría
                if (selectedCategory == null || selectedCategory!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor selecciona una categoría'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final stock = double.parse(stockController.text.trim());
                final minStock = double.parse(minStockController.text.trim());
                final maxStock = double.parse(maxStockController.text.trim());
                // Limpiar el símbolo $ si está presente
                final costText = costController.text.trim().replaceAll('\$', '').replaceAll(' ', '');
                final cost = double.parse(costText);
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

                // El ID se asignará desde el backend
                final newItem = InventoryItem(
                  id: 'temp', // Temporal, se actualizará desde el backend
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
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await controller.addInventoryItem(newItem);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de creación
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Producto agregado al inventario exitosamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear item: ${_extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
    // Helper para formatear números sin decimales innecesarios
    String formatNumber(double value, {int maxDecimals = 2}) {
      if (value == value.toInt()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(maxDecimals).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final stockController = TextEditingController(
      text: formatNumber(item.currentStock),
    );
    final minStockController = TextEditingController(
      text: formatNumber(item.minStock),
    );
    final maxStockController = TextEditingController(
      text: formatNumber(item.maxStock),
    );
    final costController = TextEditingController(
      text: formatNumber(item.cost, maxDecimals: 2),
    );
    final supplierController = TextEditingController(text: item.supplier ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Editar ${item.name}',
                style: TextStyle(fontSize: isTablet ? 20 : 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: isTablet ? 24 : 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
        content: SizedBox(
          width: isTablet ? 500 : double.infinity,
          child: SingleChildScrollView(
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final stock = double.parse(stockController.text.trim());
                  final minStock = double.parse(minStockController.text.trim());
                  final maxStock = double.parse(maxStockController.text.trim());
                  // Limpiar el símbolo $ si está presente
                  final costText = costController.text.trim().replaceAll('\$', '').replaceAll(' ', '');
                  final cost = double.parse(costText);
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
                  await controller.updateInventoryItem(updatedItem);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de edición
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventario actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar inventario: ${_extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
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
                  
                  // Si es aumento, usar restockInventoryItem para registrar movimiento
                  if (!isDecrease) {
                    await controller.restockInventoryItem(item.id, quantity);
                  } else {
                    await controller.updateInventoryItem(updatedItem);
                  }
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de ajuste
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
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
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al ajustar stock: ${_extractErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
            onPressed: () async {
              // Mostrar indicador de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await controller.deleteInventoryItem(item.id);
                
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                // Cerrar diálogo de confirmación
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto "${item.name}" eliminado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar item: ${_extractErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
                initialValue: controller.selectedUserRole,
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
                initialValue: controller.selectedUserStatus,
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
      return SizedBox(
        width: double.infinity,
        child: Card(
          child: _buildUsersTable(context, users, controller, isTablet),
        ),
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
    final dateFormat = DateFormat('d/M/yyyy');

    final headerStyle = TextStyle(fontWeight: AppTheme.fontWeightSemibold);

    return DataTable(
      columnSpacing: 8,
      horizontalMargin: 12,
      headingRowHeight: 40,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      columns: [
        DataColumn(
          label: Text('Nombre', style: headerStyle.copyWith(fontSize: 12)),
          tooltip: 'Nombre completo',
        ),
        DataColumn(
          label: Text('Usuario', style: headerStyle.copyWith(fontSize: 12)),
        ),
        DataColumn(
          label: Text('Contraseña', style: headerStyle.copyWith(fontSize: 12)),
        ),
        DataColumn(
          label: Text('Teléfono', style: headerStyle.copyWith(fontSize: 12)),
        ),
        DataColumn(
          label: Text('Roles', style: headerStyle.copyWith(fontSize: 12)),
        ),
        DataColumn(
          label: Text('Estado', style: headerStyle.copyWith(fontSize: 12)),
        ),
        DataColumn(
          label: Text('Fecha', style: headerStyle.copyWith(fontSize: 12)),
          tooltip: 'Fecha de creación',
        ),
        DataColumn(
          label: Text('', style: headerStyle.copyWith(fontSize: 12)),
          tooltip: 'Acciones',
          numeric: true,
        ),
      ],
      rows: users.map((user) {
        return DataRow(
          cells: [
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  user.username,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  user.password.isNotEmpty ? user.password : '—',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  user.phone?.isNotEmpty == true ? user.phone! : '—',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: user.roles.map((role) {
                  return Chip(
                    label: Text(
                      UserRole.getRoleText(role),
                      style: const TextStyle(fontSize: 9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    fontSize: 9,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                backgroundColor: (user.isActive ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
              ),
            ),
            DataCell(
              Text(
                dateFormat.format(user.createdAt),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            DataCell(
              Center(
                child: PopupMenuButton(
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
                  for (final role in UserRole.allRoles)
                    CheckboxListTile(
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
              onPressed: () async {
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
                  
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    final newUser = AdminUser(
                      id: 'temp', // Se asignará desde el backend
                      name: nameController.text,
                      username: usernameController.text.toLowerCase(),
                      password: passwordController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      roles: selectedRoles,
                      isActive: true,
                      createdAt: DateTime.now(),
                      createdBy: 'current_admin',
                    );
                    
                    await controller.addUser(newUser);
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de creación
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      // Extraer mensaje de error más claro
                      String errorMessage = 'Error al crear usuario';
                      final errorStr = e.toString();
                      if (errorStr.contains('Error al obtener roles')) {
                        errorMessage = 'Error al obtener roles del sistema. Verifica que el backend esté funcionando correctamente.';
                      } else if (errorStr.contains('Rol no encontrado')) {
                        errorMessage = 'Uno de los roles seleccionados no existe en el sistema.';
                      } else if (errorStr.contains('Error de conexión') || 
                                 errorStr.contains('No se pudo conectar') ||
                                 errorStr.contains('backend esté corriendo')) {
                        errorMessage = 'No se pudo conectar al backend. Verifica que esté corriendo en http://localhost:3000';
                      } else if (errorStr.contains('401') || errorStr.contains('403')) {
                        errorMessage = 'No tienes permisos para crear usuarios.';
                      } else if (errorStr.contains('username')) {
                        errorMessage = 'El nombre de usuario ya existe.';
                      } else {
                        // Extraer el mensaje más relevante
                        final match = RegExp(r'Exception:\s*(.+?)(?:Exception:|$)').firstMatch(errorStr);
                        if (match != null) {
                          errorMessage = match.group(1)?.trim() ?? errorMessage;
                        } else {
                          errorMessage = errorStr.length > 100 
                              ? '${errorStr.substring(0, 100)}...' 
                              : errorStr;
                        }
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 8),
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  }
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
                  for (final role in UserRole.allRoles)
                    CheckboxListTile(
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
                    ),
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
              onPressed: () async {
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
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    final updatedUser = user.copyWith(
                      username: usernameController.text.toLowerCase(),
                      name: nameController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      roles: selectedRoles,
                      isActive: isActive,
                    );
                    await controller.updateUser(updatedUser);
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de edición
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar usuario: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    await controller.changeUserPassword(
                      user.id,
                      passwordController.text,
                    );
                    
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Cerrar diálogo de contraseña
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Cerrar diálogo de carga
                    if (context.mounted) Navigator.of(context).pop();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar contraseña: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
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
            onPressed: () async {
              // Mostrar indicador de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await controller.deleteUser(user.id);
                
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                // Cerrar diálogo de confirmación
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario "${user.name}" eliminado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Cerrar diálogo de carga
                if (context.mounted) Navigator.of(context).pop();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar usuario: ${_extractErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
    // NOTA: La carga de tickets ya se hace en setCurrentView('tickets')
    // No llamar a loadTickets() aquí para evitar llamadas duplicadas y parpadeo
    
    final filteredTickets = controller.filteredTickets;

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
                'Gestión de Tickets de Cobro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  // Botón de refrescar
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔄 AdminView: Refrescando tickets manualmente...');
                      controller.loadTickets();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recargando tickets...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refrescar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSM),
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
            ],
          ),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            'Control y seguimiento de tickets impresos',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppTheme.spacingLG),

          // Resumen de tickets
          _buildTicketSummarySection(
            context,
            filteredTickets,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Búsqueda y filtros
          _buildTicketsSearchAndFilters(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Tabla/Lista de tickets
          _buildTicketsList(
            context,
            filteredTickets,
            controller,
            isTablet,
            isDesktop,
          ),
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
          initialValue: controller.selectedTicketStatus,
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
        SizedBox(height: AppTheme.spacingMD),

        // Filtros de período de fecha
        Text(
          'Filtrar por fecha:',
          style: TextStyle(
            fontSize: isTablet ? AppTheme.fontSizeSM : AppTheme.fontSizeXS,
            fontWeight: AppTheme.fontWeightSemibold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final period in [
                'todos',
                'hoy',
                'ayer',
                'semana',
                'mes',
                'personalizado',
              ])
                Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      const {
                        'todos': 'Todos',
                        'hoy': 'Hoy',
                        'ayer': 'Ayer',
                        'semana': 'Última semana',
                        'mes': 'Mes actual',
                        'personalizado': 'Rango personalizado',
                      }[period]!,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: controller.selectedTicketPeriod == period
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: controller.selectedTicketPeriod == period,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedTicketPeriod(period);
                      }
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: controller.selectedTicketPeriod == period
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Campos de fecha personalizada
        if (controller.selectedTicketPeriod == 'personalizado') ...[
          SizedBox(height: AppTheme.spacingMD),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          controller.ticketStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('es', 'MX'),
                      helpText: 'Seleccionar fecha',
                      cancelText: 'Cancelar',
                      confirmText: 'Aceptar',
                    );
                    if (date != null) {
                      final endDate =
                          controller.ticketEndDate ?? DateTime.now();
                      controller.setTicketDateRange(date, endDate);
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
                          controller.ticketStartDate != null
                              ? _formatDate(controller.ticketStartDate!)
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
                          controller.ticketEndDate ?? DateTime.now(),
                      firstDate:
                          controller.ticketStartDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('es', 'MX'),
                      helpText: 'Seleccionar fecha',
                      cancelText: 'Cancelar',
                      confirmText: 'Aceptar',
                    );
                    if (date != null) {
                      final startDate =
                          controller.ticketStartDate ?? DateTime.now();
                      controller.setTicketDateRange(startDate, date);
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
                          controller.ticketEndDate != null
                              ? _formatDate(controller.ticketEndDate!)
                              : 'Fecha fin',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Lista de tickets
  Widget _buildTicketsList(
    BuildContext context,
    List<payment_models.BillModel> tickets,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    // Mostrar indicador de carga
    if (controller.isLoadingTickets) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingMD),
              const Text('Cargando tickets...'),
              const SizedBox(height: AppTheme.spacingLG),
              TextButton.icon(
                onPressed: () => controller.loadTickets(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Forzar recarga'),
              ),
            ],
          ),
        ),
      );
    }
    
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
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay tickets para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Los tickets aparecerán aquí cuando se cierren cuentas',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLG),
              ElevatedButton.icon(
                onPressed: () => controller.loadTickets(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
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
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 1200
                ? 1200
                : MediaQuery.of(context).size.width,
          ),
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(
                label: Text(
                  'ID',
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
                  'Mesa/Cliente',
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
                  'Método de pago',
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
              // Determinar si es para llevar o en mesa
              final esParaLlevar = ticket.isTakeaway || 
                  (ticket.tableNumber == null && ticket.customerName != null);
              
              // Formatear ID del ticket para mostrar
              String ticketDisplayId = ticket.id;
              if (ticket.id.startsWith('CUENTA-AGRUPADA-')) {
                // Para cuentas agrupadas, mostrar un formato más legible
                final parts = ticket.id.replaceFirst('CUENTA-AGRUPADA-', '').split('-');
                final ordenIds = parts
                    .map((part) => int.tryParse(part))
                    .whereType<int>()
                    .toList();
                if (ordenIds.length > 1) {
                  ticketDisplayId = 'Cuenta agrupada (${ordenIds.length} órdenes)';
                } else {
                  ticketDisplayId = 'ORD-${ordenIds.first.toString().padLeft(6, '0')}';
                }
              } else if (ticket.id.startsWith('ORD-')) {
                // Ya está bien formateado
                ticketDisplayId = ticket.id;
              }
              
              return DataRow(
                cells: [
                  DataCell(
                    Tooltip(
                      message: ticket.id, // Mostrar el ID completo en tooltip
                      child: Text(
                        ticketDisplayId,
                        style: ticket.id.startsWith('CUENTA-AGRUPADA-')
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                    ),
                  ),
                  // Columna Tipo
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: esParaLlevar ? Colors.blue.shade700 : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            esParaLlevar ? Icons.shopping_bag : Icons.restaurant,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            esParaLlevar ? 'Para llevar' : 'En mesa',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Columna Mesa/Cliente
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.tableNumber != null)
                          Text('Mesa ${ticket.tableNumber}')
                        else if (ticket.customerName != null && ticket.customerName!.isNotEmpty)
                          Text(ticket.customerName!, style: const TextStyle(fontWeight: FontWeight.bold))
                        else
                          const Text('N/A'),
                        if (ticket.customerPhone != null && ticket.customerPhone!.isNotEmpty)
                          Text(
                            ticket.customerPhone!,
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text('\$${ticket.total.toStringAsFixed(2)}')),
                  DataCell(
                    Text(
                      ticket.paymentMethod ?? 'N/A',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: ticket.paymentMethod != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(
                        payment_models.BillStatus.getStatusText(ticket.status),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
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
                          onPressed: () => _showTicketDetailsModal(
                            context,
                            ticket,
                            isTablet,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: AppTheme.spacingXS),
                        if (ticket.status !=
                                payment_models.BillStatus.printed &&
                            ticket.status !=
                                payment_models.BillStatus.delivered)
                          IconButton(
                            icon: const Icon(Icons.print, size: 18),
                            color: AppColors.primary,
                            onPressed: () => _showPrintTicketDialog(
                              context,
                              ticket,
                              controller,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        SizedBox(width: AppTheme.spacingXS),
                        if (ticket.status ==
                                payment_models.BillStatus.printed &&
                            ticket.status !=
                                payment_models.BillStatus.delivered)
                          IconButton(
                            icon: const Icon(Icons.check_circle, size: 18),
                            color: Colors.green,
                            onPressed: () => _markTicketAsDelivered(
                              context,
                              ticket,
                              controller,
                            ),
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
        ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PARA LLEVAR',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
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
            if (ticket.paymentMethod != null) ...[
              SizedBox(height: AppTheme.spacingXS),
              Text(
                'Método de pago: ${ticket.paymentMethod}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTheme.fontSizeXS,
                ),
              ),
            ],
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

  // Modal de detalles del ticket (formato de ticket impreso)
  void _showTicketDetailsModal(
    BuildContext context,
    payment_models.BillModel ticket,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TicketDetailsModal(
        ticket: ticket,
        isTablet: isTablet,
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
            onPressed: () async {
              await controller.printTicket(ticket.id, 'Admin');
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ticket impreso: $tableText. Notificación enviada al mesero.',
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
    // NOTA: La carga de cierres ya se hace en setCurrentView('cash_closures')
    // No llamar a loadCashClosures() aquí para evitar llamadas duplicadas y parpadeo
    
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
                  // Botón de refrescar
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔄 AdminView: Refrescando cierres de caja manualmente...');
                      controller.loadCashClosures();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recargando cierres de caja...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refrescar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMD),
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

          // Información de apertura de caja del día
          _buildCashOpeningInfoInClosures(context, controller, isTablet),
          SizedBox(height: AppTheme.spacingLG),

          // Tabla/Lista de cierres (usar Consumer para asegurar reconstrucción)
          Consumer<AdminController>(
            builder: (context, adminController, child) {
              return _buildCashClosuresList(context, adminController, isTablet, isDesktop);
            },
          ),
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
              for (final period in [
                'hoy',
                'ayer',
                'semana',
                'mes',
                'personalizado',
              ])
                Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingSM),
                  child: FilterChip(
                    label: Text(
                      const {
                        'hoy': 'Hoy',
                        'ayer': 'Ayer',
                        'semana': 'Última semana',
                        'mes': 'Mes actual',
                        'personalizado': 'Rango personalizado',
                      }[period]!,
                      style: TextStyle(
                        fontSize: isTablet
                            ? AppTheme.fontSizeSM
                            : AppTheme.fontSizeXS,
                        fontWeight: controller.selectedCashClosePeriod == period
                            ? AppTheme.fontWeightSemibold
                            : AppTheme.fontWeightNormal,
                      ),
                    ),
                    selected: controller.selectedCashClosePeriod == period,
                    onSelected: (selected) {
                      if (selected) {
                        controller.setSelectedCashClosePeriod(period);
                        // Recargar cierres cuando cambia el período
                        controller.loadCashClosures();
                      }
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: controller.selectedCashClosePeriod == period
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
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
                      locale: const Locale('es', 'MX'),
                      helpText: 'Seleccionar fecha',
                      cancelText: 'Cancelar',
                      confirmText: 'Aceptar',
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
                      locale: const Locale('es', 'MX'),
                      helpText: 'Seleccionar fecha',
                      cancelText: 'Cancelar',
                      confirmText: 'Aceptar',
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

  // Información de apertura de caja en vista de cierres
  Widget _buildCashOpeningInfoInClosures(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final apertura = controller.getTodayCashOpening();
    final isOpen = controller.isCashRegisterOpen();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: isOpen ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOpen ? Icons.lock_open : Icons.lock,
                      color: isOpen ? AppColors.success : AppColors.warning,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                    Text(
                      'Apertura de Caja del Día',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTheme.fontWeightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.0 : 12.0,
                    vertical: isTablet ? 8.0 : 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOpen ? 'Caja Abierta' : 'Caja Cerrada',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            if (apertura != null) ...[
              SizedBox(height: AppTheme.spacingLG),
              Divider(color: AppColors.border),
              SizedBox(height: AppTheme.spacingMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Efectivo Inicial',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$${apertura.efectivoInicial.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isTablet ? 24.0 : 20.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cajero',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          apertura.usuario,
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fecha y Hora',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date_utils.AppDateUtils.formatDateTime(apertura.fecha),
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (apertura.notaCajero != null && apertura.notaCajero!.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: isTablet ? 18.0 : 16.0,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apertura.notaCajero!,
                          style: TextStyle(
                            fontSize: isTablet ? 13.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              SizedBox(height: AppTheme.spacingMD),
              Text(
                'No se ha registrado una apertura de caja hoy',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Lista de cierres de caja
  Widget _buildCashClosuresList(
    BuildContext context,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    // Mostrar indicador de carga
    if (controller.isLoadingCashClosures) {
      return Container(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingMD),
              const Text('Cargando cierres de caja...'),
              const SizedBox(height: AppTheme.spacingLG),
              TextButton.icon(
                onPressed: () => controller.loadCashClosures(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Forzar recarga'),
              ),
            ],
          ),
        ),
      );
    }
    
    final closures = controller.filteredCashClosures;
    print('🎨 AdminView: _buildCashClosuresList - ${closures.length} cierres para mostrar');
    if (closures.isNotEmpty) {
      print('🎨 AdminView: Primer cierre - ID: ${closures.first.id}, Usuario: ${closures.first.usuario}, Total: ${closures.first.totalNeto}');
    }

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
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'No hay cierres de caja para mostrar',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Los cierres aparecerán aquí cuando el cajero los envíe',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLG),
              ElevatedButton.icon(
                onPressed: () => controller.loadCashClosures(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
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
    print('🎨 AdminView: _buildCashClosuresTable - ${closures.length} cierres para mostrar en tabla');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withValues(alpha: 0.05),
          ),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          columns: [
            DataColumn(
              label: Text(
                'Fecha/Periodo',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Usuario',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Total Neto: Suma de todas las ventas del día (efectivo + tarjeta + otros ingresos). Es el dinero total recibido sin incluir propinas.',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Neto',
                      style: TextStyle(
                        fontWeight: AppTheme.fontWeightSemibold,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.help_outline, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Dinero recibido en efectivo',
                child: Text(
                  'Efectivo',
                  style: TextStyle(
                    fontWeight: AppTheme.fontWeightSemibold,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Dinero recibido con tarjeta de crédito/débito',
                child: Text(
                  'Tarjeta',
                  style: TextStyle(
                    fontWeight: AppTheme.fontWeightSemibold,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Tooltip(
                message: 'Estados: Pendiente (revisión pendiente), Aprobado (verificado), Rechazado (con problemas), Aclaración (requiere más información)',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Estado',
                      style: TextStyle(
                        fontWeight: AppTheme.fontWeightSemibold,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Acciones',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightSemibold,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
          ],
          rows: closures.map((closure) {
            final hasNotes = closure.notaCajero != null && closure.notaCajero!.isNotEmpty;
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(closure.fecha),
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasNotes)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.note_alt,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    closure.usuario,
                    style: TextStyle(fontSize: isTablet ? 13 : 11),
                  ),
                ),
                DataCell(
                  Text(
                    '\$${closure.totalNeto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '\$${closure.efectivo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '\$${closure.tarjeta.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: _getStatusDescription(closure.estado),
                    child: Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(closure.estado),
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            CashCloseStatus.getStatusText(closure.estado),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: CashCloseStatus.getStatusColor(
                        closure.estado,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón ver detalles
                      Tooltip(
                        message: 'Ver detalles${hasNotes ? ' (tiene notas)' : ''}',
                        child: IconButton(
                          icon: Icon(
                            hasNotes ? Icons.visibility : Icons.visibility_outlined,
                            size: 18,
                            color: hasNotes ? Colors.amber.shade700 : AppColors.primary,
                          ),
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
                      // Botones de acción (mostrar para estados pending y clarification)
                      if (closure.cierreId != null && 
                          (closure.estado == CashCloseStatus.pending || 
                           closure.estado == CashCloseStatus.clarification)) ...[
                        SizedBox(width: 4),
                        // Botón aprobar (solo si está pendiente)
                        if (closure.estado == CashCloseStatus.pending)
                          Tooltip(
                            message: 'Aprobar cierre',
                            child: IconButton(
                              icon: const Icon(Icons.check_circle, size: 18),
                              color: Colors.green,
                              onPressed: () => _handleApproveClosure(context, closure, controller),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        // Botón rechazar (solo si está pendiente)
                        if (closure.estado == CashCloseStatus.pending)
                          Tooltip(
                            message: 'Rechazar cierre',
                            child: IconButton(
                              icon: const Icon(Icons.cancel, size: 18),
                              color: Colors.red,
                              onPressed: () => _handleRejectClosure(context, closure, controller),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        // Botón pedir aclaración (si está pendiente o ya en aclaración)
                        Tooltip(
                          message: closure.estado == CashCloseStatus.clarification 
                              ? 'Ver aclaración solicitada' 
                              : 'Pedir aclaración',
                          child: IconButton(
                            icon: Icon(
                              closure.estado == CashCloseStatus.clarification 
                                  ? Icons.info_outline 
                                  : Icons.help_outline, 
                              size: 18,
                            ),
                            color: Colors.blue,
                            onPressed: () => _handleRequestClarification(context, closure, controller),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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
        builder: (context, setState) => Dialog(
          child: Container(
            width: isTablet ? 700 : (MediaQuery.of(context).size.width * 0.9),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          'Detalle del cierre',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Contenido del modal
                Expanded(
                  child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información básica mejorada
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                                  'Cierre de caja',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  closure.id,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: _getStatusDescription(closure.estado),
                            child: Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(closure.estado),
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    CashCloseStatus.getStatusText(closure.estado),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: CashCloseStatus.getStatusColor(
                                closure.estado,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingMD),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Usuario',
                              closure.usuario,
                              Icons.person,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Período',
                              closure.periodo,
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingSM),
                      _buildInfoItem(
                        context,
                        'Fecha',
                        _formatDate(closure.fecha),
                        Icons.access_time,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.spacingMD),

                // Explicación de Total Neto
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          'Total Neto: Suma de todas las ventas del día (efectivo + tarjeta + otros ingresos). Es el dinero total recibido sin incluir propinas.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      tooltip: 'Suma total de ventas sin propinas',
                    ),
                    _buildSummaryCard(
                      'Efectivo Contado',
                      '\$${closure.efectivoContado.toStringAsFixed(2)}',
                      Colors.green,
                      isTablet,
                      tooltip: 'Dinero en efectivo que el cajero contó físicamente',
                    ),
                    _buildSummaryCard(
                      'Tarjeta Total',
                      '\$${closure.totalTarjeta.toStringAsFixed(2)}',
                      Colors.blue,
                      isTablet,
                      tooltip: 'Total de pagos recibidos con tarjeta',
                    ),
                    _buildSummaryCard(
                      'Propinas Tarjeta',
                      '\$${closure.propinasTarjeta.toStringAsFixed(2)}',
                      Colors.purple,
                      isTablet,
                      tooltip: 'Propinas recibidas por pagos con tarjeta',
                    ),
                    _buildSummaryCard(
                      'Propinas Efectivo',
                      '\$${closure.propinasEfectivo.toStringAsFixed(2)}',
                      Colors.orange,
                      isTablet,
                      tooltip: 'Propinas recibidas en efectivo',
                    ),
                    if (closure.otrosIngresos > 0)
                      _buildSummaryCard(
                        'Otros Ingresos',
                        '\$${closure.otrosIngresos.toStringAsFixed(2)}',
                        Colors.teal,
                        isTablet,
                        tooltip: closure.otrosIngresosTexto ?? 'Otros ingresos adicionales',
                      ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),

                // Notas del cajero
                if (closure.notaCajero != null && closure.notaCajero!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note_alt,
                              size: 20,
                              color: Colors.amber.shade800,
                            ),
                            SizedBox(width: AppTheme.spacingSM),
                            Text(
                              'Notas del Cajero',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingSM),
                        Text(
                          closure.notaCajero!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                ],

                // Otros ingresos texto si existe
                if (closure.otrosIngresosTexto != null && closure.otrosIngresosTexto!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSM),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.teal.shade800,
                        ),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Otros Ingresos',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacingXS),
                              Text(
                                closure.otrosIngresosTexto!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                ],

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
                  for (final log in closure.auditLog)
                    Padding(
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
                    ),
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
                ),
                // Footer con botones
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                      SizedBox(width: AppTheme.spacingSM),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para tarjeta de resumen
  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    bool isTablet, {
    String? tooltip,
  }) {
    final cardContent = Container(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (tooltip != null)
                Tooltip(
                  message: tooltip,
                  child: Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary),
                ),
            ],
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

    return tooltip != null ? Tooltip(message: tooltip, child: cardContent) : cardContent;
  }

  // Helper para obtener icono según estado
  IconData _getStatusIcon(String status) {
    switch (status) {
      case CashCloseStatus.pending:
        return Icons.pending;
      case CashCloseStatus.approved:
        return Icons.check_circle;
      case CashCloseStatus.rejected:
        return Icons.cancel;
      case CashCloseStatus.clarification:
        return Icons.help_outline;
      default:
        return Icons.help;
    }
  }

  // Helper para obtener descripción del estado
  String _getStatusDescription(String status) {
    switch (status) {
      case CashCloseStatus.pending:
        return 'Pendiente: El cierre está esperando revisión del administrador. El cajero lo envió pero aún no ha sido verificado.';
      case CashCloseStatus.approved:
        return 'Aprobado: El administrador verificó y aprobó este cierre de caja. Todo está correcto.';
      case CashCloseStatus.rejected:
        return 'Rechazado: El administrador encontró problemas en este cierre y lo rechazó. Se requiere atención.';
      case CashCloseStatus.clarification:
        return 'Aclaración: El administrador necesita más información sobre este cierre. Se solicitaron detalles adicionales.';
      default:
        return 'Estado desconocido: No se pudo determinar el estado de este cierre.';
    }
  }

  // Widget helper para mostrar información con icono
  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        SizedBox(width: AppTheme.spacingXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Métodos para manejar acciones de cierres
  Future<void> _handleApproveClosure(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar cierre de caja'),
        content: const Text('¿Estás seguro de que deseas aprobar este cierre de caja?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmado == true && closure.cierreId != null) {
      try {
        await controller.actualizarEstadoCierre(
          cierreId: closure.cierreId!,
          estado: CashCloseStatus.approved,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cierre de caja aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al aprobar cierre: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRejectClosure(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
  ) async {
    final comentarioController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar cierre de caja'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Estás seguro de que deseas rechazar este cierre de caja?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text('Comentario (opcional):'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: comentarioController,
                  decoration: const InputDecoration(
                    hintText: 'Explica el motivo del rechazo...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmado == true && closure.cierreId != null) {
      try {
        await controller.actualizarEstadoCierre(
          cierreId: closure.cierreId!,
          estado: CashCloseStatus.rejected,
          comentarioRevision: comentarioController.text.trim().isEmpty
              ? null
              : comentarioController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cierre de caja rechazado exitosamente'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar cierre: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRequestClarification(
    BuildContext context,
    CashCloseModel closure,
    AdminController controller,
  ) async {
    final comentarioController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedir aclaración'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Qué información necesitas que el cajero aclare?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text('Solicitud de aclaración:'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: comentarioController,
                  decoration: const InputDecoration(
                    hintText: 'Describe qué información necesitas...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, describe qué información necesitas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );

    if (confirmado == true && closure.cierreId != null) {
      try {
        await controller.actualizarEstadoCierre(
          cierreId: closure.cierreId!,
          estado: CashCloseStatus.clarification,
          comentarioRevision: comentarioController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud de aclaración enviada exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar solicitud: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                initialValue: controller.selectedCashCloseStatus,
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
                  '✓ $verifiedCount | ⚠ $clarificationCount | ⏳ $pendingCount',
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
              
              // Notas del cajero
              if (closure.notaCajero != null && closure.notaCajero!.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt,
                            size: 20,
                            color: Colors.amber.shade800,
                          ),
                          SizedBox(width: AppTheme.spacingSM),
                          Text(
                            'Notas del Cajero',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingSM),
                      Text(
                        closure.notaCajero!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Otros ingresos texto si existe
              if (closure.otrosIngresosTexto != null && closure.otrosIngresosTexto!.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.teal.shade800,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Otros Ingresos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade900,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingXS),
                            Text(
                              closure.otrosIngresosTexto!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppTheme.spacingMD),

              // Historial de auditoría
              const Text(
                'Historial de Auditoría',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingSM),
              for (final log in closure.auditLog)
                Padding(
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
                ),

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
        for (final order in orders)
          Card(
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
      ],
    );
  }

  Widget _buildDailyConsumptionCards(
    BuildContext context,
    AdminController controller,
    bool isTablet,
  ) {
    final cards = _getDailyConsumptionCards(controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppTheme.spacingMD;
        const targetWidth = 210.0;
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = (maxWidth / (targetWidth + spacing))
            .floor()
            .clamp(1, 5);
        final itemWidth =
            (maxWidth -
                spacing * (crossAxisCount > 1 ? crossAxisCount - 1 : 0)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _SummaryCard(card: card, isTablet: isTablet),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<_SummaryCardData> _getDailyConsumptionCards(AdminController controller) {
    final localSales = controller.todayLocalSales;
    final takeawaySales = controller.todayTakeawaySales;
    final cashSales = controller.todayCashSales;
    final pendingTotal = controller.pendingCollectionsTotal;
    final totalNet = controller.todayTotalSales;
    final localOrdersCount = controller.todayLocalOrdersCount;
    final takeawayOrdersCount = controller.todayTakeawayOrdersCount;
    final pendingCount = controller.pendingCollectionsCount;

    return [
      _SummaryCardData(
        title: 'Ventas en Local',
        value: controller.formatCurrency(localSales),
        subtitle: localOrdersCount > 0
            ? '$localOrdersCount ${localOrdersCount == 1 ? 'orden' : 'órdenes'}'
            : 'Sin órdenes',
        color: AppColors.success,
        icon: Icons.storefront,
      ),
      _SummaryCardData(
        title: 'Ventas Para llevar',
        value: controller.formatCurrency(takeawaySales),
        subtitle: takeawayOrdersCount > 0
            ? '$takeawayOrdersCount ${takeawayOrdersCount == 1 ? 'pedido' : 'pedidos'}'
            : 'Sin pedidos',
        color: AppColors.info,
        icon: Icons.delivery_dining,
      ),
      _SummaryCardData(
        title: 'Ventas Efectivo',
        value: controller.formatCurrency(cashSales),
        subtitle: cashSales > 0 ? 'Incluye pagos mixtos' : 'Sin ventas en efectivo',
        color: AppColors.primary,
        icon: Icons.payments,
      ),
      _SummaryCardData(
        title: 'Por cobrar',
        value: controller.formatCurrency(pendingTotal),
        subtitle: pendingCount > 0
            ? '$pendingCount ${pendingCount == 1 ? 'ticket' : 'tickets'} pendientes'
            : 'Sin tickets pendientes',
        color: AppColors.error,
        icon: Icons.pending_actions,
      ),
      _SummaryCardData(
        title: 'Total Neto',
        value: controller.formatCurrency(totalNet),
        subtitle: totalNet > 0 ? 'Incluye efectivo y tarjeta' : 'Sin ventas registradas',
        color: AppColors.info,
        icon: Icons.analytics,
      ),
    ];
  }

  List<_ConsumptionRecord> _buildConsumptionRecords(
    AdminController controller,
  ) {
    final payments = controller.filteredDailyPayments;
    if (payments.isEmpty) {
      return [];
    }

    return payments.map((payment) {
      final isTakeaway = payment.tableNumber == null;
      final originLabel = isTakeaway
          ? 'Para llevar'
          : 'Mesa ${payment.tableNumber}';
      final products = <String>[];
      if ((payment.notes ?? '').isNotEmpty) {
        products.add(payment.notes!);
      }

      return _ConsumptionRecord(
        id: payment.billId,
        originType: isTakeaway ? 'para_llevar' : 'mesa',
        originLabel: originLabel,
        products: products,
        total: controller.formatCurrency(payment.totalAmount),
        paymentMethod: payment_models.PaymentType.getTypeText(payment.type),
        status: payment.voucherPrinted == true ? 'Cobrado' : 'Por imprimir',
        time: DateFormat('HH:mm').format(payment.timestamp),
        waiter: payment.cashierName,
      );
    }).toList();
  }

  Future<void> _handleMenuCategoryDeletion(
    BuildContext context,
    AdminController controller,
    String category,
  ) async {
    final isCustom = controller.isCustomCategory(category);
    final hasProducts = controller.categoryHasProducts(category);
    
    String message;
    Color backgroundColor;

    try {
      final deleted = await controller.deleteCustomCategory(category);
      
      if (deleted) {
        message = 'Categoría "$category" eliminada.';
        backgroundColor = AppColors.success;
      } else {
        if (!isCustom) {
          message =
              'La categoría "$category" es predeterminada y no se puede eliminar.';
        } else if (hasProducts) {
          message =
              'No puedes eliminar la categoría "$category" porque tiene productos asociados.';
        } else {
          message = 'No fue posible eliminar la categoría "$category".';
        }
        backgroundColor = AppColors.error;
      }
    } catch (e) {
      message = 'Error al eliminar categoría: ${e.toString()}';
      backgroundColor = AppColors.error;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleInventoryCategoryDeletion(
    BuildContext context,
    AdminController controller,
    String category,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Por ahora la categoría "$category" es predeterminada y no se puede eliminar.',
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTicketSummarySection(
    BuildContext context,
    List<payment_models.BillModel> tickets,
    bool isTablet,
    bool isDesktop,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_MX',
      symbol: r'$',
      decimalDigits: 0,
    );
    final totalTickets = tickets.length;
    final totalAmount = tickets.fold<double>(
      0.0,
      (sum, ticket) => sum + ticket.total,
    );
    final pendingCount = tickets
        .where((ticket) => ticket.status == payment_models.BillStatus.pending)
        .length;
    final printedCount = tickets
        .where(
          (ticket) =>
              ticket.status == payment_models.BillStatus.printed ||
              ticket.isPrinted,
        )
        .length;

    final cards = [
      _SummaryCardData(
        title: 'Total Tickets',
        value: '$totalTickets',
        subtitle: 'En el sistema',
        color: AppColors.primary,
        icon: Icons.receipt_long,
      ),
      _SummaryCardData(
        title: 'Valor Total',
        value: currencyFormat.format(totalAmount),
        subtitle: 'Suma de todos los tickets',
        color: AppColors.success,
        icon: Icons.attach_money,
      ),
      _SummaryCardData(
        title: 'Pendientes',
        value: '$pendingCount',
        subtitle: 'Por imprimir',
        color: AppColors.warning,
        icon: Icons.schedule,
      ),
      _SummaryCardData(
        title: 'Impresos',
        value: '$printedCount',
        subtitle: 'Listos para entrega',
        color: AppColors.info,
        icon: Icons.print,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppTheme.spacingMD;
        final targetWidth = isDesktop ? 220.0 : 200.0;
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = (maxWidth / (targetWidth + spacing))
            .floor()
            .clamp(1, 4);
        final itemWidth =
            (maxWidth -
                spacing * (crossAxisCount > 1 ? crossAxisCount - 1 : 0)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _SummaryCard(card: card, isTablet: isTablet),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData card;
  final bool isTablet;

  const _SummaryCard({required this.card, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingLG : AppTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: card.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, color: card.color),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: isTablet
                        ? AppTheme.fontSizeSM
                        : AppTheme.fontSizeXS,
                    fontWeight: AppTheme.fontWeightSemibold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSM),
          Text(
            card.value,
            style: TextStyle(
              fontSize: isTablet ? AppTheme.fontSize3XL : AppTheme.fontSize2XL,
              fontWeight: AppTheme.fontWeightBold,
              color: card.color,
            ),
          ),
          if (card.subtitle.isNotEmpty) ...[
            SizedBox(height: AppTheme.spacingXS),
            Text(
              card.subtitle,
              style: TextStyle(
                fontSize: isTablet ? AppTheme.fontSizeSM : AppTheme.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsumptionRecord {
  final String id;
  final String originType;
  final String originLabel;
  final List<String> products;
  final String total;
  final String paymentMethod;
  final String status;
  final String time;
  final String waiter;

  const _ConsumptionRecord({
    required this.id,
    required this.originType,
    required this.originLabel,
    required this.products,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.time,
    required this.waiter,
  });

  bool get isTakeaway => originType == 'para_llevar';
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
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  bool isCustom = false;
  bool autoDeduct = true;
  late List<String> categories;
  String? selectedCategory;
  String? selectedInventoryItemId;

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    categories = widget.controller.getInventoryCategories();
    if (categories.isEmpty) {
      categories = ['Otros'];
    }
    selectedCategory = categories.first;
    final items = _itemsForSelectedCategory();
    if (items.isEmpty) {
      isCustom = true;
    } else {
      final first = items.first;
      selectedInventoryItemId = first.id;
      nameController.text = first.name;
      unitController.text = first.unit;
    }
  }

  List<InventoryItem> _itemsForSelectedCategory() {
    if (selectedCategory == null) return [];
    return widget.controller.getInventoryItemsByCategory(selectedCategory!);
  }

  void _syncInventorySelection() {
    if (isCustom) return;
    final items = _itemsForSelectedCategory();
    if (items.isEmpty) {
      setState(() {
        selectedInventoryItemId = null;
        nameController.clear();
        unitController.clear();
      });
      return;
    }

    final selected = items.firstWhere(
      (item) => item.id == selectedInventoryItemId,
      orElse: () => items.first,
    );

    setState(() {
      selectedInventoryItemId = selected.id;
      nameController.text = selected.name;
      unitController.text = selected.unit;
    });
  }

  void _toggleCustomMode(bool value) {
    if (!value) {
      final items = _itemsForSelectedCategory();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ingredientes en esta categoría. Agrega uno personalizado.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    setState(() {
      isCustom = value;
      if (!isCustom) {
        _syncInventorySelection();
      } else {
        selectedInventoryItemId = null;
        nameController.clear();
        unitController.clear();
      }
    });
  }

  void _resetForm() {
    final hasInventory = _itemsForSelectedCategory().isNotEmpty;
    setState(() {
      nameController.clear();
      unitController.clear();
      quantityController.text = '1';
      autoDeduct = true;
      isCustom = !hasInventory;
      selectedInventoryItemId = null;
    });
    if (hasInventory) {
      _syncInventorySelection();
    }
  }

  void _handleAddIngredient() {
    if (!formKey.currentState!.validate()) return;

    InventoryItem? selectedInventory;
    if (!isCustom) {
      final items = _itemsForSelectedCategory();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ingredientes en esta categoría. Agrega uno personalizado.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      selectedInventory = items.firstWhere(
        (item) => item.id == selectedInventoryItemId,
        orElse: () => items.first,
      );
    }

    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser mayor a 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ingredientName = (isCustom ? nameController.text : selectedInventory?.name)?.trim() ?? '';
    final ingredientUnit = (isCustom ? unitController.text : selectedInventory?.unit)?.trim() ?? '';

    final newIngredient = RecipeIngredient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: ingredientName,
      unit: ingredientUnit,
      quantityPerPortion: quantity,
      autoDeduct: !isCustom && autoDeduct,
      isCustom: isCustom || selectedInventory == null,
      category: selectedCategory,
      inventoryItemId: selectedInventory?.id,
    );

    final updatedIngredients = [
      ...widget.ingredients,
      newIngredient,
    ];
    widget.onSave(updatedIngredients);
    _resetForm();
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
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedCategory = value;
                selectedInventoryItemId = null;
              });
              if (!isCustom) {
                _syncInventorySelection();
              }
            },
          ),
          SizedBox(height: AppTheme.spacingMD),
          if (!isCustom)
            Builder(builder: (context) {
              final items = _itemsForSelectedCategory();
              if (items.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Text(
                        'No hay ingredientes en esta categoría. Puedes agregar uno personalizado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingMD),
                    TextButton.icon(
                      onPressed: () => _toggleCustomMode(true),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ingrediente personalizado'),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedInventoryItemId ?? items.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Ingrediente del inventario',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text('${item.name} (${item.unit})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedInventoryItemId = value;
                      });
                      _syncInventorySelection();
                    },
                    validator: (value) {
                      if (isCustom) return null;
                      if (value == null || value.isEmpty) {
                        return 'Selecciona un ingrediente';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                ],
              );
            }),
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
          ] else ...[
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unidad',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: AppTheme.spacingMD),
          ],
          TextFormField(
            controller: quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad por porción *',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            subtitle: isCustom
                ? const Text('Disponible solo para ingredientes del inventario')
                : null,
            value: autoDeduct,
            onChanged: isCustom
                ? null
                : (value) {
                    setState(() {
                      autoDeduct = value;
                    });
                  },
          ),
          SizedBox(height: AppTheme.spacingMD),
          if (!isCustom)
            TextButton.icon(
              onPressed: () => _toggleCustomMode(true),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ingrediente personalizado'),
            )
          else
            TextButton.icon(
              onPressed: () => _toggleCustomMode(false),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Volver a sugeridos'),
            ),
          SizedBox(height: AppTheme.spacingMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _resetForm,
                child: const Text('Limpiar'),
              ),
              SizedBox(width: AppTheme.spacingSM),
              ElevatedButton(
                onPressed: _handleAddIngredient,
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

// Widget para mostrar el ticket completo en formato de impresión
class _TicketDetailsModal extends StatefulWidget {
  final payment_models.BillModel ticket;
  final bool isTablet;

  const _TicketDetailsModal({
    required this.ticket,
    required this.isTablet,
  });

  @override
  State<_TicketDetailsModal> createState() => _TicketDetailsModalState();
}

class _TicketDetailsModalState extends State<_TicketDetailsModal> {
  Map<String, dynamic>? _ordenData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrdenData();
  }

  Future<void> _loadOrdenData() async {
    try {
      final ordenesService = OrdenesService();
      
      // Detectar si es cuenta agrupada
      final isGrouped = (widget.ticket.isGrouped == true) || 
                       widget.ticket.id.startsWith('CUENTA-AGRUPADA-');
      
      // Obtener lista de ordenIds
      List<int> ordenIdsToLoad;
      if (isGrouped && widget.ticket.ordenIds != null && widget.ticket.ordenIds!.isNotEmpty) {
        // Usar ordenIds del ticket si están disponibles
        ordenIdsToLoad = widget.ticket.ordenIds!;
      } else if (isGrouped) {
        // Extraer ordenIds del ID del ticket (formato CUENTA-AGRUPADA-000084-000085-000086)
        final parts = widget.ticket.id.replaceFirst('CUENTA-AGRUPADA-', '').split('-');
        ordenIdsToLoad = parts
            .map((part) => int.tryParse(part))
            .whereType<int>()
            .toList();
      } else if (widget.ticket.ordenId != null) {
        ordenIdsToLoad = [widget.ticket.ordenId!];
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No hay orden asociada a este ticket';
        });
        return;
      }

      if (ordenIdsToLoad.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron extraer los IDs de las órdenes';
        });
        return;
      }

      // Obtener datos de todas las órdenes
      final List<Map<String, dynamic>> todasLasOrdenes = [];
      double subtotalTotal = 0.0;
      double descuentoTotal = 0.0;
      double impuestoTotal = 0.0;
      double propinaTotal = 0.0;
      double totalTotal = 0.0;
      final List<dynamic> todosLosItems = [];
      
      String? mesaCodigo;
      String? clienteNombre;
      String? clienteTelefono;
      String? waiterName;
      DateTime? fechaMasAntigua;

      for (final ordenId in ordenIdsToLoad) {
        final ordenData = await ordenesService.getOrden(ordenId);
        if (ordenData != null) {
          todasLasOrdenes.add(ordenData);
          
          // Acumular totales
          subtotalTotal += (ordenData['subtotal'] as num?)?.toDouble() ?? 0.0;
          descuentoTotal += (ordenData['descuentoTotal'] as num?)?.toDouble() ?? 0.0;
          impuestoTotal += (ordenData['impuestoTotal'] as num?)?.toDouble() ?? 0.0;
          propinaTotal += (ordenData['propinaSugerida'] as num?)?.toDouble() ?? 0.0;
          totalTotal += (ordenData['total'] as num?)?.toDouble() ?? 0.0;
          
          // Combinar items, asegurando que los precios estén correctos
          final items = ordenData['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            // Asegurar que los precios estén correctamente calculados
            final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
            final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
            final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
            
            // Si totalLinea es 0 o incorrecto, recalcular
            double totalLineaCalculado = precioUnitario * cantidad;
            
            // Si hay modificadores, sumar sus precios
            final modificadores = item['modificadores'] as List<dynamic>? ?? [];
            double totalModificadores = 0.0;
            for (final mod in modificadores) {
              final modPrecio = (mod['precioUnitario'] as num?)?.toDouble() ?? 0.0;
              totalModificadores += modPrecio * cantidad;
            }
            
            totalLineaCalculado += totalModificadores;
            
            // Usar el totalLinea del backend si es razonable, de lo contrario usar el calculado
            final totalLineaFinal = (totalLineaBackend <= 0.01 || 
                                   (totalLineaBackend - totalLineaCalculado).abs() > 0.01)
                ? totalLineaCalculado
                : totalLineaBackend;
            
            // Si precioUnitario es 0 pero totalLinea tiene valor, calcular precio unitario
            double precioUnitarioFinal = precioUnitario;
            if (precioUnitarioFinal <= 0.01 && totalLineaFinal > 0.01 && cantidad > 0) {
              precioUnitarioFinal = (totalLineaFinal - totalModificadores) / cantidad;
            }
            
            // Crear una copia del item con los valores corregidos
            final itemCorregido = Map<String, dynamic>.from(item);
            itemCorregido['precioUnitario'] = precioUnitarioFinal;
            itemCorregido['totalLinea'] = totalLineaFinal;
            
            todosLosItems.add(itemCorregido);
          }
          
          // Tomar datos de la primera orden (o la que tenga mesa si es para mesa)
          if (mesaCodigo == null) mesaCodigo = ordenData['mesaCodigo'] as String?;
          if (clienteNombre == null) clienteNombre = ordenData['clienteNombre'] as String?;
          if (clienteTelefono == null) clienteTelefono = ordenData['clienteTelefono'] as String?;
          if (waiterName == null) waiterName = ordenData['creadoPorNombre'] as String?;
          
          // Fecha más antigua
          final fechaOrdenStr = ordenData['creadoEn'] as String?;
          if (fechaOrdenStr != null) {
            try {
              final fechaOrden = DateTime.parse(fechaOrdenStr);
              final fechaComparar = fechaMasAntigua;
              if (fechaComparar == null || fechaOrden.isBefore(fechaComparar)) {
                fechaMasAntigua = fechaOrden;
              }
            } catch (e) {
              // Ignorar errores de parsing de fecha
            }
          }
        }
      }

      if (todasLasOrdenes.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron cargar los datos de las órdenes';
        });
        return;
      }

      // Construir el objeto combinado
      final ordenDataCombinado = {
        'items': todosLosItems,
        'subtotal': subtotalTotal,
        'descuentoTotal': descuentoTotal,
        'impuestoTotal': impuestoTotal,
        'propinaSugerida': propinaTotal,
        'total': totalTotal,
        'mesaCodigo': mesaCodigo,
        'clienteNombre': clienteNombre,
        'clienteTelefono': clienteTelefono,
        'creadoPorNombre': waiterName,
        'creadoEn': fechaMasAntigua?.toIso8601String() ?? widget.ticket.createdAt.toIso8601String(),
        'folio': isGrouped 
            ? 'CUENTA AGRUPADA (${ordenIdsToLoad.map((id) => 'ORD-${id.toString().padLeft(6, '0')}').join(', ')})'
            : 'ORD-${ordenIdsToLoad.first.toString().padLeft(6, '0')}',
      };

      setState(() {
        _ordenData = ordenDataCombinado;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los datos de la orden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: widget.isTablet ? 600 : double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: EdgeInsets.all(widget.isTablet ? 24.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket de Cobro',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contenido
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: _buildTicketContent(),
                        ),
            ),
            
            // Botón cerrar
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketContent() {
    if (_ordenData == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final items = _ordenData!['items'] as List<dynamic>? ?? [];
    final subtotal = (_ordenData!['subtotal'] as num?)?.toDouble() ?? 0.0;
    final descuento = (_ordenData!['descuentoTotal'] as num?)?.toDouble() ?? 0.0;
    final impuesto = (_ordenData!['impuestoTotal'] as num?)?.toDouble() ?? 0.0;
    final propina = (_ordenData!['propinaSugerida'] as num?)?.toDouble() ?? 0.0;
    final total = (_ordenData!['total'] as num?)?.toDouble() ?? 0.0;
    final mesaCodigo = _ordenData!['mesaCodigo'] as String?;
    final clienteNombre = _ordenData!['clienteNombre'] as String?;
    final clienteTelefono = _ordenData!['clienteTelefono'] as String?;
    final folio = _ordenData!['folio'] as String? ?? widget.ticket.id;
    final splitCount = widget.ticket.splitCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado del ticket
        Center(
          child: Column(
            children: [
              Text(
                'TICKET DE COBRO',
                style: TextStyle(
                  fontSize: widget.isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                folio,
                style: TextStyle(
                  fontSize: widget.isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(widget.ticket.createdAt),
                style: TextStyle(
                  fontSize: widget.isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Línea punteada
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          height: 1,
          child: CustomPaint(painter: _DashedLinePainter()),
        ),

        // Banner destacado para pedidos para llevar
        if (clienteNombre != null && mesaCodigo == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: widget.isTablet ? 24.0 : 20.0,
                ),
                const SizedBox(width: 8),
                Text(
                  '*** PARA LLEVAR ***',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Información de mesa/cliente
        if (mesaCodigo != null || clienteNombre != null) ...[
          if (mesaCodigo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.table_restaurant, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Mesa: $mesaCodigo',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (clienteNombre != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Cliente: $clienteNombre',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14.0 : 12.0,
                        ),
                      ),
                    ],
                  ),
                  if (clienteTelefono != null && clienteTelefono.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Teléfono: $clienteTelefono',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 13.0 : 11.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],

        // Productos
        Container(
          padding: EdgeInsets.all(widget.isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productos',
                style: TextStyle(
                  fontSize: widget.isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
                final productoNombre = item['productoNombre'] as String? ?? 'Producto';
                final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
                final modificadores = item['modificadores'] as List<dynamic>? ?? [];
                final nota = item['nota'] as String?;
                
                // Calcular total de modificadores
                double totalModificadores = 0.0;
                for (final mod in modificadores) {
                  final modPrecio = (mod['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                  totalModificadores += modPrecio * cantidad;
                }
                
                // Calcular totalLinea correctamente
                double totalLineaCalculado = (precioUnitario * cantidad) + totalModificadores;
                final totalLinea = (totalLineaBackend <= 0.01 || 
                                   (totalLineaBackend - totalLineaCalculado).abs() > 0.01)
                    ? totalLineaCalculado
                    : totalLineaBackend;
                
                // Si precioUnitario es 0 pero tenemos totalLinea, calcular precio unitario
                double precioUnitarioFinal = precioUnitario;
                if (precioUnitarioFinal <= 0.01 && totalLinea > 0.01 && cantidad > 0) {
                  precioUnitarioFinal = (totalLinea - totalModificadores) / cantidad;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cantidad.toInt()}x',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 14.0 : 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        productoNombre,
                                        style: TextStyle(
                                          fontSize: widget.isTablet ? 14.0 : 12.0,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (precioUnitarioFinal > 0.01 && cantidad > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '\$${precioUnitarioFinal.toStringAsFixed(2)} c/u',
                                          style: TextStyle(
                                            fontSize: widget.isTablet ? 11.0 : 10.0,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                // Modificadores
                                if (modificadores.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ...modificadores.map((mod) {
                                    final modNombre = mod['nombre'] as String? ?? '';
                                    final modPrecio = (mod['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                                      child: Row(
                                        children: [
                                          const Text('  + ', style: TextStyle(fontSize: 10)),
                                          Expanded(
                                            child: Text(
                                              modNombre,
                                              style: TextStyle(
                                                fontSize: widget.isTablet ? 11.0 : 10.0,
                                                color: AppColors.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                          if (modPrecio > 0)
                                            Text(
                                              '\$${modPrecio.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: widget.isTablet ? 11.0 : 10.0,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                // Nota del producto
                                if (nota != null && nota.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Nota: $nota',
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 10.0 : 9.0,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (precioUnitarioFinal > 0.01 && cantidad == 1)
                                Text(
                                  '\$${precioUnitarioFinal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: widget.isTablet ? 11.0 : 10.0,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else if (precioUnitarioFinal > 0.01)
                                Text(
                                  '\$${precioUnitarioFinal.toStringAsFixed(2)} c/u',
                                  style: TextStyle(
                                    fontSize: widget.isTablet ? 10.0 : 9.0,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${totalLinea.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: widget.isTablet ? 14.0 : 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Resumen financiero
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14.0 : 12.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (descuento > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Descuento:',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '-\$${descuento.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
              if (impuesto > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Impuesto:',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${impuesto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
              if (propina > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Propina sugerida:',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${propina.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 2),
                    bottom: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (splitCount > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(widget.isTablet ? 12.0 : 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total por persona (${splitCount} ${splitCount == 1 ? 'persona' : 'personas'}):',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '\$${(total / splitCount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Información de impresión
        if (widget.ticket.printedBy != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.print, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Impreso por: ${widget.ticket.printedBy}',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 11.0 : 10.0,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Painter para línea punteada estilo ticket
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
