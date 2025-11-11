import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';

/// Repositorio en memoria para compartir las cuentas abiertas entre Mesero y
/// Cajero. Posteriormente se conectará con backend/base de datos.
class BillRepository extends ChangeNotifier {
  BillRepository() {
    _seedSampleBills();
  }

  final List<BillModel> _bills = [];

  List<BillModel> get bills => List.unmodifiable(_bills);

  List<BillModel> get pendingBills =>
      _bills.where((bill) => bill.status == BillStatus.pending).toList();

  void addBill(BillModel bill) {
    _bills.insert(0, bill);
    notifyListeners();
  }

  void updateBill(String billId, BillModel Function(BillModel) updater) {
    final index = _bills.indexWhere((bill) => bill.id == billId);
    if (index == -1) return;

    _bills[index] = updater(_bills[index]);
    notifyListeners();
  }

  void removeBill(String billId) {
    _bills.removeWhere((bill) => bill.id == billId);
    notifyListeners();
  }

  void removeBillsForTable(int tableNumber) {
    _bills.removeWhere((bill) => bill.tableNumber == tableNumber);
    notifyListeners();
  }

  void _seedSampleBills() {
    _bills.addAll([
      BillModel(
        id: 'BILL-001',
        tableNumber: 5,
        items: [
          BillItem(
            name: 'Taco de Barbacoa',
            quantity: 3,
            price: 22.0,
            total: 66.0,
          ),
          BillItem(
            name: 'Consomé Grande',
            quantity: 1,
            price: 35.0,
            total: 35.0,
          ),
          BillItem(
            name: 'Agua de Horchata',
            quantity: 2,
            price: 18.0,
            total: 36.0,
          ),
        ],
        subtotal: 137.0,
        tax: 0.0,
        discount: 0.0,
        total: 137.0,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 240)),
        waiterName: 'Mesero',
      ),
      BillModel(
        id: 'BILL-002',
        tableNumber: 3,
        items: [
          BillItem(
            name: 'Mix Barbacoa',
            quantity: 1,
            price: 95.0,
            total: 95.0,
          ),
          BillItem(
            name: 'Taco de Carnitas',
            quantity: 2,
            price: 22.0,
            total: 44.0,
          ),
        ],
        subtotal: 139.0,
        tax: 0.0,
        discount: 6.95,
        total: 132.05,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 260)),
        waiterName: 'Mesero',
        waiterNotes: 'Separar cuenta para dos personas',
        isPrinted: true,
        printedBy: 'Ana Rodríguez',
        requestedByWaiter: true,
      ),
      BillModel(
        id: 'BILL-003',
        items: [
          BillItem(
            name: 'Quesadilla de Barbacoa',
            quantity: 2,
            price: 40.0,
            total: 80.0,
          ),
          BillItem(
            name: 'Refresco',
            quantity: 2,
            price: 12.0,
            total: 24.0,
          ),
        ],
        subtotal: 104.0,
        tax: 0.0,
        discount: 0.0,
        total: 104.0,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 180)),
        isTakeaway: true,
        customerName: 'Jahir',
        customerPhone: '55 1234 5678',
        waiterName: 'Mesero',
      ),
    ]);
  }
}

