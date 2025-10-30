import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class CajeroController extends ChangeNotifier {
  // Estado de las facturas
  List<BillModel> _bills = [];

  // Estado de los pagos
  List<PaymentModel> _payments = [];

  // Estado de los cierres de caja
  List<CashCloseModel> _cashClosures = [];

  // Factura seleccionada
  BillModel? _selectedBill;

  // Filtros
  String _selectedStatus = 'todas';
  String _selectedPaymentType = 'todas';

  // Vista actual
  String _currentView = 'main';

  // Getters
  List<BillModel> get bills => _bills;
  List<PaymentModel> get payments => _payments;
  List<CashCloseModel> get cashClosures => _cashClosures;
  BillModel? get selectedBill => _selectedBill;
  String get selectedStatus => _selectedStatus;
  String get selectedPaymentType => _selectedPaymentType;
  String get currentView => _currentView;

  // Obtener facturas filtradas
  List<BillModel> get filteredBills {
    return _bills.where((bill) {
      final statusMatch =
          _selectedStatus == 'todas' || bill.status == _selectedStatus;
      return statusMatch;
    }).toList();
  }

  // Obtener pagos filtrados
  List<PaymentModel> get filteredPayments {
    return _payments.where((payment) {
      final typeMatch =
          _selectedPaymentType == 'todas' ||
          payment.type == _selectedPaymentType;
      return typeMatch;
    }).toList();
  }

  CajeroController() {
    _initializeData();
  }

  void _initializeData() {
    // Inicializar facturas de ejemplo
    _bills = [
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
        tax: 22.0,
        total: 159.0,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      BillModel(
        id: 'BILL-002',
        tableNumber: 3,
        items: [
          BillItem(name: 'Mix Barbacoa', quantity: 1, price: 95.0, total: 95.0),
          BillItem(
            name: 'Taco de Carnitas',
            quantity: 2,
            price: 22.0,
            total: 44.0,
          ),
        ],
        subtotal: 139.0,
        tax: 22.0,
        total: 161.0,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      BillModel(
        id: 'BILL-003',
        tableNumber: null,
        items: [
          BillItem(
            name: 'Quesadilla de Barbacoa',
            quantity: 2,
            price: 40.0,
            total: 80.0,
          ),
          BillItem(name: 'Refresco', quantity: 3, price: 12.0, total: 36.0),
        ],
        subtotal: 116.0,
        tax: 19.0,
        total: 135.0,
        status: BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        isTakeaway: true,
        customerName: 'Jahir',
      ),
    ];

    // Inicializar pagos de ejemplo
    _payments = [
      PaymentModel(
        id: 'PAY-001',
        type: PaymentType.cash,
        totalAmount: 159.0,
        cashReceived: 200.0,
        tipAmount: 20.0,
        tipDelivered: true,
        cashApplied: 180.0,
        change: 21.0,
        notes: 'Pago en efectivo con propina',
        tableNumber: 5,
        billId: 'BILL-001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        cashierName: 'Juan Martínez',
      ),
    ];

    // Inicializar cierres de caja de ejemplo
    _cashClosures = [
      CashCloseModel(
        id: 'close_001',
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        periodo: 'Día',
        usuario: 'Juan Martínez',
        totalNeto: 2500.0,
        efectivo: 1500.0,
        tarjeta: 1000.0,
        propinasTarjeta: 150.0,
        propinasEfectivo: 100.0,
        pedidosParaLlevar: 5,
        estado: CashCloseStatus.approved,
        efectivoContado: 1500.0,
        totalTarjeta: 1000.0,
        otrosIngresos: 0.0,
        totalDeclarado: 2500.0,
        auditLog: [
          AuditLogEntry(
            id: 'log_001',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            action: 'enviado',
            usuario: 'Juan Martínez',
            mensaje: 'Cierre enviado por Juan Martínez',
          ),
          AuditLogEntry(
            id: 'log_002',
            timestamp: DateTime.now().subtract(
              const Duration(days: 1, hours: -2),
            ),
            action: 'aprobado',
            usuario: 'Admin',
            mensaje: 'Cierre aprobado por Admin',
          ),
        ],
      ),
    ];

    notifyListeners();
  }

  // Seleccionar factura
  void selectBill(BillModel bill) {
    _selectedBill = bill;
    notifyListeners();
  }

  // Cambiar filtro de estado
  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de tipo de pago
  void setSelectedPaymentType(String type) {
    _selectedPaymentType = type;
    notifyListeners();
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Procesar pago
  void processPayment(PaymentModel payment) {
    _payments.add(payment);

    // Actualizar estado de la factura
    _bills = _bills.map((bill) {
      if (bill.id == payment.billId) {
        return bill.copyWith(status: BillStatus.paid);
      }
      return bill;
    }).toList();

    notifyListeners();
  }

  // Agregar nueva factura
  void addBill(BillModel bill) {
    _bills.insert(0, bill);
    notifyListeners();
  }

  // Cancelar factura
  void cancelBill(String billId) {
    _bills = _bills.map((bill) {
      if (bill.id == billId) {
        return bill.copyWith(status: BillStatus.cancelled);
      }
      return bill;
    }).toList();
    notifyListeners();
  }

  // Enviar cierre de caja
  void sendCashClose(CashCloseModel cashClose) {
    _cashClosures.insert(0, cashClose);
    notifyListeners();
  }

  // Obtener estadísticas
  Map<String, double> getPaymentStats() {
    final today = DateTime.now();
    final todayPayments = _payments.where((payment) {
      return payment.timestamp.day == today.day &&
          payment.timestamp.month == today.month &&
          payment.timestamp.year == today.year;
    }).toList();

    double totalCash = 0;
    double totalCard = 0;
    double totalTips = 0;

    for (final payment in todayPayments) {
      if (payment.type == PaymentType.cash) {
        totalCash += payment.totalAmount;
        totalTips += payment.tipAmount ?? 0;
      } else if (payment.type == PaymentType.card) {
        totalCard += payment.totalAmount;
        totalTips += payment.tipAmount ?? 0;
      } else if (payment.type == PaymentType.mixed) {
        totalCash += payment.cashApplied ?? 0;
        totalCard += payment.totalAmount - (payment.cashApplied ?? 0);
        totalTips += payment.tipAmount ?? 0;
      }
    }

    return {
      'totalCash': totalCash,
      'totalCard': totalCard,
      'totalTips': totalTips,
      'total': totalCash + totalCard,
    };
  }

  // Obtener facturas pendientes
  List<BillModel> getPendingBills() {
    return _bills.where((bill) => bill.status == BillStatus.pending).toList();
  }

  // Obtener facturas pagadas
  List<BillModel> getPaidBills() {
    return _bills.where((bill) => bill.status == BillStatus.paid).toList();
  }

  // Obtener cierres pendientes
  List<CashCloseModel> getPendingClosures() {
    return _cashClosures
        .where(
          (closure) =>
              closure.estado == CashCloseStatus.pending ||
              closure.estado == CashCloseStatus.clarification,
        )
        .toList();
  }

  // Calcular cambio para pago en efectivo
  double calculateChange(
    double totalAmount,
    double cashReceived,
    double tipAmount,
  ) {
    final cashApplied = cashReceived - tipAmount;
    return cashApplied - totalAmount;
  }

  // Validar pago en efectivo
  bool validateCashPayment(
    double totalAmount,
    double cashReceived,
    double tipAmount,
  ) {
    final cashApplied = cashReceived - tipAmount;
    return cashApplied >= totalAmount;
  }

  // Obtener color de estado de factura
  Color getBillStatusColor(String status) {
    switch (status) {
      case BillStatus.pending:
        return Colors.orange;
      case BillStatus.paid:
        return Colors.green;
      case BillStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de estado de cierre
  Color getCashCloseStatusColor(String status) {
    switch (status) {
      case CashCloseStatus.pending:
        return Colors.orange;
      case CashCloseStatus.approved:
        return Colors.green;
      case CashCloseStatus.rejected:
        return Colors.red;
      case CashCloseStatus.clarification:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de tipo de pago
  Color getPaymentTypeColor(String type) {
    switch (type) {
      case PaymentType.cash:
        return Colors.green;
      case PaymentType.card:
        return Colors.blue;
      case PaymentType.mixed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Formatear fecha
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Formatear moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
