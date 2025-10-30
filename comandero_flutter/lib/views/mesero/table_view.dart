import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/table_model.dart';
import '../../utils/app_colors.dart';

class TableView extends StatelessWidget {
  const TableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        final table = controller.selectedTable!;
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
          // Columna principal - Información de la mesa
          Expanded(
            flex: 2,
            child: _buildMainColumn(context, controller, table, cart, true),
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
                      color: _getStatusColor(table.status).withValues(alpha: 0.1),
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
                Text(
                  '${table.customers ?? 0} personas',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
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
                    if (item.product?.hot == true || item.hot == true) ...[
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
                    'Cantidad: ${item.customizations['quantity'] ?? 1}',
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
            '\$${item.product?.price?.toStringAsFixed(0) ?? item.price?.toStringAsFixed(0) ?? '0'}',
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
              'Agregar Productos',
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
        if (controller.getCurrentCart().isNotEmpty) ...[
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
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
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
              onPressed: () {
                // TODO: Implementar cerrar mesa
              },
              icon: const Icon(Icons.receipt),
              label: Text(
                'Cerrar Mesa',
                style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning.withValues(alpha: 0.1)),
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

  Widget _buildOrderHistoryColumn(
    BuildContext context,
    MeseroController controller,
    TableModel table,
    bool isTablet,
  ) {
    // Mock de historial de pedidos
    final orderHistory = [
      {
        'id': 'ORD-034',
        'items': ['3x Taco Barbacoa'],
        'status': 'Listo',
        'time': '14:20',
      },
      {
        'id': 'ORD-029',
        'items': ['1x Mix Barbacoa', '2x Agua Horchata'],
        'status': 'En preparación',
        'time': '13:45',
      },
      {
        'id': 'ORD-025',
        'items': ['2x Quesadilla Barbacoa'],
        'status': 'Entregado',
        'time': '13:15',
      },
    ];

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
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.info,
                    size: isTablet ? 20.0 : 18.0,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Historial de Pedidos — Mesa ${table.number}',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de pedidos
            Expanded(
              child: orderHistory.isEmpty
                  ? _buildEmptyOrderHistory(isTablet)
                  : _buildOrderHistoryList(orderHistory, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrderHistory(bool isTablet) {
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
        ],
      ),
    );
  }

  Widget _buildOrderHistoryList(List orderHistory, bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 16.0),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        return _buildOrderHistoryItem(order, isTablet);
      },
    );
  }

  Widget _buildOrderHistoryItem(Map order, bool isTablet) {
    final statusColor = _getOrderStatusColor(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['items'].join(', '),
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 10.0,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isTablet ? 12.0 : 10.0,
                color: AppColors.info.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 4),
              Text(
                order['time'],
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.info.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ],
      ),
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
}


