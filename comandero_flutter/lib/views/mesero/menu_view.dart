import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  String selectedCategory = 'Todo el Menú';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Datos del menú basados en las imágenes de referencia
  final List<Map<String, dynamic>> menuItems = [
    // Tacos
    {
      'name': 'Taco de Barbacoa',
      'price': 22,
      'description':
          '2 tortillas de maíz con barbacoa de res, cebolla, cilantro y salsa',
      'category': 'Tacos',
      'image': 'taco_barbacoa',
      'hot': false,
    },
    {
      'name': 'Taco de Maciza',
      'price': 25,
      'description':
          '2 tortillas con carne maciza, cebolla asada y salsa verde',
      'category': 'Tacos',
      'image': 'taco_maciza',
      'hot': true,
    },
    {
      'name': 'Taco de Costilla',
      'price': 28,
      'description': '2 tortillas con costilla deshebrada, cebolla curtida',
      'category': 'Tacos',
      'image': 'taco_costilla',
      'hot': false,
    },
    // Platos Especiales
    {
      'name': 'Mix Barbacoa',
      'price': 95,
      'description': '3 tacos mixtos + consomé + cebolla asada + salsas',
      'category': 'Platos Especiales',
      'image': 'mix_barbacoa',
      'hot': false,
      'specialty': true,
    },
    {
      'name': 'Costilla en Salsa',
      'price': 130,
      'description': 'Costilla bañada en salsa roja con tortillas y guarnición',
      'category': 'Platos Especiales',
      'image': 'costilla_salsa',
      'hot': true,
      'specialty': true,
    },
    {
      'name': 'Orden de Barbacoa',
      'price': 110,
      'description': '250g de barbacoa, tortillas, consomé y salsas',
      'category': 'Platos Especiales',
      'image': 'orden_barbacoa',
      'hot': false,
      'specialty': true,
    },
    // Acompañamientos
    {
      'name': 'Tortillas Hechas a Mano',
      'price': 15,
      'description': '10 tortillas de maíz recién hechas',
      'category': 'Acompañamientos',
      'image': 'tortillas',
      'hot': false,
    },
    {
      'name': 'Cebolla Curtida',
      'price': 10,
      'description': 'Cebolla morada encurtida con especias',
      'category': 'Acompañamientos',
      'image': 'cebolla',
      'hot': false,
    },
    {
      'name': 'Frijoles Charros',
      'price': 25,
      'description': 'Frijoles bayos cocidos con especias y chile',
      'category': 'Acompañamientos',
      'image': 'frijoles',
      'hot': true,
    },
    // Bebidas
    {
      'name': 'Agua de Horchata',
      'price': 18,
      'description': 'Agua fresca de arroz con canela',
      'category': 'Bebidas',
      'image': 'horchata',
      'hot': false,
    },
    {
      'name': 'Agua de Jamaica',
      'price': 18,
      'description': 'Agua fresca de flor de jamaica',
      'category': 'Bebidas',
      'image': 'jamaica',
      'hot': false,
    },
    {
      'name': 'Refresco en Lata',
      'price': 15,
      'description': 'Coca-Cola, Sprite, Fanta',
      'category': 'Bebidas',
      'image': 'refresco',
      'hot': false,
    },
    {
      'name': 'Cerveza Nacional',
      'price': 25,
      'description': 'Corona, Dos Equis, Tecate',
      'category': 'Bebidas',
      'image': 'cerveza',
      'hot': false,
    },
    // Consomés
    {
      'name': 'Consomé de Pollo',
      'price': 25,
      'description': 'Caldo nutritivo de pollo con verduras y especias',
      'category': 'Consomes',
      'image': 'consome_pollo',
      'hot': false,
      'sizes': true,
    },
    {
      'name': 'Consomé de Res',
      'price': 30,
      'description': 'Caldo sustancioso de huesos de res con vegetales',
      'category': 'Consomes',
      'image': 'consome_res',
      'hot': false,
      'sizes': true,
    },
    {
      'name': 'Consomé Mixto',
      'price': 35,
      'description': 'Combinación de caldo de pollo y res con hierbas',
      'category': 'Consomes',
      'image': 'consome_mixto',
      'hot': false,
      'sizes': true,
    },
    // Salsas
    {
      'name': 'Salsa Roja',
      'price': 5,
      'description': 'Salsa de chile guajillo picante',
      'category': 'Salsas',
      'image': 'salsa_roja',
      'hot': true,
    },
    {
      'name': 'Salsa Verde',
      'price': 5,
      'description': 'Salsa de chile serrano',
      'category': 'Salsas',
      'image': 'salsa_verde',
      'hot': true,
    },
    {
      'name': 'Salsa de Chile de Árbol',
      'price': 8,
      'description': 'Muy picante - para valientes',
      'category': 'Salsas',
      'image': 'salsa_arbol',
      'hot': true,
    },
  ];

  final List<String> categories = [
    'Todo el Menú',
    'Tacos',
    'Platos Especiales',
    'Acompañamientos',
    'Bebidas',
    'Consomes',
    'Salsas',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredItems {
    List<Map<String, dynamic>> items = menuItems;

    // Filtrar por categoría
    if (selectedCategory != 'Todo el Menú') {
      items = items
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['description'].toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
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

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header con barra naranja
              _buildHeader(context, isTablet),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de búsqueda
                      _buildSearchBar(isTablet),
                      const SizedBox(height: 16),

                      // Filtros de categoría
                      _buildCategoryFilters(isTablet),
                      const SizedBox(height: 16),

                      // Especialidad del día
                      _buildSpecialtyCard(isTablet),
                      const SizedBox(height: 24),

                      // Grid de productos
                      _buildProductsGrid(isTablet, isDesktop),
                      const SizedBox(height: 24),

                      // Mensaje de disponibilidad
                      _buildAvailabilityMessage(isTablet),
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
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
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
                  context.read<MeseroController>().setCurrentView('table');
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 16),

              // Logo y título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comandix',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Juan Martínez • Mesero',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Iconos de acción
              Row(
                children: [
                  // Notificaciones
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Implementar notificaciones
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Carrito
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<MeseroController>().setCurrentView(
                            'cart',
                          );
                        },
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Consumer<MeseroController>(
                        builder: (context, controller, child) {
                          final cartItems = controller.totalCartItems;
                          if (cartItems > 0) {
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$cartItems',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),

                  // Salir
                  IconButton(
                    onPressed: () {
                      // TODO: Implementar logout
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          hintText: "Buscar platillo, ej. 'barbacoa'",
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
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

  Widget _buildSpecialtyCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: AppColors.primary,
            size: isTablet ? 24.0 : 20.0,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Especialidad del Día',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mix Barbacoa con consomé - ¡Recién salido del horno!',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(bool isTablet, bool isDesktop) {
    final items = filteredItems;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isTablet ? 16.0 : 12.0,
        mainAxisSpacing: isTablet ? 16.0 : 12.0,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildProductCard(items[index], isTablet);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          _addToCart(item);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto (placeholder)
              Container(
                height: isTablet ? 120.0 : 100.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/ui_reference/${item['image']}.png',
                    ),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Si no existe la imagen, mostrar icono por defecto
                    },
                  ),
                ),
                child: item['image'] == null
                    ? Icon(
                        Icons.restaurant,
                        size: isTablet ? 40.0 : 32.0,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              const SizedBox(height: 8),

              // Nombre del producto
              Text(
                item['name'],
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Descripción
              Text(
                item['description'],
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Precio y etiquetas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${item['price']}',
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      if (item['hot'] == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: isTablet ? 12.0 : 10.0,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Picante',
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 8.0,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (item['specialty'] == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: isTablet ? 12.0 : 10.0,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Especialidad',
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 8.0,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (item['sizes'] == true) ...[
                        Container(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.straighten,
                                size: isTablet ? 12.0 : 10.0,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Tamaños',
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 8.0,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityMessage(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
            size: isTablet ? 20.0 : 18.0,
          ),
          const SizedBox(width: 8),
          Text(
            'Barbacoa disponible hasta agotar existencias',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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

  void _addToCart(Map<String, dynamic> item) {
    // TODO: Implementar lógica de agregar al carrito
    // final controller = context.read<MeseroController>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} agregado al carrito'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
