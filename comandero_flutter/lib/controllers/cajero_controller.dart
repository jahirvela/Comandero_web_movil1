import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../models/admin_model.dart';
import '../services/payment_repository.dart';
import '../services/bill_repository.dart';
import '../services/pagos_service.dart';
import '../services/socket_service.dart';
import '../services/cierres_service.dart';
import '../services/tickets_service.dart';
import '../utils/date_utils.dart' as date_utils;

class CajeroController extends ChangeNotifier {
  final PagosService _pagosService = PagosService();

  CajeroController({
    required PaymentRepository paymentRepository,
    required BillRepository billRepository,
  }) : _paymentRepository = paymentRepository,
       _billRepository = billRepository {
    _paymentRepository.addListener(_handlePaymentsChanged);
    _billRepository.addListener(_handleBillsChanged);
    _initializeAsync();
  }

  // Inicialización asíncrona para asegurar que todo se cargue correctamente
  Future<void> _initializeAsync() async {
    try {
      print('🔄 Cajero: Inicializando controlador...');

      // 1. Inicializar datos locales primero
      _bills = _billRepository.pendingBills;
      _payments = List.from(_paymentRepository.payments);
      _cashClosures = [];
      notifyListeners();

      // 2. Conectar Socket.IO ANTES de configurar listeners
      print('🔌 Cajero: Conectando Socket.IO...');
      try {
        final socketService = SocketService();
        if (!socketService.isConnected) {
          await socketService.connect();
          print('✅ Cajero: Socket.IO conectado exitosamente');
        } else {
          print('✅ Cajero: Socket.IO ya estaba conectado');
        }
      } catch (e) {
        print('⚠️ Cajero: Error al conectar Socket.IO (continuando): $e');
      }

      // 3. Configurar listeners DESPUÉS de conectar Socket.IO
      _setupSocketListeners();

      // 4. Cargar datos desde el backend
      await Future.wait([refreshBills(), loadCashClosures()]);

      print('✅ Cajero: Inicialización completada');
    } catch (e) {
      print('❌ Cajero: Error en inicialización: $e');
      // Aún así notificar cambios para que la UI se muestre
      notifyListeners();
    }
  }

