import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment_model.dart';
import '../../controllers/cajero_controller.dart';
import '../../utils/app_colors.dart';

/// Modal para registrar el comprobante de pago con tarjeta
class CardVoucherModal extends StatefulWidget {
  final BillModel bill;
  final String cardMethod; // 'debito' o 'credito'
  final String terminal;
  final CajeroController controller;
  final bool isTablet;

  const CardVoucherModal({
    super.key,
    required this.bill,
    required this.cardMethod,
    required this.terminal,
    required this.controller,
    required this.isTablet,
  });

  static Future<void> show(
    BuildContext context,
    BillModel bill,
    String cardMethod,
    String terminal,
    CajeroController controller,
    bool isTablet,
  ) {
    return showDialog(
      context: context,
      builder: (context) => CardVoucherModal(
        bill: bill,
        cardMethod: cardMethod,
        terminal: terminal,
        controller: controller,
        isTablet: isTablet,
      ),
    );
  }

  @override
  State<CardVoucherModal> createState() => _CardVoucherModalState();
}

class _CardVoucherModalState extends State<CardVoucherModal> {
  final _transactionIdController = TextEditingController();
  final _authorizationCodeController = TextEditingController();
  final _last4DigitsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _voucherPrinted = false;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _transactionIdController.dispose();
    _authorizationCodeController.dispose();
    _last4DigitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: widget.isTablet ? 600 : double.infinity,
        padding: EdgeInsets.all(widget.isTablet ? 24.0 : 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Registrar comprobante',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 20.0 : 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resumen del pago
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.brown,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.cardMethod == 'debito'
                            ? 'Tarjeta de debito'
                            : 'Tarjeta de crédito',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 12.0 : 10.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.terminal,
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total cobrado: ${widget.controller.formatCurrency(widget.bill.total)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Método y Terminal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Método',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12.0 : 10.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.cardMethod == 'debito'
                              ? 'Tarjeta de debito'
                              : 'Tarjeta de crédito',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
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
                          'Terminal',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12.0 : 10.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.terminal,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fecha y hora
              Text(
                'Fecha y hora',
                style: TextStyle(
                  fontSize: widget.isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy hh:mm a', 'es').format(_selectedDateTime),
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14.0 : 12.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ID de transacción (requerido)
              TextFormField(
                controller: _transactionIdController,
                decoration: InputDecoration(
                  labelText: 'ID de transacción (voucher) *',
                  hintText: 'Ej: 123456789012',
                  prefixIcon: const Icon(Icons.receipt_long),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _transactionIdController.text.isEmpty &&
                          _transactionIdController.text.isNotEmpty
                      ? 'Campo requerido'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_transactionIdController.text.isEmpty &&
                  _transactionIdController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Campo requerido',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Código de autorización (opcional)
              TextFormField(
                controller: _authorizationCodeController,
                decoration: InputDecoration(
                  labelText: 'Código de autorización (opcional)',
                  hintText: 'Ej: 123456',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Últimos 4 dígitos (opcional)
              TextFormField(
                controller: _last4DigitsController,
                decoration: InputDecoration(
                  labelText: 'Últimos 4 dígitos (opcional)',
                  hintText: '1234',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 16),

              // Checkbox ticket impreso
              CheckboxListTile(
                title: const Text('Ticket impreso (voucher entregado al cliente)'),
                value: _voucherPrinted,
                onChanged: (value) {
                  setState(() {
                    _voucherPrinted = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              // Nota informativa
              if (!_voucherPrinted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se recomienda imprimir el voucher para el cliente',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12.0 : 10.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Notas/Comentarios
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas / Comentarios',
                  hintText: 'Ej: Cliente aprobó en terminal; voucher TX...',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _transactionIdController.text.trim().isNotEmpty
                          ? _confirmPayment
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmar pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPayment() {
    if (_transactionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El ID de transacción es requerido')),
      );
      return;
    }

    final payment = PaymentModel(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      type: PaymentType.card,
      totalAmount: widget.bill.total,
      tableNumber: widget.bill.tableNumber,
      billId: widget.bill.id,
      timestamp: DateTime.now(),
      cashierName: 'Cajero', // TODO: Obtener del AuthController
      cardMethod: widget.cardMethod,
      terminal: widget.terminal,
      transactionId: _transactionIdController.text.trim(),
      authorizationCode: _authorizationCodeController.text.trim().isNotEmpty
          ? _authorizationCodeController.text.trim()
          : null,
      last4Digits: _last4DigitsController.text.trim().isNotEmpty
          ? _last4DigitsController.text.trim()
          : null,
      voucherPrinted: _voucherPrinted,
      cardPaymentDate: _selectedDateTime,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    widget.controller.processPayment(payment);
    Navigator.of(context).pop();

    // Mostrar modal de éxito
    _showSuccessModal(payment);
  }

  void _showSuccessModal(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Pago procesado exitosamente!',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El pago con tarjeta ha sido registrado correctamente',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12.0 : 10.0,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Método:', payment.cardMethod == 'debito'
                      ? 'Tarjeta de debito'
                      : 'Tarjeta de crédito'),
                  _buildDetailRow('Terminal:', payment.terminal ?? ''),
                  _buildDetailRow('ID de transacción:', payment.transactionId ?? ''),
                  const Divider(),
                  _buildDetailRow('Total:', widget.controller.formatCurrency(payment.totalAmount)),
                  _buildDetailRow('Orden:', payment.billId),
                  _buildDetailRow(
                    'Fecha:',
                    payment.cardPaymentDate != null
                        ? DateFormat('d/M/yyyy, hh:mm:ss a', 'es')
                            .format(payment.cardPaymentDate!)
                        : DateFormat('d/M/yyyy, hh:mm:ss a', 'es')
                            .format(DateTime.now()),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar impresión de comprobante
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir comprobante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: widget.isTablet ? 12.0 : 10.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: widget.isTablet ? 12.0 : 10.0,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

