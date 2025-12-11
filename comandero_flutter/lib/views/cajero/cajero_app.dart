import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/cajero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/payment_model.dart';
import '../../models/admin_model.dart';
import '../../services/payment_repository.dart';
import '../../services/bill_repository.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../widgets/logout_button.dart';
import 'cash_closure_view.dart';
import 'sales_reports_view.dart';
import 'cash_management_view.dart';
import 'payment_processing_view.dart';
import 'cash_payment_modal.dart';
import 'card_payment_modal.dart';

class CajeroApp extends StatelessWidget {
  const CajeroApp({super.key});

  // Consolidar items de bill por nombre (sumar cantidades)
  /// Consolida items con el mismo nombre y calcula el total correctamente
  /// Total = precio unitario * cantidad total
  static List<Map<String, dynamic>> _consolidateBillItems(
    List<BillItem> items,
  ) {
    final Map<String, Map<String, dynamic>> consolidated = {};

    for (var item in items) {
      final key = item.name.toLowerCase();
      if (consolidated.containsKey(key)) {
        // Sumar cantidades
        consolidated[key]!['quantity'] += item.quantity;
        // Recalcular total basado en precio unitario * cantidad total
        final newQuantity = consolidated[key]!['quantity'] as int;
        final price = consolidated[key]!['price'] as double;
        consolidated[key]!['total'] = price * newQuantity;
      } else {
        consolidated[key] = {
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price, // Guardar precio unitario para recalcular
          'total': item.price * item.quantity, // Calcular total correctamente
        };
      }
    }

    return consolidated.values.toList();
  }

  /// Calcula el total real de una cuenta sumando precio * cantidad de cada item
  /// Esto asegura que siempre se muestre el precio correcto
  static double _calculateBillTotal(BillModel bill) {
    // Calcular total sumando precio * cantidad de cada item
    final totalFromItems = bill.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    // Aplicar descuento si existe
    return totalFromItems - bill.discount + bill.tax;
  }

