import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/product_model.dart';
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
  String orderNote = '';
  int splitCount = 1;
  final TextEditingController _orderNoteController = TextEditingController();

  @override
  void dispose() {
    _orderNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        final cart = controller.getCurrentCart();
        final subtotal = controller.calculateTotal();
        final discountAmount = subtotal * (discountPercentage / 100);
        final subtotalAfterDiscount = subtotal - discountAmount;

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
                            _buildOrderItems(cart, controller, isTablet),
                            if (controller.isTakeawayMode) ...[
                              const SizedBox(height: 16),
                              _buildAddMoreProductsButton(context, controller, isTablet),
                            ],
                            const SizedBox(height: 24),

                            // Sección de descuento
                            _buildDiscountSection(isTablet),
                            const SizedBox(height: 24),

                            // Sección para llevar
                            _buildTakeawaySection(isTablet),
                            const SizedBox(height: 24),

                            // Nota del pedido
                            _buildOrderNoteSection(isTablet),
                            const SizedBox(height: 24),

                            // División de cuenta
                            _buildSplitSection(isTablet),
                            const SizedBox(height: 24),

                            // Resumen y totales (con IVA si está habilitado en configuración)
                            FutureBuilder<bool>(
                              future: controller.getIvaHabilitado(),
                              builder: (context, snapshot) {
                                final ivaHabilitado = snapshot.data ?? false;
                                final impuesto = ivaHabilitado ? (subtotalAfterDiscount * 0.16) : 0.0;
                                final totalConIva = subtotalAfterDiscount + impuesto;
                                return _buildSummarySection(
                                  subtotal,
                                  discountAmount,
                                  totalConIva,
                                  splitCount,
                                  isTablet,
                                  ivaHabilitado: ivaHabilitado,
                                  impuesto: impuesto,
                                );
                              },
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
                  // Navegar a la vista correcta según el modo
                  if (controller.isTakeawayMode) {
                    controller.setCurrentView('menu');
                  } else {
                    controller.setCurrentView('table');
                  }
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
                      'Pedido ${table?.displayLabel ?? table?.number ?? ''}',
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

  Widget _buildOrderItems(List<CartItem> cart, MeseroController controller, bool isTablet) {
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
            ...cart.map((item) => _buildCartItem(item, controller, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, MeseroController controller, bool isTablet) {
    final product = item.product;
    final quantity = (item.customizations['quantity'] as int?) ?? 1;
    final kitchenNotes = (item.customizations['kitchenNotes'] as String?) ?? '';
    final extras =
        (item.customizations['extras'] as List<dynamic>?) ?? const [];
    final personId = item.customizations['personId'] as String?;
    final personName = personId != null ? controller.personNames[personId] : null;

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
                // Mostrar persona asignada si es cuenta dividida
                if (controller.isDividedAccountMode) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showPersonSelector(context, item, controller, isTablet),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: personId != null
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: personId != null
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            personId != null ? Icons.person : Icons.person_outline,
                            size: isTablet ? 14.0 : 12.0,
                            color: personId != null ? AppColors.primary : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            personName ?? 'Sin asignar',
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 10.0,
                              color: personId != null ? AppColors.primary : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: isTablet ? 12.0 : 10.0,
                            color: personId != null ? AppColors.primary : AppColors.warning,
                          ),
                        ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (quantity > 1)
                    Text(
                      '\$${(((_getUnitPrice(item) * quantity)).toStringAsFixed(0))}',
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Text(
                      '\$${_getUnitPrice(item).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  if (quantity > 1)
                    Text(
                      '\$${_getUnitPrice(item).toStringAsFixed(0)} c/u',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
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

  double _getUnitPrice(CartItem item) {
    final customPrice =
        item.customizations['sizePrice'] ?? item.customizations['unitPrice'];
    if (customPrice is num) {
      return customPrice.toDouble();
    }
    return item.product.price;
  }

  Widget _buildAddMoreProductsButton(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => controller.setCurrentView('menu'),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          'Añadir más productos',
          style: TextStyle(
            fontSize: isTablet ? 16.0 : 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: EdgeInsets.symmetric(vertical: isTablet ? 14.0 : 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        // Si estamos en modo takeaway, mostrar info del cliente
        final isTakeawayMode = controller.isTakeawayMode;
        final takeawayName = controller.takeawayCustomerName;
        final takeawayPhone = controller.takeawayCustomerPhone;

        // Si estamos desde una mesa y no es modo takeaway, ocultar la sección
        if (!isTakeawayMode && controller.selectedTable != null) {
          return const SizedBox.shrink();
        }

        // Si estamos en modo takeaway, usar los datos del cliente guardados
        if (isTakeawayMode && takeawayName != null) {
          // Actualizar estado local con datos del controlador
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && customerName != takeawayName) {
              setState(() {
                isTakeaway = true;
                customerName = takeawayName;
                customerPhone = takeawayPhone ?? '';
              });
            }
          });

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.warning.withValues(alpha: 0.05),
              ),
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: AppColors.warning,
                        size: isTablet ? 24.0 : 20.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pedido Para Llevar',
                        style: TextStyle(
                          fontSize: isTablet ? 20.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Cliente: $takeawayName',
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (takeawayPhone != null && takeawayPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Tel: $takeawayPhone',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Si no hay mesa seleccionada ni es modo takeaway, no mostrar nada
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOrderNoteSection(bool isTablet) {
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
              'Nota del Pedido',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderNoteController,
              onChanged: (value) {
                setState(() {
                  orderNote = value;
                });
              },
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Nota adicional (opcional)',
                hintText: 'Ej. Sin cebolla, para llevar, etc.',
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
    int splitCount,
    bool isTablet, {
    bool ivaHabilitado = false,
    double impuesto = 0.0,
  }) {
    final totalPerPerson = splitCount > 1 ? total / splitCount : total;

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
            if (ivaHabilitado) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IVA (16%):',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${impuesto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: AppColors.textPrimary,
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
            if (splitCount > 1) ...[
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
                      'Total por persona (${splitCount} ${splitCount == 1 ? 'persona' : 'personas'}):',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '\$${totalPerPerson.toStringAsFixed(2)}',
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
      barrierDismissible: true,
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
            // Botón X para cerrar
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
              iconSize: isTablet ? 24.0 : 20.0,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textSecondary,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${table?.displayLabel ?? table?.number ?? ''}',
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
              onPressed: () async {
                // Mostrar indicador de carga
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Obtener nombre del usuario del AuthController
                  final authController = Provider.of<AuthController>(context, listen: false);
                  final userName = authController.userName.isNotEmpty 
                      ? authController.userName 
                      : 'Mesero';
                  
                  // Determinar si es modo takeaway (desde sección Para Llevar o switch)
                  final isTakeawayMode = controller.isTakeawayMode;
                  final finalIsTakeaway = isTakeaway || isTakeawayMode;
                  
                  // Obtener datos del cliente (del controlador si es modo takeaway, o del form)
                  final finalCustomerName = isTakeawayMode 
                      ? (controller.takeawayCustomerName ?? customerName.trim())
                      : customerName.trim();
                  final finalCustomerPhone = isTakeawayMode 
                      ? (controller.takeawayCustomerPhone ?? customerPhone.trim())
                      : customerPhone.trim();
                  
                  // Validar campos obligatorios para takeaway
                  if (finalIsTakeaway && finalCustomerName.isEmpty) {
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa el nombre del cliente para el pedido para llevar'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                    return;
                  }

                  // Calcular descuento
                  final subtotal = controller.calculateTotal();
                  final discountAmount = subtotal * (discountPercentage / 100);
                  // Enviar pedido a cocina
                  await controller.sendOrderToKitchen(
                    isTakeaway: finalIsTakeaway,
                    customerName: finalIsTakeaway ? finalCustomerName : null,
                    customerPhone: finalIsTakeaway && finalCustomerPhone.isNotEmpty ? finalCustomerPhone : null,
                    waiterName: userName,
                    discount: discountAmount,
                    orderNote: orderNote.trim().isNotEmpty ? orderNote.trim() : null,
                    splitCount: splitCount,
                  );
                  
                  // Cerrar diálogo de carga
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                  // Cerrar diálogo de confirmación
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                  // Regresar a la vista correcta
                  if (isTakeawayMode) {
                    // Limpiar datos del cliente para llevar después de enviar
                    controller.clearTakeawayCustomerInfo();
                    // Recargar historial de para llevar
                    controller.loadTakeawayOrderHistory();
                    // Regresar a la vista de para llevar
                    controller.setCurrentView('takeaway');
                  } else {
                    // Regresar a la vista de mesa
                    controller.setCurrentView('table');
                  }

                  // Mostrar confirmación
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(finalIsTakeaway 
                            ? '¡Pedido para llevar enviado a cocina! 🛍️' 
                            : '¡Pedido enviado a cocina! 🔥'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  
                  if (context.mounted) {
                    final errStr = e.toString();
                    final isUnauthorized = errStr.contains('401') || errStr.contains('Unauthorized');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUnauthorized
                              ? 'Sesión expirada o no autorizada. Cierra sesión y vuelve a entrar, luego intenta enviar el pedido de nuevo.'
                              : 'Error al enviar pedido: ${errStr.length > 80 ? "${errStr.substring(0, 80)}..." : errStr}',
                        ),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
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
            onPressed: () async {
              final table = controller.selectedTable;
              if (table != null) {
                try {
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  await controller.sendToCashier(table.id);
                  
                  // Cerrar diálogo de carga
                  if (context.mounted) Navigator.of(context).pop();
                  
                  // Cerrar diálogo de confirmación
                  if (context.mounted) Navigator.of(context).pop();
                  
                  controller.setCurrentView('floor');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cuenta de ${table.displayLabel} enviada al Cajero',
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
                          'Error al enviar cuenta: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para seleccionar persona para un producto
  void _showPersonSelector(
    BuildContext context,
    CartItem item,
    MeseroController controller,
    bool isTablet,
  ) {
    final personNames = controller.personNames;
    final currentPersonId = item.customizations['personId'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asignar a persona',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (personNames.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No hay personas. Agrega una persona primero.',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...personNames.entries.map((entry) {
                final personId = entry.key;
                final personName = entry.value;
                final isSelected = currentPersonId == personId;

                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.person : Icons.person_outline,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    personName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.assignCartItemToPerson(item.id, personId);
                    Navigator.pop(context);
                  },
                );
              }),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                currentPersonId == null ? Icons.check_circle : Icons.radio_button_unchecked,
                color: currentPersonId == null ? AppColors.warning : AppColors.textSecondary,
              ),
              title: Text(
                'Sin asignar',
                style: TextStyle(
                  fontWeight: currentPersonId == null ? FontWeight.w600 : FontWeight.normal,
                  color: currentPersonId == null ? AppColors.warning : AppColors.textPrimary,
                ),
              ),
              onTap: () {
                // Remover asignación: simplemente remover personId del item
                // El controller se actualizará cuando se modifique el carrito
                final cart = controller.getCurrentCart();
                final itemToUpdate = cart.firstWhere((i) => i.id == item.id);
                itemToUpdate.customizations.remove('personId');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddPersonDialog(context, controller, isTablet);
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar persona'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para agregar persona
  void _showAddPersonDialog(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Persona'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la persona',
            hintText: 'Ej: Juan, María, Persona 1',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                controller.addPerson(name: name);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

}
