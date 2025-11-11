import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_repository.dart';
import '../services/bill_repository.dart';

class CajeroController extends ChangeNotifier {
  CajeroController({
    required PaymentRepository paymentRepository,
    required BillRepository billRepository,
  })  : _paymentRepository = paymentRepository,
        _billRepository = billRepository {
    _paymentRepository.addListener(_handlePaymentsChanged);
    _billRepository.addListener(_handleBillsChanged);
    _initializeData();
  }

  final PaymentRepository _paymentRepository;
  final BillRepository _billRepository;

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
  String _selectedShowFilter = 'Todos'; // 'Todos', 'Solo para llevar', 'Mesas'

  // Vista actual
  String _currentView = 'main';

  // Getters
  List<BillModel> get bills => _bills;
  List<PaymentModel> get payments => _payments;
  List<CashCloseModel> get cashClosures => _cashClosures;
  BillModel? get selectedBill => _selectedBill;
  String get selectedStatus => _selectedStatus;
  String get selectedPaymentType => _selectedPaymentType;
  String get selectedShowFilter => _selectedShowFilter;
  String get currentView => _currentView;

  // Obtener facturas filtradas
  List<BillModel> get filteredBills {
    return _bills.where((bill) {
      final statusMatch =
          _selectedStatus == 'todas' || bill.status == _selectedStatus;
      
      // Filtro por tipo (Todos, Solo para llevar, Mesas)
      final showMatch = _selectedShowFilter == 'Todos' ||
          (_selectedShowFilter == 'Solo para llevar' && bill.isTakeaway) ||
          (_selectedShowFilter == 'Mesas' && !bill.isTakeaway && bill.tableNumber != null);
      
      return statusMatch && showMatch && bill.status == BillStatus.pending;
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

  void _initializeData() {
    _bills = _billRepository.pendingBills;
    _payments = List.from(_paymentRepository.payments);

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

  // Cambiar filtro de mostrar
  void setSelectedShowFilter(String filter) {
    _selectedShowFilter = filter;
    notifyListeners();
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Procesar pago
  void processPayment(PaymentModel payment) {
    _paymentRepository.addPayment(payment);
    _billRepository.removeBill(payment.billId);

    notifyListeners();
  }

  // Marcar factura como impresa
  void markBillAsPrinted(
    String billId,
    String printedBy, {
    String? paymentId,
  }) {
    _billRepository.updateBill(
      billId,
      (bill) => bill.copyWith(
        isPrinted: true,
        printedBy: printedBy,
      ),
    );

    if (paymentId != null) {
      _paymentRepository.markAsPrinted(paymentId);
    }

    notifyListeners();
  }

  // Agregar nueva factura
  void addBill(BillModel bill) {
    _billRepository.addBill(bill);
  }

  // Cancelar factura
  void cancelBill(String billId) {
    _billRepository.updateBill(
      billId,
      (bill) => bill.copyWith(status: BillStatus.cancelled),
    );
  }

  // Enviar cierre de caja
  void sendCashClose(CashCloseModel cashClose) {
    _cashClosures.insert(0, cashClose);
    notifyListeners();
  }

  void _handlePaymentsChanged() {
    _payments = List.from(_paymentRepository.payments);
    notifyListeners();
  }

  void _handleBillsChanged() {
    _bills = _billRepository.pendingBills;
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentRepository.removeListener(_handlePaymentsChanged);
    _billRepository.removeListener(_handleBillsChanged);
    super.dispose();
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
  // Cambio = efectivo recibido - total (sin restar propina)
  // La propina NO se descuenta del efectivo recibido
  double calculateChange(
    double totalAmount,
    double cashReceived,
    double tipAmount,
  ) {
    return cashReceived - totalAmount;
  }

  // Calcular efectivo aplicado al pago (para registro en cierre)
  // Efectivo aplicado = total + propina (para contar todo el dinero)
  double calculateCashApplied(
    double totalAmount,
    double tipAmount,
  ) {
    return totalAmount + tipAmount;
  }

  // Validar pago en efectivo
  bool validateCashPayment(
    double totalAmount,
    double cashReceived,
    double tipAmount,
  ) {
    // El efectivo recibido debe ser suficiente para cubrir el total
    return cashReceived >= totalAmount;
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
