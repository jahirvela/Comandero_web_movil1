import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cajero_controller.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;

/// Modal para registrar múltiples pagos manuales (mixto)
class MixedPaymentModal extends StatefulWidget {
  final BillModel bill;
  final CajeroController controller;
  final bool isTablet;

  const MixedPaymentModal({
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
      builder: (_) => MixedPaymentModal(
        bill: bill,
        controller: controller,
        isTablet: isTablet,
      ),
    );
  }

  @override
  State<MixedPaymentModal> createState() => _MixedPaymentModalState();
}

class _MixedPaymentModalState extends State<MixedPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final List<_MixedPaymentEntry> _entries = [];
  final _tipController = TextEditingController();
  bool _submitted = false;

  double get _billTotal => widget.bill.calculatedTotal;
  double get _totalPaid =>
      _entries.fold(0.0, (sum, entry) => sum + entry.amount);
  double get _tipAmount => double.tryParse(_tipController.text) ?? 0;
  // La propina es un extra, no se resta del saldo restante
  // Solo verificamos que el total pagado cubra el total de la cuenta
  double get _remaining => _billTotal - _totalPaid;

  @override
  void initState() {
    super.initState();
    _entries.add(
      _MixedPaymentEntry(id: 'entry-${DateTime.now().millisecondsSinceEpoch}'),
    );
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    _tipController.dispose();
    super.dispose();
  }

  bool _isEntryValid(_MixedPaymentEntry entry) {
    return entry.amount > 0;
  }

  bool get _allEntriesValid =>
      _entries.every((entry) => _isEntryValid(entry)) && _totalPaid > 0;

  // Validar que el total pagado cubra al menos el total de la cuenta
  // La propina es un extra, así que el total pagado puede ser mayor
  bool get _totalsMatch => _remaining <= 0.01;

  bool get _canConfirm => _allEntriesValid && _totalsMatch;

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 760 : 620,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isTablet),
                const SizedBox(height: 12),
                _buildSummary(isTablet),
                const SizedBox(height: 12),
                _buildTipField(isTablet),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ..._entries.asMap().entries.map(
                          (entry) =>
                              _buildEntryCard(entry.value, entry.key, isTablet),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _addEntry,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar forma de pago'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActions(isTablet),
              ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pago mixto',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Registra varias formas de pago de forma manual.',
              style: TextStyle(
                fontSize: isTablet ? 13 : 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSummary(bool isTablet) {
    final remaining = _remaining;
    final totalPaid = _totalPaid;
    final tip = _tipAmount;
    // Está balanceado si el total pagado cubre al menos el total de la cuenta
    // El excedente puede ser por propina, que es válido
    final isBalanced = _totalsMatch;
    final isOver = remaining < 0;
    final hasExcessFromTip = isOver && totalPaid >= _billTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isBalanced || hasExcessFromTip)
              ? AppColors.success.withValues(alpha: 0.5)
              : (isOver ? Colors.redAccent : Colors.orange).withValues(
                  alpha: 0.4,
                ),
        ),
        color: (isBalanced || hasExcessFromTip)
            ? AppColors.success.withValues(alpha: 0.08)
            : (isOver
                  ? Colors.redAccent.withValues(alpha: 0.06)
                  : Colors.orange.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'Subtotal:',
            value: widget.controller.formatCurrency(widget.bill.subtotal - widget.bill.discount),
            color: AppColors.textSecondary,
            isTablet: isTablet,
          ),
          if (widget.controller.ivaHabilitado) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              label: 'IVA (16%):',
              value: widget.controller.formatCurrency(widget.bill.tax),
              color: AppColors.textSecondary,
              isTablet: isTablet,
            ),
          ],
          const SizedBox(height: 6),
          _buildSummaryRow(
            label: 'Total de la cuenta',
            value: widget.controller.formatCurrency(_billTotal),
            color: AppColors.textPrimary,
            isTablet: isTablet,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            label: 'Total acumulado',
            value: widget.controller.formatCurrency(totalPaid),
            color: AppColors.primary,
            isTablet: isTablet,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            label: 'Propina',
            value: widget.controller.formatCurrency(tip),
            color: AppColors.textSecondary,
            isTablet: isTablet,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            label: isBalanced
                ? 'Saldo listo'
                : (hasExcessFromTip
                      ? 'Excedente (propina)'
                      : (isOver ? 'Excedente' : 'Monto restante')),
            value: widget.controller.formatCurrency(remaining.abs()),
            color: (isBalanced || hasExcessFromTip)
                ? AppColors.success
                : (isOver ? Colors.redAccent : Colors.orange),
            isTablet: isTablet,
            icon: (isBalanced || hasExcessFromTip)
                ? Icons.check_circle
                : (isOver ? Icons.warning : Icons.info_outline),
          ),
          if (!isBalanced && !hasExcessFromTip)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isOver
                      ? 'El total acumulado supera el total de la cuenta.'
                      : 'El total acumulado es menor al total de la cuenta.',
                  style: TextStyle(
                    color: isOver ? Colors.redAccent : Colors.orange,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
              ),
            ),
          if (hasExcessFromTip && tip > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'El excedente corresponde a la propina registrada.',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: isTablet ? 12 : 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color color,
    required bool isTablet,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: isTablet ? 18 : 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTipField(bool isTablet) {
    return TextFormField(
      controller: _tipController,
      decoration: InputDecoration(
        labelText: 'Propina global (opcional)',
        prefixIcon: const Icon(Icons.volunteer_activism),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEntryCard(_MixedPaymentEntry entry, int index, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pago ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (_entries.length > 1)
                IconButton(
                  onPressed: () => _removeEntry(entry),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  tooltip: 'Eliminar pago',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTypeSelector(entry, isTablet)),
              const SizedBox(width: 12),
              Expanded(child: _buildAmountField(entry)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTypeSpecificFields(entry, isTablet),
          const SizedBox(height: 12),
          _buildNotesField(entry),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(_MixedPaymentEntry entry, bool isTablet) {
    return DropdownButtonFormField<String>(
      value: entry.type,
      decoration: InputDecoration(
        labelText: 'Tipo de pago',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: const [
        DropdownMenuItem(value: PaymentType.cash, child: Text('Efectivo')),
        DropdownMenuItem(value: PaymentType.card, child: Text('Tarjeta')),
        DropdownMenuItem(
          value: PaymentType.transfer,
          child: Text('Transferencia'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          entry.type = value;
          entry.referenceCtrl.clear();
          entry.bankCtrl.clear();
          // Resetear cardMethod a débito por defecto cuando se cambia el tipo
          if (value == PaymentType.card) {
            entry.cardMethod = 'debito';
          }
        });
      },
    );
  }

  Widget _buildAmountField(_MixedPaymentEntry entry) {
    return TextFormField(
      controller: entry.amountCtrl,
      decoration: InputDecoration(
        labelText: 'Monto *',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      validator: (_) {
        if (entry.amount <= 0) return 'Ingresa un monto válido';
        if (_totalPaid > _billTotal + 0.01) {
          return 'El total no debe exceder la cuenta';
        }
        return null;
      },
    );
  }

  Widget _buildTypeSpecificFields(_MixedPaymentEntry entry, bool isTablet) {
    switch (entry.type) {
      case PaymentType.card:
        return Column(
          children: [
            // Selector de tipo de tarjeta (Débito/Crédito)
            DropdownButtonFormField<String>(
              value: entry.cardMethod,
              decoration: InputDecoration(
                labelText: 'Tipo de tarjeta',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'debito',
                  child: Text('Tarjeta Débito'),
                ),
                DropdownMenuItem(
                  value: 'credito',
                  child: Text('Tarjeta Crédito'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    entry.cardMethod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: entry.referenceCtrl,
              decoration: InputDecoration(
                labelText: 'Referencia / voucher (opcional)',
                prefixIcon: const Icon(Icons.receipt_long),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'El cobro se registra manualmente. Ingresa la referencia del voucher o terminal.',
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case PaymentType.transfer:
        return Column(
          children: [
            TextFormField(
              controller: entry.bankCtrl,
              decoration: InputDecoration(
                labelText: 'Banco (opcional)',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.referenceCtrl,
              decoration: InputDecoration(
                labelText: 'Referencia / clave (opcional)',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      default:
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Efectivo registrado manualmente.',
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              color: AppColors.textSecondary,
            ),
          ),
        );
    }
  }

  Widget _buildNotesField(_MixedPaymentEntry entry) {
    return TextFormField(
      controller: entry.notesCtrl,
      decoration: InputDecoration(
        labelText: 'Observaciones (opcional)',
        prefixIcon: const Icon(Icons.note_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            onPressed: _canConfirm ? _confirmPayments : _showValidationWarning,
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmar pagos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
            ),
          ),
        ),
      ],
    );
  }

  void _addEntry() {
    setState(() {
      _entries.add(
        _MixedPaymentEntry(
          id: 'entry-${DateTime.now().millisecondsSinceEpoch}-${_entries.length}',
        ),
      );
    });
  }

  void _removeEntry(_MixedPaymentEntry entry) {
    setState(() {
      entry.dispose();
      _entries.remove(entry);
    });
  }

  void _showValidationWarning() {
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Completa los datos obligatorios y asegúrate que el total coincida.',
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmPayments() async {
    setState(() => _submitted = true);
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !_canConfirm) {
      _showValidationWarning();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final cashierName = auth.userName.isNotEmpty ? auth.userName : 'Cajero';

      // Guardar información crítica del bill antes de procesar pagos
      final billId = widget.bill.id;
      final ordenId = widget.bill.ordenId;
      final ordenIdsFromBill = widget.bill.ordenIdsFromBillIdInt;

      print('💳 MixedPayment: Procesando pagos para billId: $billId');
      print('💳 MixedPayment: OrdenId: $ordenId');
      print('💳 MixedPayment: OrdenIds: $ordenIdsFromBill');

      // Filtrar solo las entradas válidas (con monto > 0)
      final validEntries = _entries.where((e) => e.amount > 0).toList();

      if (validEntries.isEmpty) {
        if (mounted) Navigator.of(context).pop(); // loading
        _showValidationWarning();
        return;
      }

      // Procesar todos los pagos parciales primero (manteniendo el bill abierto)
      bool allPaymentsSuccessful = true;
      String? errorMessage;

      for (int i = 0; i < validEntries.length; i++) {
        final entry = validEntries[i];
        final isLast = i == validEntries.length - 1;

        final payment = _buildPaymentFromEntry(
          entry,
          cashierName,
          includeTip: isLast && _tipAmount > 0,
        );

        // Asegurar que el billId sea el correcto usando el bill original
        // El payment ya tiene el billId correcto desde _buildPaymentFromEntry

        print(
          '💳 MixedPayment: Procesando pago ${i + 1}/${validEntries.length}',
        );
        print(
          '💳 MixedPayment: Tipo: ${entry.type}, Monto: ${payment.totalAmount}',
        );
        print('💳 MixedPayment: BillId: "${payment.billId}"');
        print('💳 MixedPayment: keepBillOpen: ${!isLast}');

        try {
          await widget.controller.processPayment(
            payment,
            keepBillOpen: !isLast,
            ordenIdOverride: ordenId,
            ordenIdsOverride: ordenIdsFromBill,
          );
          print('✅ MixedPayment: Pago ${i + 1} procesado exitosamente');

          // Pequeña pausa para asegurar que el bill se actualice correctamente
          if (!isLast) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e, stackTrace) {
          print('❌ MixedPayment: Error al procesar pago ${i + 1}: $e');
          print('Stack trace: $stackTrace');
          errorMessage = e.toString();
          allPaymentsSuccessful = false;
          break;
        }
      }

      if (mounted) Navigator.of(context).pop(); // loading

      if (allPaymentsSuccessful) {
        if (mounted) Navigator.of(context).pop(); // modal
        if (mounted) _showSuccessDialog();
      } else {
        // Si hubo un error, mantener el modal abierto para que el usuario pueda corregir
        if (mounted && errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar pagos: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ MixedPayment: Error al procesar pagos: $e');
      print('Stack trace: $stackTrace');
      if (mounted) Navigator.of(context).pop(); // loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pagos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  PaymentModel _buildPaymentFromEntry(
    _MixedPaymentEntry entry,
    String cashierName, {
    bool includeTip = false,
  }) {
    final timestamp = date_utils.AppDateUtils.now();
    final tipToApply = includeTip ? _tipAmount : 0.0;
    final totalWithTip = entry.amount + tipToApply;
    switch (entry.type) {
      case PaymentType.card:
        // Construir referencia con tipo de tarjeta
        final cardTypeLabel = entry.cardMethod == 'debito'
            ? 'Tarjeta Débito'
            : 'Tarjeta Crédito';
        final referencia = entry.referenceCtrl.text.trim().isNotEmpty
            ? '$cardTypeLabel - Ref: ${entry.referenceCtrl.text.trim()}'
            : cardTypeLabel;

        return PaymentModel(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}-${entry.id}',
          type: PaymentType.card,
          totalAmount: totalWithTip,
          transactionId: entry.referenceCtrl.text.trim().isNotEmpty
              ? entry.referenceCtrl.text.trim()
              : null,
          reference: referencia,
          notes: entry.notesCtrl.text.trim().isEmpty
              ? null
              : entry.notesCtrl.text.trim(),
          billId: widget.bill.id,
          tableNumber: widget.bill.tableNumber,
          cashierName: cashierName,
          timestamp: timestamp,
          terminal: 'Manual',
          cardMethod:
              entry.cardMethod, // Usar el método seleccionado (debito/credito)
          tipAmount: tipToApply > 0 ? tipToApply : null,
        );
      case PaymentType.transfer:
        return PaymentModel(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}-${entry.id}',
          type: PaymentType.transfer,
          totalAmount: totalWithTip,
          bankName: entry.bankCtrl.text.trim(),
          reference: entry.referenceCtrl.text.trim(),
          notes: entry.notesCtrl.text.trim().isEmpty
              ? null
              : entry.notesCtrl.text.trim(),
          billId: widget.bill.id,
          tableNumber: widget.bill.tableNumber,
          cashierName: cashierName,
          timestamp: timestamp,
          tipAmount: tipToApply > 0 ? tipToApply : null,
        );
      default:
        return PaymentModel(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}-${entry.id}',
          type: PaymentType.cash,
          totalAmount: totalWithTip,
          cashReceived: totalWithTip,
          cashApplied: totalWithTip,
          change: 0,
          notes: entry.notesCtrl.text.trim().isEmpty
              ? null
              : entry.notesCtrl.text.trim(),
          billId: widget.bill.id,
          tableNumber: widget.bill.tableNumber,
          cashierName: cashierName,
          timestamp: timestamp,
          tipAmount: tipToApply > 0 ? tipToApply : null,
        );
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
            const Text('Pagos registrados exitosamente'),
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
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los pagos han sido registrados y enviados al administrador.',
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
              'Total aplicado: ${widget.controller.formatCurrency(_totalPaid + _tipAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: widget.isTablet ? 16 : 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (_tipAmount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Propina: ${widget.controller.formatCurrency(_tipAmount)}',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Desglose de pagos:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: widget.isTablet ? 14 : 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ..._entries
                .where((e) => e.amount > 0)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          PaymentType.getTypeText(entry.type),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          widget.controller.formatCurrency(entry.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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

class _MixedPaymentEntry {
  _MixedPaymentEntry({required this.id})
    : type = PaymentType.cash,
      cardMethod = 'debito', // Por defecto débito
      amountCtrl = TextEditingController(),
      bankCtrl = TextEditingController(),
      referenceCtrl = TextEditingController(),
      notesCtrl = TextEditingController();

  final String id;
  String type;
  String cardMethod; // 'debito' o 'credito' para pagos con tarjeta
  final TextEditingController amountCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController referenceCtrl;
  final TextEditingController notesCtrl;

  double get amount => double.tryParse(amountCtrl.text) ?? 0;

  void dispose() {
    amountCtrl.dispose();
    bankCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
  }
}
