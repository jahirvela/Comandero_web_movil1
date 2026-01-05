import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pdf_widgets;
import '../models/payment_model.dart';
import '../models/admin_model.dart';
import '../services/payment_repository.dart';
import '../services/bill_repository.dart';
import '../services/pagos_service.dart';
import '../services/socket_service.dart';
import '../services/cierres_service.dart';
import '../services/tickets_service.dart';
import '../services/ordenes_service.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/file_download_helper.dart';

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

    // Escuchar actualizaciones de órdenes
    // CRÍTICO: NO refrescar automáticamente porque podría eliminar bills pendientes de pago
    // Los bills creados vía cuenta.enviada se mantienen hasta que se procese el pago real
    // Solo agregar nuevas bills si hay una orden nueva, pero NO eliminar las existentes
    socketService.onOrderUpdated((data) {
      try {
        final ordenId = data['ordenId'] as int?;
        final estadoNombre =
            (data['estadoNombre'] as String?)?.toLowerCase() ?? '';
        print('📄 Cajero: Orden $ordenId actualizada a estado: $estadoNombre');

        // CRÍTICO: NO refrescar automáticamente las bills desde el backend
        // porque esto podría eliminar bills pendientes que aún no se han cobrado
        // Las bills solo deben eliminarse cuando se procese el pago (onPaymentCreated)
        // o cuando se cancele explícitamente la orden
        if (estadoNombre.contains('cancel')) {
          // Solo si la orden fue cancelada, eliminar el bill correspondiente
          final billToRemove = _bills.firstWhere(
            (b) => b.ordenId == ordenId && b.status == BillStatus.pending,
            orElse: () => throw StateError('No bill found'),
          );
          _billRepository.removeBill(billToRemove.id);
          _bills = _billRepository.pendingBills;
          notifyListeners();
          print('✅ Cajero: Bill eliminado por cancelación de orden $ordenId');
        }
        // NO refrescar en otros casos para evitar eliminar bills pendientes
      } catch (e) {
        // Si no se encuentra el bill, no hacer nada (puede que ya fue eliminado)
        if (e is! StateError) {
          print('Error al procesar actualización de orden en cajero: $e');
        }
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

    // Escuchar eventos de pagos actualizados (NO duplicar con onPaymentCreated de más abajo)
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

    // Escuchar cuando se crea un pago (desde el backend después del cobro)
    // IMPORTANTE: Este listener se ejecuta cuando realmente se procesa un pago,
    // NO cuando solo se imprime un ticket. Aquí SÍ debemos eliminar el bill.
    socketService.onPaymentCreated((data) {
      try {
        final ordenId = data['ordenId'] as int?;
        final billId = data['billId'] as String?;

        // Actualizar lista de pagos primero
        _payments = List.from(_paymentRepository.payments);

        if (ordenId != null) {
          print(
            '💳 Cajero: Pago creado recibido - Orden $ordenId (procesando eliminación de bill)',
          );

          // Eliminar bill por ordenId o billId SOLO cuando realmente se procesó el pago
          if (billId != null) {
            _billRepository.removeBill(billId);
            print('✅ Cajero: Bill eliminado por billId: $billId');
          } else {
            // Buscar bill por ordenId
            try {
              final billToRemove = _bills.firstWhere(
                (b) => b.ordenId == ordenId && b.status == BillStatus.pending,
              );
              _billRepository.removeBill(billToRemove.id);
              print(
                '✅ Cajero: Bill eliminado por ordenId: $ordenId (billId: ${billToRemove.id})',
              );
            } catch (e) {
              print(
                '⚠️ Cajero: No se encontró bill pendiente para orden $ordenId (puede haber sido eliminado previamente)',
              );
            }
          }

          // Actualizar _bills y notificar
          _bills = _billRepository.pendingBills;
          notifyListeners();

          print('✅ Cajero: Bill eliminado después del cobro - Orden $ordenId');
        } else {
          // Si no hay ordenId, solo actualizar la lista de pagos
          notifyListeners();
        }
      } catch (e) {
        print('⚠️ Cajero: Error al procesar pago creado: $e');
        // NO refrescar automáticamente - solo refrescar manualmente si es necesario
        // refreshBills() podría eliminar bills pendientes incorrectamente
      }
    });

    // Escuchar eventos de cierres de caja (para actualización en tiempo real)
    socketService.onCashClosureCreated((data) {
      try {
        print('💰 Cajero: Evento cierre.creado recibido');
        // Recargar cierres para obtener la apertura actualizada
        loadCashClosures();
      } catch (e) {
        print('Error al procesar cierre creado en cajero: $e');
      }
    });

    socketService.onCashClosureUpdated((data) {
      try {
        print('💰 Cajero: Evento cierre.actualizado recibido');
        // Recargar cierres para obtener la apertura actualizada
        loadCashClosures();
      } catch (e) {
        print('Error al procesar cierre actualizado en cajero: $e');
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
  /// IMPORTANTE: Este método solo agrega nuevas bills, NO elimina las existentes pendientes
  /// Las bills solo se eliminan cuando se procesa el pago o se cancela la orden
  Future<void> refreshBills() async {
    try {
      print(
        '🔄 Cajero: Refrescando bills desde backend (solo agregando nuevas, preservando pendientes)...',
      );

      // Guardar las bills pendientes existentes antes de cargar
      final billsPendientesExistentes = _bills
          .where((b) => b.status == BillStatus.pending)
          .toList();

      // Cargar bills desde el backend (esto puede agregar nuevas, pero preservará las pendientes)
      await _billRepository.loadBills();

      // Obtener todas las bills después de cargar
      final todasLasBills = _billRepository.bills;

      // CRÍTICO: Restaurar bills pendientes que fueron eliminadas incorrectamente
      // PERO solo si las órdenes NO están pagadas O fueron creadas recientemente (enviadas al cajero)
      // Esto asegura que las bills creadas vía cuenta.enviada no desaparezcan
      // pero evita restaurar bills de órdenes ya cobradas anteriormente
      int billsRestauradas = 0;

      // Obtener órdenes del backend para verificar su estado
      final ordenesService = OrdenesService();
      final ordenes = await ordenesService.getOrdenes();
      final ahora = DateTime.now();

      for (final billExistente in billsPendientesExistentes) {
        // Verificar si la bill ya no existe en el repositorio
        if (!todasLasBills.any((b) => b.id == billExistente.id)) {
          // Verificar si la orden está pagada y fue creada hace más de 5 minutos
          // (lo que indicaría que ya fue cobrada anteriormente, no recién enviada)
          bool debeRestaurar = true;

          if (billExistente.ordenId != null) {
            final ordenData = ordenes.firstWhere(
              (o) => o['id'] == billExistente.ordenId,
              orElse: () => <String, dynamic>{},
            );

            if (ordenData.isNotEmpty) {
              final estadoNombre =
                  (ordenData['estadoNombre'] as String?)?.toLowerCase() ?? '';

              if (estadoNombre.contains('pagada')) {
                // Verificar cuándo fue creada la orden
                final creadoEnStr = ordenData['creadoEn'] as String?;
                if (creadoEnStr != null) {
                  try {
                    final creadoEn = date_utils.AppDateUtils.parseToLocal(
                      creadoEnStr,
                    );
                    final diferenciaMinutos = ahora
                        .difference(creadoEn)
                        .inMinutes;

                    // Si la orden fue creada hace más de 5 minutos y está pagada,
                    // significa que ya fue cobrada anteriormente, NO restaurar
                    if (diferenciaMinutos > 5) {
                      debeRestaurar = false;
                      print(
                        '⚠️ Cajero: NO restaurando bill ${billExistente.id} - Orden ${billExistente.ordenId} pagada hace más de 5 minutos (fue cobrada anteriormente)',
                      );
                    } else {
                      // Orden pagada pero creada recientemente, probablemente fue enviada al cajero
                      print(
                        '✅ Cajero: Restaurando bill ${billExistente.id} - Orden ${billExistente.ordenId} pagada pero creada recientemente (enviada al cajero)',
                      );
                    }
                  } catch (e) {
                    // Si no se puede parsear la fecha, restaurar por seguridad
                    print(
                      '⚠️ Cajero: No se pudo parsear fecha de orden ${billExistente.ordenId}, restaurando bill por seguridad',
                    );
                  }
                } else {
                  // Sin fecha de creación, NO restaurar si está pagada
                  debeRestaurar = false;
                  print(
                    '⚠️ Cajero: NO restaurando bill ${billExistente.id} - Orden ${billExistente.ordenId} pagada sin fecha de creación',
                  );
                }
              }
            }
          }

          if (debeRestaurar) {
            // Esta bill pendiente fue eliminada incorrectamente, restaurarla
            _billRepository.addBill(billExistente);
            billsRestauradas++;
            print(
              '🔄 Cajero: Restaurando bill pendiente eliminada: ${billExistente.id}',
            );
          }
        }
      }

      // Actualizar la lista de bills
      _bills = _billRepository.pendingBills;
      notifyListeners();

      if (billsRestauradas > 0) {
        print('✅ Cajero: $billsRestauradas bills pendientes restauradas');
      }
      print(
        '✅ Cajero: ${_bills.length} bills pendientes (${_bills.map((b) => b.id).join(", ")})',
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

      // CRÍTICO: Extraer todos los ordenIds si es una cuenta agrupada
      final ordenIdsCompletos = bill.ordenIdsFromBillIdInt;
      final esCuentaAgrupada = ordenIdsCompletos.length > 1;

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
        'ordenId': ordenId, // Orden principal
        'formaPagoId': formaPagoId, // Ya es int
        'monto': payment.totalAmount
            .toDouble(), // Monto total de la cuenta agrupada
        'estado': 'aplicado',
      };

      // Si es cuenta agrupada, incluir todos los ordenIds para que el backend procese todas las órdenes
      if (esCuentaAgrupada) {
        pagoData['ordenIds'] = ordenIdsCompletos;
        print(
          '💳 Cajero: Procesando pago de cuenta agrupada - ${ordenIdsCompletos.length} órdenes: $ordenIdsCompletos',
        );
      }

      // Agregar fechaPago en formato ISO datetime válido
      // IMPORTANTE: payment.timestamp ya está en CDMX, convertir a UTC para el backend
      // El backend espera formato ISO 8601 con timezone UTC (ej: 2024-01-01T12:00:00.000Z)
      final fechaUtc = payment.timestamp.isUtc
          ? payment.timestamp
          : payment.timestamp.toUtc();
      final fechaIso = fechaUtc.toIso8601String();
      // Asegurar que tenga timezone Z para UTC
      if (!fechaIso.endsWith('Z')) {
        pagoData['fechaPago'] = fechaIso.endsWith('Z')
            ? fechaIso
            : '${fechaIso}Z';
      } else {
        pagoData['fechaPago'] = fechaIso;
      }

      // Agregar referencia solo si tiene valor (no enviar null explícitamente)
      // Para pagos con tarjeta, usar transactionId o authorizationCode como referencia
      String? referencia;
      if (payment.type.toLowerCase().contains('card') ||
          payment.type.toLowerCase().contains('tarjeta')) {
        // Para tarjeta, incluir información de débito/crédito
        final cardTypeLabel = payment.cardMethod == 'debito'
            ? 'Tarjeta Débito'
            : (payment.cardMethod == 'credito' ? 'Tarjeta Crédito' : 'Tarjeta');

        // Construir referencia con tipo de tarjeta y detalles de transacción
        final List<String> referenciaParts = [cardTypeLabel];

        if (payment.transactionId != null &&
            payment.transactionId!.isNotEmpty) {
          referenciaParts.add('TX: ${payment.transactionId}');
        }

        if (payment.authorizationCode != null &&
            payment.authorizationCode!.isNotEmpty) {
          referenciaParts.add('Auth: ${payment.authorizationCode}');
        }

        if (payment.last4Digits != null && payment.last4Digits!.isNotEmpty) {
          referenciaParts.add('****${payment.last4Digits}');
        }

        referencia = referenciaParts.join(' - ');

        // Si no hay información de transacción, usar solo el tipo de tarjeta
        if (referencia == cardTypeLabel &&
            payment.notes != null &&
            payment.notes!.isNotEmpty) {
          referencia = '$cardTypeLabel - ${payment.notes}';
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

      // Actualizar _bills inmediatamente después de eliminar
      // NO llamar a loadBills() aquí porque puede eliminar bills pendientes que aún deberían estar visibles
      // Solo actualizar la lista local de bills pendientes
      _bills = _billRepository.pendingBills;
      notifyListeners();

      // Emitir evento Socket para notificar al admin en tiempo real
      final socketService = SocketService();
      socketService.emit('pago.creado', {
        'ordenId': ordenId,
        'ordenIds': esCuentaAgrupada
            ? ordenIdsCompletos
            : null, // Incluir todos los ordenIds si es cuenta agrupada
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
      print(
        '📢 Cajero: Evento pago.creado emitido para orden $ordenId${esCuentaAgrupada ? ' (cuenta agrupada: ${ordenIdsCompletos.length} órdenes)' : ''}',
      );

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
    // Obtener el bill para verificar si es una cuenta agrupada
    final bill = _billRepository.getBill(billId);

    // Si hay ordenId, imprimir el ticket en el backend
    if (ordenId != null || bill != null) {
      try {
        final ticketsService = TicketsService();

        // Extraer todos los ordenIds del billId si es una cuenta agrupada
        final ordenIdsCompletos = <int>[];
        if (bill != null) {
          ordenIdsCompletos.addAll(bill.ordenIdsFromBillIdInt);
        }

        // Si no se pudieron extraer del billId pero tenemos ordenId, usarlo
        final ordenIdPrincipal =
            ordenId ??
            (ordenIdsCompletos.isNotEmpty ? ordenIdsCompletos.first : null);

        if (ordenIdPrincipal != null) {
          // Si hay múltiples ordenIds (cuenta agrupada), enviarlos todos para que el ticket muestre todos los productos
          final result = await ticketsService.imprimirTicket(
            ordenId: ordenIdPrincipal,
            ordenIds: ordenIdsCompletos.length > 1 ? ordenIdsCompletos : null,
            incluirCodigoBarras: true,
          );

          if (!result['success']) {
            print('Error al imprimir ticket: ${result['error']}');
            // Continuar de todas formas para marcar como impreso localmente
          } else {
            print(
              '✅ Cajero: Ticket impreso correctamente${ordenIdsCompletos.length > 1 ? ' (${ordenIdsCompletos.length} órdenes agrupadas)' : ''}',
            );
          }
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
        efectivoInicial: efectivoInicial,
      );

      // Enviar al backend (el backend manejará que es una apertura si efectivoFinal es igual a efectivoInicial y totalPagos es 0)
      await cierresService.crearCierreCaja(apertura);

      // Recargar cierres para obtener la apertura actualizada
      await loadCashClosures();

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

    // Obtener la fecha de referencia: última apertura de caja del día o último cierre con ventas
    DateTime? fechaReferencia;

    // Buscar la última apertura de caja del día
    final apertura = getTodayCashOpening();
    if (apertura != null) {
      fechaReferencia = apertura.fecha;
    }

    // Buscar el último cierre de caja con ventas del día (más reciente que la apertura)
    final hoy = DateTime.now();
    final cierresConVentas = _cashClosures.where((cierre) {
      final esHoy =
          cierre.fecha.year == hoy.year &&
          cierre.fecha.month == hoy.month &&
          cierre.fecha.day == hoy.day;

      // Verificar que sea un cierre con ventas (no una apertura)
      final esCierreConVentas = cierre.totalNeto > 0;

      return esHoy && esCierreConVentas;
    }).toList();

    if (cierresConVentas.isNotEmpty) {
      // Ordenar por fecha descendente y tomar el más reciente
      cierresConVentas.sort((a, b) => b.fecha.compareTo(a.fecha));
      final ultimoCierre = cierresConVentas.first;

      // Si hay una apertura, usar la fecha más reciente entre apertura y último cierre
      if (fechaReferencia != null) {
        fechaReferencia = ultimoCierre.fecha.isAfter(fechaReferencia)
            ? ultimoCierre.fecha
            : fechaReferencia;
      } else {
        fechaReferencia = ultimoCierre.fecha;
      }
    }

    // Filtrar pagos del día actual Y posteriores a la fecha de referencia
    final todayPayments = _payments.where((payment) {
      final esHoy =
          payment.timestamp.day == today.day &&
          payment.timestamp.month == today.month &&
          payment.timestamp.year == today.year;

      // Si hay una fecha de referencia (apertura o último cierre), solo incluir pagos posteriores
      if (fechaReferencia != null) {
        return esHoy && payment.timestamp.isAfter(fechaReferencia);
      }

      // Si no hay fecha de referencia, mostrar todos los pagos del día
      return esHoy;
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

  // Obtener la apertura de caja del día actual
  // Una apertura se identifica por: efectivoInicial > 0 y totalNeto = 0 (o muy bajo) y numeroOrdenes = 0
  CashCloseModel? getTodayCashOpening() {
    final hoy = DateTime.now();
    final aperturas = _cashClosures.where((cierre) {
      // Verificar que sea del día de hoy
      final esHoy =
          cierre.fecha.year == hoy.year &&
          cierre.fecha.month == hoy.month &&
          cierre.fecha.day == hoy.day;

      // Verificar que sea una apertura: tiene efectivo inicial y no tiene ventas significativas
      final esApertura =
          cierre.efectivoInicial > 0 &&
          (cierre.totalNeto == 0 || cierre.totalNeto < 1.0) &&
          cierre.pedidosParaLlevar == 0;

      return esHoy && esApertura;
    }).toList();

    // Retornar la más reciente (última apertura del día)
    if (aperturas.isEmpty) return null;

    aperturas.sort((a, b) => b.fecha.compareTo(a.fecha));
    return aperturas.first;
  }

  // Verificar si la caja está abierta hoy
  bool isCashRegisterOpen() {
    final apertura = getTodayCashOpening();
    if (apertura == null) return false; // No hay apertura, caja cerrada

    final hoy = DateTime.now();
    // Buscar cierres de caja del día con ventas significativas (totalNeto > 0)
    // que sean más recientes que la apertura
    final cierresConVentas = _cashClosures.where((cierre) {
      final esHoy =
          cierre.fecha.year == hoy.year &&
          cierre.fecha.month == hoy.month &&
          cierre.fecha.day == hoy.day;

      // Verificar que sea un cierre con ventas (no una apertura)
      final esCierreConVentas =
          cierre.totalNeto > 0 &&
          cierre.fecha.isAfter(apertura.fecha); // Más reciente que la apertura

      return esHoy && esCierreConVentas;
    }).toList();

    // Si hay un cierre con ventas más reciente que la apertura, la caja está cerrada
    if (cierresConVentas.isNotEmpty) {
      // Ordenar por fecha descendente para obtener el más reciente
      cierresConVentas.sort((a, b) => b.fecha.compareTo(a.fecha));
      final cierreMasReciente = cierresConVentas.first;
      // Si el cierre más reciente tiene ventas, la caja está cerrada
      return cierreMasReciente.totalNeto <= 0;
    }

    // Si no hay cierres con ventas, la caja está abierta
    return true;
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
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case CashCloseStatus.pending:
      case 'pendiente':
        return Colors.orange;
      case CashCloseStatus.approved:
      case 'aprobado':
        return Colors.green;
      case CashCloseStatus.rejected:
      case 'rechazado':
        return Colors.red;
      case CashCloseStatus.clarification:
      case 'aclaración':
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

  // Exportar cierres de caja a CSV
  Future<void> exportCashClosuresToCSV() async {
    try {
      final hoy = DateTime.now();
      final cierresDelDia = _cashClosures.where((cierre) {
        return cierre.fecha.year == hoy.year &&
            cierre.fecha.month == hoy.month &&
            cierre.fecha.day == hoy.day;
      }).toList();

      // Ordenar por fecha descendente
      cierresDelDia.sort((a, b) => b.fecha.compareTo(a.fecha));

      // Construir contenido CSV
      final csvLines = <String>[];

      // Encabezados
      csvLines.add(
        'Fecha,Hora,Cajero,Total Ventas,Efectivo,Tarjeta,Otros Ingresos,Propinas,Estado,Efectivo Inicial,Notas',
      );

      // Datos
      for (final cierre in cierresDelDia) {
        final fecha = date_utils.AppDateUtils.formatDateTime(cierre.fecha);
        final fechaParts = fecha.split(' ');
        final fechaStr = fechaParts.isNotEmpty ? fechaParts[0] : '';
        final horaStr = fechaParts.length > 1 ? fechaParts[1] : '';

        final estadoStr = cierre.estado.toString().split('.').last;
        final notas = (cierre.notaCajero ?? '')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ');

        csvLines.add(
          [
            fechaStr,
            horaStr,
            cierre.usuario,
            cierre.totalNeto.toStringAsFixed(2),
            cierre.efectivo.toStringAsFixed(2),
            cierre.tarjeta.toStringAsFixed(2),
            cierre.otrosIngresos.toStringAsFixed(2),
            (cierre.propinasTarjeta + cierre.propinasEfectivo).toStringAsFixed(
              2,
            ),
            estadoStr,
            cierre.efectivoInicial.toStringAsFixed(2),
            notas,
          ].join(','),
        );
      }

      // Agregar resumen al final
      final stats = getPaymentStats();
      csvLines.add('');
      csvLines.add('RESUMEN DEL DÍA');
      csvLines.add(
        'Total Ventas,${stats['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
      );
      csvLines.add(
        'Total Efectivo,${stats['totalCash']?.toStringAsFixed(2) ?? '0.00'}',
      );
      csvLines.add(
        'Total Tarjeta,${stats['totalCard']?.toStringAsFixed(2) ?? '0.00'}',
      );
      csvLines.add(
        'Total Propinas,${(stats['totalCash'] ?? 0) * 0.1 + (stats['totalCard'] ?? 0) * 0.1}',
      );

      final csvContent = csvLines.join('\n');
      final filename =
          'cierres_caja_${hoy.year}_${hoy.month.toString().padLeft(2, '0')}_${hoy.day.toString().padLeft(2, '0')}.csv';

      // Descargar archivo usando helper
      await FileDownloadHelper.downloadCSV(csvContent, filename);
      print('✅ CSV exportado correctamente: $filename');
    } catch (e) {
      print('❌ Error al exportar CSV: $e');
      rethrow;
    }
  }

  // Generar PDF de cierres de caja
  Future<void> generateCashClosuresPDF() async {
    try {
      final hoy = DateTime.now();
      final cierresDelDia = _cashClosures.where((cierre) {
        return cierre.fecha.year == hoy.year &&
            cierre.fecha.month == hoy.month &&
            cierre.fecha.day == hoy.day;
      }).toList();

      // Ordenar por fecha descendente
      cierresDelDia.sort((a, b) => b.fecha.compareTo(a.fecha));

      final stats = getPaymentStats();
      final apertura = getTodayCashOpening();

      // Crear documento PDF
      final pdfDoc = pdf_widgets.Document();

      pdfDoc.addPage(
        pdf_widgets.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pdf_widgets.EdgeInsets.all(50),
          build: (pdf_widgets.Context context) {
            return [
              // Encabezado
              pdf_widgets.Header(
                level: 0,
                child: pdf_widgets.Row(
                  mainAxisAlignment: pdf_widgets.MainAxisAlignment.spaceBetween,
                  children: [
                    pdf_widgets.Text(
                      'Reporte de Cierres de Caja',
                      style: pdf_widgets.TextStyle(
                        fontSize: 24,
                        fontWeight: pdf_widgets.FontWeight.bold,
                      ),
                    ),
                    pdf_widgets.Text(
                      date_utils.AppDateUtils.formatDateTime(hoy),
                      style: const pdf_widgets.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pdf_widgets.SizedBox(height: 20.0),

              // Información de apertura
              if (apertura != null) ...[
                pdf_widgets.Padding(
                  padding: const pdf_widgets.EdgeInsets.all(10),
                  child: pdf_widgets.Container(
                    decoration: pdf_widgets.BoxDecoration(
                      border: pdf_widgets.Border.all(color: PdfColors.green),
                      borderRadius: const pdf_widgets.BorderRadius.all(
                        pdf_widgets.Radius.circular(5),
                      ),
                    ),
                    child: pdf_widgets.Column(
                      crossAxisAlignment: pdf_widgets.CrossAxisAlignment.start,
                      children: [
                        pdf_widgets.Text(
                          'Apertura de Caja',
                          style: pdf_widgets.TextStyle(
                            fontSize: 16,
                            fontWeight: pdf_widgets.FontWeight.bold,
                          ),
                        ),
                        pdf_widgets.SizedBox(height: 5.0),
                        pdf_widgets.Text('Cajero: ${apertura.usuario}'),
                        pdf_widgets.Text(
                          'Efectivo Inicial: ${formatCurrency(apertura.efectivoInicial)}',
                        ),
                        pdf_widgets.Text(
                          'Fecha: ${date_utils.AppDateUtils.formatDateTime(apertura.fecha)}',
                        ),
                        if (apertura.notaCajero != null &&
                            apertura.notaCajero!.isNotEmpty)
                          pdf_widgets.Text('Notas: ${apertura.notaCajero}'),
                      ],
                    ),
                  ),
                ),
                pdf_widgets.SizedBox(height: 20.0),
              ],

              // Resumen del día
              pdf_widgets.Padding(
                padding: const pdf_widgets.EdgeInsets.all(10),
                child: pdf_widgets.Container(
                  decoration: pdf_widgets.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: const pdf_widgets.BorderRadius.all(
                      pdf_widgets.Radius.circular(5),
                    ),
                  ),
                  child: pdf_widgets.Column(
                    crossAxisAlignment: pdf_widgets.CrossAxisAlignment.start,
                    children: [
                      pdf_widgets.Text(
                        'Resumen del Día',
                        style: pdf_widgets.TextStyle(
                          fontSize: 16,
                          fontWeight: pdf_widgets.FontWeight.bold,
                        ),
                      ),
                      pdf_widgets.SizedBox(height: 10.0),
                      pdf_widgets.Row(
                        mainAxisAlignment:
                            pdf_widgets.MainAxisAlignment.spaceBetween,
                        children: [
                          pdf_widgets.Text('Total Ventas:'),
                          pdf_widgets.Text(
                            formatCurrency(
                              (stats['totalSales'] as num?)?.toDouble() ?? 0.0,
                            ),
                            style: pdf_widgets.TextStyle(
                              fontWeight: pdf_widgets.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pdf_widgets.Row(
                        mainAxisAlignment:
                            pdf_widgets.MainAxisAlignment.spaceBetween,
                        children: [
                          pdf_widgets.Text('Total Efectivo:'),
                          pdf_widgets.Text(
                            formatCurrency(
                              (stats['totalCash'] as num?)?.toDouble() ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      pdf_widgets.Row(
                        mainAxisAlignment:
                            pdf_widgets.MainAxisAlignment.spaceBetween,
                        children: [
                          pdf_widgets.Text('Total Tarjeta:'),
                          pdf_widgets.Text(
                            formatCurrency(
                              (stats['totalCard'] as num?)?.toDouble() ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pdf_widgets.SizedBox(height: 20.0),

              // Tabla de cierres
              pdf_widgets.Text(
                'Cierres de Caja del Día',
                style: pdf_widgets.TextStyle(
                  fontSize: 18,
                  fontWeight: pdf_widgets.FontWeight.bold,
                ),
              ),
              pdf_widgets.SizedBox(height: 10.0),

              cierresDelDia.isEmpty
                  ? pdf_widgets.Text(
                      'No hay cierres de caja registrados para el día de hoy.',
                    )
                  : pdf_widgets.Table(
                      border: pdf_widgets.TableBorder.all(
                        color: PdfColors.grey,
                      ),
                      children: [
                        // Encabezados
                        pdf_widgets.TableRow(
                          decoration: const pdf_widgets.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Fecha/Hora',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Cajero',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Total',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Efectivo',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Tarjeta',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                            pdf_widgets.Padding(
                              padding: const pdf_widgets.EdgeInsets.all(5),
                              child: pdf_widgets.Text(
                                'Estado',
                                style: pdf_widgets.TextStyle(
                                  fontWeight: pdf_widgets.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Datos
                        for (final cierre in cierresDelDia)
                          pdf_widgets.TableRow(
                            children: [
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  date_utils.AppDateUtils.formatDateTime(
                                    cierre.fecha,
                                  ),
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  cierre.usuario,
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  formatCurrency(cierre.totalNeto),
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  formatCurrency(cierre.efectivo),
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  formatCurrency(cierre.tarjeta),
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  cierre.estado.toString().split('.').last,
                                  style: const pdf_widgets.TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

              pdf_widgets.SizedBox(height: 30.0),

              // Pie de página
              pdf_widgets.Divider(),
              pdf_widgets.Text(
                'Generado el ${date_utils.AppDateUtils.formatDateTime(DateTime.now())}',
                style: const pdf_widgets.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
                textAlign: pdf_widgets.TextAlign.center,
              ),
            ];
          },
        ),
      );

      // Mostrar diálogo de impresión/descarga
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfDoc.save(),
      );

      print('✅ PDF generado correctamente');
    } catch (e) {
      print('❌ Error al generar PDF: $e');
      rethrow;
    }
  }
}
