import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../controllers/cocinero_controller.dart';
import '../../utils/app_colors.dart';

class OrderDetailModal {
  static void show(
    BuildContext context, {
    required OrderModel order,
    required CocineroController controller,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final statusColor = controller.getStatusColor(order.status);
    final priorityColor = controller.getPriorityColor(order.priority);
    final elapsedTime = controller.formatElapsedTime(order.orderTime);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: statusColor,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del Pedido',
                            style: TextStyle(
                              fontSize: isTablet ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.isTakeaway
                                ? 'Para llevar - ${order.id}'
                                : 'Mesa ${order.tableNumber} - ${order.id}',
                            style: TextStyle(
                              fontSize: isTablet ? 14.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado y prioridad
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              OrderStatus.getStatusText(order.status),
                              style: TextStyle(
                                fontSize: isTablet ? 14.0 : 12.0,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: priorityColor),
                            ),
                            child: Text(
                              OrderPriority.getPriorityText(order.priority),
                              style: TextStyle(
                                fontSize: isTablet ? 14.0 : 12.0,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Información del pedido
                      _buildDetailItem(
                        context,
                        'Mesero',
                        order.waiter,
                        Icons.person,
                        isTablet,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem(
                        context,
                        'Tiempo transcurrido',
                        elapsedTime,
                        Icons.access_time,
                        isTablet,
                      ),
                      if (order.isTakeaway && order.customerName != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailItem(
                          context,
                          'Cliente',
                          order.customerName!,
                          Icons.person_outline,
                          isTablet,
                        ),
                      ],
                      if (order.isTakeaway && order.customerPhone != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailItem(
                          context,
                          'Teléfono',
                          order.customerPhone!,
                          Icons.phone,
                          isTablet,
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Items del pedido
                      Text(
                        'Items del Pedido',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map((item) => _buildOrderItem(context, item, isTablet)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: isTablet ? 20.0 : 18.0,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 10.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildOrderItem(BuildContext context, OrderItem item, bool isTablet) {
    final isCriticalNote = item.notes.toLowerCase().contains('urgente') ||
        item.notes.toLowerCase().contains('crítico') ||
        item.notes.toLowerCase().contains('rapido');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
      decoration: BoxDecoration(
        color: isCriticalNote
            ? Colors.red.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCriticalNote ? Colors.red : AppColors.border,
          width: isCriticalNote ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontSize: isTablet ? 14.0 : 12.0,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isCriticalNote) ...[
                        Icon(
                          Icons.warning,
                          size: isTablet ? 16.0 : 14.0,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.notes,
                          style: TextStyle(
                            fontSize: isTablet ? 12.0 : 10.0,
                            color: isCriticalNote ? Colors.red : AppColors.textSecondary,
                            fontWeight: isCriticalNote ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.station,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

