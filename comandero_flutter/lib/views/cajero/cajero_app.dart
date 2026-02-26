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
import 'transfer_payment_modal.dart';
import 'mixed_payment_modal.dart';
import '../../services/tickets_service.dart';

class CajeroApp extends StatelessWidget {
  const CajeroApp({super.key});

  // Consolidar items de bill por nombre (sumar cantidades)
  /// Consolida items con el mismo nombre COMPLETO (incluyendo tamaño) y calcula el total correctamente
  /// Total = precio unitario * cantidad total
  /// IMPORTANTE: NO consolida productos con diferentes tamaños (ej: "Alitas (chicas)" vs "Alitas (medianas)")
  static List<Map<String, dynamic>> _consolidateBillItems(
    List<BillItem> items,
  ) {
    final Map<String, Map<String, dynamic>> consolidated = {};

    for (var item in items) {
      // Usar el nombre COMPLETO (con tamaño si existe) como clave
      // Esto asegura que productos con diferentes tamaños NO se consoliden
      final key = item.name; // Usar nombre completo, no lowercase para preservar mayúsculas/minúsculas
      if (consolidated.containsKey(key)) {
        // Solo consolidar si el precio unitario es el mismo (mismo producto y tamaño)
        final existingPrice = consolidated[key]!['price'] as double;
        if ((existingPrice - item.price).abs() < 0.01) {
          // Sumar cantidades solo si es el mismo producto con el mismo precio
          consolidated[key]!['quantity'] += item.quantity;
          // Recalcular total basado en precio unitario * cantidad total
          final newQuantity = consolidated[key]!['quantity'] as int;
          consolidated[key]!['total'] = existingPrice * newQuantity;
        } else {
          // Si el precio es diferente, es un producto diferente (aunque el nombre sea similar)
          // Agregar como un item separado con un identificador único
          final uniqueKey = '$key-${item.price.toStringAsFixed(2)}';
          consolidated[uniqueKey] = {
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
            'total': item.price * item.quantity,
          };
        }
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

          // Información de apertura de caja
          _buildCashOpeningInfo(context, cajeroController, isTablet),
          const SizedBox(height: 24),

          // Resumen de consumo del día
          _buildDailyConsumptionSummary(context, cajeroController, isTablet),
          const SizedBox(height: 24),

          // Historial de cobros
          _buildCollectionHistorySection(context, cajeroController, isTablet),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final spacing = isNarrow ? 8.0 : 12.0;
        final paddingV = isTablet ? 16.0 : (isNarrow ? 10.0 : 14.0);
        final paddingH = isNarrow ? 8.0 : 12.0;
        final fontSize = isTablet ? 16.0 : (isNarrow ? 12.0 : 14.0);
        final iconSize = isNarrow ? 18.0 : 24.0;

        if (isNarrow) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: (constraints.maxWidth - spacing) / 2,
                child: ElevatedButton.icon(
                  onPressed: () => _showCashOpenModal(context, controller, isTablet),
                  icon: Icon(Icons.lock_open, size: iconSize),
                  label: Text('Apertura de Caja', style: TextStyle(fontSize: fontSize)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                  ),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - spacing) / 2,
                child: ElevatedButton.icon(
                  onPressed: () => _showCashCloseModal(context, controller, isTablet),
                  icon: Icon(Icons.account_balance_wallet, size: iconSize),
                  label: Text('Cerrar Caja', style: TextStyle(fontSize: fontSize)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                  ),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - spacing) / 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showDownloadCSVDialog(context, isTablet),
                  icon: Icon(Icons.download, size: iconSize),
                  label: Text('Descargar CSV', style: TextStyle(fontSize: fontSize)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                  ),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - spacing) / 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showDownloadPDFDialog(context, isTablet),
                  icon: Icon(Icons.picture_as_pdf, size: iconSize),
                  label: Text('Descargar PDF', style: TextStyle(fontSize: fontSize)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCashOpenModal(context, controller, isTablet),
                icon: const Icon(Icons.lock_open),
                label: Text('Apertura de Caja', style: TextStyle(fontSize: fontSize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: paddingV),
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCashCloseModal(context, controller, isTablet),
                icon: const Icon(Icons.account_balance_wallet),
                label: Text('Cerrar Caja', style: TextStyle(fontSize: fontSize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: paddingV),
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDownloadCSVDialog(context, isTablet),
                icon: const Icon(Icons.download),
                label: Text('Descargar CSV', style: TextStyle(fontSize: fontSize)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: paddingV),
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDownloadPDFDialog(context, isTablet),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text('Descargar PDF', style: TextStyle(fontSize: fontSize)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(vertical: paddingV),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Información de apertura de caja
  Widget _buildCashOpeningInfo(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    return Consumer<CajeroController>(
      builder: (context, ctrl, child) {
        final apertura = ctrl.getTodayCashOpening();
        final isOpen = ctrl.isCashRegisterOpen();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOpen ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
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
                    const SizedBox(width: 12),
                    Text(
                      'Estado de Caja',
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),
              Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efectivo Inicial',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${apertura.efectivoInicial.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 20.0 : 18.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Apertura',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                ],
              ),
              if (apertura.notaCajero != null && apertura.notaCajero!.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                      const SizedBox(width: 8),
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
              const SizedBox(height: 12),
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
      },
    );
  }

  // Resumen de consumo del día (datos reales del día, se actualiza al hacer cobros)
  Widget _buildDailyConsumptionSummary(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    return Consumer<CajeroController>(
      builder: (context, ctrl, child) {
        final stats = ctrl.getDailyConsumptionStats();
        final ventasLocal = stats['totalLocal'] ?? 0.0;
        final ventasParaLlevar = stats['totalParaLlevar'] ?? 0.0;
        final efectivo = stats['totalCash'] ?? 0.0;
        final tarjetaDebito = stats['totalDebit'] ?? 0.0;
        final tarjetaCredito = stats['totalCredit'] ?? 0.0;

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 400;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Consumo del Día',
                            style: TextStyle(
                              fontSize: isTablet ? 18.0 : 16.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              ctrl.setCurrentView('closures');
                              ctrl.loadCashClosures();
                            },
                            icon: Icon(Icons.open_in_new, size: isTablet ? 20.0 : 18.0),
                            label: const Text('Ver en Cierre de Caja'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Resumen de Consumo del Día',
                            style: TextStyle(
                              fontSize: isTablet ? 18.0 : 16.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ctrl.setCurrentView('closures');
                            ctrl.loadCashClosures();
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ver en Cierre de Caja'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
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
                              ventasLocal,
                              Colors.green,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Ventas Para llevar',
                              ventasParaLlevar,
                              Colors.blue,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Efectivo',
                              efectivo,
                              Colors.amber.shade700,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Tarjeta Débito',
                              tarjetaDebito,
                              Colors.purple.shade300,
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsumptionCard(
                              'Tarjeta Crédito',
                              tarjetaCredito,
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
                                  ventasLocal,
                                  Colors.green,
                                  isTablet,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildConsumptionCard(
                                  'Para llevar',
                                  ventasParaLlevar,
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
                                  efectivo,
                                  Colors.amber.shade700,
                                  isTablet,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildConsumptionCard(
                                  'Débito',
                                  tarjetaDebito,
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
                              tarjetaCredito,
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
      },
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

  // Sección de Historial de cobros
  Widget _buildCollectionHistorySection(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
  ) {
    return _CollectionHistoryWidget(
      controller: controller,
      isTablet: isTablet,
      buildPaymentMethodCard: _buildPaymentMethodCard,
      showPaymentMethodDetails: _showPaymentMethodDetails,
    );
  }

  /// Botón compacto por método de pago: al hacer clic se abre el modal con la lista de cobros.
  Widget _buildPaymentMethodCard(
    BuildContext context,
    String methodName,
    double total,
    List<Map<String, dynamic>> payments,
    Color color,
    bool isTablet,
  ) {
    if (total == 0 && payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: payments.isNotEmpty
            ? () => _showPaymentMethodDetails(context, methodName, payments, color, isTablet)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 14.0 : 10.0, vertical: isTablet ? 10.0 : 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                methodName,
                style: TextStyle(
                  fontSize: isTablet ? 13.0 : 12.0,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 13.0 : 12.0,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (payments.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.list_alt, size: isTablet ? 16.0 : 14.0, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodDetails(
    BuildContext context,
    String methodName,
    List<Map<String, dynamic>> payments,
    Color color,
    bool isTablet,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cobros - $methodName',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${payments.fold<double>(0, (sum, p) => sum + (p['monto'] as double)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                ...payments.map((payment) {
                  final waiterName = payment['waiterName'] as String?;
                  final ordenId = payment['ordenId'] as String? ?? '—';
                  final mesaInfo = payment['mesa'] as String? ?? '—';
                  final meseroLabel = (waiterName != null && waiterName.trim().isNotEmpty)
                      ? waiterName
                      : '—';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                                      meseroLabel == '—' ? 'Mesero: —' : 'Mesero: $meseroLabel',
                                      style: TextStyle(
                                        fontSize: isTablet ? 14.0 : 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Orden: $ordenId',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12.0 : 11.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(payment['monto'] as double).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mesaInfo,
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 11.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (payment['banco'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Banco: ${payment['banco']}',
                              style: TextStyle(
                                fontSize: isTablet ? 11.0 : 10.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (payment['referencia'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ref: ${payment['referencia']}',
                              style: TextStyle(
                                fontSize: isTablet ? 11.0 : 10.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (payment['tipoTarjeta'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              payment['tipoTarjeta'] as String,
                              style: TextStyle(
                                fontSize: isTablet ? 11.0 : 10.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
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
}

// Lista de facturas con filtro
extension _CajeroAppExtension on CajeroApp {
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

  Widget _buildBillsList(
    BuildContext context,
    CajeroController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Consumer<CajeroController>(
      builder: (context, ctrl, child) {
        final bills = ctrl.filteredBills;
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
      },
    );
  }

  Widget _buildEmptyBills(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: isTablet ? 64.0 : 48.0,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay facturas',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBillCard(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    final billDate = bill.createdAt;
    final timeAgo = date_utils.AppDateUtils.formatTimeAgoShort(billDate);

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
                      if (!bill.isTakeaway)
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
                            bill.tableDisplayLabel,
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
                            Text(
                              bill.displayId,
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (bill.requestedByWaiter && !bill.isPrinted) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10.0 : 8.0,
                                  vertical: isTablet ? 6.0 : 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill.waiterName != null && bill.waiterName!.isNotEmpty
                                      ? 'Solicitado por Mesero ${bill.waiterName}'
                                      : 'Solicitado por Mesero',
                                  style: TextStyle(
                                    fontSize: isTablet ? 11.0 : 9.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
                      timeAgo,
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
                // Resumen consolidado de productos (dividido por persona si es cuenta dividida)
                if (bill.isDividedAccount && bill.personAccounts != null && bill.personAccounts!.isNotEmpty) ...[
                  // Mostrar agrupado por persona
                  ...bill.personAccounts!.map((personAccount) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header de persona
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: isTablet ? 18.0 : 16.0,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    personAccount.name,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16.0 : 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                controller.formatCurrency(personAccount.total),
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Items de esta persona
                          ...CajeroApp._consolidateBillItems(personAccount.items).map(
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
                          // Subtotal por persona
                          if (personAccount.discount > 0 || personAccount.items.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13.0 : 11.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  controller.formatCurrency(personAccount.subtotal),
                                  style: TextStyle(
                                    fontSize: isTablet ? 13.0 : 11.0,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (personAccount.discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Descuento:',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '-${controller.formatCurrency(personAccount.discount)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (controller.ivaHabilitado) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'IVA (16%):',
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    controller.formatCurrency(personAccount.tax),
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.0 : 11.0,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  // Mostrar resumen normal (cuenta general)
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
                ],

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
                              fontSize: isTablet ? 15.0 : 13.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            controller.formatCurrency(
                              bill.items.fold<double>(0, (sum, i) => sum + i.total),
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 15.0 : 13.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (bill.discount > 0) ...[
                        const SizedBox(height: 8),
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
                      ],
                      if (controller.ivaHabilitado) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'IVA (16%):',
                              style: TextStyle(
                                fontSize: isTablet ? 15.0 : 13.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              controller.formatCurrency(bill.tax),
                              style: TextStyle(
                                fontSize: isTablet ? 15.0 : 13.0,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isTablet ? 220 : 200,
                  child: bill.isPrinted
                      ? OutlinedButton.icon(
                          onPressed: () {
                            // Reimprimir
                          },
                          icon:
                              Icon(Icons.refresh, size: isTablet ? 18.0 : 16.0),
                          label: const Text('Reimprimir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 12.0 : 10.0,
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            _showPrintTicketDialog(
                              context,
                              bill,
                              controller,
                              isTablet,
                            );
                          },
                          icon:
                              Icon(Icons.print, size: isTablet ? 18.0 : 16.0),
                          label: const Text('Imprimir ticket'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 12.0 : 10.0,
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: isTablet ? 220 : 200,
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
                    label: const Text('Pago en efectivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12.0 : 10.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isTablet ? 220 : 200,
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
                    label: const Text('Pagar con tarjeta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12.0 : 10.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isTablet ? 220 : 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      TransferPaymentModal.show(
                        context,
                        bill,
                        controller,
                        isTablet,
                      );
                    },
                    icon:
                        Icon(Icons.account_balance, size: isTablet ? 18.0 : 16.0),
                    label: const Text('Transferencia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12.0 : 10.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isTablet ? 220 : 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      MixedPaymentModal.show(
                        context,
                        bill,
                        controller,
                        isTablet,
                      );
                    },
                    icon: Icon(Icons.category, size: isTablet ? 18.0 : 16.0),
                    label: const Text('Pago mixto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade600,
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
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Imprimir Ticket'),
        content: Text(
          '¿Deseas imprimir el ticket de la ${bill.tableDisplayLabel}?',
          style: TextStyle(fontSize: isTablet ? 14.0 : 13.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ordenIdsList = bill.ordenIds ?? (bill.ordenIdsFromBillIdInt.isNotEmpty ? bill.ordenIdsFromBillIdInt : (bill.ordenId != null ? [bill.ordenId!] : <int>[]));
              final ordenIdPrincipal = bill.ordenId ?? (ordenIdsList.isNotEmpty ? ordenIdsList.first : null);
              if (ordenIdPrincipal == null) {
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo obtener el ID de la orden para imprimir'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              showDialog(
                context: scaffoldContext,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final ticketsService = TicketsService();
                final result = await ticketsService.imprimirTicket(
                  ordenId: ordenIdPrincipal,
                  ordenIds: ordenIdsList.length > 1 ? ordenIdsList : null,
                  incluirCodigoBarras: true,
                );
                if (scaffoldContext.mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text(result['mensaje'] as String? ?? 'Ticket impreso'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] as String? ?? 'Error al imprimir'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Error al imprimir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (scaffoldContext.mounted) {
                  Navigator.of(scaffoldContext).pop();
                }
              }
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  void _showDownloadCSVDialog(BuildContext context, bool isTablet) {
    final controller = Provider.of<CajeroController>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar CSV'),
        content: const Text('¿Deseas descargar el reporte de cierres de caja en formato CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                await controller.exportCashClosuresToCSV();
                
                // Cerrar indicador de carga
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ CSV descargado correctamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Cerrar indicador de carga si está abierto
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Mostrar mensaje de error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al descargar CSV: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  void _showDownloadPDFDialog(BuildContext context, bool isTablet) {
    final controller = Provider.of<CajeroController>(context, listen: false);
    // Usar el contexto del widget (padre) para mostrar/cerrar el loading; el context del builder
    // del diálogo se invalida al hacer pop y deja el loading atrapado.
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generar PDF'),
        content: const Text('¿Deseas generar el reporte de cierres de caja en formato PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Mostrar indicador de carga con contexto que sigue válido (no el del diálogo)
              showDialog(
                context: scaffoldContext,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              try {
                await controller.generateCashClosuresPDF();
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ PDF generado correctamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al generar PDF: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } finally {
                // Cerrar indicador de carga siempre (éxito, error o cancelación del diálogo de impresión)
                if (scaffoldContext.mounted) {
                  Navigator.of(scaffoldContext).pop();
                }
              }
            },
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

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

class _CollectionHistoryWidget extends StatefulWidget {
  final CajeroController controller;
  final bool isTablet;
  final Widget Function(BuildContext, String, double, List<Map<String, dynamic>>, Color, bool) buildPaymentMethodCard;
  final void Function(BuildContext, String, List<Map<String, dynamic>>, Color, bool) showPaymentMethodDetails;

  const _CollectionHistoryWidget({
    required this.controller,
    required this.isTablet,
    required this.buildPaymentMethodCard,
    required this.showPaymentMethodDetails,
  });

  @override
  State<_CollectionHistoryWidget> createState() => _CollectionHistoryWidgetState();
}

class _CollectionHistoryWidgetState extends State<_CollectionHistoryWidget> {
  String _selectedPeriod = 'hoy';
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = date_utils.AppDateUtils.nowCdmx();
    final initial = isStart
        ? (_customStart ?? now.subtract(const Duration(days: 7)))
        : (_customEnd ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
          if (_customEnd != null && _customEnd!.isBefore(picked)) {
            _customEnd = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          }
        } else {
          _customEnd = picked;
          if (_customStart != null && _customStart!.isAfter(picked)) {
            _customStart = DateTime(picked.year, picked.month, picked.day);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CajeroController>(
      builder: (context, ctrl, child) {
        final history = ctrl.getCollectionHistory(
          periodo: _selectedPeriod,
          fechaInicioCustom: _selectedPeriod == 'personalizado' ? _customStart : null,
          fechaFinCustom: _selectedPeriod == 'personalizado' ? _customEnd : null,
        );
        final efectivo = history['efectivo'] as Map<String, dynamic>;
        final tarjeta = history['tarjeta'] as Map<String, dynamic>;
        final transferencia = history['transferencia'] as Map<String, dynamic>;
        final mixto = history['mixto'] as Map<String, dynamic>;
        final propinas = history['propinas'] as Map<String, dynamic>;
        final totalGeneral = history['totalGeneral'] as double;

        return Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(widget.isTablet ? 12.0 : 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 500;
                    final titleRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          color: AppColors.primary,
                          size: widget.isTablet ? 20.0 : 18.0,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Historial de cobros',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                    final dropdown = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                            DropdownMenuItem(value: 'ayer', child: Text('Ayer')),
                            DropdownMenuItem(value: 'semana', child: Text('En la semana')),
                            DropdownMenuItem(value: 'mes', child: Text('Hace un mes')),
                            DropdownMenuItem(value: 'personalizado', child: Text('Rango personalizado')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              final openCalendar = value == 'personalizado';
                              setState(() {
                                _selectedPeriod = value;
                                if (value == 'personalizado' && _customStart == null && _customEnd == null) {
                                  final now = date_utils.AppDateUtils.nowCdmx();
                                  _customStart = now.subtract(const Duration(days: 7));
                                  _customEnd = now;
                                }
                              });
                              if (openCalendar && context.mounted) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && context.mounted) _pickDate(context, true);
                                });
                              }
                            }
                          },
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12.0 : 11.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                    final totalBadge = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Total: \$${totalGeneral.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 13.0 : 12.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    );
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              dropdown,
                              const SizedBox(width: 8),
                              Expanded(
                                child: totalBadge,
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        titleRow,
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [dropdown, totalBadge],
                        ),
                      ],
                    );
                  },
                ),
                if (_selectedPeriod == 'personalizado') ...[
                  const SizedBox(height: 10),
                  Text(
                    'Selecciona el rango de fechas (toca para abrir calendario)',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 11.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(context, true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary.withValues(alpha: 0.05),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, size: 22, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Desde',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _customStart != null
                                          ? date_utils.AppDateUtils.formatDate(_customStart!)
                                          : 'Toca para calendario',
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 13.0 : 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(context, false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary.withValues(alpha: 0.05),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, size: 22, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Hasta',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _customEnd != null
                                          ? date_utils.AppDateUtils.formatDate(_customEnd!)
                                          : 'Toca para calendario',
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 13.0 : 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    widget.buildPaymentMethodCard(
                      context,
                      'Efectivo',
                      efectivo['total'] as double,
                      (efectivo['pagos'] as List).cast<Map<String, dynamic>>(),
                      Colors.green,
                      widget.isTablet,
                    ),
                    widget.buildPaymentMethodCard(
                      context,
                      'Tarjeta',
                      tarjeta['total'] as double,
                      (tarjeta['pagos'] as List).cast<Map<String, dynamic>>(),
                      Colors.purple,
                      widget.isTablet,
                    ),
                    widget.buildPaymentMethodCard(
                      context,
                      'Transferencia',
                      transferencia['total'] as double,
                      (transferencia['pagos'] as List).cast<Map<String, dynamic>>(),
                      Colors.blue,
                      widget.isTablet,
                    ),
                    widget.buildPaymentMethodCard(
                      context,
                      'Pago Mixto',
                      mixto['total'] as double,
                      (mixto['pagos'] as List).cast<Map<String, dynamic>>(),
                      Colors.orange,
                      widget.isTablet,
                    ),
                  ],
                ),
                if ((propinas['total'] as double) > 0) ...[
                  const SizedBox(height: 10),
                  Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Propinas: \$${(propinas['total'] as double).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 13.0 : 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
      final authController = Provider.of<AuthController>(context, listen: false);
      final userName = authController.userName.isNotEmpty
          ? authController.userName
          : null;
      await widget.controller.openCashRegister(
        efectivoInicial: efectivoInicial,
        nota: _notaController.text.trim().isEmpty
            ? null
            : _notaController.text.trim(),
        usuario: userName,
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

            // Mostrar efectivo inicial si hay apertura del día (información)
            Builder(
              builder: (context) {
                final apertura = widget.controller.getTodayCashOpening();
                if (apertura == null || apertura.efectivoInicial <= 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Efectivo inicial (apertura):',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.controller.formatCurrency(apertura.efectivoInicial),
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

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

            // Total declarado (con desglose IVA si está habilitado)
            Builder(
              builder: (context) {
                final efectivo =
                    double.tryParse(_efectivoContadoController.text) ?? 0;
                final tarjeta =
                    double.tryParse(_totalTarjetaController.text) ?? 0;
                final otros =
                    double.tryParse(_otrosIngresosController.text) ?? 0;
                final totalDeclarado = efectivo + tarjeta + otros;
                final showIva = widget.controller.ivaHabilitado;
                // IVA 16% México: si total incluye IVA, subtotal = total/1.16, iva = total - subtotal
                final subtotal = showIva && totalDeclarado > 0
                    ? totalDeclarado / 1.16
                    : 0.0;
                final iva = showIva && totalDeclarado > 0
                    ? totalDeclarado - subtotal
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showIva && totalDeclarado > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal (base gravable):',
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14.0 : 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.controller.formatCurrency(subtotal),
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14.0 : 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'IVA (16%):',
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14.0 : 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.controller.formatCurrency(iva),
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14.0 : 12.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                      ],
                      Row(
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

    // Obtener efectivo inicial de la apertura del día (para verificación contable)
    final apertura = widget.controller.getTodayCashOpening();
    final efectivoInicial = apertura?.efectivoInicial ?? 0.0;

    final cashClose = CashCloseModel(
      id: 'close_${DateTime.now().millisecondsSinceEpoch}',
      fecha: date_utils.AppDateUtils.nowCdmx(),
      periodo: 'Día',
      usuario: userName,
      totalNeto: totalDeclarado,
      efectivo: efectivo,
      tarjeta: tarjeta,
      efectivoInicial: efectivoInicial,
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
          timestamp: date_utils.AppDateUtils.nowCdmx(),
          action: 'enviado',
          usuario: userName,
          mensaje: 'Cierre enviado por $userName',
        ),
      ],
    );

    // Guardar el ScaffoldMessenger antes de cerrar el modal
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await widget.controller.sendCashClose(cashClose);
      
      // Cerrar el modal de cierre de caja
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Esperar un momento para que el modal se cierre completamente
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Después de completar el cierre, ofrecer generar reportes (CSV y PDF)
      if (!mounted) return;
      
      // Obtener un contexto fresco del Scaffold
      if (!mounted) return;
      final scaffoldContext = scaffoldMessenger.context;
      
      // Mostrar diálogo preguntando qué reportes quiere generar
      final reportType = await showDialog<String>(
        context: scaffoldContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cierre de Caja Completado'),
          content: const Text(
            'El cierre de caja se ha enviado correctamente.\n\n'
            '¿Deseas generar reportes con toda la información financiera del día?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('later'),
              child: const Text('Más tarde'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop('csv'),
              child: const Text('Solo CSV'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop('pdf'),
              child: const Text('Solo PDF'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop('both'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CSV y PDF'),
            ),
          ],
        ),
      );

      if (reportType != null && reportType != 'later') {
        try {
          final List<String> errors = [];

          // Generar CSV si es necesario
          if (reportType == 'csv' || reportType == 'both') {
            try {
              await widget.controller.exportCashClosuresToCSV();
              print('✅ CSV exportado correctamente');
            } catch (e) {
              errors.add('Error al generar CSV: $e');
              print('❌ Error al exportar CSV: $e');
            }
          }

          // Generar PDF si es necesario
          if (reportType == 'pdf' || reportType == 'both') {
            try {
              await widget.controller.generateCashClosuresPDF();
              print('✅ PDF generado correctamente');
            } catch (e) {
              errors.add('Error al generar PDF: $e');
              print('❌ Error al generar PDF: $e');
            }
          }

          // Mostrar mensajes de éxito o error
          if (mounted) {
            final messenger = ScaffoldMessenger.of(scaffoldContext);
            
            if (errors.isNotEmpty) {
              // Hubo errores
              messenger.showSnackBar(
                SnackBar(
                  content: Text('⚠️ Cierre enviado, pero hubo errores:\n${errors.join('\n')}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            } else {
              // Todo salió bien
              if (reportType == 'csv') {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ CSV generado y descargado correctamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (reportType == 'pdf') {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ PDF generado correctamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (reportType == 'both') {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✅ CSV y PDF generados correctamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        } catch (e) {
          print('❌ Error general al generar reportes: $e');
          if (mounted) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(
                content: Text('⚠️ Cierre enviado, pero error al generar reportes: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Si falla, aún cerrar el modal pero mostrar error
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al enviar cierre: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
  }
}