  /// Extrae los IDs de órdenes del billId y los formatea para mostrar de forma clara
  /// Ejemplo: "BILL-MESA-2-30-31-32" -> "Órdenes: ORD-000030, ORD-000031, ORD-000032"
  static String _getOrdenIdsFromBillId(String billId) {
    if (billId.contains('BILL-MESA-') && billId.contains('-')) {
      final parts = billId.split('-');
      if (parts.length >= 4) {
        // Obtener todas las partes después de "BILL-MESA-X" (las órdenes)
        final ordenIds = parts.sublist(3);
        if (ordenIds.length > 1) {
          // Formatear cada orden como ORD-XXXXXX de forma más clara
          final ordenIdsFormateados = ordenIds
              .map((id) {
                return 'ORD-${id.padLeft(6, '0')}';
              })
              .join(', ');
          return '$ordenIdsFormateados';
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => CajeroController(
            paymentRepository: context.read<PaymentRepository>(),
            billRepository: context.read<BillRepository>(),
          ),
        ),
      ],
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
                'Caja - Comandix',
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
          TextButton.icon(
            onPressed: null,
            icon: Icon(Icons.receipt_long, size: isTablet ? 16.0 : 14.0),
            label: Text(
              '$pendingBills cuentas',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 8),
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
          // Botones de acción
          _buildActionButtons(context, cajeroController, isTablet),
          const SizedBox(height: 24),

          // Resumen de consumo del día
          _buildDailyConsumptionSummary(cajeroController, isTablet),
          const SizedBox(height: 24),

          // Lista de facturas con filtro
          _buildBillsListWithFilter(
            context,
            cajeroController,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  // Botones de acción (Apertura de Caja, Cerrar Caja, Descargar CSV, Descargar PDF)
  Widget _buildActionButtons(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCashOpenModal(context, controller, isTablet),
            icon: const Icon(Icons.lock_open),
            label: Text(
              'Apertura de Caja',
              style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCashCloseModal(context, controller, isTablet),
            icon: const Icon(Icons.account_balance_wallet),
            label: Text(
              'Cerrar Caja',
              style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDownloadCSVDialog(context, isTablet),
            icon: const Icon(Icons.download),
            label: Text(
              'Descargar CSV',
              style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDownloadPDFDialog(context, isTablet),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(
              'Descargar PDF',
              style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
            ),
          ),
        ),
      ],
    );
  }

  // Resumen de consumo del día
  Widget _buildDailyConsumptionSummary(
    CajeroController controller,
    bool isTablet,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Consumo del Día',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.setCurrentView('closures');
                    // Cargar cierres al cambiar de vista
                    controller.loadCashClosures();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver en Cierre de Caja'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
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
                        child: _buildConsumptionCard(
                          'Ventas en Local',
                          stats['totalCash']! +
                              stats['totalCard']! -
                              (stats['totalCash']! * 0.4),
                          Colors.green,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Ventas Para llevar',
                          stats['totalCard']! * 0.5,
                          Colors.blue,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Efectivo',
                          stats['totalCash']!,
                          Colors.yellow,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Tarjeta Débito',
                          stats['totalCard']! * 0.55,
                          Colors.purple.shade300,
                          isTablet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Tarjeta Crédito',
                          stats['totalCard']! * 0.45,
                          Colors.purple.shade400,
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
                            child: _buildConsumptionCard(
                              'Ventas en Local',
                              stats['totalCash']! +
                                  stats['totalCard']! -
                                  (stats['totalCash']! * 0.4),
                              Colors.green,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Para llevar',
                              stats['totalCard']! * 0.5,
                              Colors.blue,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildConsumptionCard(
                              'Efectivo',
                              stats['totalCash']!,
                              Colors.yellow,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Débito',
                              stats['totalCard']! * 0.55,
                              Colors.purple.shade300,
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildConsumptionCard(
                          'Crédito',
                          stats['totalCard']! * 0.45,
                          Colors.purple.shade400,
                          isTablet,
                        ),
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

  Widget _buildConsumptionCard(
    String title,
    double value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
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

  // Lista de facturas con filtro
  Widget _buildBillsListWithFilter(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cuentas por Cobrar',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            _buildShowFilter(controller, isTablet),
          ],
        ),
        const SizedBox(height: 16),
        _buildBillsList(context, controller, isTablet, isDesktop),
      ],
    );
  }

  Widget _buildShowFilter(CajeroController controller, bool isTablet) {
    return Row(
      children: [
        Text(
          'Mostrar:',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 12.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedShowFilter,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(
                  value: 'Solo para llevar',
                  child: Text('Solo para llevar'),
                ),
                DropdownMenuItem(value: 'Mesas', child: Text('Mesas')),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.setSelectedShowFilter(value);
                }
              },
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDownloadCSVDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Figma'),
        content: const Text('Exportando reporte en formato CSV...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar descarga de CSV
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showDownloadPDFDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Figma'),
        content: const Text('Exportando reporte en formato PDF...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar descarga de PDF
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
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
    // IMPORTANTE: Usar hora CDMX para cálculos precisos
    // bill.createdAt ya está parseado con parseToLocal, así que está en CDMX
    final now = date_utils.AppDateUtils.now();
    // No hacer .toLocal() otra vez porque ya está en hora local (CDMX)
    final billDate = bill.createdAt;
    final elapsedMinutes = now.difference(billDate).inMinutes;
    
    // Si el tiempo es negativo, puede ser un error de zona horaria
    // En ese caso, mostrar "Recién" en lugar de un número negativo
    final displayMinutes = elapsedMinutes < 0 ? 0 : elapsedMinutes;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 24.0 : 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header estilo ticket con fondo gris
          Container(
            padding: EdgeInsets.all(isTablet ? 18.0 : 14.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!bill.isTakeaway && bill.tableNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mesa ${bill.tableNumber}',
                            style: TextStyle(
                              fontSize: isTablet ? 13.0 : 11.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (bill.isTakeaway)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: isTablet ? 16.0 : 14.0,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PARA LLEVAR',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Si hay múltiples órdenes con badge de mesa, mostrar solo info de agrupación
                            if (bill.id.contains('BILL-MESA-') &&
                                bill.id.split('-').length > 4 &&
                                !bill.isTakeaway &&
                                bill.tableNumber != null)
                              // Para múltiples órdenes: mostrar contador claro
                              Text(
                                bill.displayId,
                                style: TextStyle(
                                  fontSize: isTablet ? 15.0 : 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
                                ),
                              )
                            else if (!(!bill.isTakeaway &&
                                bill.tableNumber != null))
                              // Si no hay badge de mesa, mostrar el displayId completo
                              Text(
                                bill.displayId,
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            else
                              // Para una sola orden con mesa, mostrar el ID formateado
                              Text(
                                bill.displayId,
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            // Mostrar información adicional si hay múltiples órdenes
                            if (bill.id.contains('BILL-MESA-') &&
                                bill.id.split('-').length > 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: isTablet ? 12.0 : 10.0,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _getOrdenIdsFromBillId(bill.id),
                                        style: TextStyle(
                                          fontSize: isTablet ? 11.0 : 9.0,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.formatCurrency(bill.calculatedTotal),
                      style: TextStyle(
                        fontSize: isTablet ? 22.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      displayMinutes < 1 
                          ? 'Recién' 
                          : 'Hace $displayMinutes min',
                      style: TextStyle(
                        fontSize: isTablet ? 11.0 : 9.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Línea punteada estilo ticket
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),

          // Contenido del ticket
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiquetas de estado
                if (bill.isPrinted || bill.requestedByWaiter)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (bill.isPrinted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Impreso por ${bill.printedBy ?? 'Cajero'}',
                            style: TextStyle(
                              fontSize: isTablet ? 11.0 : 9.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (bill.requestedByWaiter && !bill.isPrinted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Solicitado por Mesero',
                            style: TextStyle(
                              fontSize: isTablet ? 11.0 : 9.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (bill.isPrinted || bill.requestedByWaiter)
                  const SizedBox(height: 16),

                // Resumen consolidado de productos en un solo recuadro
                Container(
                  padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Productos',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Consolidar productos por nombre
                      ...CajeroApp._consolidateBillItems(bill.items).map(
                        (consolidatedItem) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${consolidatedItem['quantity']}x',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  consolidatedItem['name'] as String,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14.0 : 12.0,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${consolidatedItem['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                      if (bill.discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Descuento:',
                              style: TextStyle(
                                fontSize: isTablet ? 15.0 : 13.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '-${controller.formatCurrency(bill.discount)}',
                              style: TextStyle(
                                fontSize: isTablet ? 15.0 : 13.0,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              // Calcular total desde los items para asegurar que sea correcto
                              controller.formatCurrency(
                                CajeroApp._calculateBillTotal(bill),
                              ),
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bill.splitCount > 1) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
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
                                'Total por persona (${bill.splitCount} ${bill.splitCount == 1 ? 'persona' : 'personas'}):',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                controller.formatCurrency(
                                  CajeroApp._calculateBillTotal(bill) /
                                      bill.splitCount,
                                ),
                                style: TextStyle(
                                  fontSize: isTablet ? 18.0 : 16.0,
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

                // Información del cliente para pedidos para llevar
                if (bill.isTakeaway && bill.customerName != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: isTablet ? 18.0 : 16.0,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cliente: ${bill.customerName}',
                              style: TextStyle(
                                fontSize: isTablet ? 14.0 : 12.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (bill.customerPhone != null &&
                            bill.customerPhone!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: isTablet ? 16.0 : 14.0,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill.customerPhone!,
                                style: TextStyle(
                                  fontSize: isTablet ? 13.0 : 11.0,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Notas del mesero si existen
                if (bill.waiterNotes != null &&
                    bill.waiterNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.pink.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: isTablet ? 18.0 : 16.0,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nota del pedido: ${bill.waiterNotes}',
                            style: TextStyle(
                              fontSize: isTablet ? 13.0 : 11.0,
                              color: Colors.purple.shade700,
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

          const SizedBox(height: 16),

          // Línea punteada antes de botones
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),

          // Botones de acción estilo ticket
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (bill.isPrinted)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Reimprimir
                      },
                      icon: Icon(Icons.refresh, size: isTablet ? 18.0 : 16.0),
                      label: Text('Reimprimir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12.0 : 10.0,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showPrintTicketDialog(
                          context,
                          bill,
                          controller,
                          isTablet,
                        );
                      },
                      icon: Icon(Icons.print, size: isTablet ? 18.0 : 16.0),
                      label: Text('Imprimir ticket'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12.0 : 10.0,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      CashPaymentModal.show(
                        context,
                        bill,
                        controller,
                        isTablet,
                      );
                    },
                    icon: Icon(
                      Icons.attach_money,
                      size: isTablet ? 18.0 : 16.0,
                    ),
                    label: Text('\$ Cobrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12.0 : 10.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      CardPaymentModal.show(
                        context,
                        bill,
                        controller,
                        isTablet,
                      );
                    },
                    icon: Icon(Icons.credit_card, size: isTablet ? 18.0 : 16.0),
                    label: Text('Pagar con tarjeta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12.0 : 10.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintTicketDialog(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimir Ticket'),
        content: Text(
          '¿Imprimir ticket para ${bill.isTakeaway ? (bill.customerName ?? 'cliente') : 'Mesa ${bill.tableNumber}'}?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Obtener nombre del usuario del AuthController
              final authController = Provider.of<AuthController>(
                context,
                listen: false,
              );
              final userName = authController.userName.isNotEmpty
                  ? authController.userName
                  : 'Cajero';
              // Marcar como impreso e imprimir ticket
              await controller.markBillAsPrinted(
                bill.id,
                userName,
                ordenId: bill.ordenId,
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Método removido - ahora se usa CashPaymentModal.show directamente

  void _showCashOpenModal(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _CashOpenModal(controller: controller, isTablet: isTablet),
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
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Modal antiguo removido - ahora se usa CashPaymentModal y CardPaymentModal

// Modal de Apertura de Caja
class _CashOpenModal extends StatefulWidget {
  final CajeroController controller;
  final bool isTablet;

  const _CashOpenModal({required this.controller, required this.isTablet});

  @override
  State<_CashOpenModal> createState() => _CashOpenModalState();
}

class _CashOpenModalState extends State<_CashOpenModal> {
  final _efectivoInicialController = TextEditingController();
  final _notaController = TextEditingController();

  @override
  void dispose() {
    _efectivoInicialController.dispose();
    _notaController.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apertura de Caja',
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
            const SizedBox(height: 8),
            Text(
              'Registra el efectivo inicial para comenzar el día',
              style: TextStyle(
                fontSize: widget.isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _efectivoInicialController,
              decoration: const InputDecoration(
                labelText: 'Efectivo inicial *',
                hintText: '5000',
                prefixIcon: Icon(Icons.money),
                helperText: 'Cantidad de efectivo con la que inicias el día',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note),
                hintText: 'Observaciones sobre la apertura',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
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
                  child: ElevatedButton.icon(
                    onPressed: _openCashRegister,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Abrir Caja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  Future<void> _openCashRegister() async {
    final efectivoInicial =
        double.tryParse(_efectivoInicialController.text) ?? 0;

    if (efectivoInicial <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido para el efectivo inicial'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await widget.controller.openCashRegister(
        efectivoInicial: efectivoInicial,
        nota: _notaController.text.trim().isEmpty
            ? null
            : _notaController.text.trim(),
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Caja abierta con \$${efectivoInicial.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir caja: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enviar Cierre de Caja',
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
            const SizedBox(height: 8),
            Text(
              'Completa la información del cierre de caja para enviar al Admin',
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
                labelText: 'Efectivo contado hoy *',
                hintText: '5000',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalTarjetaController,
              decoration: const InputDecoration(
                labelText: 'Total tarjeta *',
                hintText: '2000',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otrosIngresosController,
              decoration: const InputDecoration(
                labelText: 'Otros ingresos',
                hintText: '500',
                prefixIcon: Icon(Icons.visibility),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otrosIngresosTextoController,
              decoration: const InputDecoration(
                labelText: 'Describe los otros ingresos (opcional)',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notaCajeroController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.note),
                hintText: 'por el dia de hoy fue esto',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Total declarado
            Builder(
              builder: (context) {
                final efectivo =
                    double.tryParse(_efectivoContadoController.text) ?? 0;
                final tarjeta =
                    double.tryParse(_totalTarjetaController.text) ?? 0;
                final otros =
                    double.tryParse(_otrosIngresosController.text) ?? 0;
                final totalDeclarado = efectivo + tarjeta + otros;

                return Container(
                  padding: const EdgeInsets.all(16),
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
                        'Total declarado:',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.controller.formatCurrency(totalDeclarado),
                        style: TextStyle(
                          fontSize: widget.isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  child: ElevatedButton.icon(
                    onPressed: _sendCashClose,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Cierre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  Future<void> _sendCashClose() async {
    final efectivo = double.tryParse(_efectivoContadoController.text) ?? 0;
    final tarjeta = double.tryParse(_totalTarjetaController.text) ?? 0;
    final otros = double.tryParse(_otrosIngresosController.text) ?? 0;

    // Validar que al menos uno de los campos tenga valor
    if (efectivo <= 0 && tarjeta <= 0 && otros <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un monto para el cierre'),
        ),
      );
      return;
    }

    final totalDeclarado = efectivo + tarjeta + otros;

    // Obtener nombre del usuario del AuthController
    final authController = Provider.of<AuthController>(context, listen: false);
    final userName = authController.userName.isNotEmpty
        ? authController.userName
        : 'Cajero';

    final cashClose = CashCloseModel(
      id: 'close_${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      periodo: 'Día',
      usuario: userName,
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
          usuario: userName,
          mensaje: 'Cierre enviado por $userName',
        ),
      ],
    );

    try {
      await widget.controller.sendCashClose(cashClose);
      Navigator.of(context).pop();
    } catch (e) {
      // Si falla, aún cerrar el modal pero mostrar error
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar cierre: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cierre de caja enviado'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
