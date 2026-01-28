import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cajero_controller.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;

/// Modal para registrar un pago por transferencia manual
class TransferPaymentModal extends StatefulWidget {
  final BillModel bill;
  final CajeroController controller;
  final bool isTablet;

  const TransferPaymentModal({
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
      builder: (_) => TransferPaymentModal(
        bill: bill,
        controller: controller,
        isTablet: isTablet,
      ),
    );
  }

  @override
  State<TransferPaymentModal> createState() => _TransferPaymentModalState();
}

class _TransferPaymentModalState extends State<TransferPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _tipController = TextEditingController();
  final _bankController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _submitted = false;

  double get _billTotal => widget.bill.calculatedTotal;
  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _tip => double.tryParse(_tipController.text) ?? 0;
  double get _paidWithTip => _amount + _tip;
  double get _remaining => (_billTotal - _paidWithTip).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    // Precargar con el total pendiente para agilizar el cobro
    _amountController.text = widget.bill.calculatedTotal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tipController.dispose();
    _bankController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _amount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 620 : 520,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isTablet),
                  const SizedBox(height: 12),
                  _buildSummaryCard(isTablet),
                  const SizedBox(height: 16),
                  _buildAmountField(isTablet),
                  const SizedBox(height: 12),
                  _buildBankField(isTablet),
                  const SizedBox(height: 12),
                  _buildReferenceField(isTablet),
                  const SizedBox(height: 12),
                  _buildTipField(isTablet),
                  const SizedBox(height: 12),
                  _buildNotesField(isTablet),
                  const SizedBox(height: 20),
                  _buildActions(isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Pago por transferencia',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de la cuenta',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.controller.formatCurrency(_billTotal),
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monto a pagar',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.controller.formatCurrency(_amount),
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo restante',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _remaining <= 0 ? Icons.check_circle : Icons.info_outline,
                    size: isTablet ? 18 : 16,
                    color: _remaining <= 0 ? AppColors.success : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.controller.formatCurrency(_remaining),
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _remaining <= 0 ? AppColors.success : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(bool isTablet) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Monto *',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      validator: (_) {
        if (_amount <= 0) return 'Ingresa un monto mayor a 0';
        // Permitir que el monto sea mayor si incluye propina
        // La propina es un extra, así que monto + propina puede ser mayor que el total
        if (_amount < _billTotal - _tip) {
          return 'El monto debe cubrir al menos el total de la cuenta';
        }
        return null;
      },
    );
  }

  Widget _buildBankField(bool isTablet) {
    return TextFormField(
      controller: _bankController,
      decoration: InputDecoration(
        labelText: 'Banco (opcional)',
        hintText: 'Ej. BBVA, Santander...',
        prefixIcon: const Icon(Icons.account_balance),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildReferenceField(bool isTablet) {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: 'Referencia / clave de rastreo (opcional)',
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTipField(bool isTablet) {
    return TextFormField(
      controller: _tipController,
      decoration: InputDecoration(
        labelText: 'Propina (opcional)',
        prefixIcon: const Icon(Icons.volunteer_activism),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNotesField(bool isTablet) {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Observaciones (opcional)',
        prefixIcon: const Icon(Icons.note_alt_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildActions(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isValid ? _confirmPayment : null,
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmar pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 14 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final payment = PaymentModel(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        type: PaymentType.transfer,
        totalAmount: _paidWithTip,
        tableNumber: widget.bill.tableNumber,
        billId: widget.bill.id,
        timestamp: date_utils.AppDateUtils.now(),
        cashierName: auth.userName.isNotEmpty ? auth.userName : 'Cajero',
        bankName: _bankController.text.trim(),
        reference: _referenceController.text.trim(),
        tipAmount: _tip > 0 ? _tip : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.controller.processPayment(payment);

      if (mounted) Navigator.of(context).pop(); // loading
      if (mounted) Navigator.of(context).pop(); // modal
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text('Transferencia registrada exitosamente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El pago ha sido registrado y enviado al administrador.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Monto: ${widget.controller.formatCurrency(_amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: widget.isTablet ? 16 : 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (_tip > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Propina: ${widget.controller.formatCurrency(_tip)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
            if (_bankController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Banco: ${_bankController.text.trim()}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (_referenceController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Referencia: ${_referenceController.text.trim()}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