  // Configurar listeners de Socket.IO
  void _setupSocketListeners() {
    final socketService = SocketService();

    // Escuchar nuevas órdenes (para crear facturas automáticamente)
    socketService.onOrderCreated((data) {
      try {
        // Recargar bills cuando se crea una nueva orden
        _bills = _billRepository.pendingBills;
        notifyListeners();
      } catch (e) {
        print('Error al procesar nueva orden en cajero: $e');
      }
    });

    // Escuchar actualizaciones de órdenes - refrescar desde backend
    socketService.onOrderUpdated((data) {
      try {
        print('📄 Cajero: Orden actualizada, refrescando bills...');
        refreshBills();
      } catch (e) {
        print('Error al procesar actualización de orden en cajero: $e');
      }
    });

    // Escuchar alertas de pago
    socketService.onAlertaPago((data) {
      try {
        // Recargar pagos cuando hay alertas
        _payments = List.from(_paymentRepository.payments);
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de pago: $e');
      }
    });

    // Escuchar alertas de caja
    socketService.onAlertaCaja((data) {
      try {
        // Recargar cierres de caja cuando hay alertas
        // TODO: Implementar cuando se agregue el servicio de cierres
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de caja: $e');
      }
    });

    // Escuchar eventos de pagos
    socketService.onPaymentCreated((data) {
      try {
        // Recargar pagos cuando se crea un nuevo pago
        _payments = List.from(_paymentRepository.payments);
        _bills = _billRepository.pendingBills;
        notifyListeners();
      } catch (e) {
        print('Error al procesar pago creado en cajero: $e');
      }
    });

    socketService.onPaymentUpdated((data) {
      try {
        // Recargar pagos cuando se actualiza un pago
        _payments = List.from(_paymentRepository.payments);
        _bills = _billRepository.pendingBills;
        notifyListeners();
      } catch (e) {
        print('Error al procesar pago actualizado en cajero: $e');
      }
    });

    // Escuchar actualizaciones de cierres de caja (para aclaraciones, aprobaciones, etc.)
    socketService.onCashClosureUpdated((data) {
      try {
        final cierreIdStr = data['id']?.toString() ?? '';
        print(
          '💰 Cajero: Cierre de caja actualizado - ID: $cierreIdStr, Estado: ${data['status']}',
        );

        // Si es una aclaración, mostrar notificación destacada
        final estado = (data['status'] as String?)?.toLowerCase() ?? '';
        final comentarioRevision = data['comentarioRevision'] as String?;

        if (estado == 'clarification' &&
            comentarioRevision != null &&
            comentarioRevision.isNotEmpty) {
          print('⚠️ Cajero: Aclaración solicitada para cierre $cierreIdStr');
          print('📝 Comentario: $comentarioRevision');
          // Recargar cierres para mostrar el nuevo estado
          loadCashClosures();
        } else {
          // Para otros estados (aprobado, rechazado), también recargar
          loadCashClosures();
        }

        notifyListeners();
      } catch (e) {
        print('Error al procesar actualización de cierre en cajero: $e');
      }
    });

    // Escuchar cuando se envía una cuenta desde el mesero
    socketService.on('cuenta.enviada', (data) {
      try {
        final billId =
            data['id'] as String? ??
            'BILL-${date_utils.AppDateUtils.now().millisecondsSinceEpoch}';
        print('📄 Cajero: Cuenta recibida en tiempo real: $billId');

        // IMPORTANTE: Verificar duplicados por billId, no solo por ordenId
        // Esto permite manejar bills con múltiples órdenes agrupadas
        final existingBill = _billRepository.bills
            .where((b) => b.id == billId && b.status == BillStatus.pending)
            .toList();
        if (existingBill.isNotEmpty) {
          print('⚠️ Cajero: Ya existe bill pendiente con ID $billId');
          return;
        }

        // Crear bill INMEDIATAMENTE desde los datos del evento
        final ordenId = data['ordenId'] as int?;
        final ordenIds = data['ordenIds'] as List<dynamic>?;
        final multipleOrders = data['multipleOrders'] as bool? ?? false;

        if (multipleOrders && ordenIds != null) {
          print(
            '📋 Cajero: Bill con ${ordenIds.length} órdenes agrupadas: $ordenIds',
          );
        }

        // Crear items desde los datos del evento
        final items =
            (data['items'] as List<dynamic>?)?.map((item) {
              return BillItem(
                name: item['name'] as String? ?? 'Producto',
                quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
                total: (item['total'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList() ??
            [];

        final bill = BillModel(
          id: billId, // Usar el billId del evento (puede ser único para múltiples órdenes)
          tableNumber: data['tableNumber'] as int?,
          ordenId: ordenId, // Orden principal para compatibilidad
          items: items,
          subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
          tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
          status: BillStatus.pending,
          createdAt: data['createdAt'] != null
              ? date_utils.AppDateUtils.parseToLocal(data['createdAt'])
              : date_utils.AppDateUtils.now(),
          waiterName: data['waiterName'] as String? ?? 'Mesero',
          requestedByWaiter: true,
          splitCount: (data['splitCount'] as num?)?.toInt() ?? 1,
          isTakeaway: data['isTakeaway'] as bool? ?? false,
          customerName: data['customerName'] as String?,
          customerPhone: data['customerPhone'] as String?,
          waiterNotes: data['waiterNotes'] as String?,
        );

        // Agregar al repositorio local
        _billRepository.addBill(bill);
        _bills = _billRepository.pendingBills;
        notifyListeners();

        final ordenCount = multipleOrders && ordenIds != null
            ? ordenIds.length
            : 1;
        print(
          '✅ Cajero: Bill creado - ${bill.id} para mesa ${bill.tableNumber}, $ordenCount orden(es), total: \$${bill.total}',
        );
      } catch (e, stackTrace) {
        print('❌ Error al procesar cuenta enviada: $e');
        print('Stack trace: $stackTrace');
      }
    });
  }

  /// Refrescar bills desde el backend (método público para llamar manualmente)
  Future<void> refreshBills() async {
    try {
      print('🔄 Cajero: Refrescando bills desde backend...');
      await _billRepository.loadBills();
      _bills = _billRepository.pendingBills;
      notifyListeners();
      print(
        '✅ Cajero: ${_bills.length} bills cargados (${_bills.map((b) => b.id).join(", ")})',
      );
    } catch (e, stackTrace) {
      print('❌ Error al refrescar bills: $e');
      print('Stack trace: $stackTrace');
      // Aún así notificar cambios para que la UI se muestre
      notifyListeners();
    }
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
    final filtered = _bills.where((bill) {
      final statusMatch =
          _selectedStatus == 'todas' || bill.status == _selectedStatus;

      // Filtro por tipo (Todos, Solo para llevar, Mesas)
      final showMatch =
          _selectedShowFilter == 'Todos' ||
          (_selectedShowFilter == 'Solo para llevar' && bill.isTakeaway) ||
          (_selectedShowFilter == 'Mesas' &&
              !bill.isTakeaway &&
              bill.tableNumber != null);

      final isPending = bill.status == BillStatus.pending;
      final result = statusMatch && showMatch && isPending;

      if (!result && bill.status == BillStatus.pending) {
        print(
          '⚠️ Cajero: Bill ${bill.id} filtrado - statusMatch: $statusMatch, showMatch: $showMatch, isPending: $isPending',
        );
      }

      return result;
    }).toList();

    print(
      '📊 Cajero: filteredBills - Total bills: ${_bills.length}, Filtrados: ${filtered.length}, Status seleccionado: $_selectedStatus, Show seleccionado: $_selectedShowFilter',
    );
    return filtered;
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

  // Cargar cierres de caja desde el backend
  Future<void> loadCashClosures() async {
    try {
      print('🔄 Cajero: Cargando cierres de caja desde backend...');
      final cierresService = CierresService();
      final cierres = await cierresService.listarCierresCaja();
      _cashClosures = cierres;
      notifyListeners();
      print('✅ Cajero: ${cierres.length} cierres cargados desde el backend');
    } catch (e, stackTrace) {
      print('❌ Error al cargar cierres de caja: $e');
      print('Stack trace: $stackTrace');
      // Aún así notificar cambios para que la UI se muestre
      _cashClosures = [];
      notifyListeners();
    }
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
  Future<void> processPayment(PaymentModel payment) async {
    try {
      // Obtener formas de pago disponibles
      final formasPago = await _pagosService.getFormasPago();

      // Mapear tipo de pago del frontend a formaPagoId del backend
      int? formaPagoId;
      final tipoLower = payment.type.toLowerCase();

      if (tipoLower.contains('cash') || tipoLower.contains('efectivo')) {
        final forma = formasPago.firstWhere(
          (f) =>
              (f['nombre'] as String).toLowerCase().contains('efectivo') ||
              (f['nombre'] as String).toLowerCase().contains('cash'),
          orElse: () => formasPago.isNotEmpty ? formasPago[0] : {'id': 1},
        );
        formaPagoId = forma['id'] as int;
      } else if (tipoLower.contains('card') || tipoLower.contains('tarjeta')) {
        final forma = formasPago.firstWhere(
          (f) =>
              (f['nombre'] as String).toLowerCase().contains('tarjeta') ||
              (f['nombre'] as String).toLowerCase().contains('card'),
          orElse: () => formasPago.isNotEmpty ? formasPago[0] : {'id': 2},
        );
        formaPagoId = forma['id'] as int;
      } else if (tipoLower.contains('mixed') || tipoLower.contains('mixto')) {
        // Para pagos mixtos, crear múltiples pagos o usar la primera forma disponible
        formaPagoId = formasPago.isNotEmpty ? formasPago[0]['id'] as int : 1;
      }

      if (formaPagoId == null) {
        throw Exception('Forma de pago no encontrada: ${payment.type}');
      }

      // Obtener el ordenId del bill
      final bill = _billRepository.getBill(payment.billId);
      if (bill == null) {
        throw Exception('Bill no encontrado: ${payment.billId}');
      }

      // El ordenId debe estar en el bill (se agrega cuando se crea la orden)
      final ordenId = bill.ordenId;
      if (ordenId == null) {
        throw Exception(
          'El bill no tiene un ordenId asociado. BillId: ${payment.billId}',
        );
      }

      // Preparar datos del pago para el backend
      // Validar que los datos requeridos estén presentes
      if (ordenId <= 0) {
        throw Exception('ordenId inválido: $ordenId');
      }
      if (formaPagoId <= 0) {
        throw Exception('formaPagoId inválido: $formaPagoId');
      }
      if (payment.totalAmount <= 0) {
        throw Exception('monto inválido: ${payment.totalAmount}');
      }

      // Construir pagoData - asegurar tipos correctos
      // El backend espera números para ordenId, formaPagoId y monto
      final pagoData = <String, dynamic>{
        'ordenId': ordenId, // Ya es int
        'formaPagoId': formaPagoId, // Ya es int
        'monto': payment.totalAmount.toDouble(), // Asegurar que sea double
        'estado': 'aplicado',
      };

      // Agregar fechaPago en formato ISO datetime válido
      // IMPORTANTE: payment.timestamp ya está en CDMX, convertir a UTC para el backend
      // El backend espera formato ISO 8601 con timezone UTC (ej: 2024-01-01T12:00:00.000Z)
      final fechaUtc = payment.timestamp.isUtc 
          ? payment.timestamp 
          : payment.timestamp.toUtc();
      final fechaIso = fechaUtc.toIso8601String();
      // Asegurar que tenga timezone Z para UTC
      if (!fechaIso.endsWith('Z')) {
        pagoData['fechaPago'] = fechaIso.endsWith('Z') ? fechaIso : '${fechaIso}Z';
      } else {
        pagoData['fechaPago'] = fechaIso;
      }

      // Agregar referencia solo si tiene valor (no enviar null explícitamente)
      // Para pagos con tarjeta, usar transactionId o authorizationCode como referencia
      String? referencia;
      if (payment.type.toLowerCase().contains('card') ||
          payment.type.toLowerCase().contains('tarjeta')) {
        // Para tarjeta, priorizar transactionId, luego authorizationCode, luego notes
        referencia =
            payment.transactionId ?? payment.authorizationCode ?? payment.notes;

        // Si hay transactionId y authorizationCode, combinarlos
        if (payment.transactionId != null &&
            payment.authorizationCode != null) {
          referencia =
              '${payment.transactionId} - Auth: ${payment.authorizationCode}';
        }
      } else {
        // Para efectivo, usar notes si está disponible
        referencia = payment.notes;
      }

      if (referencia != null &&
          referencia.isNotEmpty &&
          referencia.trim().isNotEmpty) {
        pagoData['referencia'] = referencia.trim();
      }

      print('💳 Cajero: Enviando pago al backend: $pagoData');
      print(
        '💳 Cajero: Tipos - ordenId: ${pagoData['ordenId'].runtimeType}, formaPagoId: ${pagoData['formaPagoId'].runtimeType}, monto: ${pagoData['monto'].runtimeType}',
      );

      // Registrar pago en BD
      await _pagosService.registrarPago(pagoData);

      // Si hay propina, registrarla también
      if (payment.tipAmount != null && payment.tipAmount! > 0) {
        try {
          await _pagosService.registrarPropina(ordenId, payment.tipAmount!);
        } catch (e) {
          print('Error al registrar propina: $e');
          // No lanzamos error, la propina es opcional
        }
      }

      // Actualizar repositorio local
      _paymentRepository.addPayment(payment);
      _billRepository.removeBill(payment.billId);

      // Recargar bills desde el backend para asegurar sincronización
      await _billRepository.loadBills();

      // Emitir evento Socket para notificar al admin en tiempo real
      final socketService = SocketService();
      socketService.emit('pago.creado', {
        'ordenId': ordenId,
        'billId': payment.billId,
        'monto': payment.totalAmount,
        'metodoPago': payment.type,
        'propina': payment.tipAmount ?? 0,
        'efectivoRecibido': payment.cashReceived,
        'cambio': payment.change ?? 0,
        'cajero': payment.cashierName,
        'timestamp': payment.timestamp.toIso8601String(),
        'tableNumber': payment.tableNumber,
      });
      print('📢 Cajero: Evento pago.creado emitido para orden $ordenId');

      notifyListeners();
      // Los pagos ya están guardados en la BD a través del servicio
    } catch (e) {
      print('Error al procesar pago: $e');
      rethrow;
    }
  }

  // Marcar factura como impresa e imprimir ticket
  Future<void> markBillAsPrinted(
    String billId,
    String printedBy, {
    String? paymentId,
    int? ordenId,
  }) async {
    // Si hay ordenId, imprimir el ticket en el backend
    if (ordenId != null) {
      try {
        final ticketsService = TicketsService();
        final result = await ticketsService.imprimirTicket(
          ordenId: ordenId,
          incluirCodigoBarras: true,
        );

        if (!result['success']) {
          print('Error al imprimir ticket: ${result['error']}');
          // Continuar de todas formas para marcar como impreso localmente
        }
      } catch (e) {
        print('Error al imprimir ticket: $e');
        // Continuar de todas formas para marcar como impreso localmente
      }
    }

    // Marcar como impreso localmente
    _billRepository.updateBill(
      billId,
      (bill) => bill.copyWith(isPrinted: true, printedBy: printedBy),
    );

    if (paymentId != null) {
      _paymentRepository.markAsPrinted(paymentId);
    }

    // Emitir evento Socket para notificar al admin en tiempo real
    final socketService = SocketService();
    socketService.emit('ticket.impreso', {
      'billId': billId,
      'ordenId': ordenId,
      'impresoPor': printedBy,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('📢 Cajero: Evento ticket.impreso emitido para orden $ordenId');

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

  // Apertura de caja - Registrar efectivo inicial
  Future<void> openCashRegister({
    required double efectivoInicial,
    String? nota,
  }) async {
    try {
      final cierresService = CierresService();
      // Crear un cierre con solo efectivo inicial (apertura)
      final apertura = CashCloseModel(
        id: 'open_${DateTime.now().millisecondsSinceEpoch}',
        fecha: DateTime.now(),
        periodo: 'Día',
        usuario: 'Cajero',
        totalNeto: 0,
        efectivo: efectivoInicial,
        tarjeta: 0,
        propinasTarjeta: 0,
        propinasEfectivo: 0,
        pedidosParaLlevar: 0,
        estado: CashCloseStatus.pending,
        efectivoContado: efectivoInicial,
        totalTarjeta: 0,
        otrosIngresos: 0,
        totalDeclarado: efectivoInicial,
        notaCajero: nota,
        auditLog: [],
      );

      // Enviar al backend (el backend manejará que es una apertura si efectivoFinal es igual a efectivoInicial y totalPagos es 0)
      await cierresService.crearCierreCaja(apertura);
      notifyListeners();
    } catch (e) {
      print('Error al registrar apertura de caja: $e');
      rethrow;
    }
  }

  // Enviar cierre de caja
  Future<void> sendCashClose(CashCloseModel cashClose) async {
    try {
      final cierresService = CierresService();
      // Enviar al backend
      final cierreCreado = await cierresService.crearCierreCaja(cashClose);
      // Agregar a la lista local
      _cashClosures.insert(0, cierreCreado);
      notifyListeners();
    } catch (e) {
      print('Error al enviar cierre de caja: $e');
      // Aún así agregar localmente para que el usuario vea el cierre
      _cashClosures.insert(0, cashClose);
      notifyListeners();
      rethrow;
    }
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
  double calculateCashApplied(double totalAmount, double tipAmount) {
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
    // Asegurarse de que la fecha esté en zona horaria local
    final localDate = date.isUtc ? date.toLocal() : date;
    return date_utils.AppDateUtils.formatDateTime(localDate);
  }

  // Formatear moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
