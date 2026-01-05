import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';
import 'alert_to_kitchen_modal.dart';

/// Vista para gestionar órdenes "Para Llevar"
class TakeawayView extends StatefulWidget {
  const TakeawayView({super.key});

  @override
  State<TakeawayView> createState() => _TakeawayViewState();
}

class _TakeawayViewState extends State<TakeawayView> {
  @override
  void initState() {
    super.initState();
    // El historial ya se carga en el controlador al inicializar
    // Solo refrescamos si es necesario (el controller ya filtra órdenes enviadas)
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, controller, isTablet),
                    const SizedBox(height: 16),
                    _buildNewOrderButton(context, controller, isTablet),
                    const SizedBox(height: 24),
                    _buildOrderHistorySection(context, controller, isTablet),
                  ],
                ),
              ),
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
    return Row(
      children: [
        IconButton(
          onPressed: () => controller.setCurrentView('floor'),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.shopping_bag,
          size: isTablet ? 28.0 : 24.0,
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pedidos Para Llevar',
            style: TextStyle(
              fontSize: isTablet ? 22.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            // Forzar recarga completa del historial
            await controller.loadTakeawayOrderHistory();
            // Forzar actualización de la UI
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.refresh),
          color: AppColors.info,
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildNewOrderButton(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showNewTakeawayOrderDialog(context, controller),
        icon: const Icon(Icons.add),
        label: Text(
          'Nuevo Pedido Para Llevar',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    // Usar Consumer para que se actualice cuando cambie el historial o los estados
    return Consumer<MeseroController>(
      builder: (context, ctrl, child) {
        final takeawayOrders = ctrl.getTakeawayOrderHistory();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.info, size: isTablet ? 20.0 : 18.0),
                const SizedBox(width: 8),
                Text(
                  'Pedidos Pendientes',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (takeawayOrders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${takeawayOrders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (takeawayOrders.isEmpty)
              _buildEmptyState(isTablet)
            else
              ...takeawayOrders.map((order) => _buildOrderCard(context, order, ctrl, isTablet)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: isTablet ? 48.0 : 40.0,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos para llevar',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón de arriba para crear uno',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    MeseroController controller,
    bool isTablet,
  ) {
    final rawStatus = order['status'] as String? ?? '';
    final statusColor = _getStatusColor(rawStatus);
    final statusText = _getStatusText(rawStatus);
    final customerName = order['customerName'] as String? ?? 'Cliente';
    final customerPhone = order['customerPhone'] as String? ?? '';
    final items = order['items'] as List<dynamic>? ?? [];
    final orderId = order['id'] as String? ?? 'ORD-???';
    final time = order['time'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ID y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Información del cliente
            Row(
              children: [
                Icon(Icons.person, size: isTablet ? 18.0 : 16.0, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.phone, size: isTablet ? 16.0 : 14.0, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    customerPhone,
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            // Items/Productos
            if (items.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.restaurant_menu, size: isTablet ? 16.0 : 14.0, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items.take(3).map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.toString(),
                            style: TextStyle(
                              fontSize: isTablet ? 13.0 : 11.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList()..addAll([
                        if (items.length > 3)
                          Text(
                            '... y ${items.length - 3} más',
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 10.0,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Hora
            Row(
              children: [
                Icon(Icons.access_time, size: isTablet ? 14.0 : 12.0, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            // Botones de acción
            if (_canShowActions(rawStatus)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón de Enviar Alerta
                  ElevatedButton.icon(
                    onPressed: () => _showAlertModalForOrder(context, order),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: Text(
                      'Enviar alerta',
                      style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16.0 : 12.0,
                        vertical: isTablet ? 10.0 : 8.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón de Cerrar Cuenta
                  ElevatedButton.icon(
                    onPressed: () => _showCloseAccountDialog(context, order, controller, isTablet),
                    icon: Icon(Icons.attach_money, size: isTablet ? 18.0 : 16.0),
                    label: Text(
                      'Cerrar Cuenta',
                      style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16.0 : 12.0,
                        vertical: isTablet ? 10.0 : 8.0,
                      ),
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

  bool _canShowActions(String status) {
    final statusLower = status.toLowerCase();
    return !statusLower.contains('pagada') &&
           !statusLower.contains('cancelada') &&
           !statusLower.contains('cerrada') &&
           !statusLower.contains('cobrada');
  }

  void _showAlertModalForOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final orderId = order['id'] as String? ?? 'ORD-???';
    // Para órdenes para llevar, usamos "Para Llevar" como tableNumber
    // El backend manejará tableId como null automáticamente
    final tableNumber = 'Para Llevar';
    
    showAlertToKitchenModal(
      context,
      tableNumber: tableNumber,
      orderId: orderId,
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('listo') || statusLower.contains('recoger')) {
      return AppColors.success;
    } else if (statusLower.contains('preparacion') || statusLower.contains('preparando')) {
      return AppColors.info;
    } else if (statusLower.contains('pagada') || statusLower.contains('cobrada')) {
      return Colors.grey;
    } else if (statusLower.contains('cancelada')) {
      return AppColors.error;
    }
    return AppColors.warning; // Pendiente
  }

  // Convertir estado del backend a texto legible
  String _getStatusText(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('listo') || statusLower.contains('recoger')) {
      return 'Listo para recoger';
    } else if (statusLower.contains('preparacion') || statusLower.contains('preparando')) {
      return 'En preparación';
    } else if (statusLower.contains('pagada') || statusLower.contains('cobrada')) {
      return 'Pagada';
    } else if (statusLower.contains('cancelada')) {
      return 'Cancelada';
    } else if (statusLower.contains('abierta') || statusLower.contains('pendiente')) {
      return 'Pendiente';
    }
    return 'En espera';
  }

  void _showNewTakeawayOrderDialog(BuildContext context, MeseroController controller) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.shopping_bag, color: AppColors.warning),
              const SizedBox(width: 12),
              const Expanded(child: Text('Nuevo Pedido')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente *',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: 'Ej: 555-123-4567',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa el nombre del cliente'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Guardar datos del cliente y abrir menú
                controller.setTakeawayCustomerInfo(
                  name,
                  phoneController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
                controller.setCurrentView('menu');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir al Menú'),
            ),
          ],
        );
      },
    );
  }

  void _showCloseAccountDialog(
    BuildContext context,
    Map<String, dynamic> order,
    MeseroController controller,
    bool isTablet,
  ) async {
    final ordenId = order['ordenId'] as int?;
    final customerName = order['customerName'] as String? ?? 'Cliente';
    final customerPhone = order['customerPhone'] as String? ?? '';

    if (ordenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el ID de la orden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar indicador de carga mientras se obtienen los detalles
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // IMPORTANTE: Obtener TODAS las órdenes activas del mismo cliente
    // Esto permite mostrar todas las órdenes que se cobrarán juntas
    double totalConsumo = 0.0;
    final allItems = <Map<String, dynamic>>[];
    final allOrderIds = <int>[];

    try {
      // Obtener todas las órdenes del historial del mismo cliente
      final takeawayHistory = controller.getTakeawayOrderHistory();
      final ordenesDelCliente = takeawayHistory.where((o) {
        final orderCustomerName = o['customerName'] as String? ?? '';
        final orderCustomerPhone = o['customerPhone'] as String? ?? '';
        
        final nombreCoincide = (customerName.toLowerCase().trim()) ==
            (orderCustomerName.toLowerCase().trim());
        final telefonoCoincide = (customerPhone.trim()) ==
            (orderCustomerPhone.trim());
        
        final esMismoCliente = nombreCoincide && 
            (telefonoCoincide || (customerPhone.isEmpty && orderCustomerPhone.isEmpty));

        if (!esMismoCliente) return false;

        // Excluir órdenes ya pagadas/cerradas
        final status = (o['status'] as String?)?.toLowerCase() ?? '';
        final esExcluida =
            status.contains('pagada') ||
            status.contains('cancelada') ||
            status.contains('cerrada') ||
            status.contains('enviada') ||
            status.contains('cobrada');
        return !esExcluida;
      }).toList();

      // Obtener detalles de todas las órdenes del cliente
      for (var orderData in ordenesDelCliente) {
        final ordenIdActual = orderData['ordenId'] as int?;
        if (ordenIdActual != null) {
          allOrderIds.add(ordenIdActual);
          final ordenDetalle = await controller.getOrdenDetalle(ordenIdActual);
          if (ordenDetalle != null) {
            final items = ordenDetalle['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
              final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
              
              // CRÍTICO: Calcular totalLinea siempre como cantidad × precioUnitario
              // Si totalLinea viene del backend como 0 o incorrecto, recalcular
              final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
              final totalLineaCalculado = precioUnitario * cantidad;
              
              // Usar el cálculo si el backend viene con 0 o si el calculado es diferente (tolerancia de 0.01)
              final totalLinea = (totalLineaBackend <= 0.01 || (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
                  ? totalLineaCalculado
                  : totalLineaBackend;
              
              totalConsumo += totalLinea;
              
              allItems.add({
                'nombre': item['productoNombre'] as String? ?? 'Producto',
                'cantidad': cantidad,
                'precioUnitario': precioUnitario,
                'subtotal': totalLinea, // Asegurar que siempre tenga el valor calculado correctamente
                'extras': item['modificadores'] as List<dynamic>? ?? [],
                'nota': item['nota'] as String?,
                'ordenId': ordenIdActual, // Para identificar de qué orden viene cada item
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error al obtener detalles de órdenes: $e');
    }

    // Cerrar indicador de carga
    if (context.mounted) Navigator.of(context).pop();

    final total = totalConsumo;
    final tieneMultiplesOrdenes = allOrderIds.length > 1;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color: AppColors.warning,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tieneMultiplesOrdenes
                                ? 'Cerrar cuenta — Para Llevar (${allOrderIds.length} órdenes)'
                                : 'Cerrar cuenta — Para Llevar',
                            style: TextStyle(
                              fontSize: isTablet ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (tieneMultiplesOrdenes)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Órdenes: ${allOrderIds.map((id) => 'ORD-$id').join(', ')}',
                                style: TextStyle(
                                  fontSize: isTablet ? 12.0 : 10.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (customerPhone.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  customerPhone,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14.0 : 12.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Contenido - tabla de productos
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: Column(
                    children: [
                      if (allItems.isNotEmpty) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: isTablet ? 16.0 : 12.0,
                              headingRowColor: WidgetStateProperty.all(
                                AppColors.secondary.withValues(alpha: 0.3),
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Cant.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Producto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Costo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 13.0 : 11.0,
                                    ),
                                  ),
                                ),
                              ],
                              rows: allItems.map((item) {
                                final quantity = item['cantidad'] as int? ?? 1;
                                final nombre = item['nombre'] as String? ?? 'Producto';
                                final unitPrice = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                                
                                // CRÍTICO: Recalcular subtotal siempre como cantidad × precioUnitario
                                // Si el subtotal viene como 0 o incorrecto, usar el cálculo
                                final subtotalBackend = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                                final subtotalCalculado = unitPrice * quantity;
                                
                                // Usar el cálculo si el backend viene con 0 o si hay diferencia significativa
                                final subtotal = (subtotalBackend <= 0.01 || (subtotalCalculado - subtotalBackend).abs() > 0.01)
                                    ? subtotalCalculado
                                    : subtotalBackend;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        '$quantity',
                                        style: TextStyle(fontSize: isTablet ? 13.0 : 11.0),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        nombre,
                                        style: TextStyle(fontSize: isTablet ? 13.0 : 11.0),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${unitPrice.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: isTablet ? 13.0 : 11.0),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${subtotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 13.0 : 11.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
                              child: Text(
                                'No hay productos registrados para esta orden',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Total
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a pagar:',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 22.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mensaje informativo
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: isTablet ? 20.0 : 18.0,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tieneMultiplesOrdenes
                                    ? 'Se cobrarán ${allOrderIds.length} órdenes juntas. Al enviar la cuenta, llegará al Cajero para su cobro.'
                                    : 'Al enviar la cuenta, llegará al Cajero para su cobro.',
                                style: TextStyle(
                                  fontSize: isTablet ? 14.0 : 12.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.border),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16.0 : 14.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close),
                            const SizedBox(width: 8),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Mostrar indicador de carga
                            showDialog(
                              context: dialogContext,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            await controller.sendTakeawayToCashier(ordenId);
                            
                            // Cerrar diálogo de carga
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            
                            // Cerrar diálogo de confirmación
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            
                            // Forzar recarga completa del historial y actualización de la UI
                            await controller.loadTakeawayOrderHistory();
                            if (mounted) setState(() {});
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Cuenta de $customerName enviada al Cajero',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            // Cerrar diálogo de carga
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            
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
                        },
                        icon: const Icon(Icons.send),
                        label: Text(
                          'Enviar al Cajero',
                          style: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16.0 : 14.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
