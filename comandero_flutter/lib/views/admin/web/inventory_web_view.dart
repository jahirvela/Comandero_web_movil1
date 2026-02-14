import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../../../services/reportes_service.dart';
import '../../../utils/app_colors.dart';

class InventoryWebView extends StatefulWidget {
  const InventoryWebView({super.key});

  @override
  State<InventoryWebView> createState() => _InventoryWebViewState();
}

class _InventoryWebViewState extends State<InventoryWebView> {
  String _selectedCategory = 'todas';
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estadísticas
                  _buildHeader(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Filtros y búsqueda
                  _buildFiltersSection(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Tabla de inventario
                  _buildInventoryTable(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Acciones rápidas
                  _buildQuickActions(controller, isTablet, isDesktop),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final inventory = controller.inventoryItems;
    final lowStockCount = controller.getLowStockItems().length;
    final outOfStockCount = controller.getOutOfStockItems().length;
    final totalValue = inventory.fold<double>(
      0.0,
      (sum, item) => sum + (item.currentStock * item.unitPrice),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: AppColors.primary,
                  size: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gestión de Inventario',
                  style: TextStyle(
                    fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${inventory.length} productos',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Valor Total',
                          '\$${totalValue.toStringAsFixed(2)}',
                          Colors.blue,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Stock Bajo',
                          '$lowStockCount',
                          Colors.orange,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Sin Stock',
                          '$outOfStockCount',
                          Colors.red,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Categorías',
                          '${controller.getInventoryCategories().length}',
                          Colors.purple,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Valor Total',
                              '\$${totalValue.toStringAsFixed(2)}',
                              Colors.blue,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Stock Bajo',
                              '$lowStockCount',
                              Colors.orange,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Sin Stock',
                              '$outOfStockCount',
                              Colors.red,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Categorías',
                              '${controller.getInventoryCategories().length}',
                              Colors.purple,
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtros y Búsqueda',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      // Búsqueda
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar productos...',
                            helperText: 'Los resultados se filtran al escribir',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Categoría
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'todas',
                              child: Text('Todas las categorías'),
                            ),
                            for (final category
                                in controller.getInventoryCategories())
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Ordenar
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Ordenar por',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16.0 : 12.0,
                              vertical: isDesktop ? 16.0 : 12.0,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Nombre'),
                            ),
                            DropdownMenuItem(
                              value: 'stock',
                              child: Text('Stock'),
                            ),
                            DropdownMenuItem(
                              value: 'price',
                              child: Text('Precio'),
                            ),
                            DropdownMenuItem(
                              value: 'category',
                              child: Text('Categoría'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Checkbox stock bajo
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 12.0 : 8.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showLowStockOnly,
                              onChanged: (value) {
                                setState(() {
                                  _showLowStockOnly = value!;
                                });
                              },
                              activeColor: Colors.orange,
                            ),
                            Text(
                              'Solo stock bajo',
                              style: TextStyle(
                                fontSize: isDesktop ? 12.0 : 10.0,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      // Búsqueda
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          helperText: 'Los resultados se filtran al escribir',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Categoría
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'todas',
                                  child: Text('Todas'),
                                ),
                                for (final category
                                    in controller.getInventoryCategories())
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Ordenar
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _sortBy,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Ordenar',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text('Nombre'),
                                ),
                                DropdownMenuItem(
                                  value: 'stock',
                                  child: Text('Stock'),
                                ),
                                DropdownMenuItem(
                                  value: 'price',
                                  child: Text('Precio'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Checkbox stock bajo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showLowStockOnly,
                              onChanged: (value) {
                                setState(() {
                                  _showLowStockOnly = value!;
                                });
                              },
                              activeColor: Colors.orange,
                            ),
                            Text(
                              'Solo stock bajo',
                              style: TextStyle(
                                fontSize: isDesktop ? 12.0 : 10.0,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTable(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final filteredItems = _getFilteredItems(controller);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: EdgeInsets.all(
              isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Inventario (${filteredItems.length} productos)',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Contenido: mensaje vacío o tabla
          if (filteredItems.isEmpty)
            Padding(
              padding: EdgeInsets.all(isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: isDesktop ? 64.0 : 48.0,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.inventoryItems.isEmpty
                          ? 'No hay productos en inventario'
                          : 'Sin coincidencias para la búsqueda',
                      style: TextStyle(
                        fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              columnSpacing: isDesktop ? 24.0 : (isTablet ? 16.0 : 12.0),
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.05),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Producto',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Categoría',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Stock Actual',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Stock Mínimo',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Precio Unitario',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Valor Total',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: filteredItems
                  .map(
                    (item) =>
                        _buildDataRow(item, controller, isTablet, isDesktop),
                  )
                  .toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    InventoryItem item,
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final isLowStock = item.currentStock <= item.minimumStock;
    final isOutOfStock = item.currentStock == 0;

    Color statusColor = Colors.green;
    String statusText = 'Normal';
    IconData statusIcon = Icons.check_circle;

    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Sin Stock';
      statusIcon = Icons.error;
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Stock Bajo';
      statusIcon = Icons.warning;
    }

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: isDesktop ? 40.0 : 32.0,
                height: isDesktop ? 40.0 : 32.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: isDesktop ? 20.0 : 16.0,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: TextStyle(
                        fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.category,
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '${item.currentStock} ${item.unit}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            '${item.minimumStock} ${item.unit}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${item.unitPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${(item.currentStock * item.unitPrice).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(
                statusIcon,
                size: isDesktop ? 16.0 : 14.0,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () => _showEditItemDialog(item, controller),
                icon: Icon(Icons.edit, size: isDesktop ? 18.0 : 16.0),
                color: Colors.blue,
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: () => _showStockAdjustmentDialog(item, controller),
                icon: Icon(Icons.inventory, size: isDesktop ? 18.0 : 16.0),
                color: Colors.orange,
                tooltip: 'Ajustar Stock',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(item, controller),
                icon: Icon(Icons.delete, size: isDesktop ? 18.0 : 16.0),
                color: Colors.red,
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Importar CSV',
                          Icons.upload_file,
                          Colors.blue,
                          () => _showImportDialog(),
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Exportar Reporte',
                          Icons.download,
                          Colors.green,
                          () => _showExportDialog(controller),
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Ajuste Masivo',
                          Icons.edit_note,
                          Colors.orange,
                          () => _showBulkAdjustmentDialog(),
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Generar Pedido',
                          Icons.shopping_cart,
                          Colors.purple,
                          () => _showPurchaseOrderDialog(),
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Importar CSV',
                              Icons.upload_file,
                              Colors.blue,
                              () => _showImportDialog(),
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              'Exportar Reporte',
                              Icons.download,
                              Colors.green,
                              () => _showExportDialog(controller),
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Ajuste Masivo',
                              Icons.edit_note,
                              Colors.orange,
                              () => _showBulkAdjustmentDialog(),
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              'Generar Pedido',
                              Icons.shopping_cart,
                              Colors.purple,
                              () => _showPurchaseOrderDialog(),
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0),
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<InventoryItem> _getFilteredItems(AdminController controller) {
    var items = controller.inventoryItems;

    // Filtrar por búsqueda solo cuando hay texto
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(q.toLowerCase()) ||
                (item.description?.toLowerCase().contains(q.toLowerCase()) ??
                    false) ||
                item.category.toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != 'todas') {
      items = items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Filtrar por stock bajo
    if (_showLowStockOnly) {
      items = items
          .where((item) => item.currentStock <= item.minimumStock)
          .toList();
    }

    // Ordenar
    switch (_sortBy) {
      case 'name':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stock':
        items.sort((a, b) => a.currentStock.compareTo(b.currentStock));
        break;
      case 'price':
        items.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'category':
        items.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return items;
  }

  void _showAddItemDialog(AdminController controller) {
    // TODO: Implementar diálogo para agregar producto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de agregar producto en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showEditItemDialog(InventoryItem item, AdminController controller) {
    // TODO: Implementar diálogo para editar producto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de editar producto en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showStockAdjustmentDialog(
    InventoryItem item,
    AdminController controller,
  ) {
    // TODO: Implementar diálogo para ajustar stock
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de ajuste de stock en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteConfirmation(InventoryItem item, AdminController controller) {
    // TODO: Implementar confirmación de eliminación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de eliminación en desarrollo'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showImportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de importación CSV en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showExportDialog(AdminController controller) {
    final now = DateTime.now();
    DateTime fechaInicio = DateTime(now.year, now.month, 1);
    DateTime fechaFin = now;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.download, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Exportar reporte de inventario'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el rango de fechas para el reporte de movimientos de inventario.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Desde'),
                    subtitle: Text(
                      '${fechaInicio.day.toString().padLeft(2, '0')}/${fechaInicio.month.toString().padLeft(2, '0')}/${fechaInicio.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => fechaInicio = picked);
                          if (fechaInicio.isAfter(fechaFin)) {
                            setDialogState(() => fechaFin = fechaInicio);
                          }
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Hasta'),
                    subtitle: Text(
                      '${fechaFin.day.toString().padLeft(2, '0')}/${fechaFin.month.toString().padLeft(2, '0')}/${fechaFin.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaFin,
                          firstDate: fechaInicio,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => fechaFin = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await ReportesService().generarReporteInventarioPDF(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reporte PDF descargado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al descargar PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar PDF'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await ReportesService().generarReporteInventarioCSV(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reporte CSV descargado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al descargar CSV: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('Descargar CSV'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkAdjustmentDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de ajuste masivo en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showPurchaseOrderDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de pedido de compra en desarrollo'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
