import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import '../../controllers/cajero_controller.dart';
import '../../utils/app_colors.dart';
import 'card_voucher_modal.dart';

/// Modal para pagar con tarjeta (primera parte: enviar a terminal)
class CardPaymentModal extends StatefulWidget {
  final BillModel bill;
  final CajeroController controller;
  final bool isTablet;

  const CardPaymentModal({
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
      builder: (context) => CardPaymentModal(
        bill: bill,
        controller: controller,
        isTablet: isTablet,
      ),
    );
  }

  @override
  State<CardPaymentModal> createState() => _CardPaymentModalState();
}

class _CardPaymentModalState extends State<CardPaymentModal> {
  String _selectedMethod = 'debito'; // 'debito' o 'credito'
  String _selectedTerminal = 'Terminal 1';
  bool _isTerminalConnected = true; // Simulado

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
                  color: Colors.orange,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagar con tarjeta',
                      style: TextStyle(
                        fontSize: widget.isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resumen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caja 1',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${widget.controller.formatCurrency(widget.bill.total)} MXN',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${widget.controller.formatCurrency(widget.bill.total)}',
                              style: TextStyle(
                                fontSize: widget.isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('MXN'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Método de pago
              Text(
                'Método de pago',
                style: TextStyle(
                  fontSize: widget.isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'debito'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'debito'
                              ? Colors.orange
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedMethod == 'debito'
                                ? Colors.orange
                                : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Tarjeta de débito',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 14.0 : 12.0,
                              fontWeight: FontWeight.w600,
                              color: _selectedMethod == 'debito'
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'credito'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'credito'
                              ? Colors.orange
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedMethod == 'credito'
                                ? Colors.orange
                                : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Tarjeta de crédito',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 14.0 : 12.0,
                              fontWeight: FontWeight.w600,
                              color: _selectedMethod == 'credito'
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Terminal
              Text(
                'Terminal',
                style: TextStyle(
                  fontSize: widget.isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTerminal,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Terminal 1',
                              child: Text('Terminal 1'),
                            ),
                            DropdownMenuItem(
                              value: 'Terminal 2',
                              child: Text('Terminal 2'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTerminal = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isTerminalConnected
                          ? Colors.orange
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi,
                          color: Colors.white,
                          size: widget.isTablet ? 20.0 : 18.0,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Conectado',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Resumen del pago
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          widget.controller.formatCurrency(widget.bill.total),
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14.0 : 12.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a cobrar:',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 16.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.controller.formatCurrency(widget.bill.total),
                          style: TextStyle(
                            fontSize: widget.isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nota importante
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: widget.isTablet ? 20.0 : 18.0,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Acerca la terminal al cliente. El sistema no procesa la tarjeta: la terminal imprime el voucher. Luego el cajero registra manualmente el comprobante en el formulario de registro.',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 12.0 : 10.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
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
                      onPressed: _sendToTerminal,
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Enviar a terminal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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

  void _sendToTerminal() {
    Navigator.of(context).pop();
    
    // Mostrar modal de registro de comprobante
    Future.delayed(const Duration(milliseconds: 300), () {
      CardVoucherModal.show(
        context,
        widget.bill,
        _selectedMethod,
        _selectedTerminal,
        widget.controller,
        widget.isTablet,
      );
    });
  }
}

