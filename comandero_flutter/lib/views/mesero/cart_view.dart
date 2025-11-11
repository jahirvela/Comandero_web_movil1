import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/product_model.dart';
import '../../utils/app_colors.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  double discountPercentage = 0.0;
  double tipPercentage = 0.0;
  double tipAmount = 0.0;
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
        final subtotalAfterDiscount = subtotal - discountAmount;
        tipAmount = subtotalAfterDiscount * (tipPercentage / 100);
        final total = subtotalAfterDiscount + tipAmount;

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

                            // Propina
                            _buildTipSection(isTablet),
                            const SizedBox(height: 24),

                            // Resumen y totales
                            _buildSummarySection(
                              subtotal,
                              discountAmount,
                              tipAmount,
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

  Widget _buildOrderItems(List<CartItem> cart, bool isTablet) {
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

  Widget _buildCartItem(CartItem item, bool isTablet) {
    final product = item.product;
    final quantity = (item.customizations['quantity'] as int?) ?? 1;
    final kitchenNotes = (item.customizations['kitchenNotes'] as String?) ?? '';
    final extras =
        (item.customizations['extras'] as List<dynamic>?) ?? const [];

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
                  product.name,
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: $quantity',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (kitchenNotes.isNotEmpty) ...[
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
                      'Nota: $kitchenNotes',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: extras
                        .map<Widget>(
                          (extra) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              extra.toString(),
                              style: TextStyle(
                                fontSize: isTablet ? 11.0 : 9.0,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // Precio y botón eliminar
          Column(
            children: [
              Text(
                '\$${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () {
                  context.read<MeseroController>().removeFromCart(item.id);
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
              activeThumbColor: AppColors.primary,
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

  Widget _buildTipSection(bool isTablet) {
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
              'Propina',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Botones de porcentaje rápido
            Row(
              children: [
                _buildTipButton('0%', 0.0, isTablet),
                const SizedBox(width: 8),
                _buildTipButton('10%', 10.0, isTablet),
                const SizedBox(width: 8),
                _buildTipButton('15%', 15.0, isTablet),
                const SizedBox(width: 8),
                _buildTipButton('20%', 20.0, isTablet),
              ],
            ),
            const SizedBox(height: 16),
            // Campo personalizado
            TextField(
              onChanged: (value) {
                setState(() {
                  tipPercentage = double.tryParse(value) ?? 0.0;
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Propina personalizada (%)',
                hintText: '0',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo de monto fijo
            TextField(
              onChanged: (value) {
                setState(() {
                  tipAmount = double.tryParse(value) ?? 0.0;
                  // Calcular porcentaje equivalente
                  final subtotal = context
                      .read<MeseroController>()
                      .calculateTotal();
                  if (subtotal > 0) {
                    tipPercentage = (tipAmount / subtotal) * 100;
                  }
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Propina (monto fijo)',
                hintText: '0.00',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipButton(String label, double percentage, bool isTablet) {
    final isSelected = tipPercentage == percentage;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            tipPercentage = percentage;
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

  Widget _buildSummarySection(
    double subtotal,
    double discountAmount,
    double tipAmount,
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
            if (tipAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Propina (${tipPercentage.toStringAsFixed(0)}%):',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.info,
                    ),
                  ),
                  Text(
                    '\$${tipAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.info,
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
              _showSendToKitchenConfirmation(context, controller, isTablet);
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
              controller.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showSendToKitchenConfirmation(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final cart = controller.getCurrentCart();
    final table = controller.selectedTable;

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              color: AppColors.success,
              size: isTablet ? 28.0 : 24.0,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Pedido enviado a cocina!',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mesa ${table?.number ?? ''}',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'El pedido ha sido enviado exitosamente a cocina. El cocinero recibirá una notificación.',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: isTablet ? 20.0 : 18.0,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cart.length} ${cart.length == 1 ? 'artículo' : 'artículos'} enviados',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Enviar pedido a cocina
                controller.sendOrderToKitchen(
                  isTakeaway: isTakeaway,
                  customerName: isTakeaway ? customerName : null,
                  customerPhone: isTakeaway ? customerPhone : null,
                );

                Navigator.of(dialogContext).pop();

                // Regresar a la vista de mesa
                controller.setCurrentView('table');

                // Mostrar confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('¡Pedido enviado a cocina! 🔥'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Aceptar',
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
              final table = controller.selectedTable;
              if (table != null) {
                controller.sendToCashier(table.id);
                controller.setCurrentView('floor');
              }
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
