import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/kitchen_alerts_service.dart';
import '../../services/socket_service.dart';
import '../../models/kitchen_alert.dart';
import '../../utils/date_utils.dart' as date_utils;

class CaptainAlertToKitchenModal extends StatefulWidget {
  final String tableNumber;
  final String orderId;

  const CaptainAlertToKitchenModal({
    super.key,
    required this.tableNumber,
    required this.orderId,
  });

  @override
  State<CaptainAlertToKitchenModal> createState() => _CaptainAlertToKitchenModalState();
}

class _CaptainAlertToKitchenModalState extends State<CaptainAlertToKitchenModal> {
  String selectedAlertType = '';
  String selectedReason = '';
  String additionalDetails = '';
  String priority = 'Normal';

  final List<String> alertTypes = [
    'Demora',
    'Cancelación',
    'Cambio en orden',
    'Otra',
  ];

  final List<String> reasons = [
    'Mucho tiempo de espera',
    'Cliente se retiró',
    'Cliente cambió pedido',
    'Falta ingrediente',
    'Error en comanda',
    'Otro',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enviar alerta a cocina',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Selecciona el tipo de alerta que deseas enviar al equipo de cocina',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Información de la orden
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    'Mesa: ${widget.tableNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Orden: ${widget.orderId}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de alerta
            Text(
              'Tipo de alerta *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: selectedAlertType.isEmpty
                  ? null
                  : selectedAlertType,
              decoration: InputDecoration(
                hintText: 'Selecciona el tipo de alerta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                for (final type in alertTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAlertType = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Motivo
            Text(
              'Motivo *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: selectedReason.isEmpty ? null : selectedReason,
              decoration: InputDecoration(
                hintText: 'Selecciona el motivo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                for (final reason in reasons)
                  DropdownMenuItem(value: reason, child: Text(reason)),
              ],
              onChanged: (value) {
                setState(() {
                  selectedReason = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Detalles adicionales
            Text(
              'Motivo / Detalle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              onChanged: (value) {
                setState(() {
                  additionalDetails = value;
                });
              },
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Detalles adicionales (opcional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prioridad
            Text(
              'Prioridad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: priority == 'Normal',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => priority = 'Normal');
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: priority == 'Normal'
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Urgente'),
                  selected: priority == 'Urgente',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => priority = 'Urgente');
                  },
                  selectedColor: AppColors.error.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: priority == 'Urgente'
                        ? AppColors.error
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canSendAlert() ? _sendAlert : null,
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Enviar alerta',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: priority == 'Urgente'
                          ? AppColors.error
                          : AppColors.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canSendAlert() {
    return selectedAlertType.isNotEmpty && selectedReason.isNotEmpty;
  }

  void _sendAlert() async {
    if (!_canSendAlert()) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener información del capitán actual
      String captainNombre = 'Capitán';
      try {
        final authService = AuthService();
        final profile = await authService.getProfile();
        if (profile != null) {
          captainNombre =
              profile['username']?.toString() ??
              profile['nombre']?.toString() ??
              'Capitán';
        }
      } catch (e) {
        print('⚠️ Error al obtener perfil del capitán: $e');
      }

      // Extraer ordenId numérico del formato "ORD-000069" -> 69
      final ordenIdMatch = RegExp(r'ORD-(\d+)').firstMatch(widget.orderId);
      final ordenId = ordenIdMatch != null
          ? int.tryParse(ordenIdMatch.group(1) ?? '')
          : null;

      if (ordenId == null) {
        throw Exception('No se pudo extraer el ID de la orden de: ${widget.orderId}');
      }

      // Construir mensaje completo
      final mensaje =
          '$selectedAlertType: $selectedReason${additionalDetails.isNotEmpty ? ' - $additionalDetails' : ''}';

      // Mapear tipo de alerta del UI al enum del nuevo sistema
      AlertType alertType;
      if (selectedAlertType.toLowerCase() == 'cancelación' || selectedAlertType.toLowerCase() == 'cancelacion') {
        alertType = AlertType.CANCEL_ORDER;
      } else if (selectedAlertType.toLowerCase() == 'cambio en orden') {
        alertType = AlertType.UPDATE_ORDER;
      } else if (selectedAlertType.toLowerCase() == 'demora') {
        alertType = AlertType.EXTRA_ITEM;
      } else {
        alertType = AlertType.NEW_ORDER;
      }

      // Extraer tableId del número de mesa
      final tableId = int.tryParse(widget.tableNumber);

      // Crear la alerta usando el nuevo modelo
      final alert = KitchenAlert(
        orderId: ordenId,
        tableId: tableId,
        station: StationType.general, // El backend determinará la estación correcta
        type: alertType,
        message: mensaje,
        createdByUserId: 0, // Se obtendrá del token en el backend
        createdAt: date_utils.AppDateUtils.nowCdmx(),
        priority: priority, // Incluir la prioridad seleccionada
      );

      // Usar el NUEVO servicio de alertas de cocina (Socket.IO directo)
      final socketService = SocketService();
      if (!socketService.isConnected) {
        await socketService.connect();
      }
      final kitchenAlertsService = KitchenAlertsService(socketService);
      
      // Configurar listeners ANTES de enviar la alerta
      bool ackReceived = false;
      String? errorMessage;
      
      kitchenAlertsService.listenCreateAck((receivedAlert) {
        ackReceived = true;
        print('✅ Alerta confirmada por el backend - OrderId: ${receivedAlert.orderId}');
      });
      
      kitchenAlertsService.listenErrors((errorMsg, details) {
        errorMessage = errorMsg;
        print('❌ Error en alerta: $errorMsg');
      });
      
      // Enviar la alerta vía Socket.IO
      kitchenAlertsService.sendAlert(alert);
      
      // Esperar un momento para recibir el ACK o error (timeout de 2 segundos)
      int attempts = 0;
      while (attempts < 20 && !ackReceived && errorMessage == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Si hubo un error, lanzar excepción
      if (errorMessage != null) {
        throw Exception(errorMessage);
      }
      
      // Limpiar listeners
      kitchenAlertsService.dispose();

      print(
        '📢 Capitán ($captainNombre) envió alerta: $selectedAlertType - $selectedReason',
      );
      print('   ✅ Alerta guardada en BD y emitida a cocina por el backend');

      // Cerrar diálogo de carga
      if (context.mounted) Navigator.pop(context);

      // Mostrar confirmación con detalles
      if (context.mounted) {
        _showConfirmationDialog(context, captainNombre);
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (context.mounted) Navigator.pop(context);

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alerta: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(BuildContext context, String captainNombre) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Alerta Enviada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se ha enviado la alerta a Cocina:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: priority == 'Urgente'
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: priority == 'Urgente'
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        priority == 'Urgente'
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                        color: priority == 'Urgente'
                            ? Colors.red
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedAlertType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: priority == 'Urgente'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      if (priority == 'Urgente') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Motivo: $selectedReason'),
                  if (additionalDetails.isNotEmpty)
                    Text('Detalles: $additionalDetails'),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('Mesa ${widget.tableNumber}'),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(widget.orderId),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('Enviado por: $captainNombre (Capitán)'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Cerrar modal principal
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar el modal
void showCaptainAlertToKitchenModal(
  BuildContext context, {
  required String tableNumber,
  required String orderId,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        CaptainAlertToKitchenModal(tableNumber: tableNumber, orderId: orderId),
  );
}

