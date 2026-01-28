import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/productos_service.dart';
import '../../services/categorias_service.dart';

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
  String? selectedSize;
  int? selectedSizeId;
  double? selectedSizePrice;
  String? selectedTemperature; // Para bebidas
  final Map<String, bool> selectedExtras = {};
  final Map<String, double> extraPrices = {};
  String kitchenNotes = '';
  
  // Productos de la BD
  List<Map<String, dynamic>> _extrasProducts = [];
  List<Map<String, dynamic>> _salsasProducts = [];
  bool _loadingProducts = true;
  final ProductosService _productosService = ProductosService();
  final CategoriasService _categoriasService = CategoriasService();

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
    _loadProductsFromDB();
  }

  List<Map<String, dynamic>> get _sizes {
    final raw = widget.product['sizes'] as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((s) => Map<String, dynamic>.from(s as Map)).toList();
  }

  bool get _hasSizes =>
      (widget.product['hasSizes'] as bool? ?? false) || _sizes.isNotEmpty;

  Future<void> _loadProductsFromDB() async {
    setState(() {
      _loadingProducts = true;
    });

    try {
      // Obtener todas las categorías desde el backend
      final categorias = await _categoriasService.getCategorias();
      
      // Buscar las categorías por nombre (búsqueda flexible)
      int? ingredientesExtraId;
      int? salsasId;
      
      for (var categoria in categorias) {
        final nombre = (categoria['nombre'] as String? ?? '').trim();
        final nombreLower = nombre.toLowerCase();
        final id = categoria['id'] as int?;
        
        if (id != null) {
          // Buscar "Ingredientes Extra" (puede tener variaciones en el nombre)
          if (nombreLower.contains('ingrediente') && nombreLower.contains('extra') ||
              nombreLower == 'extras' ||
              nombreLower == 'ingredientes extra' ||
              nombreLower == 'ingrediente extra') {
            ingredientesExtraId = id;
            print('Categoría "Ingredientes Extra" encontrada: ID=$id, Nombre="$nombre"');
          }
          // Buscar "Salsas"
          if (nombreLower.contains('salsa') && 
              (nombreLower == 'salsas' || nombreLower == 'salsa' || nombreLower.startsWith('salsa'))) {
            salsasId = id;
            print('Categoría "Salsas" encontrada: ID=$id, Nombre="$nombre"');
          }
        }
      }
      
      // Debug: mostrar todas las categorías disponibles
      print('Categorías disponibles:');
      for (var cat in categorias) {
        print('  - ID: ${cat['id']}, Nombre: "${cat['nombre']}"');
      }

      // Cargar productos de "Ingredientes Extra"
      if (ingredientesExtraId != null) {
        final productos = await _productosService.getProductosPorCategoria(ingredientesExtraId);
        _extrasProducts = productos
            .map((p) => p as Map<String, dynamic>)
            .toList();
      } else {
        print('Advertencia: No se encontró la categoría "Ingredientes Extra"');
        _extrasProducts = [];
      }

      // Cargar productos de "Salsas"
      if (salsasId != null) {
        final productos = await _productosService.getProductosPorCategoria(salsasId);
        _salsasProducts = productos
            .map((p) => p as Map<String, dynamic>)
            .toList();
      } else {
        print('Advertencia: No se encontró la categoría "Salsas"');
        _salsasProducts = [];
      }

      print('Productos cargados - Ingredientes Extra: ${_extrasProducts.length}, Salsas: ${_salsasProducts.length}');

      setState(() {
        _loadingProducts = false;
      });

      // Inicializar después de cargar productos
      _initializeModifiers();
    } catch (e) {
      print('Error al cargar productos extras y salsas: $e');
      setState(() {
        _loadingProducts = false;
        _extrasProducts = [];
        _salsasProducts = [];
      });
      _initializeModifiers();
    }
  }

  void _initializeModifiers() {
    final category = widget.product['category'] as String?;

    // Inicializar salsas según el tipo de producto
    // NO inicializar automáticamente - dejar que el usuario seleccione
    if (category == 'Tacos' ||
        category == 'Platos Especiales' ||
        category == 'Salsas') {
      // No preseleccionar ninguna salsa - dejar en null para que el usuario elija
      selectedSauce = null;
    }

    // Inicializar tamaño desde la configuración del producto
    if (_hasSizes && _sizes.isNotEmpty) {
      final first = _sizes.first;
      selectedSize = (first['name'] ?? first['nombre'] ?? first['etiqueta'])
          ?.toString();
      selectedSizeId = (first['id'] as num?)?.toInt();
      selectedSizePrice = (first['price'] ?? first['precio'] ?? 0).toDouble();
    }

    // Inicializar temperatura para bebidas
    if (category == 'Bebidas') {
      selectedTemperature = '¿Con hielo? (Fría)';
    }

    // Configurar extras disponibles desde la BD
    // Solo mostrar extras si el producto permite extras (Tacos o Platos Especiales)
    if (category == 'Tacos' || category == 'Platos Especiales') {
      for (var extra in _extrasProducts) {
        final nombre = extra['nombre'] as String? ?? '';
        final precio = (extra['precio'] as num?)?.toDouble() ?? 0.0;
        if (nombre.isNotEmpty) {
          extraPrices[nombre] = precio;
        }
      }
    }
  }

  double get totalPrice {
    final priceValue = widget.product['price'];
    double basePrice = selectedSizePrice ??
        (priceValue is num ? priceValue.toDouble() : 0.0);
    if (basePrice.isNaN || basePrice.isInfinite) basePrice = 0.0;

    // Agregar precio de extras
    double extrasTotal = 0.0;
    selectedExtras.forEach((key, value) {
      if (value && extraPrices.containsKey(key)) {
        extrasTotal += extraPrices[key]!;
      }
    });

    // Agregar precio de salsa si tiene precio
    if (selectedSauce != null && selectedSauce != 'Sin salsa') {
      for (var salsa in _salsasProducts) {
        if (salsa['nombre'] == selectedSauce) {
          final precio = (salsa['precio'] as num?)?.toDouble() ?? 0.0;
          extrasTotal += precio;
          break;
        }
      }
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

                    // Tamaño (si el producto tiene tamaños configurados)
                    if (_hasSizes) ...[
                      _buildSizeSection(isTablet),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Temperatura/Hielo (solo para bebidas)
                    if (category == 'Bebidas') ...[
                      _buildTemperatureSection(isTablet),
                      SizedBox(height: AppTheme.spacingLG),
                    ],

                    // Ingredientes extra (para tacos y platos especiales)
                    // Mostrar siempre si es taco o plato especial, la sección manejará si hay productos
                    if (category == 'Tacos' || category == 'Platos Especiales') ...[
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
                      if (_hasSizes && selectedSize != null) ...[
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
                        '\$${(selectedSizePrice ?? (widget.product['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
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
    final sizes = _sizes;

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
              'Selecciona tamaño',
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
                  '${size['name'] ?? size['nombre'] ?? size['etiqueta']} - \$${((size['price'] ?? size['precio'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                ),
                trailing: Icon(
                  selectedSize ==
                          (size['name'] ?? size['nombre'] ?? size['etiqueta'])
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selectedSize ==
                          (size['name'] ?? size['nombre'] ?? size['etiqueta'])
                      ? AppColors.primary
                      : AppColors.border,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    selectedSize = (size['name'] ?? size['nombre'] ?? size['etiqueta'])
                        ?.toString();
                    selectedSizeId = (size['id'] as num?)?.toInt();
                    selectedSizePrice =
                        (size['price'] ?? size['precio'] ?? 0).toDouble();
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
    if (_loadingProducts) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_extrasProducts.isEmpty) return const SizedBox.shrink();

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
            ..._extrasProducts.map((extra) {
              final nombre = extra['nombre'] as String? ?? '';
              final precio = (extra['precio'] as num?)?.toDouble() ?? 0.0;
              final isSelected = selectedExtras[nombre] ?? false;
              return CheckboxListTile(
                title: Text(
                  precio > 0 
                    ? '$nombre +\$${precio.toStringAsFixed(0)}'
                    : nombre,
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    selectedExtras[nombre] = value ?? false;
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
    if (_loadingProducts) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Crear lista de salsas desde la BD + opción "Sin salsa"
    final sauces = <Map<String, dynamic>>[];
    
    // Agregar opción "Sin salsa" al PRINCIPIO (como opción por defecto)
    sauces.add({
      'nombre': 'Sin salsa',
      'precio': 0.0,
    });
    
    // Luego agregar las salsas de la BD
    for (var salsa in _salsasProducts) {
      final nombre = salsa['nombre'] as String? ?? '';
      final precio = (salsa['precio'] as num?)?.toDouble() ?? 0.0;
      sauces.add({
        'nombre': nombre,
        'precio': precio,
      });
    }

    // Si no hay salsas en la BD, solo mostrar "Sin salsa" pero NO preseleccionarla
    if (sauces.isEmpty) return const SizedBox.shrink();

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
                title: Text(
                  sauce['precio'] > 0
                    ? '${sauce['nombre']} +\$${sauce['precio'].toStringAsFixed(0)}'
                    : sauce['nombre'] as String,
                ),
                trailing: Icon(
                  selectedSauce == sauce['nombre']
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selectedSauce == sauce['nombre']
                      ? AppColors.primary
                      : AppColors.border,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    // Si se hace clic en la opción ya seleccionada, deseleccionarla
                    if (selectedSauce == sauce['nombre']) {
                      selectedSauce = null;
                    } else {
                      selectedSauce = sauce['nombre'] as String;
                    }
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
                    '\$${(totalPrice.isNaN || totalPrice.isInfinite ? 0.0 : totalPrice).toStringAsFixed(2)}',
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
                // Si no hay salsa seleccionada, usar "Sin salsa" por defecto
                final finalSauce = selectedSauce ?? 'Sin salsa';
                
                // Obtener el precio de la salsa seleccionada
                double saucePrice = 0.0;
                if (finalSauce != 'Sin salsa') {
                  for (var salsa in _salsasProducts) {
                    if (salsa['nombre'] == finalSauce) {
                      saucePrice = (salsa['precio'] as num?)?.toDouble() ?? 0.0;
                      break;
                    }
                  }
                }

                final baseUnitPrice =
                    selectedSizePrice ??
                    (widget.product['price'] as num?)?.toDouble() ??
                    0.0;

                final result = {
                  'quantity': quantity,
                  'sauce': finalSauce,
                  'saucePrice': saucePrice, // Precio de la salsa seleccionada
                  'size': selectedSize,
                  'sizeId': selectedSizeId,
                  'sizePrice': baseUnitPrice,
                  'unitPrice': baseUnitPrice,
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
