import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';

/// Repositorio en memoria que simula el almacenamiento de transacciones
/// realizadas por el cajero. Posteriormente puede conectarse a una base de
/// datos real o a una API. Por ahora se utiliza como fuente única de verdad
/// para que tanto Cajero como Administrador accedan a los mismos datos.
class PaymentRepository extends ChangeNotifier {
  final List<PaymentModel> _payments = [];

  PaymentRepository() {
    // Ya no se cargan datos de ejemplo
    // Los datos se cargan desde el backend a través de los controladores
  }

  List<PaymentModel> get payments => List.unmodifiable(_payments);

  void addPayment(PaymentModel payment) {
    _payments.insert(0, payment);
    notifyListeners();
  }

  void addPayments(List<PaymentModel> payments) {
    _payments.clear();
    _payments.addAll(payments);
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
}

