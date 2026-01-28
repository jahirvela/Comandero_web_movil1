import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../utils/app_colors.dart';
import '../../models/table_model.dart';
import '../../models/payment_model.dart';
import '../../services/comandas_service.dart';
import 'alert_to_kitchen_modal.dart';

/// Vista especial para manejar cuenta dividida por persona
/// Permite agregar personas y tomar pedidos por persona separadamente
class DividedAccountView extends StatefulWidget {
  const DividedAccountView({super.key});

  @override
  State<DividedAccountView> createState() => _DividedAccountViewState();
}

class _DividedAccountViewState extends State<DividedAccountView> {
  String? _selectedPersonId;

  @override
  void initState() {
    super.initState();
    // Al iniciar, crear primera persona si no existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MeseroController>();
      if (controller.isDividedAccountMode && controller.personNames.isEmpty) {
        final firstPersonId = controller.addPerson();
        controller.setSelectedPersonId(firstPersonId);
        setState(() {
          _selectedPersonId = firstPersonId;
        });
      } else if (controller.personNames.isNotEmpty) {
        final firstPersonId = controller.personNames.keys.first;
        controller.setSelectedPersonId(firstPersonId);
        setState(() {
          _selectedPersonId = firstPersonId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final table = controller.selectedTable;
        final persons = controller.personNames;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(
              table != null ? 'Cuenta Dividida — Mesa ${table.number}' : 'Cuenta Dividida',
              style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Regresar al panel principal de mesas (floor view)
                controller.setCurrentView('floor');
              },
            ),
          ),
          body: persons.isEmpty
              ? _buildEmptyState(context, controller, isTablet)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;
                    final isWide = constraints.maxWidth > 1200;
                    
                    // En móvil, usar layout vertical
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          // Panel de personas (colapsable o en tabs)
                          _buildPersonListMobile(context, controller, persons, isTablet),
                          // Contenido principal
                          Expanded(
                            child: _selectedPersonId == null
                                ? _buildNoPersonSelected(isTablet)
                                : _buildPersonOrderView(
                                    context,
                                    controller,
                                    _selectedPersonId!,
                                    isTablet,
                                  ),
                          ),
                        ],
                      );
                    }
                    
                    // En tablet/desktop, usar layout horizontal
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Panel lateral: Lista de personas
                        Container(
                          width: isWide ? 320 : (isDesktop ? 280 : 250),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            border: Border(
                              right: BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildPersonListSidebar(
                            context,
                            controller,
                            persons,
                            isTablet,
                          ),
                        ),
                        // Panel principal: Pedido de la persona seleccionada
                        Expanded(
                          child: _selectedPersonId == null
                              ? _buildNoPersonSelected(isTablet)
                              : _buildPersonOrderView(
                                  context,
                                  controller,
                                  _selectedPersonId!,
                                  isTablet,
                                ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: isTablet ? 80.0 : 64.0,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Cuenta Dividida',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega personas para dividir la cuenta',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddPersonDialog(context, controller, isTablet),
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Primera Persona'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.0 : 24.0,
                  vertical: isTablet ? 16.0 : 12.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPersonSelected(bool isTablet) {
    return Center(
      child: Text(
        'Selecciona una persona para ver su pedido',
        style: TextStyle(
          fontSize: isTablet ? 18.0 : 16.0,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPersonOrderView(
    BuildContext context,
    MeseroController controller,
    String personId,
    bool isTablet,
  ) {
    final personName = controller.personNames[personId] ?? 'Persona';
    final personItems = controller.getItemsForPerson(personId);
    final total = personItems.fold<double>(
      0.0,
      (sum, item) {
        final qty = (item.customizations['quantity'] as num?)?.toDouble() ?? 1.0;
        double itemTotal = _getUnitPrice(item) * qty;
        final extraPrices = item.customizations['extraPrices'] as List<dynamic>? ?? [];
        for (var priceEntry in extraPrices) {
          if (priceEntry is Map) {
            final precio = (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
            itemTotal += precio * qty;
          }
        }
        final saucePrice = (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
        if (saucePrice > 0) {
          itemTotal += saucePrice * qty;
        }
        return sum + itemTotal;
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isWide = constraints.maxWidth > 1200;
        
        // En pantallas grandes, mostrar dos columnas (pedido actual | historial)
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda: Pedido actual de la persona
              Expanded(
                flex: 1,
                child: _buildPersonOrderColumn(
                  context,
                  controller,
                  personId,
                  personName,
                  personItems,
                  total,
                  isTablet,
                ),
              ),
              const SizedBox(width: 16),
              // Columna derecha: Historial de pedidos de esta persona
              Expanded(
                flex: 1,
                child: _buildPersonHistoryColumn(
                  context,
                  controller,
                  personId,
                  personName,
                  isTablet,
                ),
              ),
            ],
          );
        }
        
        // En pantallas medianas/pequeñas, usar tabs o scroll vertical
        return SingleChildScrollView(
          child: _buildPersonOrderColumn(
            context,
            controller,
            personId,
            personName,
            personItems,
            total,
            isTablet,
          ),
        );
      },
    );
  }

  Widget _buildPersonOrderColumn(
    BuildContext context,
    MeseroController controller,
    String personId,
    String personName,
    List<dynamic> personItems,
    double total,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Header de la persona
        Container(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.primary,
                size: isTablet ? 24.0 : 20.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${personItems.length} ${personItems.length == 1 ? 'producto' : 'productos'} • Total: \$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.setCurrentView('menu');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Productos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12.0 : 8.0,
                      vertical: isTablet ? 12.0 : 10.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de productos de la persona
        if (personItems.isNotEmpty)
          ...personItems.map((item) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20.0 : 16.0,
                  vertical: isTablet ? 8.0 : 6.0,
                ),
                child: _buildPersonCartItem(
                  context,
                  controller,
                  item,
                  personId,
                  isTablet,
                ),
              )),
        if (personItems.isEmpty)
          _buildEmptyPersonCart(personName, isTablet),
        // Footer con acciones
        if (personItems.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 20.0 : 18.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendPersonOrderToKitchen(
                      context,
                      controller,
                      personId,
                      isTablet,
                    ),
                    icon: const Icon(Icons.send),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Enviar Pedido de $personName a Cocina'),
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
        // Botón de cerrar cuenta (solo si hay historial y no está cerrada)
        if (_hasPersonHistory(controller, personId) && !_isPersonAccountClosed(controller, personId))
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCloseAccountForPerson(
                  context,
                  controller,
                  personId,
                  personName,
                  isTablet,
                ),
                icon: const Icon(Icons.receipt_long),
                label: Text('Cerrar Cuenta de $personName'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 14.0 : 12.0,
                  ),
                ),
              ),
            ),
          ),
        // Indicador de cuenta cerrada
        if (_isPersonAccountClosed(controller, personId))
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cuenta de $personName cerrada',
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPersonHistoryColumn(
    BuildContext context,
    MeseroController controller,
    String personId,
    String personName,
    bool isTablet,
  ) {
    final table = controller.selectedTable;
    if (table == null) return const SizedBox.shrink();
    
    // Obtener historial de órdenes de esta persona específica
    final allHistory = controller.getTableOrderHistory(table.id);
    final personHistory = allHistory.where((order) {
      // Verificar si esta orden pertenece a esta persona
      if (order['isDividedAccount'] == true && order['personAssignments'] != null) {
        final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
        return personAssignments?.containsKey(personId) == true;
      }
      return false;
    }).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del historial
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppColors.info,
                  size: isTablet ? 20.0 : 18.0,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial — $personName',
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${personHistory.length} ${personHistory.length == 1 ? 'pedido' : 'pedidos'}',
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 10.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de pedidos
          Expanded(
            child: personHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 40.0 : 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: isTablet ? 48.0 : 40.0,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay pedidos enviados',
                            style: TextStyle(
                              fontSize: isTablet ? 14.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                    itemCount: personHistory.length,
                    itemBuilder: (context, index) {
                      final order = personHistory[index];
                      return _buildPersonHistoryItem(
                        context,
                        controller,
                        order,
                        personName,
                        isTablet,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonHistoryItem(
    BuildContext context,
    MeseroController controller,
    Map<String, dynamic> order,
    String personName,
    bool isTablet,
  ) {
    final statusColor = _getOrderStatusColor(order['status'] ?? '');
    final orderId = order['id'] ?? 'ORD';
    final items = order['items'] as List<dynamic>? ?? [];
    final time = order['time'] ?? '';
    final ordenId = order['ordenId'] as int?;
    
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12.0 : 8.0),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Pedido de $personName',
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 10.0,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 10.0 : 8.0,
                    vertical: isTablet ? 6.0 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order['status'] ?? 'Pendiente',
                    style: TextStyle(
                      fontSize: isTablet ? 11.0 : 9.0,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              items.join(', '),
              style: TextStyle(
                fontSize: isTablet ? 13.0 : 11.0,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                ),
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
            if (ordenId != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _reimprimirComanda(context, ordenId, isTablet),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: Text(
                      'Reimprimir',
                      style: TextStyle(fontSize: isTablet ? 11.0 : 9.0),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12.0 : 8.0,
                        vertical: isTablet ? 8.0 : 6.0,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAlertModalForOrder(
                      context,
                      controller.selectedTable!,
                      order,
                      personName,
                    ),
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: Text(
                      'Alerta',
                      style: TextStyle(fontSize: isTablet ? 11.0 : 9.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12.0 : 8.0,
                        vertical: isTablet ? 8.0 : 6.0,
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

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cocina':
      case 'pendiente':
        return AppColors.warning;
      case 'en preparación':
        return AppColors.info;
      case 'listo':
        return AppColors.success;
      case 'entregado':
        return Colors.grey;
      case 'cancelado':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyPersonCart(String personName, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isTablet ? 64.0 : 48.0,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos para $personName',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MeseroController>().setCurrentView('menu');
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Productos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCartItem(
    BuildContext context,
    MeseroController controller,
    dynamic item,
    String personId,
    bool isTablet,
  ) {
    final quantity = (item.customizations['quantity'] as num?)?.toInt() ?? 1;
    final unitPrice = _getUnitPrice(item);
    final itemTotal = unitPrice * quantity;

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12.0 : 8.0),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad: $quantity',
                    style: TextStyle(
                      fontSize: isTablet ? 13.0 : 11.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.customizations['size'] != null)
                    Text(
                      'Tamaño: ${item.customizations['size']}',
                      style: TextStyle(
                        fontSize: isTablet ? 13.0 : 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (item.customizations['sauce'] != null)
                    Text(
                      'Salsa: ${item.customizations['sauce']}',
                      style: TextStyle(
                        fontSize: isTablet ? 13.0 : 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Precio y botón eliminar
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${itemTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: isTablet ? 24.0 : 20.0,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  onPressed: () {
                    controller.removeFromCart(item.id);
                    // Si se eliminó el último item, actualizar la vista
                    final remainingItems = controller.getItemsForPerson(personId);
                    if (remainingItems.isEmpty && mounted) {
                      setState(() {
                        // Mantener selección pero mostrar estado vacío
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getUnitPrice(dynamic item) {
    final customPrice = item.customizations['sizePrice'] ??
        item.customizations['unitPrice'];
    if (customPrice is num) {
      return customPrice.toDouble();
    }
    double basePrice = item.product.price;
    final extraPrices = item.customizations['extraPrices'] as List<dynamic>? ?? [];
    for (var priceEntry in extraPrices) {
      if (priceEntry is Map) {
        basePrice += (priceEntry['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    final saucePrice = (item.customizations['saucePrice'] as num?)?.toDouble() ?? 0.0;
    if (saucePrice > 0) {
      basePrice += saucePrice;
    }
    return basePrice;
  }

  void _showAddPersonDialog(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Agregar Persona',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nombre de la persona',
            hintText: 'Ej: Juan, María, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final personId = controller.addPerson(name: name);
                controller.setSelectedPersonId(personId);
                Navigator.of(dialogContext).pop();
                setState(() {
                  _selectedPersonId = personId;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showRenamePersonDialog(
    BuildContext context,
    MeseroController controller,
    String personId,
    String currentName,
    bool isTablet,
  ) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Renombrar Persona',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                controller.renamePerson(personId, name);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeletePersonDialog(
    BuildContext context,
    MeseroController controller,
    String personId,
    String personName,
    bool isTablet,
  ) {
    final personItems = controller.getItemsForPerson(personId);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Eliminar Persona',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: Text(
          personItems.isNotEmpty
              ? '$personName tiene ${personItems.length} ${personItems.length == 1 ? 'producto' : 'productos'} asignados. No se puede eliminar.'
              : '¿Eliminar a $personName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          if (personItems.isEmpty)
            ElevatedButton(
              onPressed: () {
                controller.removePerson(personId);
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  final remainingPersons = controller.personNames;
                  if (remainingPersons.isEmpty) {
                    controller.setCurrentView('table');
                  } else {
                    setState(() {
                      _selectedPersonId = remainingPersons.keys.first;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
        ],
      ),
    );
  }

  Future<void> _sendPersonOrderToKitchen(
    BuildContext context,
    MeseroController controller,
    String personId,
    bool isTablet,
  ) async {
    final personItems = controller.getItemsForPerson(personId);
    if (personItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay productos para enviar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final personName = controller.personNames[personId] ?? 'Persona';

    // Confirmar envío
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Enviar Pedido a Cocina',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: Text(
          '¿Enviar el pedido de $personName (${personItems.length} ${personItems.length == 1 ? 'producto' : 'productos'}) a cocina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Copiar los IDs de items antes de enviar (para evitar problemas con la lista modificada)
      final itemIds = personItems.map((item) => item.id).toList();
      
      // Enviar solo los items de esta persona específica con el nombre de la persona
      // NOTA: El controller NO debe limpiar el carrito automáticamente para cuenta dividida
      await controller.sendOrderToKitchen(
        specificItems: personItems,
        personId: personId,
        customerName: personName, // Pasar nombre de la persona como customerName para que aparezca en cocina
      );
      
      // Los items ya fueron removidos por el controller en sendOrderToKitchen
      // No es necesario removerlos aquí de nuevo
      
      // Actualizar la UI para reflejar los cambios
      if (mounted) {
        setState(() {
          // Forzar rebuild del estado
        });
      }

      // NO regresar a TableView, quedarse en DividedAccountView
      // El usuario puede seguir pidiendo para esta u otra persona

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido de $personName enviado a cocina',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar pedido: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildPersonListSidebar(
    BuildContext context,
    MeseroController controller,
    Map<String, String> persons,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Header del panel
        Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.info,
                size: isTablet ? 20.0 : 18.0,
              ),
              const SizedBox(width: 8),
              Text(
                'Personas (${persons.length})',
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Lista de personas
        Expanded(
          child: ListView.builder(
            itemCount: persons.length,
            itemBuilder: (context, index) {
              final personId = persons.keys.elementAt(index);
              final personName = persons[personId]!;
              final personItems = controller.getItemsForPerson(personId);
              final isSelected = _selectedPersonId == personId;

              return InkWell(
                onTap: () {
                  controller.setSelectedPersonId(personId);
                  setState(() {
                    _selectedPersonId = personId;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    personName,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16.0 : 14.0,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (_isPersonAccountClosed(controller, personId))
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 8.0 : 6.0,
                                      vertical: isTablet ? 4.0 : 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: isTablet ? 12.0 : 10.0,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Cerrada',
                                          style: TextStyle(
                                            fontSize: isTablet ? 10.0 : 8.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${personItems.length} ${personItems.length == 1 ? 'producto' : 'productos'}',
                              style: TextStyle(
                                fontSize: isTablet ? 12.0 : 10.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: isTablet ? 20.0 : 18.0,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenamePersonDialog(
                              context,
                              controller,
                              personId,
                              personName,
                              isTablet,
                            );
                          } else if (value == 'delete') {
                            _showDeletePersonDialog(
                              context,
                              controller,
                              personId,
                              personName,
                              isTablet,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Renombrar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Botón para agregar persona
        Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPersonDialog(
                context,
                controller,
                isTablet,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Persona'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        // Botón para cerrar cuenta completa (solo si hay historial)
        if (_hasAnyPersonHistory(controller))
          _buildCloseAllAccountsButton(context, controller, isTablet),
        // Botón para cerrar mesa (siempre visible en modo división)
        _buildCloseTableButton(context, controller, isTablet),
      ],
    );
  }

  bool _hasAnyPersonHistory(MeseroController controller) {
    final table = controller.selectedTable;
    if (table == null) return false;
    
    final allHistory = controller.getTableOrderHistory(table.id);
    return allHistory.any((order) => order['isDividedAccount'] == true);
  }

  bool _areAllPersonAccountsClosed(MeseroController controller) {
    final table = controller.selectedTable;
    if (table == null) return false;
    
    final personNames = controller.personNames;
    if (personNames.isEmpty) return false;
    
    // Verificar que todas las personas tengan historial y todas sus cuentas estén cerradas
    bool allHaveHistory = true;
    bool allClosed = true;
    
    for (final personId in personNames.keys) {
      if (!_hasPersonHistory(controller, personId)) {
        allHaveHistory = false;
        break;
      }
      if (!_isPersonAccountClosed(controller, personId)) {
        allClosed = false;
        break;
      }
    }
    
    return allHaveHistory && allClosed;
  }

  Widget _buildCloseTableButton(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final table = controller.selectedTable;
    if (table == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCloseTableConfirmation(context, controller, isTablet),
          icon: const Icon(Icons.table_restaurant),
          label: Text('Cerrar Mesa ${table.number}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 14.0 : 12.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonListMobile(
    BuildContext context,
    MeseroController controller,
    Map<String, String> persons,
    bool isTablet,
  ) {
    // En móvil, mostrar como tabs o dropdown
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 12.0 : 8.0),
        itemCount: persons.length + 1, // +1 para botón agregar
        itemBuilder: (context, index) {
          if (index == persons.length) {
            // Botón agregar persona
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddPersonDialog(context, controller, isTablet),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12.0 : 8.0,
                    vertical: isTablet ? 8.0 : 6.0,
                  ),
                ),
              ),
            );
          }
          
          final personId = persons.keys.elementAt(index);
          final personName = persons[personId]!;
          final personItems = controller.getItemsForPerson(personId);
          final isSelected = _selectedPersonId == personId;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(personName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  controller.setSelectedPersonId(personId);
                  setState(() {
                    _selectedPersonId = personId;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCloseTableConfirmation(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final table = controller.selectedTable;
    if (table == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Cerrar Mesa',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: Text(
          '¿Deseas cerrar la Mesa ${table.number}? Esto reseteará el modo de cuenta y podrás elegir nuevamente entre cuenta general o dividida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Resetear el modo dividido para esta mesa
              controller.resetDividedAccountModeForTable(table.id.toString());
              // Cerrar la mesa
              controller.closeTable(table.id);
              // Regresar al plano de mesas
              controller.setCurrentView('floor');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mesa ${table.number} cerrada. Puedes elegir un nuevo modo de cuenta.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Mesa'),
          ),
        ],
      ),
    );
  }

  void _reimprimirComanda(
    BuildContext context,
    int ordenId,
    bool isTablet,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Reimprimir comanda',
          style: TextStyle(fontSize: isTablet ? 20.0 : 18.0),
        ),
        content: Text(
          '¿Deseas reimprimir la comanda de la orden ORD-${ordenId.toString().padLeft(6, '0')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reimprimir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final comandasService = ComandasService();
      final resultado = await comandasService.reimprimirComanda(ordenId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensaje'] as String? ?? 'Comanda reimpresa exitosamente'),
            backgroundColor: resultado['exito'] == true ? AppColors.success : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reimprimir comanda: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAlertModalForOrder(
    BuildContext context,
    TableModel table,
    Map<String, dynamic> order,
    String personName,
  ) {
    final orderId = order['id']?.toString() ?? 'ORD';
    // Nota: personName no está disponible en showAlertToKitchenModal actualmente
    // Se puede agregar después si es necesario
    showAlertToKitchenModal(
      context,
      tableNumber: table.number.toString(),
      orderId: orderId,
    );
  }

  bool _hasPersonHistory(MeseroController controller, String personId) {
    final table = controller.selectedTable;
    if (table == null) return false;
    
    final allHistory = controller.getTableOrderHistory(table.id);
    return allHistory.any((order) {
      if (order['isDividedAccount'] == true && order['personAssignments'] != null) {
        final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
        return personAssignments?.containsKey(personId) == true;
      }
      return false;
    });
  }

  bool _isPersonAccountClosed(MeseroController controller, String personId) {
    final table = controller.selectedTable;
    if (table == null) return false;
    
    return controller.isPersonAccountClosed(table.id, personId);
  }

  void _showCloseAccountForPerson(
    BuildContext context,
    MeseroController controller,
    String personId,
    String personName,
    bool isTablet,
  ) async {
    final table = controller.selectedTable;
    if (table == null) return;

    // Obtener historial de esta persona específica
    final allHistory = controller.getTableOrderHistory(table.id);
    final personHistory = allHistory.where((order) {
      if (order['isDividedAccount'] == true && order['personAssignments'] != null) {
        final personAssignments = order['personAssignments'] as Map<String, dynamic>?;
        return personAssignments?.containsKey(personId) == true;
      }
      return false;
    }).toList();

    if (personHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$personName no tiene pedidos enviados para cerrar cuenta'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Obtener items de todas las órdenes de esta persona
    double totalConsumo = 0.0;
    final allItems = <Map<String, dynamic>>[];

    for (var order in personHistory) {
      final ordenId = order['ordenId'] as int?;
      if (ordenId != null) {
        try {
          final ordenData = await controller.getOrdenDetalle(ordenId);
          if (ordenData != null) {
            final items = ordenData['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
              final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
              final totalLineaBackend = (item['totalLinea'] as num?)?.toDouble() ?? 0.0;
              final totalLineaCalculado = precioUnitario * cantidad;
              final totalLinea = (totalLineaBackend <= 0.01 ||
                      (totalLineaCalculado - totalLineaBackend).abs() > 0.01)
                  ? totalLineaCalculado
                  : totalLineaBackend;

              totalConsumo += totalLinea;

              allItems.add({
                'nombre': item['productoNombre'] as String? ?? 'Producto',
                'tamano': item['productoTamanoEtiqueta'] as String?,
                'cantidad': cantidad,
                'precioUnitario': precioUnitario,
                'subtotal': totalLinea,
                'extras': item['modificadores'] as List<dynamic>? ?? [],
                'nota': item['nota'] as String?,
                'ordenId': ordenId,
                'ordenNumero': 'ORD-${ordenId.toString().padLeft(6, '0')}',
                'personName': personName, // Agregar nombre de persona
              });
            }
          }
        } catch (e) {
          print('Error al obtener detalles de orden $ordenId: $e');
        }
      }
    }

    // Mostrar diálogo de cierre de cuenta para esta persona
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppColors.warning,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cerrar cuenta — $personName',
                            style: TextStyle(
                              fontSize: isTablet ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Mesa ${table.number} • ${personHistory.length} ${personHistory.length == 1 ? 'pedido' : 'pedidos'}',
                            style: TextStyle(
                              fontSize: isTablet ? 14.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
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
              // Contenido
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
                                final tamano = item['tamano'] as String? ?? '';
                                final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;

                                return DataRow(
                                  cells: [
                                    DataCell(Text('$quantity')),
                                    DataCell(Text(
                                      tamano.isNotEmpty ? '$nombre ($tamano)' : nombre,
                                      style: TextStyle(fontSize: isTablet ? 13.0 : 11.0),
                                    )),
                                    DataCell(Text(
                                      '\$${subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 13.0 : 11.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Text(
                              'No hay consumo registrado',
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                                color: AppColors.textSecondary,
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
                              'Total $personName:',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${totalConsumo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botones
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
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
                              builder: (loadingContext) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // Usar el método específico para cerrar cuenta individual
                            await controller.sendPersonAccountToCashier(table.id, personId, personName);

                            // Cerrar el diálogo de carga
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            // Cerrar el diálogo principal del ticket
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            
                            // Mostrar mensaje de éxito
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cuenta de $personName enviada al Cajero. Las otras cuentas permanecen abiertas.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            // Cerrar el diálogo de carga en caso de error
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al enviar cuenta: ${e.toString()}'),
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

  // Botón para cerrar cuenta completa (todas las personas)
  Widget _buildCloseAllAccountsButton(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final table = controller.selectedTable;
    if (table == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Cerrar cuenta completa',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCloseAllAccountsDialog(
                context,
                controller,
                isTablet,
              ),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Cerrar Cuenta Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16.0 : 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseAllAccountsDialog(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) async {
    final table = controller.selectedTable;
    if (table == null) return;

    // Usar el mismo método que table_view pero adaptado para mostrar por persona
    // Por ahora, redirigir al método existente que ya maneja cuenta dividida
    // Esto se puede mejorar después para mostrar un diálogo personalizado
    
    // Simplemente llamar al método de cerrar cuenta que ya existe
    // El controller ya maneja la cuenta dividida correctamente y resetea el modo dividido
    try {
      await controller.sendToCashier(table.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta completa de Mesa ${table.number} enviada al Cajero'),
            backgroundColor: AppColors.success,
          ),
        );
        // Regresar al panel principal de mesas después de cerrar cuenta
        controller.setCurrentView('floor');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar cuenta: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
