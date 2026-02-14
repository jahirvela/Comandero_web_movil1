import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';
import 'alert_to_kitchen_modal.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  String selectedFilter = 'Todos';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filters = [
    'Todos',
    'Pendientes',
    'En preparación',
    'Listos',
    'Entregados',
    'Cancelados',
  ];

  // Datos mock del historial de pedidos
  final List<Map<String, dynamic>> orderHistory = [
    {
      'id': 'ORD-034',
      'tableNumber': 'Mesa 1',
      'items': ['3x Taco Barbacoa', '1x Agua Horchata'],
      'status': 'Listo',
      'time': '14:20',
      'date': '2024-01-15',
      'total': 84.0,
      'customerName': 'Juan Pérez',
      'notes': 'Sin cebolla',
    },
    {
      'id': 'ORD-029',
      'tableNumber': 'Mesa 3',
      'items': ['1x Mix Barbacoa', '2x Agua Jamaica'],
      'status': 'En preparación',
      'time': '13:45',
      'date': '2024-01-15',
      'total': 131.0,
      'customerName': 'María García',
      'notes': '',
    },
    {
      'id': 'ORD-025',
      'tableNumber': 'Mesa 2',
      'items': ['2x Quesadilla Barbacoa', '1x Consomé de Res'],
      'status': 'Entregado',
      'time': '13:15',
      'date': '2024-01-15',
      'total': 95.0,
      'customerName': 'Carlos López',
      'notes': 'Extra picante',
    },
    {
      'id': 'ORD-020',
      'tableNumber': 'Mesa 4',
      'items': ['1x Costilla en Salsa', '1x Cerveza Nacional'],
      'status': 'Cancelado',
      'time': '12:30',
      'date': '2024-01-15',
      'total': 155.0,
      'customerName': 'Ana Martínez',
      'notes': 'Cliente se retiró',
    },
    {
      'id': 'ORD-018',
      'tableNumber': 'Mesa 1',
      'items': ['4x Taco de Maciza', '2x Agua Horchata'],
      'status': 'Entregado',
      'time': '12:00',
      'date': '2024-01-15',
      'total': 136.0,
      'customerName': 'Roberto Silva',
      'notes': '',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredOrders {
    List<Map<String, dynamic>> orders = orderHistory;

    // Filtrar por estado
    if (selectedFilter != 'Todos') {
      orders = orders
          .where((order) => order['status'] == selectedFilter)
          .toList();
    }

    // Filtrar por búsqueda solo cuando hay texto
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      orders = orders.where((order) {
        return order['id'].toLowerCase().contains(q.toLowerCase()) ||
            order['tableNumber'].toLowerCase().contains(q.toLowerCase()) ||
            order['customerName'].toLowerCase().contains(q.toLowerCase());
      }).toList();
    }

    return orders;
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de búsqueda
                      _buildSearchBar(isTablet),
                      const SizedBox(height: 16),

                      // Filtros
                      _buildFilters(isTablet),
                      const SizedBox(height: 24),

                      // Lista de pedidos
                      _buildOrdersList(isTablet),
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
                  context.read<MeseroController>().setCurrentView('floor');
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
                      'Historial de Pedidos',
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

              // Botón de estadísticas
              IconButton(
                onPressed: () {
                  _showStatisticsDialog(context);
                },
                icon: const Icon(Icons.analytics, color: Colors.white),
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
          hintText: "Buscar por orden, mesa o cliente",
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

  Widget _buildFilters(bool isTablet) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
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

  Widget _buildOrdersList(bool isTablet) {
    final orders = filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyState(isTablet, sourceEmpty: orderHistory.isEmpty);
    }

    return Column(
      children: orders
          .map((order) => _buildOrderCard(order, isTablet))
          .toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isTablet) {
    final statusColor = _getStatusColor(order['status']);
    final statusIcon = _getStatusIcon(order['status']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la orden
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['id'],
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order['tableNumber'],
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusIcon,
                          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order['status'],
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del cliente
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order['customerName'],
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order['time'],
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 12.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items del pedido
              Text(
                'Items:',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order['items'].join(', '),
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (order['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
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
                    'Nota: ${order['notes']}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Total y acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${order['total'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      if (order['status'] == 'En preparación' ||
                          order['status'] == 'Listo') ...[
                        IconButton(
                          onPressed: () {
                            _showAlertToKitchenModal(order);
                          },
                          icon: const Icon(Icons.warning_amber_rounded),
                          color: AppColors.warning,
                          iconSize: isTablet ? 20.0 : 18.0,
                        ),
                      ],
                      IconButton(
                        onPressed: () {
                          _showOrderDetails(order);
                        },
                        icon: const Icon(Icons.visibility),
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

  Widget _buildEmptyState(bool isTablet, {bool sourceEmpty = false}) {
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
            Icons.restaurant_menu,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            sourceEmpty
                ? 'No hay pedidos'
                : 'Sin coincidencias para la búsqueda',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            sourceEmpty
                ? 'Los pedidos aparecerán aquí'
                : 'Intenta cambiar los filtros o la búsqueda',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return AppColors.warning;
      case 'En preparación':
        return AppColors.info;
      case 'Listo':
        return AppColors.success;
      case 'Entregado':
        return Colors.grey;
      case 'Cancelado':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente':
        return '⏳';
      case 'En preparación':
        return '👨‍🍳';
      case 'Listo':
        return '✅';
      case 'Entregado':
        return '📦';
      case 'Cancelado':
        return '❌';
      default:
        return '❓';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mesa: ${order['tableNumber']}'),
              Text('Cliente: ${order['customerName']}'),
              Text('Hora: ${order['time']}'),
              Text('Estado: ${order['status']}'),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order['items'].map<Widget>((item) => Text('• $item')),
              if (order['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nota: ${order['notes']}'),
              ],
              const SizedBox(height: 16),
              Text('Total: \$${order['total'].toStringAsFixed(2)}'),
            ],
          ),
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

  void _showAlertToKitchenModal(Map<String, dynamic> order) {
    // Extraer información de la orden
    final orderId = order['id']?.toString() ?? 'ORD-UNKNOWN';
    final tableNumber =
        order['tableNumber']?.toString() ??
        order['mesaId']?.toString() ??
        order['mesa']?.toString() ??
        'N/A';

    // Usar el modal completo de alertas
    showAlertToKitchenModal(
      context,
      tableNumber: tableNumber,
      orderId: orderId,
    );
  }

  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas del día'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total de pedidos: 5'),
            Text('Pedidos entregados: 2'),
            Text('Pedidos en preparación: 1'),
            Text('Pedidos listos: 1'),
            Text('Pedidos cancelados: 1'),
            SizedBox(height: 16),
            Text('Ventas totales: \$601.00'),
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
