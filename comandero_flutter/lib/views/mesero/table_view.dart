import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/table_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;
import 'alert_to_kitchen_modal.dart';

class TableView extends StatelessWidget {
  const TableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        // Verificar si hay mesa seleccionada, si no, regresar al plano
        final table = controller.selectedTable;
        if (table == null) {
          // Regresar al plano de mesas si no hay mesa seleccionada
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.setCurrentView('floor');
          });
          return const Center(child: CircularProgressIndicator());
        }
        final cart = controller.getCurrentCart();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isDesktop = constraints.maxWidth > 900;

            if (isDesktop) {
              return _buildDesktopLayout(context, controller, table, cart);
            } else {
              return _buildMobileLayout(
                context,
                controller,
                table,
                cart,
                isTablet,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    List cart,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna principal - Información de la mesa (scrollable)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildMainColumn(context, controller, table, cart, true),
            ),
          ),
          const SizedBox(width: 24),
          // Columna lateral - Historial de pedidos
          Expanded(
            flex: 1,
            child: _buildOrderHistoryColumn(context, controller, table, true),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    List cart,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        children: [
          _buildMainColumn(context, controller, table, cart, isTablet),
          const SizedBox(height: 24),
          _buildOrderHistoryColumn(context, controller, table, isTablet),
        ],
      ),
    );
  }

  Widget _buildMainColumn(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    List cart,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, table, isTablet),
        const SizedBox(height: 24),

        // Estado de la mesa
        _buildTableStatusCard(context, controller, table, isTablet),
        const SizedBox(height: 24),

        // Consumo de mesa
        _buildConsumptionCard(context, controller, table, cart, isTablet),
        const SizedBox(height: 24),

        // Acciones
        _buildActionsSection(context, controller, isTablet),
        const SizedBox(height: 24),

        // Info del puesto
        _buildRestaurantInfo(isTablet),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TableModel table, bool isTablet) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final controller = context.read<MeseroController>();
            controller.setCurrentView('floor');
          },
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mesa ${table.number}',
              style: TextStyle(
                fontSize: isTablet ? 28.0 : 24.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${table.seats} lugares disponibles',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableStatusCard(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
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
                  'Estado de la Mesa',
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(table.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(
                        table.status,
                      ).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    TableStatus.getStatusText(table.status),
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(table.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Comensales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppColors.textPrimary,
                      size: isTablet ? 20.0 : 18.0,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comensales',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${table.customers ?? 0} personas',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showEditCustomersDialog(
                        context,
                        controller,
                        table,
                        isTablet,
                      ),
                      child: Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    List cart,
    bool isTablet,
  ) {
    final total = controller.calculateTotal();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
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
                  'Consumo de Mesa',
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${cart.length} ${cart.length == 1 ? 'artículo' : 'artículos'}',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cart.isEmpty) ...[
              _buildEmptyCart(isTablet),
            ] else ...[
              _buildCartItems(cart, isTablet),
              const SizedBox(height: 16),
              _buildCartTotal(total, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay artículos en el consumo',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca "Agregar Productos" para comenzar',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List cart, bool isTablet) {
    return Column(
      children: [
        ...cart.take(3).map((item) => _buildCartItem(item, isTablet)),
        if (cart.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+${cart.length - 3} artículos más',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCartItem(dynamic item, bool isTablet) {
    // Calcular precio total del item incluyendo extras y salsas
    final quantity = (item.customizations?['quantity'] as num?)?.toInt() ?? 1;
    double unitPrice = item.product?.price ?? item.price ?? 0.0;

    // Agregar precio de extras
    final extraPrices =
        item.customizations?['extraPrices'] as List<dynamic>? ?? [];
    for (var priceEntry in extraPrices) {
      if (priceEntry is Map) {
        final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
        unitPrice += precio;
      }
    }

    // Agregar precio de salsa
    final saucePrice =
        (item.customizations?['saucePrice'] as num?)?.toDouble() ?? 0.0;
    if (saucePrice > 0) {
      unitPrice += saucePrice;
    }

    final itemTotal = unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.product?.name ?? item.name ?? 'Producto',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.product?.hot == true) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.local_fire_department,
                        size: isTablet ? 16.0 : 14.0,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
                if (item.customizations?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad: $quantity',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\$${itemTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTotal(double total, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total:',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final table = controller.selectedTable;
    return Column(
      children: [
        // Botón Agregar Productos
        SizedBox(
          width: double.infinity,
          height: isTablet ? 56.0 : 48.0,
          child: ElevatedButton.icon(
            onPressed: () => controller.setCurrentView('menu'),
            icon: const Icon(Icons.add),
            label: Text(
              'Agregar pedido',
              style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botones adicionales si hay productos
        if (controller.getCurrentCart().isNotEmpty && table != null) ...[
          SizedBox(
            width: double.infinity,
            height: isTablet ? 48.0 : 44.0,
            child: OutlinedButton.icon(
              onPressed: () => controller.setCurrentView('cart'),
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Ver Consumo Completo',
                style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 48.0 : 44.0,
            child: OutlinedButton.icon(
              onPressed: () => _handleCloseTable(context, controller, table),
              icon: const Icon(Icons.receipt),
              label: Text(
                'Cerrar Mesa',
                style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(
                  color: AppColors.warning.withValues(alpha: 0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleCloseTable(
    BuildContext context,
    MeseroController controller,
    TableModel? table,
  ) async {
    if (table == null) return;

    final shouldClose =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cerrar mesa'),
            content: Text(
              'Se eliminarán los pedidos de la mesa ${table.number} y volverá a estar disponible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar mesa'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClose) return;

    controller.closeTable(table.id);
    controller.setCurrentView('floor');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesa ${table.number} cerrada correctamente.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildOrderHistoryColumn(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) {
    // Usar Consumer para que se actualice cuando cambie el historial
    return Consumer<MeseroController>(
      builder: (context, ctrl, child) {
        // NUEVO SISTEMA: Siempre cargar historial desde backend
        // El controller ya filtra las órdenes finalizadas
        final orderHistory = ctrl.getTableOrderHistory(table.id);

        // Cargar historial desde backend al mostrar la vista
        // Esto asegura que siempre tengamos datos actualizados
        if (orderHistory.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ctrl.loadTableOrderHistory(table.id);
          });
        }

        // El controller ya filtra las órdenes pagadas/canceladas/cerradas
        // Solo normalizar para mostrar
        final displayHistory = orderHistory;

        final normalizedHistory = displayHistory
            .map<Map<String, dynamic>>(
              (order) => {
                ...order,
                'tableNumber': order['tableNumber'] ?? table.number,
              },
            )
            .toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.info.withValues(alpha: 0.1)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.info.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del historial
                Padding(
                  padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.info,
                            size: isTablet ? 20.0 : 18.0,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consumo Actual — Mesa ${table.number}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                                Text(
                                  'Pedidos pendientes de cobro',
                                  style: TextStyle(
                                    fontSize: isTablet ? 11.0 : 10.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          SizedBox(
                            width: isTablet ? 160 : 150,
                            child: ElevatedButton.icon(
                              onPressed: () => _showCloseAccountDialog(
                                context,
                                ctrl,
                                table,
                                isTablet,
                              ),
                              icon: const Icon(Icons.attach_money, size: 18),
                              label: Text(
                                'Cerrar cuenta',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12.0 : 8.0,
                                  vertical: isTablet ? 12.0 : 8.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isTablet ? 160 : 150,
                            child: OutlinedButton.icon(
                              onPressed: () => _showClearHistoryDialog(
                                context,
                                ctrl,
                                table,
                                isTablet,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(
                                'Limpiar historial',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12.0 : 8.0,
                                  vertical: isTablet ? 12.0 : 8.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de pedidos
                Expanded(
                  child: normalizedHistory.isEmpty
                      ? _buildEmptyOrderHistory(isTablet, table, ctrl)
                      : _buildOrderHistoryList(
                          context,
                          normalizedHistory,
                          isTablet,
                          table,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOrderHistory(
    bool isTablet,
    TableModel table,
    MeseroController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: isTablet ? 48.0 : 40.0,
            color: AppColors.info.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos recientes para esta mesa.',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.info,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Resetear la bandera de limpiado antes de recargar
              controller.resetHistoryClearedFlag(table.id);
              await controller.forceReloadTableHistory(table.id);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar historial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryList(
    BuildContext context,
    List<Map<String, dynamic>> orderHistory,
    bool isTablet,
    TableModel table,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 16.0),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        return _buildOrderHistoryItem(context, order, isTablet, table);
      },
    );
  }

  Widget _buildOrderHistoryItem(
    BuildContext context,
    Map<String, dynamic> order,
    bool isTablet,
    TableModel table,
  ) {
    final statusColor = _getOrderStatusColor(order['status']);
    final isTakeaway = order['isTakeaway'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'],
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
                  order['status'],
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
          // Indicador de tipo de orden: Para llevar o En mesa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isTakeaway
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTakeaway ? Icons.shopping_bag_outlined : Icons.restaurant,
                  size: isTablet ? 14.0 : 12.0,
                  color: isTakeaway ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  isTakeaway ? 'Para llevar' : 'En mesa',
                  style: TextStyle(
                    fontSize: isTablet ? 11.0 : 9.0,
                    fontWeight: FontWeight.w600,
                    color: isTakeaway ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Items del pedido
          Text(
            order['items'].join(', '),
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
                order['time'],
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (_canSendAlertForStatus(order['status'])) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAlertModalForOrder(context, table, order),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Enviar alerta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.0 : 12.0,
                    vertical: isTablet ? 10.0 : 8.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canSendAlertForStatus(String? status) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return normalized.contains('prepar') ||
        normalized.contains('listo') ||
        normalized.contains('enviado') ||
        normalized.contains('pend');
  }

  void _showAlertModalForOrder(
    BuildContext context,
    TableModel table,
    Map<String, dynamic> order,
  ) {
    final orderId = order['id']?.toString() ?? 'ORD';
    showAlertToKitchenModal(
      context,
      tableNumber: table.number.toString(),
      orderId: orderId,
    );
  }

  Widget _buildRestaurantInfo(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withValues(alpha: 0.1),
              AppColors.error.withValues(alpha: 0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.primary,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Barbacoa recién hecha',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¡Servimos hasta agotar existencias del día!',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case TableStatus.libre:
        return AppColors.success;
      case TableStatus.ocupada:
        return AppColors.error;
      case TableStatus.enLimpieza:
        return Colors.grey;
      case TableStatus.reservada:
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'En cocina':
        return AppColors.warning;
      case 'En preparación':
        return AppColors.info;
      case 'Listo':
        return AppColors.success;
      case 'Entregado':
        return Colors.grey;
      case 'Cancelado':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  void _showEditCustomersDialog(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) {
    final customersController = TextEditingController(
      text: table.customers != null && table.customers! > 0
          ? '${table.customers}'
          : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Editar Comensales',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mesa ${table.number}',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de personas',
                hintText: 'Ej: 4',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final customers = int.tryParse(customersController.text) ?? 0;
              if (customers >= 0) {
                try {
                  await controller.changeTableStatus(table.id, table.status);
                  _updateTableCustomers(controller, table.id, customers);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al actualizar mesa: ${e.toString()}',
                        ),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un número válido de personas'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateTableCustomers(
    MeseroController controller,
    int tableId,
    int customers,
  ) {
    // Actualizar comensales en la mesa
    controller.updateTableCustomers(tableId, customers);
  }

  void _showClearHistoryDialog(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) {
    final history = controller.getTableOrderHistory(table.id);
    final totalItems = history.fold<int>(0, (sum, order) {
      final items = order['items'] as List<dynamic>? ?? [];
      return sum + items.length;
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Limpiar historial de mesa',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalItems ${totalItems == 1 ? 'artículo' : 'artículos'} en ${history.length} ${history.length == 1 ? 'pedido' : 'pedidos'}',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirma si deseas limpiar el historial de pedidos para esta mesa',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Confirmas que deseas limpiar el historial de Pedidos para la Mesa ${table.number}? Esto no eliminará registros del sistema, solo ocultará la lista en esta sesión.',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
            onPressed: () async {
              // Limpiar historial en memoria y persistir
              await controller.clearTableHistory(table.id);

              // Cerrar el diálogo
              Navigator.of(dialogContext).pop();

              // Mostrar confirmación
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Historial limpiado correctamente'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              // Forzar actualización de la vista
              await Future.delayed(const Duration(milliseconds: 100));
              // El controller ya notifica automáticamente cuando se limpia el historial
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar historial'),
          ),
        ],
      ),
    );
  }

  void _showCloseAccountDialog(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) async {
    // Cargar historial de órdenes desde el backend si no está cargado Y no fue limpiado
    final isCleared = controller.isHistoryCleared(table.id);

    // Obtener historial local primero
    var history = controller.getTableOrderHistory(table.id);

    // Solo recargar desde el backend si el historial local está vacío Y no fue limpiado
    if (history.isEmpty && !isCleared) {
      await controller.loadTableOrderHistory(table.id);
      history = controller.getTableOrderHistory(table.id);
    }

    // IMPORTANTE: Tomar TODAS las órdenes activas de la mesa
    // Esto permite agrupar múltiples pedidos del mismo cliente para cobro conjunto
    final historialCompleto = history;
    final ordenesNoPagadas = historialCompleto.where((order) {
      final status = (order['status'] as String?)?.toLowerCase() ?? '';
      final esFinalizada =
          status == 'pagada' ||
          status == 'cancelada' ||
          status == 'cerrada' ||
          status == 'enviada';
      return !esFinalizada;
    }).toList();

    // Ordenar por fecha (más reciente primero)
    ordenesNoPagadas.sort((a, b) {
      try {
        final fechaA = date_utils.AppDateUtils.parseToLocal(
          a['date'] ?? '1970-01-01',
        );
        final fechaB = date_utils.AppDateUtils.parseToLocal(
          b['date'] ?? '1970-01-01',
        );
        return fechaB.compareTo(fechaA);
      } catch (e) {
        return 0;
      }
    });

    // Tomar TODAS las órdenes activas para agrupar el consumo completo
    final allOrders = ordenesNoPagadas;

    // Calcular consumo total de todas las órdenes abiertas
    double totalConsumo = 0.0;
    final allItems = <Map<String, dynamic>>[];

    for (var order in allOrders) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId != null) {
        try {
          // Obtener detalles de la orden del backend
          final ordenData = await controller.getOrdenDetalle(ordenId);
          if (ordenData != null) {
            final items = ordenData['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 1.0;
              final precioUnitario =
                  (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
              final totalLinea =
                  (item['totalLinea'] as num?)?.toDouble() ??
                  (precioUnitario * cantidad);
              totalConsumo += totalLinea;

              allItems.add({
                'nombre': item['productoNombre'] as String? ?? 'Producto',
                'cantidad': cantidad.toInt(),
                'precioUnitario': precioUnitario,
                'subtotal': totalLinea,
                'extras': item['modificadores'] as List<dynamic>? ?? [],
                'nota': item['nota'] as String?,
                'ordenId':
                    ordenId, // Agregar ID de orden para identificar agrupación
                'ordenNumero':
                    'ORD-${ordenId.toString().padLeft(6, '0')}', // Formato visible
              });
            }
          }
        } catch (e) {
          print('Error al obtener detalles de orden $ordenId: $e');
          // Si falla, usar datos del historial local
          final items = order['items'] as List<dynamic>? ?? [];
          for (var itemStr in items) {
            // Parsear string como "3x Agua de Horchata"
            final itemStrValue = itemStr?.toString() ?? '';
            if (itemStrValue.isEmpty) continue;

            final match = RegExp(r'(\d+)x\s+(.+)').firstMatch(itemStrValue);
            if (match != null) {
              final qtyStr = match.group(1);
              final nombreStr = match.group(2);
              final qty = (qtyStr != null) ? (int.tryParse(qtyStr) ?? 1) : 1;
              final nombre = nombreStr ?? 'Producto';
              // Usar precio estimado si no tenemos el real
              final precioEstimado = 50.0; // Precio por defecto
              final subtotal = precioEstimado * qty;
              totalConsumo += subtotal;

              allItems.add({
                'nombre': nombre,
                'cantidad': qty,
                'precioUnitario': precioEstimado,
                'subtotal': subtotal,
                'extras': [],
                'nota': null,
                'ordenId': ordenId,
                'ordenNumero': 'ORD-${ordenId.toString().padLeft(6, '0')}',
              });
            }
          }
        }
      }
    }

    // Si no hay órdenes en el historial, usar el carrito actual
    final cart = controller.getCurrentCart();
    if (allItems.isEmpty && cart.isNotEmpty) {
      for (var item in cart) {
        final quantity = (item.customizations['quantity'] as int?) ?? 1;

        // Calcular precio unitario incluyendo extras y salsas
        double unitPrice = item.product.price;

        // Agregar precio de extras
        final extraPrices =
            item.customizations['extraPrices'] as List<dynamic>? ?? [];
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            unitPrice += precio;
          }
        }

        // Agregar precio de salsa
        final saucePrice =
            (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
        if (saucePrice > 0) {
          unitPrice += saucePrice;
        }

        final subtotal = unitPrice * quantity;
        totalConsumo += subtotal;

        final extras = (item.customizations['extras'] as List<dynamic>?) ?? [];
        final sauce = item.customizations['sauce'] as String?;
        final kitchenNotes = item.customizations['kitchenNotes'] as String?;

        allItems.add({
          'nombre': item.product.name,
          'cantidad': quantity,
          'precioUnitario': unitPrice,
          'subtotal': subtotal,
          'extras': sauce != null ? [sauce] : extras,
          'nota': kitchenNotes,
        });
      }
    }

    final total = totalConsumo;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppColors.warning,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cerrar cuenta — Mesa ${table.number}',
                            style: TextStyle(
                              fontSize: isTablet ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            allOrders.length > 1
                                ? 'Resumen de consumo (${allOrders.length} órdenes agrupadas)'
                                : 'Resumen de consumo',
                            style: TextStyle(
                              fontSize: isTablet ? 14.0 : 12.0,
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

              // Contenido sin scroll - tabla completa visible
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: Column(
                    children: [
                      // Tabla de consumo - sin scroll, todo visible
                      if (allItems.isNotEmpty) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: isTablet ? 16.0 : 12.0,
                              headingRowColor: WidgetStateProperty.all(
                                AppColors.secondary.withValues(alpha: 0.3),
                              ),
                              columns: [
                                if (allOrders.length > 1)
                                  DataColumn(
                                    label: Text(
                                      'Orden',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 13.0 : 11.0,
                                      ),
                                    ),
                                  ),
                                DataColumn(
                                  label: Text(
                                    'Cant.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Producto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Extras',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Costo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                              ],
                              rows: allItems.map((item) {
                                final quantity = item['cantidad'] as int? ?? 1;
                                final nombre =
                                    item['nombre'] as String? ?? 'Producto';
                                final extras =
                                    item['extras'] as List<dynamic>? ?? [];
                                final nota = item['nota'] as String?;
                                final unitPrice =
                                    (item['precioUnitario'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                                final subtotal =
                                    (item['subtotal'] as num?)?.toDouble() ??
                                    (unitPrice * quantity);

                                String extrasText = '';
                                if (extras.isNotEmpty) {
                                  extrasText = extras
                                      .map((e) {
                                        if (e is Map) {
                                          return e['nombre'] as String? ??
                                              e.toString();
                                        }
                                        return e.toString();
                                      })
                                      .join(', ');
                                }
                                if (nota != null && nota.isNotEmpty) {
                                  if (extrasText.isNotEmpty) {
                                    extrasText += ' | Nota: $nota';
                                  } else {
                                    extrasText = 'Nota: $nota';
                                  }
                                }
                                if (extrasText.isEmpty) {
                                  extrasText = '-';
                                }

                                final ordenNumero =
                                    item['ordenNumero'] as String?;

                                return DataRow(
                                  cells: [
                                    // Mostrar número de orden solo si hay múltiples órdenes
                                    if (allOrders.length > 1)
                                      DataCell(
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            ordenNumero ?? '-',
                                            style: TextStyle(
                                              fontSize: isTablet ? 11.0 : 9.0,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    DataCell(
                                      Text(
                                        '$quantity',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13.0 : 11.0,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        nombre,
                                        style: TextStyle(
                                          fontSize: isTablet ? 13.0 : 11.0,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        extrasText,
                                        style: TextStyle(
                                          fontSize: isTablet ? 11.0 : 9.0,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${unitPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13.0 : 11.0,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${subtotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13.0 : 11.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
                              child: Text(
                                'No hay consumo registrado para esta mesa',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Totales
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.3),
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
                                    fontSize: isTablet ? 18.0 : 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18.0 : 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mensaje informativo
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: isTablet ? 20.0 : 18.0,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Al enviar la cuenta, llegará al Cajero para su cobro e impresión de ticket.',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.border),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16.0 : 14.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close),
                            const SizedBox(width: 8),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Mostrar indicador de carga
                            showDialog(
                              context: dialogContext,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await controller.sendToCashier(table.id);

                            // Cerrar diálogo de carga
                            if (dialogContext.mounted)
                              Navigator.of(dialogContext).pop();

                            // Cerrar diálogo de confirmación
                            if (dialogContext.mounted)
                              Navigator.of(dialogContext).pop();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Cuenta de Mesa ${table.number} enviada al Cajero',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            // Cerrar diálogo de carga
                            if (dialogContext.mounted)
                              Navigator.of(dialogContext).pop();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al enviar cuenta: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: Text(
                          'Enviar al Cajero',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16.0 : 14.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
