import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

/// Modal para personalizar un producto antes de agregarlo al pedido
/// Basado en las imágenes 12-13 y 19-26 proporcionadas
class ProductModifierModal extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductModifierModal({super.key, required this.product});

  @override
  State<ProductModifierModal> createState() => _ProductModifierModalState();

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProductModifierModal(product: product),
    );
  }
}

class _ProductModifierModalState extends State<ProductModifierModal> {
  int quantity = 1;
  String? selectedSauce;
  String? selectedSize; // Para consomés y bebidas
  String? selectedTemperature; // Para bebidas
  final Map<String, bool> selectedExtras = {};
  final Map<String, double> extraPrices = {};
  String kitchenNotes = '';

  // Estimación de tiempo según el producto
  String get estimatedTime {
    final category = widget.product['category'] as String?;
    if (category == 'Consomes' || category == 'Platos Especiales') {
      return '8-12 min';
    } else if (category == 'Bebidas') {
      return '2-3 min';
    } else {
      return '5-8 min';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeModifiers();
  }

  void _initializeModifiers() {
    final category = widget.product['category'] as String?;
    final name = widget.product['name'] as String?;

    // Inicializar salsas según el tipo de producto
    if (category == 'Tacos' ||
        category == 'Platos Especiales' ||
        category == 'Salsas') {
      selectedSauce = 'Salsa roja (picante)';
    }

    // Inicializar tamaño para consomés
    if (category == 'Consomes') {
      selectedSize = 'Mediano';
    }

    // Inicializar temperatura para bebidas
    if (category == 'Bebidas') {
      selectedTemperature = '¿Con hielo? (Fría)';
    }

    // Configurar extras disponibles según el producto
    if (category == 'Tacos') {
      extraPrices['Carne extra'] = 15.0;
      extraPrices['Cebolla asada'] = 5.0;
      extraPrices['Cebolla curtida'] = 3.0;
      extraPrices['Queso Oaxaca'] = 8.0;
    } else if (category == 'Platos Especiales') {
      if (name?.contains('Mix') == true) {
        extraPrices['Taco adicional'] = widget.product['price'] * 0.23; // ~22
        extraPrices['Consomé extra'] = 15.0;
        extraPrices['Tortillas extra (5 pzs)'] = 8.0;
      }
    }
  }

  double get totalPrice {
    double basePrice = (widget.product['price'] as num).toDouble();

    // Aplicar precio según tamaño si es consomé
    if (widget.product['category'] == 'Consomes' && selectedSize != null) {
      if (selectedSize == 'Chico') {
        basePrice = (widget.product['price'] as num).toDouble();
      } else if (selectedSize == 'Mediano') {
        basePrice = (widget.product['price'] as num).toDouble() + 10;
      } else if (selectedSize == 'Grande') {
        basePrice = (widget.product['price'] as num).toDouble() + 20;
      }
    }

    // Agregar precio de extras
    double extrasTotal = 0.0;
    selectedExtras.forEach((key, value) {
      if (value && extraPrices.containsKey(key)) {
        extrasTotal += extraPrices[key]!;
      }
    });

    // Agregar precio de salsa premium
    if (selectedSauce == 'Chile de árbol (muy picante)') {
      extrasTotal += 3.0;
    }

    return (basePrice + extrasTotal) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final category = widget.product['category'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, isTablet),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Producto info
                    _buildProductInfo(isTablet),
                    SizedBox(height: AppTheme.spacingXL),

                    // Cantidad
                    _buildQuantitySection(isTablet),
                    SizedBox(height: AppTheme.spacingLG),

                    // Tamaño (solo para consomés)
                    if (category == 'Consomes') ...[
                      _buildSizeSection(isTablet),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Temperatura/Hielo (solo para bebidas)
                    if (category == 'Bebidas') ...[
                      _buildTemperatureSection(isTablet),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Ingredientes extra (para tacos y platos especiales)
                    if ((category == 'Tacos' ||
                            category == 'Platos Especiales') &&
                        extraPrices.isNotEmpty) ...[
                      _buildExtrasSection(isTablet),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Salsas (para tacos, platos especiales)
                    if (category == 'Tacos' ||
                        category == 'Platos Especiales' ||
                        category == 'Salsas') ...[
                      _buildSaucesSection(isTablet, category),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Notas para cocina
                    _buildKitchenNotesSection(isTablet),
                  ],
                ),
              ),
            ),

            // Footer con total y botón
            _buildFooter(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLG),
          topRight: Radius.circular(AppTheme.radiusLG),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'] as String,
                  style: TextStyle(
                    fontSize: isTablet ? 24.0 : 20.0,
                    fontWeight: AppTheme.fontWeightBold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personaliza tu orden',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['name'] as String,
                        style: TextStyle(
                          fontSize: isTablet ? 20.0 : 18.0,
                          fontWeight: AppTheme.fontWeightBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingXS),
                      Text(
                        widget.product['description'] as String? ?? '',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.product['category'] == 'Consomes' &&
                          selectedSize != null) ...[
                        SizedBox(height: AppTheme.spacingSM),
                        Text(
                          'Tamaño seleccionado: $selectedSize',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.primary,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMD,
                        vertical: AppTheme.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        '\$${(widget.product['price'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: AppTheme.fontWeightBold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMD,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: isTablet ? 14.0 : 12.0,
                            color: AppColors.info,
                          ),
                          SizedBox(width: AppTheme.spacingXS),
                          Text(
                            estimatedTime,
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 10.0,
                              color: AppColors.info,
                              fontWeight: AppTheme.fontWeightMedium,
                            ),
                          ),
                        ],
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

  Widget _buildQuantitySection(bool isTablet) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cantidad',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 1
                      ? () {
                          setState(() {
                            quantity--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: quantity > 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: AppTheme.fontWeightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSection(bool isTablet) {
    final sizes = [
      {'name': 'Chico', 'price': (widget.product['price'] as num).toDouble()},
      {
        'name': 'Mediano',
        'price': (widget.product['price'] as num).toDouble() + 10,
      },
      {
        'name': 'Grande',
        'price': (widget.product['price'] as num).toDouble() + 20,
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona tamaño: Chico / Mediano / Grande',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            for (final size in sizes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '${size['name']} - \$${((size['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
                trailing: Icon(
                  selectedSize == size['name']
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selectedSize == size['name']
                      ? AppColors.primary
                      : AppColors.border,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    selectedSize = size['name'] as String;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureSection(bool isTablet) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperatura / Hielo',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            for (final option in const [
              '¿Con hielo? (Fría)',
              'Sin hielo (Al tiempo)',
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option),
                trailing: Icon(
                  selectedTemperature == option
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selectedTemperature == option
                      ? AppColors.primary
                      : AppColors.border,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    selectedTemperature = option;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasSection(bool isTablet) {
    if (extraPrices.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredientes extra',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            ...extraPrices.entries.map((entry) {
              final isSelected = selectedExtras[entry.key] ?? false;
              return CheckboxListTile(
                title: Text(
                  '${entry.key} +\$${entry.value.toStringAsFixed(0)}',
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    selectedExtras[entry.key] = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSaucesSection(bool isTablet, String? category) {
    final sauces = category == 'Salsas'
        ? ['Salsa roja (picante)', 'Salsa verde (medio)']
        : [
            'Salsa roja (picante)',
            'Salsa verde (medio)',
            'Chile de árbol (muy picante) +\$3',
            'Sin salsa',
          ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salsas (incluida)',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            for (final sauce in sauces)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(sauce),
                trailing: Icon(
                  selectedSauce == sauce
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selectedSauce == sauce
                      ? AppColors.primary
                      : AppColors.border,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    selectedSauce = sauce;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenNotesSection(bool isTablet) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notas para cocina',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                fontWeight: AppTheme.fontWeightSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextField(
              onChanged: (value) {
                setState(() {
                  kitchenNotes = value;
                });
              },
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: sin cilantro, extra picante, tortilla doradita',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                contentPadding: EdgeInsets.all(AppTheme.spacingMD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusLG),
          bottomRight: Radius.circular(AppTheme.radiusLG),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: AppTheme.fontWeightSemibold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Tiempo estimado:',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 24.0 : 20.0,
                      fontWeight: AppTheme.fontWeightBold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    estimatedTime,
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingLG),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 56.0 : 48.0,
            child: ElevatedButton(
              onPressed: () {
                final result = {
                  'quantity': quantity,
                  'sauce': selectedSauce,
                  'size': selectedSize,
                  'temperature': selectedTemperature,
                  'extras': selectedExtras.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList(),
                  'extraPrices': selectedExtras.entries
                      .where((e) => e.value)
                      .map((e) {
                        final price = extraPrices[e.key] ?? 0.0;
                        return {'name': e.key, 'price': price};
                      })
                      .toList(),
                  'kitchenNotes': kitchenNotes,
                  'totalPrice': totalPrice,
                };
                Navigator.of(context).pop(result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: Text(
                'Agregar al Pedido',
                style: TextStyle(
                  fontSize: isTablet ? 18.0 : 16.0,
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
