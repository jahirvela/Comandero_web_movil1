import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  double discountPercentage = 0.0;
  bool isTakeaway = false;
  String customerName = '';
  String customerPhone = '';
  int splitCount = 1;

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        final cart = controller.getCurrentCart();
        final subtotal = controller.calculateTotal();
        final discountAmount = subtotal * (discountPercentage / 100);
        final total = subtotal - discountAmount;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  // Header
                  _buildHeader(context, controller, isTablet),

                  // Contenido principal
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cart.isEmpty) ...[
                            _buildEmptyCart(isTablet),
                          ] else ...[
                            // Artículos del pedido
                            _buildOrderItems(cart, isTablet),
                            const SizedBox(height: 24),

                            // Sección de descuento
                            _buildDiscountSection(isTablet),
                            const SizedBox(height: 24),

                            // Sección para llevar
                            _buildTakeawaySection(isTablet),
                            const SizedBox(height: 24),

                            // División de cuenta
                            _buildSplitSection(isTablet),
                            const SizedBox(height: 24),

                            // Resumen y totales
                            _buildSummarySection(
                              subtotal,
                              discountAmount,
                              total,
                              isTablet,
                            ),
                            const SizedBox(height: 24),

                            // Botones de acción
                            _buildActionButtons(context, controller, isTablet),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Botón flotante de estado
              floatingActionButton: _buildFloatingStatusButton(isTablet),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final cart = controller.getCurrentCart();
    final table = controller.selectedTable;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Row(
            children: [
              // Botón de regreso
              IconButton(
                onPressed: () {
                  controller.setCurrentView('table');
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 16),

              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido Mesa ${table?.number ?? ''}',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${cart.length} ${cart.length == 1 ? 'artículo' : 'artículos'}',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón limpiar todo
              IconButton(
                onPressed: () {
                  _showClearCartDialog(context, controller);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay artículos en el pedido',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos desde el menú',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List cart, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Artículos del Pedido',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...cart.map((item) => _buildCartItem(item, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Producto',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${item['quantity'] ?? 1}',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item['notes'] != null && item['notes'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Nota: ${item['notes']}',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Precio y botón eliminar
          Column(
            children: [
              Text(
                '\$${item['price']?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () {
                  // TODO: Implementar eliminar del carrito
                },
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                iconSize: isTablet ? 24.0 : 20.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descuento',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Botones de porcentaje
            Row(
              children: [
                _buildDiscountButton('0%', 0.0, isTablet),
                const SizedBox(width: 8),
                _buildDiscountButton('5%', 5.0, isTablet),
                const SizedBox(width: 8),
                _buildDiscountButton('10%', 10.0, isTablet),
                const SizedBox(width: 8),
                _buildDiscountButton('15%', 15.0, isTablet),
              ],
            ),
            const SizedBox(height: 16),

            // Campo personalizado
            TextField(
              onChanged: (value) {
                setState(() {
                  discountPercentage = double.tryParse(value) ?? 0.0;
                });
              },
              decoration: InputDecoration(
                labelText: 'Descuento personalizado (%)',
                hintText: '0',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountButton(String label, double percentage, bool isTablet) {
    final isSelected = discountPercentage == percentage;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            discountPercentage = percentage;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.secondary,
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: TextStyle(fontSize: isTablet ? 14.0 : 12.0)),
      ),
    );
  }

  Widget _buildTakeawaySection(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Solo para llevar?',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Switch(
              value: isTakeaway,
              onChanged: (value) {
                setState(() {
                  isTakeaway = value;
                });
              },
              activeColor: AppColors.primary,
            ),

            if (isTakeaway) ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  setState(() {
                    customerName = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Nombre del cliente *',
                  hintText: 'Ej. Jahir',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  setState(() {
                    customerPhone = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: '55 1234 5678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSection(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'División de Cuenta',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text(
                  'Dividir entre:',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),

                IconButton(
                  onPressed: () {
                    if (splitCount > 1) {
                      setState(() {
                        splitCount--;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$splitCount',
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      splitCount++;
                    });
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),

                const SizedBox(width: 8),
                Text(
                  splitCount == 1 ? 'persona' : 'personas',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
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

  Widget _buildSummarySection(
    double subtotal,
    double discountAmount,
    double total,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descuento (${discountPercentage.toInt()}%):',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '-\$${discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Botón enviar a cocina
        SizedBox(
          width: double.infinity,
          height: isTablet ? 56.0 : 48.0,
          child: ElevatedButton.icon(
            onPressed: () {
              controller.sendToKitchen();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Pedido enviado a cocina! 🔥'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: Text(
              'Enviar a Cocina',
              style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón cerrar mesa
        SizedBox(
          width: double.infinity,
          height: isTablet ? 48.0 : 44.0,
          child: OutlinedButton.icon(
            onPressed: () {
              _showCloseTableDialog(context, controller);
            },
            icon: const Icon(Icons.receipt),
            label: Text(
              'Cerrar Mesa',
              style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          // TODO: Implementar cambio de estado del puesto
        },
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_circle),
        label: Text(
          isTablet ? 'Puesto Abierto' : 'Abierto',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, MeseroController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar carrito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los artículos del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar limpiar carrito
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showCloseTableDialog(
    BuildContext context,
    MeseroController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Mesa'),
        content: const Text('¿Estás seguro de que quieres cerrar esta mesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar cerrar mesa
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
