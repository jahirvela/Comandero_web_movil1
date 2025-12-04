import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../services/inventario_service.dart';
import '../../services/ordenes_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;

class IngredientConsumptionView extends StatefulWidget {
  const IngredientConsumptionView({super.key});

  @override
  State<IngredientConsumptionView> createState() =>
      _IngredientConsumptionViewState();
}

class _IngredientConsumptionViewState extends State<IngredientConsumptionView> {
  String selectedCategory = 'Todos';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> ingredients = [];
  bool isLoading = true;

  final List<String> categories = [
    'Todos',
    'Carnes',
    'Verduras',
    'Especias',
    'Tortillas',
    'Bebidas',
  ];

  @override
  void initState() {
    super.initState();
    _loadIngredientsData();
  }

  Future<void> _loadIngredientsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final inventarioService = InventarioService();
      final ordenesService = OrdenesService();

      // Obtener items de inventario
      final items = await inventarioService.getItems();

      // Obtener órdenes del día para calcular consumo
      final ordenes = await ordenesService.getOrdenes();
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);

      final ordenesHoy = ordenes.where((o) {
        final creadoEn = o['creadoEn'] != null
            ? date_utils.AppDateUtils.parseToLocal(o['creadoEn'])
            : null;
        return creadoEn != null && creadoEn.isAfter(inicioDia);
      }).toList();

      // Mapear items a formato de ingredientes
      ingredients = items.map((item) {
        final nombre = item['nombre'] as String? ?? 'Sin nombre';
        final categoria = item['categoria'] as String? ?? 'Otros';
        final cantidadActual =
            (item['cantidadActual'] as num?)?.toDouble() ?? 0.0;
        final stockMinimo = (item['stockMinimo'] as num?)?.toDouble() ?? 0.0;
        final unidad = item['unidad'] as String? ?? 'unidad';

        // Calcular consumo del día (simplificado: basado en órdenes)
        final consumoHoy = (ordenesHoy.length * 0.5).clamp(0.0, cantidadActual);

        // Determinar estado
        String status = 'Normal';
        Color color = AppColors.success;

        if (cantidadActual <= 0) {
          status = 'Agotado';
          color = AppColors.error;
        } else if (cantidadActual < stockMinimo) {
          status = 'Bajo Stock';
          color = AppColors.warning;
        }

        return {
          'name': nombre,
          'category': categoria,
          'currentStock': cantidadActual,
          'unit': unidad,
          'minStock': stockMinimo,
          'consumptionToday': consumoHoy,
          'lastUpdated': hoy.toString().substring(11, 16),
          'status': status,
          'color': color,
        };
      }).toList();
    } catch (e) {
      print('Error al cargar datos de ingredientes: $e');
      ingredients = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Datos mock de ingredientes (respaldo)
  final List<Map<String, dynamic>> _mockIngredients = [
    {
      'name': 'Barbacoa de Res',
      'category': 'Carnes',
      'currentStock': 15.5,
      'unit': 'kg',
      'minStock': 5.0,
      'consumptionToday': 8.2,
      'lastUpdated': '14:30',
      'status': 'Bajo Stock',
      'color': AppColors.warning,
    },
    {
      'name': 'Cebolla Morada',
      'category': 'Verduras',
      'currentStock': 12.0,
      'unit': 'kg',
      'minStock': 3.0,
      'consumptionToday': 4.5,
      'lastUpdated': '14:25',
      'status': 'Normal',
      'color': AppColors.success,
    },
    {
      'name': 'Cilantro',
      'category': 'Verduras',
      'currentStock': 2.1,
      'unit': 'kg',
      'minStock': 1.0,
      'consumptionToday': 1.8,
      'lastUpdated': '14:20',
      'status': 'Bajo Stock',
      'color': AppColors.warning,
    },
    {
      'name': 'Tortillas de Maíz',
      'category': 'Tortillas',
      'currentStock': 200,
      'unit': 'pzas',
      'minStock': 50,
      'consumptionToday': 150,
      'lastUpdated': '14:15',
      'status': 'Normal',
      'color': AppColors.success,
    },
    {
      'name': 'Chile Guajillo',
      'category': 'Especias',
      'currentStock': 0.8,
      'unit': 'kg',
      'minStock': 1.0,
      'consumptionToday': 0.3,
      'lastUpdated': '14:10',
      'status': 'Agotado',
      'color': AppColors.error,
    },
    {
      'name': 'Agua Horchata',
      'category': 'Bebidas',
      'currentStock': 25.0,
      'unit': 'L',
      'minStock': 10.0,
      'consumptionToday': 12.5,
      'lastUpdated': '14:05',
      'status': 'Normal',
      'color': AppColors.success,
    },
    {
      'name': 'Carne Maciza',
      'category': 'Carnes',
      'currentStock': 8.5,
      'unit': 'kg',
      'minStock': 5.0,
      'consumptionToday': 6.2,
      'lastUpdated': '14:00',
      'status': 'Bajo Stock',
      'color': AppColors.warning,
    },
    {
      'name': 'Costilla de Res',
      'category': 'Carnes',
      'currentStock': 3.2,
      'unit': 'kg',
      'minStock': 2.0,
      'consumptionToday': 2.8,
      'lastUpdated': '13:55',
      'status': 'Bajo Stock',
      'color': AppColors.warning,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredIngredients {
    List<Map<String, dynamic>> items = ingredients;

    // Filtrar por categoría
    if (selectedCategory != 'Todos') {
      items = items
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item['name'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header
              _buildHeader(context, isTablet),

              // Contenido principal
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
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

                            // Estadísticas rápidas
                            _buildQuickStats(isTablet),
                            const SizedBox(height: 24),

                            // Lista de ingredientes
                            _buildIngredientsList(isTablet),
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
                  context.read<CocineroController>().setCurrentView('main');
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
                      'Consumo de Ingredientes',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Juan Martínez • Cocinero',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de actualizar
              IconButton(
                onPressed: () {
                  _showUpdateStockDialog(context);
                },
                icon: const Icon(Icons.update, color: Colors.white),
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
          hintText: "Buscar ingrediente",
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

  Widget _buildQuickStats(bool isTablet) {
    final lowStockCount = ingredients
        .where((item) => item['status'] == 'Bajo Stock')
        .length;
    final outOfStockCount = ingredients
        .where((item) => item['status'] == 'Agotado')
        .length;
    final normalStockCount = ingredients
        .where((item) => item['status'] == 'Normal')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Normal',
            normalStockCount,
            AppColors.success,
            isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Bajo Stock',
            lowStockCount,
            AppColors.warning,
            isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Agotado',
            outOfStockCount,
            AppColors.error,
            isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: isTablet ? 12.0 : 10.0, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList(bool isTablet) {
    final items = filteredIngredients;

    if (items.isEmpty) {
      return _buildEmptyState(isTablet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredientes (${items.length})',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (ingredient) => _buildIngredientCard(ingredient, isTablet),
        ),
      ],
    );
  }

  Widget _buildIngredientCard(Map<String, dynamic> ingredient, bool isTablet) {
    final statusColor = ingredient['color'] as Color;
    final stockPercentage =
        (ingredient['currentStock'] / (ingredient['minStock'] * 2)) * 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del ingrediente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient['name'],
                          style: TextStyle(
                            fontSize: isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ingredient['category'],
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      ingredient['status'],
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.0,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información de stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Actual',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${ingredient['currentStock']} ${ingredient['unit']}',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mínimo',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${ingredient['minStock']} ${ingredient['unit']}',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumo Hoy',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${ingredient['consumptionToday']} ${ingredient['unit']}',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel de Stock',
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stockPercentage / 100,
                    backgroundColor: AppColors.secondary,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: isTablet ? 8.0 : 6.0,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stockPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información adicional y acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isTablet ? 16.0 : 14.0,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Actualizado: ${ingredient['lastUpdated']}',
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 10.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _showUpdateStockDialog(context, ingredient);
                        },
                        icon: const Icon(Icons.edit),
                        color: AppColors.primary,
                        iconSize: isTablet ? 20.0 : 18.0,
                      ),
                      IconButton(
                        onPressed: () {
                          _showConsumptionHistory(context, ingredient);
                        },
                        icon: const Icon(Icons.history),
                        color: AppColors.info,
                        iconSize: isTablet ? 20.0 : 18.0,
                      ),
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

  Widget _buildEmptyState(bool isTablet) {
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
            Icons.inventory,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ingredientes que coincidan con los filtros',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o la búsqueda',
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

  Widget _buildFloatingStatusButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar cambio de estado de la cocina
        },
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.restaurant),
        label: Text(
          isTablet ? 'Cocina Activa' : 'Activa',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  void _showUpdateStockDialog(
    BuildContext context, [
    Map<String, dynamic>? ingredient,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ingredient != null
              ? 'Actualizar ${ingredient['name']}'
              : 'Actualizar Stock',
        ),
        content: ingredient != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stock actual: ${ingredient['currentStock']} ${ingredient['unit']}',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nuevo stock',
                      hintText: 'Ingresa la cantidad',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              )
            : const Text('Selecciona un ingrediente para actualizar su stock'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (ingredient != null)
            TextButton(
              onPressed: () {
                // TODO: Implementar actualización de stock
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock de ${ingredient['name']} actualizado'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Actualizar'),
            ),
        ],
      ),
    );
  }

  void _showConsumptionHistory(
    BuildContext context,
    Map<String, dynamic> ingredient,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de ${ingredient['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hoy: 8.2 kg'),
            Text('Ayer: 7.5 kg'),
            Text('Anteayer: 6.8 kg'),
            Text('Promedio semanal: 7.2 kg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
