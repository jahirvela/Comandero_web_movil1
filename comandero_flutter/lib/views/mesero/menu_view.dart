import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';
import '../../models/product_model.dart';
import 'product_modifier_modal.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  String selectedCategory = 'Todo el Menú';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar productos y categorías cuando se inicializa la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MeseroController>();
      controller.loadProducts();
      controller.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Obtener productos del controller
  List<ProductModel> get products {
    final controller = context.watch<MeseroController>();
    return controller.products;
  }

  // Obtener categorías del controller
  List<String> get categories {
    final controller = context.watch<MeseroController>();
    final backendCategories = controller.categories;
    
    // Crear lista de categorías: "Todo el Menú" + categorías del backend
    final categoryNames = ['Todo el Menú'];
    for (final cat in backendCategories) {
      final nombre = cat['nombre'] as String?;
      if (nombre != null && !categoryNames.contains(nombre)) {
        categoryNames.add(nombre);
      }
    }
    
    return categoryNames;
  }

  // Convertir ProductModel a Map para compatibilidad con el código existente.
  // Usar el nombre real de categoría del backend (displayCategoryName) para que
  // cada producto aparezca en su categoría correcta (Sandwiches, Tacos, etc.).
  List<Map<String, dynamic>> get menuItems {
    return products.map((product) {
      final sizes = product.sizes
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'price': s.price,
            },
          )
          .toList();
      return {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'category': product.displayCategoryName,
        'image': product.image,
        'hot': product.hot,
        'available': product.available,
        'hasSizes': product.hasSizes,
        'sizes': sizes,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get filteredItems {
    List<Map<String, dynamic>> items = menuItems;

    // Filtrar por categoría
    if (selectedCategory != 'Todo el Menú') {
      items = items
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    // Filtrar por búsqueda solo cuando hay texto
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      items = items.where((item) {
        return item['name'].toLowerCase().contains(q.toLowerCase()) ||
            item['description'].toLowerCase().contains(q.toLowerCase());
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24.0 : 16.0,
                isTablet ? 24.0 : 16.0,
                isTablet ? 24.0 : 16.0,
                isTablet ? 12.0 : 8.0,
              ),
              child: _buildHeader(context, isTablet),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 16.0,
                  vertical: isTablet ? 8.0 : 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(isTablet),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(isTablet),
                    const SizedBox(height: 24),
                    _buildProductsGrid(
                      constraints.maxWidth,
                      isTablet,
                      isDesktop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    final controller = context.watch<MeseroController>();
    String tableText;
    if (controller.selectedTable != null) {
      tableText = '${controller.selectedTable!.displayLabel} • Atendiendo';
    } else if (controller.isTakeawayMode) {
      tableText = '🛍️ Para Llevar • ${controller.takeawayCustomerName ?? "Cliente"}';
    } else {
      tableText = 'Mesero';
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            // Navegar a la vista correcta según el modo
            if (controller.isTakeawayMode) {
              controller.setCurrentView('takeaway');
            } else {
              controller.setCurrentView('table');
            }
          },
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 24.0 : 20.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                tableText,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar platillo",
          helperText: "Los resultados se filtran al escribir",
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 16.0 : 14.0,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: isTablet ? 24.0 : 20.0,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.0 : 16.0,
            vertical: isTablet ? 16.0 : 12.0,
          ),
        ),
        style: TextStyle(
          fontSize: isTablet ? 16.0 : 14.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(bool isTablet) {
    final categoryList = categories;
    if (categoryList.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categoryList.map((category) {
          final isSelected = selectedCategory == category;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              backgroundColor: AppColors.secondary,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsGrid(double maxWidth, bool isTablet, bool isDesktop) {
    final items = filteredItems;

    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: isTablet ? 64.0 : 48.0,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              menuItems.isEmpty
                  ? 'No hay productos disponibles'
                  : 'Sin coincidencias para la búsqueda',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (menuItems.isEmpty) const SizedBox(height: 8),
            if (menuItems.isEmpty)
              Text(
                'Agrega productos desde el panel de administrador',
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
    final horizontalPadding = isTablet ? 48.0 : 32.0;
    final availableWidth = (maxWidth - horizontalPadding).clamp(
      240.0,
      maxWidth,
    );
    final targetWidth = isDesktop
        ? 220.0
        : isTablet
        ? 200.0
        : 160.0;
    final crossAxisCount = (availableWidth / targetWidth).floor().clamp(
      1,
      isDesktop ? 6 : 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isTablet ? 12.0 : 10.0,
        mainAxisSpacing: isTablet ? 12.0 : 10.0,
        childAspectRatio: isTablet ? 0.62 : 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildProductCard(items[index], isTablet);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, bool isTablet) {
    return InkWell(
      onTap: () => _addToCart(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderFocus.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isTablet ? 18.0 : 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item['price']}',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['description'],
              style: TextStyle(
                fontSize: isTablet ? 13.0 : 11.0,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (item['hot'] == true)
                  _buildChip(
                    label: 'Picante',
                    color: AppColors.error,
                    icon: Icons.local_fire_department,
                    isTablet: isTablet,
                  ),
                if (item['specialty'] == true)
                  _buildChip(
                    label: 'Especialidad',
                    color: AppColors.warning,
                    icon: Icons.star,
                    isTablet: isTablet,
                  ),
                if (item['sizes'] == true)
                  _buildChip(
                    label: 'Tamaños',
                    color: AppColors.info,
                    icon: Icons.straighten,
                    isTablet: isTablet,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
    required bool isTablet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 12.0 : 10.0, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 11.0 : 9.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) async {
    final controller = context.read<MeseroController>();

    // Verificar que hay una mesa seleccionada O estamos en modo takeaway
    if (controller.selectedTable == null && !controller.isTakeawayMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona una mesa primero'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Buscar el producto real en la lista de productos del controller
    final productId = item['id'] as int;
    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductModel(
        id: productId,
        name: item['name'] as String,
        description: item['description'] as String? ?? '',
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
        category: _getCategoryId(item['category'] as String? ?? ''),
        available: true,
        hot: item['hot'] as bool? ?? false,
      ),
    );

    // Abrir modal de modificadores
    final result = await ProductModifierModal.show(context, item);

    if (result != null && mounted) {
      // IMPORTANTE: Usar el precio unitario del producto, NO el totalPrice
      // totalPrice ya incluye cantidad*precio, lo cual causaría doble multiplicación
      final productWithPrice = product;

      // Crear mapa de customizations
      final customizations = <String, dynamic>{
        'quantity': result['quantity'] as int,
        'sauce': result['sauce'] as String?,
        'saucePrice': (result['saucePrice'] as num?)?.toDouble() ?? 0.0, // Precio de la salsa
        'size': result['size'] as String?,
        'sizeId': result['sizeId'] as int?,
        'sizePrice': (result['sizePrice'] as num?)?.toDouble(),
        'unitPrice': (result['unitPrice'] as num?)?.toDouble(),
        'temperature': result['temperature'] as String?,
        'kitchenNotes': result['kitchenNotes'] as String? ?? '',
        'extras': result['extras'] as List<dynamic>? ?? [],
        'extraPrices': result['extraPrices'] as List<dynamic>? ?? [],
      };

      // Agregar al carrito
      controller.addToCart(productWithPrice, customizations: customizations);

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto agregado: ${item['name']}'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navegar a la vista correcta según el modo
      if (controller.isTakeawayMode) {
        controller.setCurrentView('cart');
      } else if (controller.isDividedAccountMode) {
        // Si está en modo dividida, regresar a la vista de cuenta dividida
        controller.setCurrentView('divided_account');
      } else {
        controller.setCurrentView('table');
      }
    }
  }

  int _getCategoryId(String category) {
    switch (category) {
      case 'Tacos':
        return ProductCategory.tacos;
      case 'Platos Especiales':
        return ProductCategory.platosEspeciales;
      case 'Acompañamientos':
        return ProductCategory.acompanamientos;
      case 'Bebidas':
        return ProductCategory.bebidas;
      case 'Extras':
        return ProductCategory.extras;
      case 'Consomes':
        return ProductCategory.consomes;
      default:
        return ProductCategory.tacos;
    }
  }
}
