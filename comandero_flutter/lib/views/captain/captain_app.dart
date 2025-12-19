import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/captain_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cocinero_controller.dart';
import '../../models/captain_model.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/logout_button.dart';
import '../cocinero/order_detail_modal.dart';
import 'alert_to_kitchen_modal.dart';

class CaptainApp extends StatefulWidget {
  const CaptainApp({super.key});

  @override
  State<CaptainApp> createState() => _CaptainAppState();
}

class _CaptainAppState extends State<CaptainApp> {
  late CaptainController _captainController;
  late CocineroController _cocineroController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _captainController = CaptainController();
    _cocineroController = CocineroController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Cargar órdenes del backend para el capitán
    await _cocineroController.loadOrders();
    await _captainController.loadTables();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _captainController.dispose();
    _cocineroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _captainController),
        ChangeNotifierProvider.value(value: _cocineroController),
      ],
      child: Consumer3<CaptainController, AuthController, CocineroController>(
        builder:
            (
              context,
              captainController,
              authController,
              cocineroController,
              child,
            ) {
              if (!_initialized) {
                return Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando datos del capitán...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

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
                    body: RefreshIndicator(
                      onRefresh: _initializeData,
                      child: _buildBody(
                        context,
                        captainController,
                        cocineroController,
                        isTablet,
                        isDesktop,
                      ),
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
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Solo lectura',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
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
    CaptainController captainController,
    CocineroController cocineroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas de resumen
          _buildSummaryCards(captainController, isTablet),
          const SizedBox(height: 24),

          // Layout principal: Alertas a la izquierda, Órdenes/Cuentas a la derecha
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // Desktop: lado a lado
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda: Alertas y Órdenes Recientes
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildAlertsSection(
                            context,
                            captainController,
                            cocineroController,
                            isTablet,
                          ),
                          const SizedBox(height: 24),
                          _buildRecentOrdersSection(
                            context,
                            captainController,
                            cocineroController,
                            isTablet,
                          ),
                          const SizedBox(height: 24),
                          _buildTablesStatusSection(
                            context,
                            captainController,
                            isTablet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Columna derecha: Cuentas por Cobrar
                    Expanded(
                      flex: 1,
                      child: _buildAccountsToCollectSection(
                        context,
                        captainController,
                        isTablet,
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile/Tablet: vertical
                return Column(
                  children: [
                    _buildAlertsSection(
                      context,
                      captainController,
                      cocineroController,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildRecentOrdersSection(
                      context,
                      captainController,
                      cocineroController,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildAccountsToCollectSection(
                      context,
                      captainController,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildTablesStatusSection(
                      context,
                      captainController,
                      isTablet,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CaptainController controller, bool isTablet) {
    final stats = controller.stats;
    final pendingBills = controller.getPendingBillsAmount();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Ventas del Día',
                  controller.formatCurrency(stats.todaySales),
                  '+${stats.variation.replaceAll('%', '')}%',
                  Colors.green,
                  Icons.show_chart,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Órdenes',
                  '${stats.totalOrders}',
                  null,
                  Colors.purple,
                  Icons.attach_money,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Ticket Promedio',
                  controller.formatCurrency(stats.avgTicket),
                  null,
                  Colors.purple,
                  Icons.calculate,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Por Cobrar',
                  controller.formatCurrency(pendingBills),
                  null,
                  Colors.red,
                  Icons.error_outline,
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
                    child: _buildSummaryCard(
                      'Ventas del Día',
                      controller.formatCurrency(stats.todaySales),
                      '+${stats.variation.replaceAll('%', '')}%',
                      Colors.green,
                      Icons.show_chart,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Órdenes',
                      '${stats.totalOrders}',
                      null,
                      Colors.purple,
                      Icons.attach_money,
                      isTablet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Ticket Promedio',
                      controller.formatCurrency(stats.avgTicket),
                      null,
                      Colors.purple,
                      Icons.calculate,
                      isTablet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Por Cobrar',
                      controller.formatCurrency(pendingBills),
                      null,
                      Colors.red,
                      Icons.error_outline,
                      isTablet,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String? variation,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
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
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 10.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: isTablet ? 24.0 : 20.0,
                          fontWeight: FontWeight.bold,
                          color: color == Colors.red
                              ? Colors.red
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (variation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          variation,
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(icon, color: Colors.purple, size: isTablet ? 24.0 : 20.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    CaptainController controller,
    CocineroController cocineroController,
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
                Expanded(
                  child: Text(
                    'Alertas',
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      controller.clearAllAlerts();
                    },
                    icon: Icon(
                      Icons.clear_all,
                      size: isTablet ? 16.0 : 14.0,
                      color: Colors.red,
                    ),
                    label: Text(
                      'Limpiar todas',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                (alert) => _buildAlertCard(
                  context,
                  alert,
                  controller,
                  cocineroController,
                  isTablet,
                ),
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
    CocineroController cocineroController,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      AlertType.getTypeIcon(alert.type),
                      size: isTablet ? 20.0 : 18.0,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.orderNumber != null
                            ? 'Orden ${alert.orderNumber}'
                            : alert.title,
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 8),
          Text(
            alert.tableNumber != null
                ? 'Mesa ${alert.tableNumber} • ${_formatAlertMessage(alert.message)}'
                : 'Para llevar • ${_formatAlertMessage(alert.message)}',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _handleViewAlert(
                        context,
                        alert,
                        controller,
                        cocineroController,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Ver',
                        style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
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

  void _handleViewAlert(
    BuildContext context,
    CaptainAlert alert,
    CaptainController controller,
    CocineroController cocineroController,
  ) {
    // Abrir directamente el modal de orden sin mostrar diálogo intermedio
    _openOrderDetail(context, alert, controller, cocineroController);
  }

  void _openOrderDetail(
    BuildContext context,
    CaptainAlert alert,
    CaptainController controller,
    CocineroController cocineroController,
  ) {
    // Buscar la orden correspondiente en las órdenes del capitán
    final orders = controller.activeOrders;
    OrderModel? order;

    try {
      if (alert.orderNumber != null) {
        order = orders.firstWhere((o) => o.id == alert.orderNumber);
      } else if (alert.tableNumber != null) {
        // Buscar orden de mesa (no para llevar)
        order = orders.firstWhere(
          (o) => o.tableNumber == alert.tableNumber && !o.isTakeaway,
        );
      } else {
        // Si tableNumber es null, es una orden para llevar
        // Buscar por orderNumber si está disponible
        if (alert.orderNumber != null) {
          order = orders.firstWhere((o) => o.id == alert.orderNumber && o.isTakeaway);
        }
      }
    } catch (e) {
      // Orden no encontrada, intentar buscar por orderNumber como último recurso
      if (alert.orderNumber != null) {
        try {
          order = orders.firstWhere((o) => o.id == alert.orderNumber);
        } catch (_) {
          // Si aún no se encuentra, mostrar mensaje de error
        }
      }
    }

    if (order != null) {
      // Mostrar modal de detalle de orden
      OrderDetailModal.show(
        context,
        order: order,
        controller: cocineroController,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden no encontrada'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildRecentOrdersSection(
    BuildContext context,
    CaptainController controller,
    CocineroController cocineroController,
    bool isTablet,
  ) {
    // Usar las órdenes del controlador del capitán (ya filtradas y cargadas desde /api/ordenes)
    final orders = controller.filteredOrders
        .where(
          (o) =>
              o.status == OrderStatus.pendiente ||
              o.status == OrderStatus.enPreparacion ||
              o.status == OrderStatus.listo ||
              o.status == OrderStatus.listoParaRecoger,
        )
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Órdenes Recientes',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (orders.isEmpty)
              _buildEmptyOrders(isTablet)
            else
              ...orders
                  .take(3)
                  .map(
                    (order) => _buildRecentOrderCard(
                      context,
                      order,
                      controller,
                      isTablet,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(
    BuildContext context,
    OrderModel order,
    CaptainController controller,
    bool isTablet,
  ) {
    final statusColor = _getOrderStatusColor(order.status);
    final statusText = _getOrderStatusText(order.status);
    
    // Obtener información adicional de la orden (items como texto, total)
    final additionalData = controller.getOrderAdditionalData(order.id);
    final itemsText = (additionalData?['itemsText'] as List<dynamic>?)?.cast<String>() ?? 
                     order.items.map((item) => '${item.quantity}x ${item.name}').toList();
    final orderTotal = (additionalData?['total'] as num?)?.toDouble() ?? 
                      _calculateOrderTotal(order);
    
    // Formatear hora de la orden (HH:mm)
    final localOrderTime = order.orderTime.isUtc ? order.orderTime.toLocal() : order.orderTime;
    final orderHour = localOrderTime.hour.toString().padLeft(2, '0');
    final orderMinute = localOrderTime.minute.toString().padLeft(2, '0');
    final orderTimeText = '$orderHour:$orderMinute';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID de orden y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Tipo de orden: Para llevar o En mesa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: order.isTakeaway
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  order.isTakeaway ? Icons.shopping_bag_outlined : Icons.restaurant,
                  size: isTablet ? 14.0 : 12.0,
                  color: order.isTakeaway ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  order.isTakeaway || order.tableNumber == null
                      ? 'Para llevar' 
                      : 'Mesa ${order.tableNumber}',
                  style: TextStyle(
                    fontSize: isTablet ? 11.0 : 9.0,
                    fontWeight: FontWeight.w600,
                    color: (order.isTakeaway || order.tableNumber == null) ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Items del pedido
          Text(
            itemsText.join(', '),
            style: TextStyle(
              fontSize: isTablet ? 13.0 : 11.0,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Hora del pedido
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                orderTimeText,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botón de alerta y total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Abrir modal para enviar alerta a cocina (igual que mesero)
                  showCaptainAlertToKitchenModal(
                    context,
                    tableNumber: order.tableNumber?.toString() ?? 
                               (order.isTakeaway ? 'Para llevar' : 'N/A'),
                    orderId: order.id,
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Enviar Alerta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              Text(
                '\$${orderTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Calcular total de la orden basado en items
  double _calculateOrderTotal(OrderModel order) {
    // Si no hay datos adicionales, estimar basado en cantidad de items
    double estimatedTotal = 0.0;
    for (var item in order.items) {
      // Estimación simple: ~$20 por item
      estimatedTotal += 20.0 * item.quantity;
    }
    return estimatedTotal;
  }

  Widget _buildAccountsToCollectSection(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
  ) {
    final bills = controller.getPendingBills();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuentas por Cobrar',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (bills.isEmpty)
              _buildEmptyBills(isTablet)
            else
              ...bills
                  .take(2)
                  .map(
                    (bill) =>
                        _buildBillCard(context, bill, controller, isTablet),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(
    BuildContext context,
    dynamic bill,
    CaptainController controller,
    bool isTablet,
  ) {
    // Simular estructura de bill
    final billId = bill['id'] ?? 'BILL-001';
    final total = bill['total']?.toDouble() ?? 0.0;
    final waiter = bill['waiter'] ?? 'Mesero';
    final tableNumber = bill['tableNumber'];
    final isTakeaway = bill['isTakeaway'] ?? false;
    final customerName = bill['customerName'];
    final elapsedMinutes = bill['elapsedMinutes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tableNumber != null ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tableNumber != null ? 'Mesa $tableNumber' : 'Para llevar',
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  billId,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTakeaway && customerName != null
                ? 'Cliente: $customerName • Mesero: $waiter'
                : 'Mesero: $waiter',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatCurrency(total),
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  '$elapsedMinutes min sin cobrar',
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesStatusSection(
    BuildContext context,
    CaptainController controller,
    bool isTablet,
  ) {
    final tables = controller.filteredTables;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Estado de Mesas',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Solo lectura (Capitán)',
                    style: TextStyle(
                      fontSize: isTablet ? 10.0 : 8.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return _buildTableStatusCard(table, controller, isTablet);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableStatusCard(
    CaptainTable table,
    CaptainController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getTableStatusColor(table.status);
    final statusText = CaptainTableStatus.getStatusText(table.status);

    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mesa ${table.number}',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText.toLowerCase(),
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (table.customers != null) ...[
            const SizedBox(height: 4),
            Text(
              '${table.customers} pers.',
              style: TextStyle(
                fontSize: isTablet ? 10.0 : 8.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOrders(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.0 : 30.0),
      child: Center(
        child: Text(
          'No hay órdenes recientes',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBills(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.0 : 30.0),
      child: Center(
        child: Text(
          'No hay cuentas por cobrar',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case OrderStatus.pendiente:
        return Colors.red;
      case OrderStatus.enPreparacion:
        return Colors.amber.shade700; // Amarillo más fuerte
      case OrderStatus.listo:
        return Colors.green;
      case OrderStatus.listoParaRecoger:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case OrderStatus.pendiente:
        return 'PENDIENTE';
      case OrderStatus.enPreparacion:
        return 'PREPARANDO';
      case OrderStatus.listo:
        return 'LISTO';
      case OrderStatus.listoParaRecoger:
        return 'LISTO PARA RECOGER';
      default:
        return status.toUpperCase();
    }
  }

  // Formatear mensaje de alerta para mostrar estados de forma legible
  String _formatAlertMessage(String message) {
    // Reemplazar "en_preparacion" con "En preparación"
    String formatted = message.replaceAll('en_preparacion', 'En preparación');
    // También reemplazar variantes comunes
    formatted = formatted.replaceAll('en_preparación', 'En preparación');
    formatted = formatted.replaceAll('En_preparacion', 'En preparación');
    formatted = formatted.replaceAll('En_preparación', 'En preparación');
    return formatted;
  }

  // Estimar total de orden basado en items
}
