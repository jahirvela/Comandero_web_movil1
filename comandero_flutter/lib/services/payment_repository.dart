import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';

/// Repositorio en memoria que simula el almacenamiento de transacciones
/// realizadas por el cajero. Posteriormente puede conectarse a una base de
/// datos real o a una API. Por ahora se utiliza como fuente única de verdad
/// para que tanto Cajero como Administrador accedan a los mismos datos.
class PaymentRepository extends ChangeNotifier {
  final List<PaymentModel> _payments = [];

  PaymentRepository() {
    _seedSampleData();
  }

  List<PaymentModel> get payments => List.unmodifiable(_payments);

  void addPayment(PaymentModel payment) {
    _payments.insert(0, payment);
    notifyListeners();
  }

  void markAsPrinted(String paymentId) {
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index == -1) return;

    final updated = _payments[index].copyWith(
      voucherPrinted: true,
    );

    _payments[index] = updated;
    notifyListeners();
  }

  void _seedSampleData() {
    final now = DateTime.now();

    _payments.addAll([
      PaymentModel(
        id: 'PAY-INIT-001',
        type: PaymentType.card,
        totalAmount: 159.0,
        billId: 'BILL-001',
        tableNumber: 5,
        cashierName: 'Juan Martínez',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        cardMethod: 'debito',
        terminal: 'Clip 05',
        transactionId: 'TRX123456789',
        authorizationCode: 'A12345',
        last4Digits: '1234',
        voucherPrinted: true,
        cardPaymentDate: now.subtract(const Duration(hours: 1, minutes: 15)),
        notes: 'Propina incluida en efectivo',
      ),
      PaymentModel(
        id: 'PAY-INIT-002',
        type: PaymentType.card,
        totalAmount: 98.5,
        billId: 'BILL-003',
        tableNumber: null,
        cashierName: 'Ana Rodríguez',
        timestamp: now.subtract(const Duration(minutes: 45)),
        cardMethod: 'credito',
        terminal: 'Getnet 02',
        transactionId: 'TRX987654321',
        authorizationCode: 'B98765',
        last4Digits: '5678',
        voucherPrinted: false,
        cardPaymentDate: now.subtract(const Duration(minutes: 40)),
        notes: 'Pedido para llevar',
      ),
      PaymentModel(
        id: 'PAY-INIT-003',
        type: PaymentType.cash,
        totalAmount: 180.0,
        cashReceived: 200.0,
        change: 20.0,
        tableNumber: 4,
        billId: 'BILL-002',
        timestamp: now.subtract(const Duration(minutes: 70)),
        cashierName: 'Juan Martínez',
        notes: 'Pago en efectivo con propina',
        tipAmount: 10.0,
        tipDelivered: true,
        cashApplied: 190.0,
      ),
    ]);
  }
}

