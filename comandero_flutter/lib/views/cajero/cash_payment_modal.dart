import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_model.dart';
import '../../controllers/cajero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';

/// Modal para confirmar cobro en efectivo
class CashPaymentModal extends StatefulWidget {
  final BillModel bill;
  final CajeroController controller;
  final bool isTablet;

  const CashPaymentModal({
    super.key,
    required this.bill,
    required this.controller,
    required this.isTablet,
  });

  static Future<void> show(
    BuildContext context,
    BillModel bill,
    CajeroController controller,
    bool isTablet,
  ) {
    return showDialog(
      context: context,
      builder: (context) => CashPaymentModal(
        bill: bill,
        controller: controller,
        isTablet: isTablet,
      ),
    );
  }

  @override
  State<CashPaymentModal> createState() => _CashPaymentModalState();
}

class _CashPaymentModalState extends State<CashPaymentModal> {
  final _cashReceivedController = TextEditingController();
  final _tipAmountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _tipDelivered = false;

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _tipAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _cashReceived => double.tryParse(_cashReceivedController.text) ?? 0.0;
  double get _tipAmount => double.tryParse(_tipAmountController.text) ?? 0.0;
  // Usar el total calculado desde los items para asegurar que sea correcto
  double get _totalAmount => widget.bill.calculatedTotal;
  
  // Cambio = efectivo recibido - total (sin restar propina)
  double get _change => _cashReceived - _totalAmount;
  
  // Efectivo aplicado = total + propina (para contar todo el dinero en cierre)
  double get _cashApplied => widget.controller.calculateCashApplied(_totalAmount, _tipAmount);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: widget.isTablet ? 500 : double.infinity,
        padding: EdgeInsets.all(widget.isTablet ? 24.0 : 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirmar cobro en efectivo',
                    style: TextStyle(
                      fontSize: widget.isTablet ? 20.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Resumen inicial
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total a pagar: ${widget.controller.formatCurrency(_totalAmount)}',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (widget.bill.tableNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mesa: ${widget.bill.tableNumber}',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 14.0 : 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Efectivo recibido
              TextFormField(
                controller: _cashReceivedController,
                decoration: InputDecoration(
                  labelText: 'Efectivo recibido *',
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Propina
              TextFormField(
                controller: _tipAmountController,
                decoration: InputDecoration(
                  labelText: 'Propina (opcional)',
                  prefixIcon: const Icon(Icons.tips_and_updates),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              
              // Checkbox propina entregada
              CheckboxListTile(
                title: const Text('Propina ya entregada al cajero'),
                value: _tipDelivered,
                onChanged: (value) {
                  setState(() {
                    _tipDelivered = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Cálculos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Efectivo aplicado al pago:',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.controller.formatCurrency(_cashApplied),
                          style: TextStyle(
                            fontSize: widget.isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cambio a devolver:',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.controller.formatCurrency(_change),
                          style: TextStyle(
                            fontSize: widget.isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Explicación del cálculo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cálculo:',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 14.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Efectivo aplicado = Total a pagar + Propina',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 12.0 : 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Cambio = Efectivo recibido - Total a pagar',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 12.0 : 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notas opcionales
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas del pago (opcional)',
                  hintText: 'Observaciones adicionales...',
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
                    child: ElevatedButton(
                      onPressed: _cashReceived > 0 && _cashReceived >= _totalAmount
                          ? _confirmPayment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmar cobro'),
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

  void _confirmPayment() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final payment = PaymentModel(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        type: PaymentType.cash,
        totalAmount: _totalAmount,
        cashReceived: _cashReceived,
        tipAmount: _tipAmount > 0 ? _tipAmount : null,
        tipDelivered: _tipDelivered,
        cashApplied: _cashApplied,
        change: _change,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        tableNumber: widget.bill.tableNumber,
        billId: widget.bill.id,
        timestamp: DateTime.now(),
        cashierName: Provider.of<AuthController>(context, listen: false).userName.isNotEmpty
            ? Provider.of<AuthController>(context, listen: false).userName
            : 'Cajero',
      );

      await widget.controller.processPayment(payment);
      
      // Cerrar diálogo de carga
      if (context.mounted) Navigator.of(context).pop();
      
      // Cerrar diálogo de pago
      if (context.mounted) Navigator.of(context).pop();
      
      // Mostrar modal de éxito
      if (context.mounted) {
        _showSuccessModal(_tipAmount);
      }
    } catch (e) {
      // Cerrar diálogo de carga
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSuccessModal(double tipAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Cobro registrado',
              style: TextStyle(
                fontSize: widget.isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.bill.tableNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mesa ${widget.bill.tableNumber}',
                style: TextStyle(
                  fontSize: widget.isTablet ? 14.0 : 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (tipAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Propina: ${widget.controller.formatCurrency(tipAmount)}',
                style: TextStyle(
                  fontSize: widget.isTablet ? 14.0 : 12.0,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

