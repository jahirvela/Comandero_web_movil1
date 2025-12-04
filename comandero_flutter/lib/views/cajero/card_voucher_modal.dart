import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cajero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;

/// Modal para registrar el comprobante de pago con tarjeta.
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
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  final _authorizationCodeController = TextEditingController();
  final _last4DigitsController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDateTime;
  
  @override
  void initState() {
    super.initState();
    // Inicializar con hora CDMX
    _selectedDateTime = date_utils.AppDateUtils.now();
  }
  bool _voucherPrinted = false;
  bool _submitted = false;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 420;
          final paddingValue = widget.isTablet
              ? 24.0
              : (isSmallScreen ? 12.0 : 20.0);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              minWidth: widget.isTablet ? 560 : 0,
            ),
            child: Padding(
              padding: EdgeInsets.all(paddingValue),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildMetadataRow(),
                      const SizedBox(height: 24),
                      _buildDateTimePicker(),
                      const SizedBox(height: 16),
                      _buildTransactionField(),
                      const SizedBox(height: 16),
                      _buildAuthorizationField(),
                      const SizedBox(height: 16),
                      _buildLastDigitsField(),
                      const SizedBox(height: 16),
                      _buildVoucherCheckbox(),
                      if (!_voucherPrinted) ...[
                        const SizedBox(height: 12),
                        _buildVoucherReminder(),
                      ],
                      const SizedBox(height: 16),
                      _buildNotesField(),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Registrar comprobante',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.isTablet ? 20 : 18,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final badgeText = widget.cardMethod == 'debito'
        ? 'Tarjeta de débito'
        : 'Tarjeta de crédito';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: widget.isTablet ? 13 : 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.terminal,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: widget.isTablet ? 14 : 12,
            ),
          ),
          const Spacer(),
          Text(
            'Total cobrado:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: widget.isTablet ? 13 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.controller.formatCurrency(widget.bill.calculatedTotal),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: widget.isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    final methodLabel = widget.cardMethod == 'debito'
        ? 'Tarjeta de débito'
        : 'Tarjeta de crédito';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Método',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: widget.isTablet ? 13 : 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                methodLabel,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: widget.isTablet ? 15 : 13,
                  fontWeight: FontWeight.w500,
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
                  color: AppColors.textSecondary,
                  fontSize: widget.isTablet ? 13 : 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.terminal,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: widget.isTablet ? 15 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha y hora',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: widget.isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateTime,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 10),
                Text(
                  date_utils.AppDateUtils.formatDateTime(_selectedDateTime),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: widget.isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionField() {
    return TextFormField(
      controller: _transactionIdController,
      decoration: InputDecoration(
        labelText: 'ID de transacción (voucher) *',
        hintText: 'Ej: 123456789012',
        prefixIcon: const Icon(Icons.receipt_long),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (_submitted && (value == null || value.trim().isEmpty)) {
          return 'Campo requerido';
        }
        return null;
      },
    );
  }

  Widget _buildAuthorizationField() {
    return TextFormField(
      controller: _authorizationCodeController,
      decoration: InputDecoration(
        labelText: 'Código de autorización (opcional)',
        hintText: 'Ej: 123456',
        prefixIcon: const Icon(Icons.vpn_key),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildLastDigitsField() {
    return TextFormField(
      controller: _last4DigitsController,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: InputDecoration(
        counterText: '',
        labelText: 'Últimos 4 dígitos (opcional)',
        hintText: '1234',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildVoucherCheckbox() {
    return CheckboxListTile(
      value: _voucherPrinted,
      contentPadding: EdgeInsets.zero,
      title: const Text('Ticket impreso (voucher entregado al cliente)'),
      onChanged: (value) {
        setState(() => _voucherPrinted = value ?? false);
      },
    );
  }

  Widget _buildVoucherReminder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Se recomienda imprimir el voucher para el cliente.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: widget.isTablet ? 13 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notas / Comentarios',
        hintText: 'Ej: Cliente aprobó en terminal; voucher TX...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildActions() {
    final isReady = _transactionIdController.text.trim().isNotEmpty;

    return Row(
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
            onPressed: isReady ? _confirmPayment : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final now = date_utils.AppDateUtils.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      locale: const Locale('es', 'MX'),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: 'Seleccionar hora',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'MX'),
          child: child!,
        );
      },
    );

    if (!mounted) return;
    if (time == null) return;

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

  void _confirmPayment() async {
    setState(() => _submitted = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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
        type: PaymentType.card,
        totalAmount: widget.bill.calculatedTotal,
        tableNumber: widget.bill.tableNumber,
        billId: widget.bill.id,
        timestamp: date_utils.AppDateUtils.now(),
        cashierName: Provider.of<AuthController>(context, listen: false).userName.isNotEmpty
            ? Provider.of<AuthController>(context, listen: false).userName
            : 'Cajero',
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

      await widget.controller.processPayment(payment);
      
      // Cerrar diálogo de carga
      if (context.mounted) Navigator.of(context).pop();
      
      // Cerrar diálogo de pago
      if (context.mounted) Navigator.of(context).pop();

      // Mostrar modal de éxito
      if (context.mounted) {
        _showSuccessModal(payment);
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

  void _showSuccessModal(PaymentModel payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CardPaymentSuccessDialog(
        payment: payment,
        controller: widget.controller,
        isTablet: widget.isTablet,
      ),
    );
  }
}

class _CardPaymentSuccessDialog extends StatelessWidget {
  final PaymentModel payment;
  final CajeroController controller;
  final bool isTablet;

  const _CardPaymentSuccessDialog({
    required this.payment,
    required this.controller,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: isTablet ? 64 : 56,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pago procesado exitosamente!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'El pago con tarjeta ha sido registrado correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSuccessSummary(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handlePrint(context),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir comprobante'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessSummary(BuildContext context) {
    final methodLabel = payment.cardMethod == 'debito'
        ? 'Tarjeta de débito'
        : 'Tarjeta de crédito';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Método', methodLabel),
          _buildDetailRow('Terminal', payment.terminal ?? ''),
          _buildDetailRow('ID de transacción', payment.transactionId ?? ''),
          const Divider(height: 20),
          _buildDetailRow(
            'Total',
            controller.formatCurrency(payment.totalAmount),
          ),
          _buildDetailRow('Orden', payment.billId),
          _buildDetailRow(
            'Fecha',
            date_utils.AppDateUtils.formatDateTime(
              payment.cardPaymentDate ?? date_utils.AppDateUtils.now(),
            ),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 14 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final shouldPrint =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Imprimir comprobante'),
            content: Text(
              '¿Deseas imprimir el comprobante?\nCajero: ${payment.cashierName}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Imprimir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!context.mounted) return;
    if (!shouldPrint) return;

    controller.markBillAsPrinted(
      payment.billId,
      payment.cashierName,
      paymentId: payment.id,
    );
    Navigator.of(context).pop();
  }
}
