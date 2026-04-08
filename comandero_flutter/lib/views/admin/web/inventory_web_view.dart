import 'dart:convert' show utf8;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../../../services/reportes_service.dart';
import '../../../config/api_config.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/date_utils.dart' as date_utils;
import '../../../utils/file_download_helper.dart';
import '../../../utils/inventory_csv_import_utils.dart';
import '../../../utils/inventory_display_utils.dart';
import '../../../utils/inventory_import_template.dart';
import '../../../utils/string_search_utils.dart';

String _inventoryWebErrorMessage(Object e) {
  final errorStr = e.toString();
  if (errorStr.contains('Error de conexión') ||
      errorStr.contains('No se pudo conectar') ||
      errorStr.contains('backend esté corriendo') ||
      errorStr.contains('connection')) {
    return 'No se pudo conectar al backend. Verifica que esté disponible en ${ApiConfig.baseUrl}';
  }
  if (errorStr.contains('401') || errorStr.contains('403')) {
    return 'No tienes permisos para realizar esta acción.';
  }
  if (errorStr.contains('Categoría no encontrada')) {
    return 'La categoría seleccionada no existe en el sistema.';
  }
  final m = RegExp(r'El backend no retornó (.+?)\.').firstMatch(errorStr);
  if (m != null) {
    return 'Error del servidor: ${m.group(1)}';
  }
  final ex = RegExp(r'Exception:\s*(.+?)(?:Exception:|$)').firstMatch(errorStr);
  if (ex != null) {
    return ex.group(1)?.trim() ?? 'Error desconocido';
  }
  return errorStr.length > 150
      ? '${errorStr.substring(0, 150)}...'
      : errorStr;
}

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

  String _formatInvNumber(double value, {int maxDecimals = 2}) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(maxDecimals)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

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
                          'Costo Total',
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
                              'Costo Total',
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
                    'ID',
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 9.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                    'Costo Unitario',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Costo Total',
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

  Widget _buildStockTableCell({
    required String primary,
    String? secondary,
    List<String>? secondaryLines,
    required bool isTablet,
    required bool isDesktop,
    required FontWeight primaryWeight,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    final small = isDesktop ? 11.0 : (isTablet ? 10.0 : 9.0);
    final lines = secondaryLines ??
        (secondary != null && secondary.isNotEmpty ? [secondary] : <String>[]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primary,
          style: TextStyle(
            fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
            fontWeight: primaryWeight,
            color: primaryColor ?? AppColors.textPrimary,
          ),
        ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line,
              style: TextStyle(
                fontSize: small,
                color: secondaryColor ?? AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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
          Tooltip(
            message: 'Usa este id en el CSV (o codigoBarras si el producto lo tiene)',
            child: SelectableText(
              item.id,
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 9.0),
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
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
          _buildStockTableCell(
            primary: inventarioStockDisplay(item),
            secondaryLines: inventarioContenidoEnvaseLines(item),
            isTablet: isTablet,
            isDesktop: isDesktop,
            primaryWeight: FontWeight.w500,
          ),
        ),
        DataCell(
          _buildStockTableCell(
            primary: inventarioMinStockDisplay(item),
            secondary: inventarioUnidadEsPieza(item.unit)
                ? null
                : inventarioEquivMinimoLine(item),
            isTablet: isTablet,
            isDesktop: isDesktop,
            primaryWeight: FontWeight.normal,
            primaryColor: AppColors.textSecondary,
            secondaryColor: AppColors.textSecondary,
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
                          () => _showImportDialog(controller),
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
                          () => _showBulkAdjustmentDialog(controller),
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
                          () => _showPurchaseOrderDialog(controller),
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
                              () => _showImportDialog(controller),
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
                              () => _showBulkAdjustmentDialog(controller),
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
                              () => _showPurchaseOrderDialog(controller),
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

    final qNorm = normalizeForInsensitiveSearch(_searchQuery);
    if (qNorm.isNotEmpty) {
      items = items.where((item) {
        return normalizeForInsensitiveSearch(item.name).contains(qNorm) ||
            normalizeForInsensitiveSearch(item.category).contains(qNorm) ||
            (item.description != null &&
                normalizeForInsensitiveSearch(item.description!).contains(qNorm)) ||
            (item.supplier != null &&
                normalizeForInsensitiveSearch(item.supplier!).contains(qNorm)) ||
            (item.codigoBarras != null &&
                normalizeForInsensitiveSearch(item.codigoBarras!).contains(qNorm));
      }).toList();
    }

    if (_selectedCategory != 'todas') {
      final cat = _selectedCategory.trim().toLowerCase();
      items = items
          .where(
            (item) => item.category.trim().toLowerCase() == cat,
          )
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

  void _showAddInventoryCategoryDialog(
    AdminController controller, {
    void Function(String createdName)? onCreated,
  }) {
    final categoryNameController = TextEditingController();
    final isWide = MediaQuery.sizeOf(context).width > 600;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Agregar categoría',
          style: TextStyle(fontSize: isWide ? 20 : 18),
        ),
        contentPadding: EdgeInsets.all(isWide ? 24 : 16),
        content: SizedBox(
          width: isWide ? 400 : double.infinity,
          child: TextField(
            controller: categoryNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Verduras, Lácteos, etc.',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryNameController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un nombre para la categoría'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final exists = controller.inventoryCategories.any(
                (c) => c.trim().toLowerCase() == categoryName.toLowerCase(),
              );
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La categoría "$categoryName" ya existe'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final catMessenger = ScaffoldMessenger.of(context);
              final catNav = Navigator.of(context);
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await controller.createInventoryCategory(categoryName);
                if (!mounted) return;
                catNav.pop();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                onCreated?.call(categoryName);
                if (!mounted) return;
                catMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Categoría "$categoryName" guardada.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } on StateError catch (e) {
                if (!mounted) return;
                catNav.pop();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (e.message == 'DUPLICATE_INVENTORY_CATEGORY' && mounted) {
                  catMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ya existe una categoría igual o muy similar a "$categoryName".',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                catNav.pop();
                if (!mounted) return;
                catMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${_inventoryWebErrorMessage(e)}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(AdminController controller) {
    final categoryOptions = controller.inventoryCategories
        .where((cat) => cat != 'todos')
        .toList();
    if (categoryOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crea al menos una categoría antes de agregar productos (usa «Crear categoría» o el panel de inventario).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codigoBarrasController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    final maxStockController = TextEditingController();
    final costController = TextEditingController();
    final supplierController = TextEditingController();
    String? selectedCategory = categoryOptions.first;
    String selectedUnit = 'g';
    const inventoryUnitOptions = [
      'kg', 'g', 'L', 'ml',
      'pza', 'Pieza', 'Piezas', 'Unidad', 'Unidades',
    ];
    final contenidoPorPiezaController = TextEditingController();
    String? selectedUnidadContenido;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    String? resolveCategoryField(AdminController c, String? sel) {
      final o = c.inventoryCategories.where((x) => x != 'todos').toList();
      if (o.isEmpty) return null;
      if (sel != null && o.contains(sel)) return sel;
      return o.first;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Agregar al inventario',
            style: TextStyle(fontSize: isWide ? 20 : 18),
          ),
          contentPadding: EdgeInsets.all(isWide ? 24 : 16),
          content: SizedBox(
            width: isWide ? 500 : double.infinity,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (value.trim().length < 2) {
                          return 'Mínimo 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codigoBarrasController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Código de barras (opcional)',
                        border: OutlineInputBorder(),
                        hintText:
                            'Único por línea de producto; para buscar al registrar entradas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: resolveCategoryField(
                        controller,
                        selectedCategory,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.inventoryCategories
                          .where((cat) => cat != 'todos')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          _showAddInventoryCategoryDialog(
                            controller,
                            onCreated: (name) {
                              setDialogState(() => selectedCategory = name);
                            },
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Crear categoría'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unidad *',
                        border: const OutlineInputBorder(),
                        helperText: inventarioUnidadEsPieza(selectedUnit)
                            ? 'Stock en número de envases. Abajo: cuánto trae cada uno (kg, L, piezas…).'
                            : 'Para envases: elige Pieza o pza y define contenido por envase.',
                      ),
                      items: inventoryUnitOptions
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedUnit = value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        return null;
                      },
                    ),
                    if (inventarioUnidadEsPieza(selectedUnit)) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contenido de cada envase (kg, g, L, ml, piezas o unidades)',
                              style: TextStyle(
                                fontSize: isWide ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ej.: 5 kg por bolsa, 2 L por garrafón, o 12 piezas por caja. Así el descuento en recetas cuadra con la unidad del ingrediente.',
                              style: TextStyle(
                                fontSize: isWide ? 12 : 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: contenidoPorPiezaController,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad por envase',
                                      border: OutlineInputBorder(),
                                      hintText: 'Ej: 5 kg, 12 piezas…',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedUnidadContenido,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad',
                                      border: OutlineInputBorder(),
                                      hintText: 'kg, ml, piezas…',
                                    ),
                                    items: inventarioUnidadContenidoOpcionesConActual(
                                            selectedUnidadContenido)
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setDialogState(
                                        () => selectedUnidadContenido = value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stockController,
                      onChanged: (_) => setDialogState(() {}),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: inventarioUnidadEsPieza(selectedUnit)
                            ? 'Stock actual (número de piezas) *'
                            : 'Stock actual *',
                        border: const OutlineInputBorder(),
                        hintText: inventarioUnidadEsPieza(selectedUnit)
                            ? 'Ej: 6 envases = 6'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: minStockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxStockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Stock máximo *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: costController,
                      onChanged: (_) => setDialogState(() {}),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Costo unitario (\$) *',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final stock = double.tryParse(stockController.text.trim()) ?? 0;
                        final costText = costController.text
                            .trim()
                            .replaceAll('\$', '')
                            .replaceAll(' ', '');
                        final cost = double.tryParse(costText) ?? 0;
                        final total = stock * cost;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            'Costo Total: \$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: supplierController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final categoryToSave =
                    resolveCategoryField(controller, selectedCategory);
                if (categoryToSave == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor selecciona una categoría'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final stock = double.parse(stockController.text.trim());
                final minStock = double.parse(minStockController.text.trim());
                final maxStock = double.parse(maxStockController.text.trim());
                final costText = costController.text
                    .trim()
                    .replaceAll('\$', '')
                    .replaceAll(' ', '');
                final cost = double.parse(costText);
                final totalPrice = stock * cost;

                String status;
                if (stock <= 0) {
                  status = InventoryStatus.outOfStock;
                } else if (stock < minStock) {
                  status = InventoryStatus.lowStock;
                } else {
                  status = InventoryStatus.available;
                }

                final codigoBarras = codigoBarrasController.text.trim();
                double? contenidoPorPieza;
                String? unidadContenido;
                if (inventarioUnidadEsPieza(selectedUnit)) {
                  final uCont = selectedUnidadContenido;
                  if (contenidoPorPiezaController.text.trim().isNotEmpty &&
                      uCont != null &&
                      uCont.isNotEmpty) {
                    contenidoPorPieza = double.tryParse(
                      contenidoPorPiezaController.text.trim(),
                    );
                    if (contenidoPorPieza != null && contenidoPorPieza > 0) {
                      unidadContenido = uCont;
                    } else {
                      contenidoPorPieza = null;
                      unidadContenido = null;
                    }
                  } else {
                    contenidoPorPieza = null;
                    unidadContenido = null;
                  }
                } else {
                  contenidoPorPieza = null;
                  unidadContenido = null;
                }
                final newItem = InventoryItem(
                  id: 'temp',
                  name: nameController.text.trim(),
                  codigoBarras:
                      codigoBarras.isEmpty ? null : codigoBarras,
                  category: categoryToSave,
                  currentStock: stock,
                  minStock: minStock,
                  maxStock: maxStock,
                  minimumStock: minStock,
                  unit: selectedUnit,
                  cost: cost,
                  price: totalPrice,
                  unitPrice: cost,
                  supplier: supplierController.text.trim().isEmpty
                      ? null
                      : supplierController.text.trim(),
                  lastRestock: date_utils.AppDateUtils.nowCdmx(),
                  status: status,
                  contenidoPorPieza: contenidoPorPieza,
                  unidadContenido: unidadContenido,
                );

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  await controller.addInventoryItem(newItem);
                  if (!mounted) return;
                  nav.pop();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Producto agregado al inventario exitosamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  nav.pop();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al crear ítem: ${_inventoryWebErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar al inventario'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(InventoryItem item, AdminController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final codigoBarrasController =
        TextEditingController(text: item.codigoBarras ?? '');
    final stockController = TextEditingController(
      text: _formatInvNumber(item.currentStock),
    );
    final minStockController = TextEditingController(
      text: _formatInvNumber(item.minStock),
    );
    final maxStockController = TextEditingController(
      text: _formatInvNumber(item.maxStock),
    );
    final costController = TextEditingController(
      text: item.cost > 0 ? _formatInvNumber(item.cost, maxDecimals: 2) : '',
    );
    final supplierController =
        TextEditingController(text: item.supplier ?? '');
    final contenidoPorPiezaController = TextEditingController(
      text: item.contenidoPorPieza != null && item.contenidoPorPieza! > 0
          ? _formatInvNumber(item.contenidoPorPieza!)
          : '',
    );
    String? selectedUnidadContenido = item.unidadContenido?.trim();
    final unidadEsPieza = inventarioUnidadEsPieza(item.unit);

    List<String> categoryOptions =
        List<String>.from(controller.getInventoryCategories());
    if (categoryOptions.isEmpty) {
      categoryOptions = ['General'];
    }
    if (!categoryOptions.contains(item.category) && item.category.isNotEmpty) {
      categoryOptions = [item.category, ...categoryOptions];
    }
    String selectedCategory = categoryOptions.contains(item.category)
        ? item.category
        : categoryOptions.first;

    final isWide = MediaQuery.sizeOf(context).width > 600;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Editar producto',
                  style: TextStyle(fontSize: isWide ? 20 : 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: isWide ? 24 : 20),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          contentPadding: EdgeInsets.all(isWide ? 24 : 16),
          content: SizedBox(
            width: isWide ? 500 : double.infinity,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (value.trim().length < 2) {
                          return 'Mínimo 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryOptions
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: item.unit,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codigoBarrasController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Código de barras (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: unidadEsPieza
                            ? 'Stock actual (número de piezas) *'
                            : 'Stock actual *',
                        border: const OutlineInputBorder(),
                        hintText: unidadEsPieza ? 'Ej: 6 envases = 6' : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    if (unidadEsPieza) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contenido de cada envase (kg, g, L, ml, piezas o unidades)',
                              style: TextStyle(
                                fontSize: isWide ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ej.: 5 kg por bolsa, 2 L por garrafón, o 12 piezas por caja. Así el descuento en recetas cuadra con la unidad de la receta.',
                              style: TextStyle(
                                fontSize: isWide ? 12 : 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: contenidoPorPiezaController,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad por envase',
                                      border: OutlineInputBorder(),
                                      hintText: 'Ej: 5 kg, 12 piezas…',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedUnidadContenido,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad',
                                      border: OutlineInputBorder(),
                                      hintText: 'kg, ml, piezas…',
                                    ),
                                    items: inventarioUnidadContenidoOpcionesConActual(
                                            selectedUnidadContenido)
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setDialogState(
                                        () => selectedUnidadContenido = value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: minStockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxStockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Stock máximo *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: costController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Costo Unitario (\$)',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Debe ser un número válido mayor o igual a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: supplierController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final stock = double.parse(stockController.text.trim());
                  final minStock = double.parse(minStockController.text.trim());
                  final maxStock = double.parse(maxStockController.text.trim());
                  final costText = costController.text
                      .trim()
                      .replaceAll('\$', '')
                      .replaceAll(' ', '');
                  final cost = costText.isEmpty ? 0.0 : double.parse(costText);
                  final totalPrice = stock * cost;

                  String status;
                  if (stock <= 0) {
                    status = InventoryStatus.outOfStock;
                  } else if (stock < minStock) {
                    status = InventoryStatus.lowStock;
                  } else {
                    status = InventoryStatus.available;
                  }

                  final codigoBarras = codigoBarrasController.text.trim();
                  double? contenidoPorPieza;
                  String? unidadContenido;
                  if (unidadEsPieza) {
                    final uContEdit = selectedUnidadContenido;
                    if (contenidoPorPiezaController.text.trim().isNotEmpty &&
                        uContEdit != null &&
                        uContEdit.isNotEmpty) {
                      contenidoPorPieza = double.tryParse(
                        contenidoPorPiezaController.text.trim(),
                      );
                      if (contenidoPorPieza != null && contenidoPorPieza > 0) {
                        unidadContenido = uContEdit;
                      } else {
                        contenidoPorPieza = null;
                        unidadContenido = null;
                      }
                    } else {
                      contenidoPorPieza = null;
                      unidadContenido = null;
                    }
                  } else {
                    contenidoPorPieza = null;
                    unidadContenido = null;
                  }

                  final newName = nameController.text.trim();
                  final updatedItem = InventoryItem(
                    id: item.id,
                    name: newName,
                    codigoBarras:
                        codigoBarras.isEmpty ? null : codigoBarras,
                    category: selectedCategory,
                    currentStock: stock,
                    minStock: minStock,
                    maxStock: maxStock,
                    minimumStock: minStock,
                    unit: item.unit,
                    cost: cost,
                    price: totalPrice,
                    unitPrice: cost,
                    supplier: supplierController.text.trim().isEmpty
                        ? null
                        : supplierController.text.trim(),
                    lastRestock: date_utils.AppDateUtils.nowCdmx(),
                    expiryDate: item.expiryDate,
                    status: status,
                    notes: item.notes,
                    description: item.description,
                    contenidoPorPieza: contenidoPorPieza,
                    unidadContenido: unidadContenido,
                  );

                  await controller.updateInventoryItem(updatedItem);

                  if (!mounted) return;
                  nav.pop();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Inventario actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  nav.pop();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al actualizar inventario: ${_inventoryWebErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockAdjustmentDialog(
    InventoryItem item,
    AdminController controller,
  ) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    var isDecrease = false;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isDecrease ? 'Disminuir stock' : 'Aumentar stock'),
          contentPadding: EdgeInsets.all(isWide ? 24 : 16),
          content: SizedBox(
            width: isWide ? 400 : double.infinity,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ToggleButtons(
                    isSelected: [!isDecrease, isDecrease],
                    onPressed: (index) {
                      setDialogState(() {
                        isDecrease = index == 1;
                        quantityController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Aumentar'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Disminuir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stock actual: ${inventarioStockDisplay(item)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  for (final line in inventarioContenidoEnvaseLines(item)) ...[
                    const SizedBox(height: 8),
                    Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: isDecrease
                          ? 'Cantidad a disminuir *'
                          : 'Cantidad a aumentar *',
                      border: const OutlineInputBorder(),
                      suffixText: inventarioUnidadSuffixAjuste(item),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obligatorio';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Debe ser un número válido mayor a 0';
                      }
                      final stockActual = item.currentStock < 0
                          ? 0.0
                          : item.currentStock;
                      if (isDecrease && quantity > stockActual) {
                        return 'No puede disminuir más del stock actual';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final quantity = double.parse(quantityController.text);
                  final stockBase =
                      item.currentStock < 0 ? 0.0 : item.currentStock;
                  final newStock = isDecrease
                      ? (stockBase - quantity).clamp(0.0, double.infinity)
                      : stockBase + quantity;

                  String status;
                  if (newStock <= 0) {
                    status = InventoryStatus.outOfStock;
                  } else if (newStock < item.minStock) {
                    status = InventoryStatus.lowStock;
                  } else {
                    status = InventoryStatus.available;
                  }

                  final updatedItem = item.copyWith(
                    currentStock: newStock,
                    price: newStock * item.unitPrice,
                    lastRestock: date_utils.AppDateUtils.nowCdmx(),
                    status: status,
                  );

                  if (!isDecrease) {
                    await controller.restockInventoryItem(item.id, quantity);
                  } else {
                    await controller.updateInventoryItem(updatedItem);
                  }

                  if (!mounted) return;
                  nav.pop();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isDecrease
                            ? 'Stock disminuido exitosamente'
                            : 'Stock aumentado exitosamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  nav.pop();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al ajustar stock: ${_inventoryWebErrorMessage(e)}',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDecrease ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isDecrease ? 'Disminuir' : 'Aumentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    InventoryItem item,
    AdminController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Estás seguro de eliminar "${item.name}" del inventario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final delMessenger = ScaffoldMessenger.of(context);
              final delNav = Navigator.of(context);
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await controller.deleteInventoryItem(item.id);
                if (!mounted) return;
                delNav.pop();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (!mounted) return;
                delMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Producto "${item.name}" eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                delNav.pop();
                if (!mounted) return;
                delMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error al eliminar ítem: ${_inventoryWebErrorMessage(e)}',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(AdminController controller) {
    final rootContext = context;
    final csvController = TextEditingController();
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.upload_file, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Importar ajustes CSV',
                    style: TextStyle(fontSize: isWide ? 20 : 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: isWide ? 520 : double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Primera fila: encabezados. Por fila indica id (columna «ID» de la tabla) '
                      'o codigoBarras (también barcode, ean, sku…). Si vienen ambos, se usa solo id. '
                      'Además, al menos uno de: cantidadActual (o stock), stockMinimo (o minimo), '
                      'stockMaximo (o maximo), costoUnitario (o costo). Números con coma o punto.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await FileDownloadHelper.downloadCSV(
                                buildInventoryImportCsvTemplateContent(),
                                'plantilla-importacion-inventario.csv',
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No se pudo generar el CSV: ${_inventoryWebErrorMessage(e)}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('Plantilla CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes =
                                  await buildInventoryImportTemplatePdfBytes();
                              await FileDownloadHelper.downloadPdf(
                                bytes,
                                'plantilla-importacion-inventario.pdf',
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No se pudo generar el PDF: ${_inventoryWebErrorMessage(e)}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Guía PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['csv', 'txt'],
                          withData: true,
                        );
                        if (result == null || result.files.isEmpty) return;
                        final bytes = result.files.single.bytes;
                        if (bytes == null) {
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo leer el archivo en este dispositivo. Pega el CSV en el cuadro de texto.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          return;
                        }
                        csvController.text = utf8.decode(bytes);
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Elegir archivo (.csv)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: csvController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'O pega aquí el contenido CSV',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final text = csvController.text.trim();
                  if (text.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Agrega un CSV o elige un archivo'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final nav = Navigator.of(rootContext);
                  showDialog<void>(
                    context: rootContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final rows = parseInventoryImportCsv(text);
                    if (rows.isEmpty) {
                      throw Exception('No hay filas de datos después del encabezado');
                    }
                    final r = await controller.importInventoryUpdatesFromCsvRowMaps(rows);
                    if (!mounted) return;
                    nav.pop();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    final errTail = r.errors.length > 3
                        ? ' (${r.errors.length} avisos; revisa la consola si hace falta)'
                        : (r.errors.isEmpty
                            ? ''
                            : ': ${r.errors.take(3).join('; ')}');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Importación: ${r.updated} actualizados, ${r.skipped} omitidos$errTail',
                        ),
                        backgroundColor:
                            r.updated > 0 ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                    if (r.errors.length > 3) {
                      for (final e in r.errors) {
                        debugPrint('[import CSV] $e');
                      }
                    }
                  } catch (e) {
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: ${_inventoryWebErrorMessage(e)}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(AdminController controller) {
    final now = DateTime.now();
    DateTime fechaInicio = DateTime(now.year, now.month, 1);
    DateTime fechaFin = now;
    final exportMessenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
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
                          context: dialogContext,
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
                          context: dialogContext,
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await ReportesService().generarReporteInventarioPDF(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    );
                    if (!mounted) return;
                    exportMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Reporte PDF descargado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    exportMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al descargar PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar PDF'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    await ReportesService().generarReporteInventarioCSV(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    );
                    if (!mounted) return;
                    exportMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Reporte CSV descargado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    exportMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al descargar CSV: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  void _showBulkAdjustmentDialog(AdminController controller) {
    final rootContext = context;
    final qtyController = TextEditingController();
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final messenger = ScaffoldMessenger.of(context);
    var mode = 'add';
    var onlyLowOrOut = true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = _getFilteredItems(controller);
          List<InventoryItem> targets() {
            var list = List<InventoryItem>.from(filtered);
            if (onlyLowOrOut) {
              list = list
                  .where(
                    (i) =>
                        i.currentStock <= i.minStock || i.currentStock <= 0,
                  )
                  .toList();
            }
            return list;
          }

          final n = targets().length;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajuste masivo de stock',
                    style: TextStyle(fontSize: isWide ? 20 : 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: isWide ? 420 : double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Se aplicará a los productos que ves ahora en la tabla '
                      '(filtros y búsqueda actuales): ${filtered.length} ítems.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: onlyLowOrOut,
                      onChanged: (v) {
                        setDialogState(() => onlyLowOrOut = v ?? true);
                      },
                      title: const Text(
                        'Solo productos en mínimo o sin stock',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    Text(
                      'Afectará $n producto${n == 1 ? '' : 's'}.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: n == 0 ? Colors.red : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: mode,
                      decoration: const InputDecoration(
                        labelText: 'Operación',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'add',
                          child: Text('Sumar a la cantidad actual'),
                        ),
                        DropdownMenuItem(
                          value: 'subtract',
                          child: Text('Restar de la cantidad actual'),
                        ),
                        DropdownMenuItem(
                          value: 'set',
                          child: Text('Fijar cantidad exacta'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => mode = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 5 o 2.5',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final list = targets();
                  if (list.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('No hay productos que coincidan con el criterio'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  final q = double.tryParse(qtyController.text.trim());
                  if (q == null || (mode != 'set' && q <= 0)) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Indica una cantidad válida (> 0, salvo «fijar» que puede ser 0)',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  if (mode == 'set' && q < 0) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('La cantidad fijada no puede ser negativa'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final nav = Navigator.of(rootContext);
                  showDialog<void>(
                    context: rootContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    await controller.bulkAdjustInventoryStockForItems(
                      list,
                      mode: mode,
                      quantity: q,
                    );
                    if (!mounted) return;
                    nav.pop();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ajuste aplicado a ${list.length} producto${list.length == 1 ? '' : 's'}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${_inventoryWebErrorMessage(e)}',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPurchaseOrderDialog(AdminController controller) {
    final rootMessenger = ScaffoldMessenger.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final need = controller.inventoryItems
        .where((i) => i.currentStock < i.minStock)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final buf = StringBuffer()
      ..writeln('Pedido sugerido — stock bajo mínimo')
      ..writeln(
        'Generado: ${DateTime.now().toLocal().toString().split('.').first}',
      )
      ..writeln('')
      ..writeln('Producto\tUnidad\tActual\tMínimo\tSugerido comprar');

    for (final i in need) {
      final gap = i.minStock - i.currentStock;
      final sug = gap <= 0 ? 0.0 : gap;
      buf.writeln(
        '${i.name}\t${i.unit}\t${i.currentStock}\t${i.minStock}\t${sug.toStringAsFixed(2)}',
      );
    }

    final text = buf.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pedido de compra (sugerido)',
                style: TextStyle(fontSize: isWide ? 20 : 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isWide ? 480 : double.maxFinite,
          child: need.isEmpty
              ? const Text(
                  'No hay productos por debajo del stock mínimo en este momento.',
                  style: TextStyle(fontSize: 14),
                )
              : SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          if (need.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!mounted) return;
                rootMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Texto copiado al portapapeles'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Share.share(
                  text,
                  subject: 'Pedido inventario Comandix',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Compartir'),
            ),
          ],
        ],
      ),
    );
  }
}
