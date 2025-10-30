import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AlertToKitchenModal extends StatefulWidget {
  final String tableNumber;
  final String orderId;

  const AlertToKitchenModal({
    super.key,
    required this.tableNumber,
    required this.orderId,
  });

  @override
  State<AlertToKitchenModal> createState() => _AlertToKitchenModalState();
}

class _AlertToKitchenModalState extends State<AlertToKitchenModal> {
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
              value: selectedAlertType.isEmpty ? null : selectedAlertType,
              decoration: InputDecoration(
                hintText: 'Selecciona el tipo de alerta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: alertTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
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
              value: selectedReason.isEmpty ? null : selectedReason,
              decoration: InputDecoration(
                hintText: 'Selecciona el motivo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: reasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
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

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Normal'),
                    value: 'Normal',
                    groupValue: priority,
                    onChanged: (value) {
                      setState(() {
                        priority = value ?? 'Normal';
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Urgente'),
                    value: 'Urgente',
                    groupValue: priority,
                    onChanged: (value) {
                      setState(() {
                        priority = value ?? 'Normal';
                      });
                    },
                    activeColor: AppColors.error,
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
                      color: priority == 'Urgente'
                          ? Colors.white
                          : AppColors.warning,
                    ),
                    label: Text(
                      'Enviar alerta',
                      style: TextStyle(
                        color: priority == 'Urgente'
                            ? Colors.white
                            : AppColors.warning,
                      ),
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

  void _sendAlert() {
    if (!_canSendAlert()) return;

    // TODO: Implementar envío de alerta a cocina
    final alertData = {
      'tableNumber': widget.tableNumber,
      'orderId': widget.orderId,
      'alertType': selectedAlertType,
      'reason': selectedReason,
      'details': additionalDetails,
      'priority': priority,
      'timestamp': DateTime.now(),
    };

    print('Enviando alerta a cocina: $alertData');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alerta enviada a cocina: $selectedAlertType'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}

// Widget para mostrar el modal
void showAlertToKitchenModal(
  BuildContext context, {
  required String tableNumber,
  required String orderId,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        AlertToKitchenModal(tableNumber: tableNumber, orderId: orderId),
  );
}
