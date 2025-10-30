import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cajero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import 'cash_closure_view.dart';
import 'sales_reports_view.dart';
import 'cash_management_view.dart';
import 'payment_processing_view.dart';

class CajeroApp extends StatelessWidget {
  const CajeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CajeroController())],
      child: Consumer2<CajeroController, AuthController>(
        builder: (context, cajeroController, authController, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth > 900;

              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: _buildAppBar(
                  context,
                  cajeroController,
                  authController,
                  isTablet,
                ),
                body: _buildBody(
                  context,
                  cajeroController,
                  isTablet,
                  isDesktop,
                ),
                floatingActionButton: _buildFloatingActionButton(
                  context,
                  cajeroController,
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
    CajeroController cajeroController,
    AuthController authController,
    bool isTablet,
  ) {
    final pendingBills = cajeroController.getPendingBills().length;

    return AppBar(
      title: Row(
        children: [
          Container(
            width: isTablet ? 40.0 : 32.0,
            height: isTablet ? 40.0 : 32.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calculate,
              size: isTablet ? 20.0 : 16.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistema de Caja - Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${authController.userName} • Cajero',
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
        if (pendingBills > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: isTablet ? 16.0 : 14.0,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$pendingBills pendientes',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
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
    CajeroController cajeroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        switch (controller.currentView) {
          case 'main':
            return _buildMainView(context, controller, isTablet, isDesktop);
          case 'closures':
            return const CashClosureView();
          case 'reports':
            return const SalesReportsView();
          case 'cash':
            return const CashManagementView();
          case 'payments':
            return const PaymentProcessingView();
          default:
            return _buildMainView(context, controller, isTablet, isDesktop);
        }
      },
    );
  }

  Widget _buildMainView(
    BuildContext context,
    CajeroController cajeroController,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navegación rápida
          _buildQuickNavigation(context, cajeroController, isTablet),
          const SizedBox(height: 24),

          // Estadísticas del día
          _buildDailyStats(cajeroController, isTablet),
          const SizedBox(height: 24),

          // Filtros
          _buildFiltersCard(context, cajeroController, isTablet),
          const SizedBox(height: 24),

          // Lista de facturas
          _buildBillsList(context, cajeroController, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation(
    BuildContext context,
    CajeroController controller,
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
                    'Cortes de Caja',
                    Icons.account_balance_wallet,
                    AppColors.warning,
                    () => controller.setCurrentView('closures'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Reportes',
                    Icons.analytics,
                    AppColors.info,
                    () => controller.setCurrentView('reports'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Gestión Efectivo',
                    Icons.money,
                    AppColors.success,
                    () => controller.setCurrentView('cash'),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    'Procesar Pagos',
                    Icons.payment,
                    AppColors.primary,
                    () => controller.setCurrentView('payments'),
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

  Widget _buildDailyStats(CajeroController controller, bool isTablet) {
    final stats = controller.getPaymentStats();

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
                          'Efectivo',
                          stats['totalCash']!,
                          Colors.green,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tarjeta',
                          stats['totalCard']!,
                          Colors.blue,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Propinas',
                          stats['totalTips']!,
                          Colors.orange,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          stats['total']!,
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
                              'Efectivo',
                              stats['totalCash']!,
                              Colors.green,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Tarjeta',
                              stats['totalCard']!,
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
                              'Propinas',
                              stats['totalTips']!,
                              Colors.orange,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              stats['total']!,
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
    double amount,
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
            '\$${amount.toStringAsFixed(2)}',
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

  Widget _buildFiltersCard(
    BuildContext context,
    CajeroController controller,
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
                      Expanded(child: _buildStatusFilter(controller, isTablet)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaymentTypeFilter(controller, isTablet),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildStatusFilter(controller, isTablet),
                      const SizedBox(height: 12),
                      _buildPaymentTypeFilter(controller, isTablet),
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

  Widget _buildStatusFilter(CajeroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de Factura',
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
                  child: Text('Todas las Facturas'),
                ),
                DropdownMenuItem(
                  value: BillStatus.pending,
                  child: Text('Pendientes'),
                ),
                DropdownMenuItem(
                  value: BillStatus.paid,
                  child: Text('Pagadas'),
                ),
                DropdownMenuItem(
                  value: BillStatus.cancelled,
                  child: Text('Canceladas'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeFilter(CajeroController controller, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Pago',
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
              value: controller.selectedPaymentType,
              isExpanded: true,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedPaymentType(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'todas',
                  child: Text('Todos los Pagos'),
                ),
                DropdownMenuItem(
                  value: PaymentType.cash,
                  child: Text('Efectivo'),
                ),
                DropdownMenuItem(
                  value: PaymentType.card,
                  child: Text('Tarjeta'),
                ),
                DropdownMenuItem(
                  value: PaymentType.mixed,
                  child: Text('Mixto'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillsList(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final bills = controller.filteredBills;

    if (bills.isEmpty) {
      return _buildEmptyBills(isTablet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facturas (${bills.length})',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...bills.map(
          (bill) => _buildBillCard(context, bill, controller, isTablet),
        ),
      ],
    );
  }

  Widget _buildEmptyBills(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay facturas',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las facturas aparecerán aquí cuando lleguen',
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

  Widget _buildBillCard(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    final statusColor = controller.getBillStatusColor(bill.status);

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
              // Header de la factura
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.id,
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (bill.isTakeaway) ...[
                        Text(
                          'Para Llevar - ${bill.customerName ?? 'Cliente'}',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Mesa ${bill.tableNumber}',
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
                          BillStatus.getStatusText(bill.status),
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.formatCurrency(bill.total),
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items de la factura
              ...bill.items.map((item) => _buildBillItem(item, isTablet)),
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
                    controller.formatDate(bill.createdAt),
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.receipt,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${bill.items.length} artículos',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botones de acción
              _buildActionButtons(context, bill, controller, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillItem(BillItem item, bool isTablet) {
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
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    return Row(
      children: [
        if (bill.status == BillStatus.pending) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                controller.selectBill(bill);
                _showPaymentModal(context, bill, controller, isTablet);
              },
              icon: const Icon(Icons.payment),
              label: Text(
                'Procesar Pago',
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
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              controller.cancelBill(bill.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Factura ${bill.id} cancelada'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.cancel),
            label: Text(
              'Cancelar',
              style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ] else if (bill.status == BillStatus.paid) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implementar reimprimir ticket
              },
              icon: const Icon(Icons.print),
              label: Text(
                'Reimprimir Ticket',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
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
        ],
      ],
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          _showCashCloseModal(context, controller, isTablet);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.account_balance_wallet),
        label: Text(
          isTablet ? 'Cierre de Caja' : 'Cierre',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  void _showPaymentModal(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _PaymentModal(bill: bill, controller: controller, isTablet: isTablet),
    );
  }

  void _showCashCloseModal(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _CashCloseModal(controller: controller, isTablet: isTablet),
    );
  }
}

class _PaymentModal extends StatefulWidget {
  final BillModel bill;
  final CajeroController controller;
  final bool isTablet;

  const _PaymentModal({
    required this.bill,
    required this.controller,
    required this.isTablet,
  });

  @override
  State<_PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<_PaymentModal> {
  String _selectedPaymentType = PaymentType.cash;
  final _cashReceivedController = TextEditingController();
  final _tipAmountController = TextEditingController();
  bool _tipDelivered = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _tipAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: widget.isTablet ? 500 : double.infinity,
        padding: EdgeInsets.all(widget.isTablet ? 24.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Procesar Pago - ${widget.bill.id}',
              style: TextStyle(
                fontSize: widget.isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${widget.controller.formatCurrency(widget.bill.total)}',
              style: TextStyle(
                fontSize: widget.isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de pago
            Text(
              'Tipo de Pago',
              style: TextStyle(
                fontSize: widget.isTablet ? 16.0 : 14.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentType = PaymentType.cash;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedPaymentType == PaymentType.cash
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedPaymentType == PaymentType.cash
                              ? AppColors.primary
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPaymentType == PaymentType.cash
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selectedPaymentType == PaymentType.cash
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text('Efectivo'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentType = PaymentType.card;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedPaymentType == PaymentType.card
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedPaymentType == PaymentType.card
                              ? AppColors.primary
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPaymentType == PaymentType.card
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selectedPaymentType == PaymentType.card
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text('Tarjeta'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos específicos según el tipo de pago
            if (_selectedPaymentType == PaymentType.cash) ...[
              TextFormField(
                controller: _cashReceivedController,
                decoration: const InputDecoration(
                  labelText: 'Efectivo Recibido',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipAmountController,
                decoration: const InputDecoration(
                  labelText: 'Propina',
                  prefixIcon: Icon(Icons.tips_and_updates),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Propina entregada'),
                value: _tipDelivered,
                onChanged: (value) {
                  setState(() {
                    _tipDelivered = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Procesar Pago'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    if (_selectedPaymentType == PaymentType.cash) {
      final cashReceived = double.tryParse(_cashReceivedController.text) ?? 0;
      final tipAmount = double.tryParse(_tipAmountController.text) ?? 0;

      if (cashReceived <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el efectivo recibido')),
        );
        return;
      }

      if (!widget.controller.validateCashPayment(
        widget.bill.total,
        cashReceived,
        tipAmount,
      )) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Efectivo insuficiente')));
        return;
      }
    }

    final payment = PaymentModel(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedPaymentType,
      totalAmount: widget.bill.total,
      cashReceived: _selectedPaymentType == PaymentType.cash
          ? double.tryParse(_cashReceivedController.text)
          : null,
      tipAmount: _selectedPaymentType == PaymentType.cash
          ? double.tryParse(_tipAmountController.text)
          : null,
      tipDelivered: _tipDelivered,
      cashApplied: _selectedPaymentType == PaymentType.cash
          ? (double.tryParse(_cashReceivedController.text) ?? 0) -
                (double.tryParse(_tipAmountController.text) ?? 0)
          : null,
      change: _selectedPaymentType == PaymentType.cash
          ? widget.controller.calculateChange(
              widget.bill.total,
              double.tryParse(_cashReceivedController.text) ?? 0,
              double.tryParse(_tipAmountController.text) ?? 0,
            )
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tableNumber: widget.bill.tableNumber,
      billId: widget.bill.id,
      timestamp: DateTime.now(),
      cashierName: 'Cajero', // TODO: Obtener del AuthController
    );

    widget.controller.processPayment(payment);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pago procesado exitosamente'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _CashCloseModal extends StatefulWidget {
  final CajeroController controller;
  final bool isTablet;

  const _CashCloseModal({required this.controller, required this.isTablet});

  @override
  State<_CashCloseModal> createState() => _CashCloseModalState();
}

class _CashCloseModalState extends State<_CashCloseModal> {
  final _efectivoContadoController = TextEditingController();
  final _totalTarjetaController = TextEditingController();
  final _otrosIngresosController = TextEditingController();
  final _otrosIngresosTextoController = TextEditingController();
  final _notaCajeroController = TextEditingController();

  @override
  void dispose() {
    _efectivoContadoController.dispose();
    _totalTarjetaController.dispose();
    _otrosIngresosController.dispose();
    _otrosIngresosTextoController.dispose();
    _notaCajeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: widget.isTablet ? 600 : double.infinity,
        padding: EdgeInsets.all(widget.isTablet ? 24.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cierre de Caja',
              style: TextStyle(
                fontSize: widget.isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Completa la información del cierre de caja',
              style: TextStyle(
                fontSize: widget.isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Campos del formulario
            TextFormField(
              controller: _efectivoContadoController,
              decoration: const InputDecoration(
                labelText: 'Efectivo Contado *',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalTarjetaController,
              decoration: const InputDecoration(
                labelText: 'Total Tarjeta *',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otrosIngresosController,
              decoration: const InputDecoration(
                labelText: 'Otros Ingresos',
                prefixIcon: Icon(Icons.add),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otrosIngresosTextoController,
              decoration: const InputDecoration(
                labelText: 'Descripción Otros Ingresos',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notaCajeroController,
              decoration: const InputDecoration(
                labelText: 'Nota del Cajero',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendCashClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enviar Cierre'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendCashClose() {
    final efectivo = double.tryParse(_efectivoContadoController.text) ?? 0;
    final tarjeta = double.tryParse(_totalTarjetaController.text) ?? 0;
    final otros = double.tryParse(_otrosIngresosController.text) ?? 0;

    if (efectivo <= 0 || tarjeta <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    final totalDeclarado = efectivo + tarjeta + otros;

    final cashClose = CashCloseModel(
      id: 'close_${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      periodo: 'Día',
      usuario: 'Cajero', // TODO: Obtener del AuthController
      totalNeto: totalDeclarado,
      efectivo: efectivo,
      tarjeta: tarjeta,
      propinasTarjeta: 0,
      propinasEfectivo: 0,
      pedidosParaLlevar: 0,
      estado: CashCloseStatus.pending,
      efectivoContado: efectivo,
      totalTarjeta: tarjeta,
      otrosIngresos: otros,
      otrosIngresosTexto: _otrosIngresosTextoController.text.trim().isEmpty
          ? null
          : _otrosIngresosTextoController.text.trim(),
      notaCajero: _notaCajeroController.text.trim().isEmpty
          ? null
          : _notaCajeroController.text.trim(),
      totalDeclarado: totalDeclarado,
      auditLog: [
        AuditLogEntry(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          action: 'enviado',
          usuario: 'Cajero', // TODO: Obtener del AuthController
          mensaje: 'Cierre enviado por Cajero',
        ),
      ],
    );

    widget.controller.sendCashClose(cashClose);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cierre de caja enviado'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
