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
import '../services/configuracion_service.dart';
import '../config/api_config.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/file_download_helper.dart';

class CajeroController extends ChangeNotifier {
  final PagosService _pagosService = PagosService();
  final ConfiguracionService _configuracionService = ConfiguracionService();

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
      final socketService = SocketService();
      try {
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
      // Verificar que esté conectado antes de configurar
      if (socketService.isConnected) {
        _setupSocketListeners();
        print('✅ Cajero: Listeners de Socket.IO configurados');
      } else {
        print('⚠️ Cajero: Socket.IO no está conectado aún, esperando...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (socketService.isConnected) {
            _setupSocketListeners();
            print('✅ Cajero: Listeners de Socket.IO configurados después de esperar');
          } else {
            print('❌ Cajero: Socket.IO no se conectó, los listeners no se configuraron');
          }
        });
      }

      // 4. Cargar configuración (IVA habilitado para mostrar en cuentas por cobrar)
      try {
        final config = await _configuracionService.getConfiguracion();
        _ivaHabilitado = config.ivaHabilitado;
      } catch (_) {
        _ivaHabilitado = false;
      }

      // 5. Cargar datos desde el backend (bills, cierres y pagos para resumen e historial)
      await Future.wait([
        refreshBills(),
        loadCashClosures(),
        _loadPaymentsFromBackend(),
      ]);

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
    
    // Verificar que Socket.IO esté conectado antes de configurar listeners
    if (!socketService.isConnected) {
      print('⚠️ Cajero: Socket.IO no está conectado en _setupSocketListeners');
      return;
    }
    
    print('✅ Cajero: Socket.IO está conectado, configurando listeners...');
    print('📡 Cajero: URL de Socket.IO: ${ApiConfig.socketUrl}');

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

        // Cuenta dividida: parsear personAccounts si el mesero los envía
        final isDividedAccount = data['isDividedAccount'] as bool? ?? false;
        List<PersonAccount>? personAccounts;
        if (isDividedAccount) {
          final paList = data['personAccounts'] as List<dynamic>?;
          if (paList != null && paList.isNotEmpty) {
            personAccounts = paList
                .map((pa) => PersonAccount.fromJson(pa as Map<String, dynamic>))
                .toList();
          }
        }

        final bill = BillModel(
          id: billId, // Usar el billId del evento (puede ser único para múltiples órdenes)
          tableNumber: data['tableNumber'] is int ? data['tableNumber'] as int? : int.tryParse(data['tableNumber']?.toString() ?? ''),
          mesaCodigo: data['mesaCodigo'] as String?,
          ordenId: ordenId, // Orden principal para compatibilidad
          ordenIds: (data['ordenIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
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
          isDividedAccount: isDividedAccount,
          personAccounts: personAccounts,
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

      // Actualizar configuración (IVA) para reflejar cambios del administrador
      try {
        final config = await _configuracionService.getConfiguracion();
        _ivaHabilitado = config.ivaHabilitado;
      } catch (_) {}

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
      final ahora = date_utils.AppDateUtils.nowCdmx();

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

  // Configuración (IVA): cuando está habilitado se muestra la línea IVA en cada cuenta por cobrar
  bool _ivaHabilitado = false;

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

  // Último error de impresión (para mostrar en SnackBar al usuario)
  String? _lastPrintError;

  // Getters
  String? get lastPrintError => _lastPrintError;
  bool get ivaHabilitado => _ivaHabilitado;
  List<BillModel> get bills => _bills;
  List<PaymentModel> get payments => _payments;
  List<CashCloseModel> get cashClosures => _cashClosures;
  BillModel? get selectedBill => _selectedBill;
  String get selectedStatus => _selectedStatus;
  String get selectedPaymentType => _selectedPaymentType;
  String get selectedShowFilter => _selectedShowFilter;
  String get currentView => _currentView;

  /// Si IVA está habilitado y la cuenta tiene impuesto en 0, recalcula IVA (16%)
  /// para mostrarlo y cobrarlo en cuentas por cobrar (incluye cuentas divididas).
  /// Para cuentas divididas también actualiza cada PersonAccount con su IVA recalculado.
  BillModel _applyIvaSiHabilitado(BillModel bill) {
    if (!_ivaHabilitado) return bill;
    if (bill.tax.abs() >= 0.005) return bill; // ya tiene IVA a nivel bill
    final base = bill.subtotal - bill.discount;
    if (base <= 0) return bill;
    final recalcTax = (base * 0.16 * 100).round() / 100;
    final recalcTotal = ((base + recalcTax) * 100).round() / 100;

    // Si es cuenta dividida, recalcular IVA por persona para que el detalle muestre bien
    List<PersonAccount>? updatedPersonAccounts;
    if (bill.personAccounts != null && bill.personAccounts!.isNotEmpty) {
      updatedPersonAccounts = bill.personAccounts!.map((pa) {
        if (pa.tax.abs() >= 0.005) return pa;
        final paBase = pa.subtotal - pa.discount;
        if (paBase <= 0) return pa;
        final paTax = (paBase * 0.16 * 100).round() / 100;
        final paTotal = ((paBase + paTax) * 100).round() / 100;
        return pa.copyWith(tax: paTax, total: paTotal);
      }).toList();
    }

    return bill.copyWith(
      tax: recalcTax,
      total: recalcTotal,
      personAccounts: updatedPersonAccounts ?? bill.personAccounts,
    );
  }

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
    return filtered.map((b) => _applyIvaSiHabilitado(b)).toList();
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

  /// Carga los pagos desde el backend y actualiza el repositorio y _payments.
  /// Enriquece con nombre del mesero (creadoPorNombre) y mesa desde la orden.
  Future<void> _loadPaymentsFromBackend() async {
    try {
      final pagosData = await _pagosService.getPagos();
      final ordenesService = OrdenesService();
      final payments = <PaymentModel>[];
      for (final pagoData in pagosData) {
        try {
          final ordenId = pagoData['ordenId'] as int?;
          String? waiterName;
          int? tableNumber;
          if (ordenId != null) {
            try {
              final orden = await ordenesService.getOrden(ordenId);
              if (orden != null) {
                waiterName = (orden['creadoPorNombre'] as String?) ??
                    (orden['creadoPorUsuarioNombre'] as String?);
                final mesaId = orden['mesaId'];
                if (mesaId != null) {
                  tableNumber = mesaId is int ? mesaId : int.tryParse(mesaId.toString());
                }
              }
            } catch (e) {
              print('⚠️ Cajero: Error al obtener orden $ordenId: $e');
            }
          }
          final formaPagoNombre =
              (pagoData['formaPagoNombre'] as String? ?? '').toLowerCase();
          String paymentType = 'cash';
          if (formaPagoNombre.contains('tarjeta') ||
              formaPagoNombre.contains('card')) {
            paymentType = 'card';
          } else if (formaPagoNombre.contains('transfer')) {
            paymentType = 'transfer';
          } else if (formaPagoNombre.contains('mixto') ||
              formaPagoNombre.contains('mixed')) {
            paymentType = 'mixed';
          }
          final fechaPago = pagoData['fechaPago'] ?? pagoData['creadoEn'];
          final payment = PaymentModel(
            id: pagoData['id'].toString(),
            type: paymentType,
            totalAmount: (pagoData['monto'] as num?)?.toDouble() ?? 0.0,
            billId: 'BILL-${ordenId ?? pagoData['id']}',
            timestamp: date_utils.AppDateUtils.parseToLocal(fechaPago),
            cashierName: 'Sistema',
            ordenId: ordenId,
            waiterName: waiterName,
            tableNumber: tableNumber,
            notes: pagoData['referencia'] as String?,
            voucherPrinted:
                (pagoData['estado'] as String?)?.toLowerCase() == 'aplicado',
          );
          payments.add(payment);
        } catch (e) {
          print('⚠️ Cajero: Error al mapear pago ${pagoData['id']}: $e');
        }
      }
      _paymentRepository.addPayments(payments);
      _payments = List.from(_paymentRepository.payments);
      print('✅ Cajero: ${payments.length} pagos cargados desde backend');
    } catch (e) {
      print('❌ Cajero: Error al cargar pagos desde backend: $e');
    }
  }

  // Cargar cierres de caja desde el backend
  Future<void> loadCashClosures() async {
    try {
      print('🔄 Cajero: Cargando cierres de caja desde backend...');
      final cierresService = CierresService();
      // Cargar cierres de los últimos 7 días para asegurar que incluya la apertura de hoy
      final ahora = date_utils.AppDateUtils.now();
      final fechaInicio = ahora.subtract(const Duration(days: 7));
      final fechaFin = ahora;
      final cierres = await cierresService.listarCierresCaja(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      _cashClosures = cierres;
      print('✅ Cajero: ${cierres.length} cierres cargados desde el backend');
      // Debug: mostrar aperturas encontradas
      final apertura = getTodayCashOpening();
      if (apertura != null) {
        print('📋 Cajero: Apertura encontrada - ID: ${apertura.id}, Fecha: ${apertura.fecha}, Efectivo Inicial: ${apertura.efectivoInicial}');
      } else {
        print('⚠️ Cajero: No se encontró apertura de caja para hoy');
        print('📋 Cajero: Total de cierres cargados: ${cierres.length}');
        if (cierres.isNotEmpty) {
          print('📋 Cajero: Primer cierre - Fecha: ${cierres.first.fecha}, Efectivo Inicial: ${cierres.first.efectivoInicial}, Total Neto: ${cierres.first.totalNeto}');
        }
      }
      notifyListeners();
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

  // Obtener bill por ID
  BillModel? getBillById(String billId) {
    return _billRepository.getBill(billId);
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
  Future<void> processPayment(
    PaymentModel payment, {
    bool keepBillOpen = false,
    int? ordenIdOverride,
    List<int>? ordenIdsOverride,
  }) async {
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
      } else if (tipoLower.contains('transfer') || tipoLower.contains('transferencia')) {
        final forma = formasPago.firstWhere(
          (f) =>
              (f['nombre'] as String).toLowerCase().contains('transfer') ||
              (f['nombre'] as String)
                  .toLowerCase()
                  .contains('transferencia'),
          orElse: () => formasPago.isNotEmpty ? formasPago[0] : {'id': 3},
        );
        formaPagoId = forma['id'] as int;
        print('💳 CajeroController: Forma de pago transferencia encontrada: ${forma['nombre']} (ID: $formaPagoId)');
      } else if (tipoLower.contains('mixed') || tipoLower.contains('mixto')) {
        // Para pagos mixtos, crear múltiples pagos o usar la primera forma disponible
        formaPagoId = formasPago.isNotEmpty ? formasPago[0]['id'] as int : 1;
      }

      if (formaPagoId == null) {
        throw Exception('Forma de pago no encontrada: ${payment.type}');
      }

      // Obtener el ordenId - usar override si está disponible (para pagos mixtos)
      int? ordenId;
      List<int> ordenIdsCompletos;
      BillModel? billForMeta;
      
      if (ordenIdOverride != null) {
        // Usar el ordenId proporcionado (pago mixto)
        ordenId = ordenIdOverride;
        ordenIdsCompletos = (ordenIdsOverride != null && ordenIdsOverride.isNotEmpty) ? ordenIdsOverride : [ordenId];
        print('💳 CajeroController: Usando ordenId override: $ordenId (pago mixto)');
        // Intentar obtener bill para metadata (mesero/mesa)
        billForMeta = _billRepository.getBill(payment.billId);
      } else {
        // Obtener el ordenId del bill (flujo normal)
        print('💳 CajeroController: Buscando bill con ID: "${payment.billId}"');
        print('💳 CajeroController: Bills disponibles: ${_billRepository.bills.map((b) => b.id).toList()}');
        print('💳 CajeroController: keepBillOpen: $keepBillOpen');
        
        var bill = _billRepository.getBill(payment.billId);
        
        // Si el bill no está disponible pero keepBillOpen es true, podría ser un pago parcial
        // Intentar recargar los bills desde el backend
        if (bill == null && keepBillOpen) {
          print('⚠️ CajeroController: Bill no encontrado pero keepBillOpen=true, recargando bills...');
          try {
            await _billRepository.loadBills();
            bill = _billRepository.getBill(payment.billId);
          } catch (e) {
            print('❌ CajeroController: Error al recargar bills: $e');
          }
        }
        
        if (bill == null) {
          print('❌ CajeroController: Bill no encontrado. BillId recibido: "${payment.billId}"');
          print('❌ CajeroController: Tipo de pago: ${payment.type}, keepBillOpen: $keepBillOpen');
          throw Exception('Bill no encontrado: ${payment.billId}');
        }
        print('✅ CajeroController: Bill encontrado. OrdenId: ${bill.ordenId}');
        billForMeta = bill;

        // El ordenId debe estar en el bill (se agrega cuando se crea la orden)
        ordenId = bill.ordenId;
        if (ordenId == null) {
          throw Exception(
            'El bill no tiene un ordenId asociado. BillId: ${payment.billId}',
          );
        }

        // CRÍTICO: Extraer todos los ordenIds si es una cuenta agrupada
        ordenIdsCompletos = bill.ordenIdsFromBillIdInt;
      }
      final esCuentaAgrupada = ordenIdsCompletos.length > 1;

      // ENRIQUECER pago con metadata para historial (mesero/orden/mesa) antes de guardar
      final tableNumberForHistory = payment.tableNumber ?? billForMeta?.tableNumber;
      final waiterNameForHistory = payment.waiterName ?? billForMeta?.waiterName;
      final paymentEnriched = payment.copyWith(
        ordenId: ordenId,
        waiterName: waiterNameForHistory,
        tableNumber: tableNumberForHistory,
      );

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
      String? referencia;
      if (payment.type.toLowerCase().contains('transfer') ||
          payment.type.toLowerCase().contains('transferencia')) {
        // Transferencia: "Banco: X | Referencia: Y | Observaciones: Z" para ticket ordenado y sin duplicados
        final parts = <String>[];
        if (payment.bankName != null && payment.bankName!.trim().isNotEmpty) {
          parts.add('Banco: ${payment.bankName!.trim()}');
        }
        if (payment.reference != null && payment.reference!.trim().isNotEmpty) {
          parts.add('Referencia: ${payment.reference!.trim()}');
        }
        if (payment.notes != null && payment.notes!.trim().isNotEmpty) {
          parts.add('Observaciones: ${payment.notes!.trim()}');
        }
        referencia = parts.isEmpty ? null : parts.join(' | ');
      } else if (payment.type.toLowerCase().contains('card') ||
          payment.type.toLowerCase().contains('tarjeta')) {
        final cardTypeLabel = payment.cardMethod == 'debito'
            ? 'Tarjeta Débito'
            : (payment.cardMethod == 'credito'
                ? 'Tarjeta Crédito'
                : 'Tarjeta');
        final ref = payment.reference?.trim() ?? '';
        final hasRef = ref.isNotEmpty;
        final hasTx = payment.transactionId != null &&
            payment.transactionId!.isNotEmpty;
        final hasAuth = payment.authorizationCode != null &&
            payment.authorizationCode!.isNotEmpty;
        final hasLast4 = payment.last4Digits != null &&
            payment.last4Digits!.isNotEmpty;
        if (hasTx || hasAuth || hasLast4) {
          final list = <String>[cardTypeLabel];
          if (hasTx) list.add('TX: ${payment.transactionId}');
          if (hasAuth) list.add('Auth: ${payment.authorizationCode}');
          if (hasLast4) list.add('****${payment.last4Digits}');
          referencia = list.join(' - ');
        } else if (hasRef) {
          referencia = '$cardTypeLabel - Ref: $ref';
        } else {
          referencia = cardTypeLabel;
        }
        if (payment.notes != null && payment.notes!.trim().isNotEmpty) {
          referencia = '$referencia | Observaciones: ${payment.notes!.trim()}';
        }
      } else {
        // Efectivo u otros: solo texto; el backend añade "Observaciones:"
        referencia = payment.reference?.trim().isNotEmpty == true
            ? payment.reference!.trim()
            : payment.notes?.trim().isNotEmpty == true
                ? payment.notes!.trim()
                : null;
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
      _paymentRepository.addPayment(paymentEnriched);
      
      // Solo eliminar el bill si keepBillOpen es false (último pago)
      if (!keepBillOpen) {
        print('💳 CajeroController: Eliminando bill ${payment.billId} (último pago)');
        _billRepository.removeBill(payment.billId);

        // Actualizar _bills inmediatamente después de eliminar
        // NO llamar a loadBills() aquí porque puede eliminar bills pendientes que aún deberían estar visibles
        // Solo actualizar la lista local de bills pendientes
        _bills = _billRepository.pendingBills;
      } else {
        print('💳 CajeroController: Manteniendo bill ${payment.billId} abierto (pago parcial)');
      }
      notifyListeners();

      // Emitir evento Socket para notificar al admin en tiempo real
      final socketService = SocketService();
      final eventoPago = <String, dynamic>{
        'ordenId': ordenId,
        'ordenIds': esCuentaAgrupada
            ? ordenIdsCompletos
            : null, // Incluir todos los ordenIds si es cuenta agrupada
        'billId': paymentEnriched.billId,
        'monto': paymentEnriched.totalAmount,
        'metodoPago': paymentEnriched.type,
        'propina': paymentEnriched.tipAmount ?? 0,
        'efectivoRecibido': paymentEnriched.cashReceived,
        'cambio': paymentEnriched.change ?? 0,
        'cajero': paymentEnriched.cashierName,
        'timestamp': paymentEnriched.timestamp.toIso8601String(),
        'tableNumber': paymentEnriched.tableNumber,
        'waiterName': paymentEnriched.waiterName,
      };
      
      // Agregar información específica para transferencia
      if (paymentEnriched.type == PaymentType.transfer) {
        eventoPago['banco'] = paymentEnriched.bankName;
        eventoPago['referencia'] = paymentEnriched.reference;
        eventoPago['tipoPago'] = 'transferencia';
      }
      
      // Agregar información específica para tarjeta
      if (paymentEnriched.type == PaymentType.card) {
        eventoPago['terminal'] = paymentEnriched.terminal;
        eventoPago['metodoTarjeta'] = paymentEnriched.cardMethod;
        eventoPago['transactionId'] = paymentEnriched.transactionId;
        eventoPago['authorizationCode'] = paymentEnriched.authorizationCode;
        eventoPago['last4Digits'] = paymentEnriched.last4Digits;
        eventoPago['tipoPago'] = 'tarjeta';
      }
      
      // Agregar información específica para efectivo
      if (paymentEnriched.type == PaymentType.cash) {
        eventoPago['tipoPago'] = 'efectivo';
      }
      
      // Agregar información específica para mixto
      // Nota: Los pagos mixtos se procesan como pagos individuales (cash, card, transfer)
      // pero se marca con keepBillOpen para indicar que es parte de un pago mixto
      if (keepBillOpen) {
        eventoPago['esPagoParcial'] = true;
        eventoPago['tipoPago'] = 'mixto_parcial';
      } else {
        // Si es el último pago de un mixto, verificar si hay más pagos en el repositorio
        final pagosDelBill = _paymentRepository.payments.where((p) => p.billId == payment.billId).toList();
        if (pagosDelBill.length > 1) {
          eventoPago['esPagoMixto'] = true;
          eventoPago['tipoPago'] = 'mixto';
          eventoPago['totalPagos'] = pagosDelBill.length;
        }
      }
      
      // Agregar notas si existen
      if (paymentEnriched.notes != null && paymentEnriched.notes!.isNotEmpty) {
        eventoPago['notas'] = paymentEnriched.notes;
      }
      
      socketService.emit('pago.creado', eventoPago);
      print(
        '📢 Cajero: Evento pago.creado emitido para orden $ordenId${esCuentaAgrupada ? ' (cuenta agrupada: ${ordenIdsCompletos.length} órdenes)' : ''}',
      );
      print('📢 Cajero: Datos del evento: $eventoPago');

      notifyListeners();
      // Los pagos ya están guardados en la BD a través del servicio
    } catch (e) {
      print('Error al procesar pago: $e');
      rethrow;
    }
  }

  // Marcar factura como impresa e imprimir ticket.
  // Retorna true si la impresión en el backend fue exitosa, false en caso contrario.
  Future<bool> markBillAsPrinted(
    String billId,
    String printedBy, {
    String? paymentId,
    int? ordenId,
    List<int>? ordenIds,
  }) async {
    // Obtener el bill para verificar si es una cuenta agrupada (puede ser null si ya se cobró)
    final bill = _billRepository.getBill(billId);

    // Construir lista de ordenIds: la pasada por parámetro (ej. desde modal de éxito) o la del bill
    final ordenIdsCompletos = <int>[];
    if (ordenIds != null && ordenIds.isNotEmpty) {
      ordenIdsCompletos.addAll(ordenIds);
    } else if (bill != null) {
      ordenIdsCompletos.addAll(bill.ordenIdsFromBillIdInt);
    }

    // ordenId: parámetro, o primer elemento de ordenIdsCompletos, o parsear desde billId (ej. BILL-ORD-47 -> 47)
    int? ordenIdPrincipal = ordenId ?? (ordenIdsCompletos.isNotEmpty ? ordenIdsCompletos.first : null);
    if (ordenIdPrincipal == null && billId.startsWith('BILL-ORD-')) {
      ordenIdPrincipal = int.tryParse(billId.replaceFirst('BILL-ORD-', ''));
      if (ordenIdPrincipal != null && ordenIdsCompletos.isEmpty) {
        ordenIdsCompletos.add(ordenIdPrincipal);
      }
    }

    bool printSuccess = false;

    // Imprimir ticket en el backend si tenemos al menos una orden
    if (ordenIdPrincipal != null) {
      try {
        final ticketsService = TicketsService();
        final result = await ticketsService.imprimirTicket(
          ordenId: ordenIdPrincipal,
          ordenIds: ordenIdsCompletos.length > 1 ? ordenIdsCompletos : null,
          incluirCodigoBarras: true,
        );

        if (!result['success']) {
          _lastPrintError = result['error'] as String? ?? 'Error al imprimir ticket';
          print('Error al imprimir ticket: $_lastPrintError');
        } else {
          _lastPrintError = null;
          print(
            '✅ Cajero: Ticket impreso correctamente${ordenIdsCompletos.length > 1 ? ' (${ordenIdsCompletos.length} órdenes agrupadas)' : ''}',
          );
          printSuccess = true;
        }
      } catch (e) {
        _lastPrintError = e.toString();
        print('Error al imprimir ticket: $e');
        // Continuar de todas formas para marcar como impreso localmente
      }
    } else {
      _lastPrintError = 'No se pudo obtener la orden para imprimir';
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
      'timestamp': date_utils.AppDateUtils.nowCdmx().toIso8601String(),
    });
    print('📢 Cajero: Evento ticket.impreso emitido para orden $ordenId');

    notifyListeners();
    return printSuccess;
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
    String? usuario,
  }) async {
    try {
      print('💰 Cajero: Iniciando apertura de caja con efectivo inicial: $efectivoInicial');
      final cierresService = CierresService();
      // Crear un cierre con solo efectivo inicial (apertura)
      final apertura = CashCloseModel(
        id: 'open_${DateTime.now().millisecondsSinceEpoch}',
        fecha: date_utils.AppDateUtils.nowCdmx(),
        periodo: 'Día',
        usuario: usuario ?? 'Cajero',
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

      print('💰 Cajero: Enviando apertura al backend...');
      // Enviar al backend (el backend manejará que es una apertura si efectivoFinal es igual a efectivoInicial y totalPagos es 0)
      final aperturaCreada = await cierresService.crearCierreCaja(apertura);
      print('💰 Cajero: Apertura creada exitosamente - ID: ${aperturaCreada.id}');

      // Agregar la apertura localmente inmediatamente para que se muestre
      _cashClosures.insert(0, aperturaCreada);
      print('💰 Cajero: Apertura agregada localmente. Total cierres: ${_cashClosures.length}');
      
      // Notificar inmediatamente para actualizar la UI
      notifyListeners();

      // Recargar cierres para asegurar sincronización con el backend
      print('💰 Cajero: Recargando cierres desde el backend...');
      await loadCashClosures();
      print('💰 Cajero: Cierres recargados. Verificando apertura...');
      
      final aperturaEncontrada = getTodayCashOpening();
      if (aperturaEncontrada != null) {
        print('✅ Cajero: Apertura encontrada después de recargar - ID: ${aperturaEncontrada.id}');
      } else {
        print('⚠️ Cajero: No se encontró apertura después de recargar');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error al registrar apertura de caja: $e');
      rethrow;
    }
  }

  // Cancelar apertura de caja
  Future<void> cancelCashOpening(String aperturaId) async {
    try {
      // Buscar la apertura en la lista
      final aperturaIndex = _cashClosures.indexWhere((c) => c.id == aperturaId);
      if (aperturaIndex == -1) {
        throw Exception('Apertura no encontrada');
      }

      final apertura = _cashClosures[aperturaIndex];
      
      // Verificar que sea una apertura (no un cierre con ventas)
      if (apertura.totalNeto > 0 || apertura.efectivoInicial == 0) {
        throw Exception('No se puede cancelar: no es una apertura válida');
      }

      // Eliminar de la lista local
      _cashClosures.removeAt(aperturaIndex);
      notifyListeners();

      // TODO: Si el backend tiene un endpoint para eliminar aperturas, llamarlo aquí
      // Por ahora solo lo eliminamos localmente
      print('✅ Apertura cancelada localmente: $aperturaId');
    } catch (e) {
      print('❌ Error al cancelar apertura: $e');
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
    final today = date_utils.AppDateUtils.nowCdmx();

    // Obtener la fecha de referencia: última apertura de caja del día o último cierre con ventas
    DateTime? fechaReferencia;

    // Buscar la última apertura de caja del día
    final apertura = getTodayCashOpening();
    if (apertura != null) {
      fechaReferencia = apertura.fecha;
    }

    // Buscar el último cierre de caja con ventas del día (más reciente que la apertura)
    final hoy = date_utils.AppDateUtils.nowCdmx();
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
    double totalTransfer = 0;
    double totalTips = 0;

    for (final payment in todayPayments) {
      final paymentTypeLower = payment.type.toLowerCase();
      if (paymentTypeLower.contains('cash') || paymentTypeLower.contains('efectivo')) {
        totalCash += payment.totalAmount;
        totalTips += payment.tipAmount ?? 0;
      } else if (paymentTypeLower.contains('card') || paymentTypeLower.contains('tarjeta')) {
        totalCard += payment.totalAmount;
        totalTips += payment.tipAmount ?? 0;
      } else if (paymentTypeLower.contains('transfer') || paymentTypeLower.contains('transferencia')) {
        totalTransfer += payment.totalAmount;
        totalTips += payment.tipAmount ?? 0;
      } else if (paymentTypeLower.contains('mixed') || paymentTypeLower.contains('mixto')) {
        totalCash += payment.cashApplied ?? 0;
        totalCard += payment.totalAmount - (payment.cashApplied ?? 0);
        totalTips += payment.tipAmount ?? 0;
      }
    }

    return {
      'totalCash': totalCash,
      'totalCard': totalCard + totalTransfer,
      'cardOnly': totalCard,
      'totalTransfer': totalTransfer,
      'totalTips': totalTips,
      'total': totalCash + totalCard + totalTransfer,
    };
  }

  /// Estadísticas del día completo para el Resumen de Consumo: todos los pagos de hoy,
  /// con desglose real por local/para llevar y débito/crédito. Se actualiza al hacer cobros.
  Map<String, double> getDailyConsumptionStats() {
    final today = date_utils.AppDateUtils.nowCdmx();
    final todayPayments = _payments.where((payment) {
      return payment.timestamp.day == today.day &&
          payment.timestamp.month == today.month &&
          payment.timestamp.year == today.year;
    }).toList();

    double totalCash = 0;
    double totalCard = 0;
    double totalTransfer = 0;
    double totalLocal = 0;
    double totalParaLlevar = 0;
    double totalDebit = 0;
    double totalCredit = 0;

    for (final payment in todayPayments) {
      final amount = payment.totalAmount;
      final isLocal = payment.tableNumber != null;
      if (isLocal) {
        totalLocal += amount;
      } else {
        totalParaLlevar += amount;
      }

      final typeLower = payment.type.toLowerCase();
      if (typeLower.contains('cash') || typeLower.contains('efectivo')) {
        totalCash += amount;
      } else if (typeLower.contains('card') || typeLower.contains('tarjeta')) {
        totalCard += amount;
        if (payment.cardMethod == 'credito') {
          totalCredit += amount;
        } else {
          totalDebit += amount;
        }
      } else if (typeLower.contains('transfer')) {
        totalTransfer += amount;
      } else if (typeLower.contains('mixed') || typeLower.contains('mixto')) {
        totalCash += payment.cashApplied ?? 0;
        final cardPart = amount - (payment.cashApplied ?? 0);
        totalCard += cardPart;
        if (payment.cardMethod == 'credito') {
          totalCredit += cardPart;
        } else {
          totalDebit += cardPart;
        }
      }
    }

    return {
      'totalCash': totalCash,
      'totalCard': totalCard + totalTransfer,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'totalLocal': totalLocal,
      'totalParaLlevar': totalParaLlevar,
      'total': totalCash + totalCard + totalTransfer,
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

  // Obtener historial completo de cobros (por período o rango personalizado)
  Map<String, dynamic> getCollectionHistory({
    String? periodo,
    DateTime? fechaInicioCustom,
    DateTime? fechaFinCustom,
  }) {
    final now = date_utils.AppDateUtils.nowCdmx();
    DateTime fechaInicio;
    DateTime fechaFin = now;

    // Determinar rango de fechas según el período
    switch (periodo) {
      case 'personalizado':
        if (fechaInicioCustom != null && fechaFinCustom != null) {
          fechaInicio = DateTime(fechaInicioCustom.year, fechaInicioCustom.month, fechaInicioCustom.day);
          fechaFin = DateTime(fechaFinCustom.year, fechaFinCustom.month, fechaFinCustom.day, 23, 59, 59, 999);
          if (fechaFin.isBefore(fechaInicio)) {
            final temp = fechaInicio;
            fechaInicio = fechaFin;
            fechaFin = DateTime(temp.year, temp.month, temp.day, 23, 59, 59, 999);
          }
        } else {
          fechaInicio = DateTime(now.year, now.month, now.day);
        }
        break;
      case 'ayer':
        // Solo el día de ayer: desde 00:00 ayer hasta antes de 00:00 hoy
        fechaInicio = DateTime(now.year, now.month, now.day - 1);
        fechaFin = DateTime(now.year, now.month, now.day); // exclusivo: no incluir hoy
        break;
      case 'semana':
        // Últimos 7 días hasta ahora
        fechaInicio = now.subtract(const Duration(days: 7));
        break;
      case 'mes':
        // Últimos 30 días (evita desborde de día/mes, ej. 31 mar -> feb)
        fechaInicio = now.subtract(const Duration(days: 30));
        break;
      case 'hoy':
      default:
        fechaInicio = DateTime(now.year, now.month, now.day);
        // Para "hoy", buscar la última apertura de caja del día
        final apertura = getTodayCashOpening();
        if (apertura != null && apertura.fecha.isAfter(fechaInicio)) {
          fechaInicio = apertura.fecha;
        }
        // Buscar el último cierre de caja con ventas del día
        final cierresConVentas = _cashClosures.where((cierre) {
          final esHoy =
              cierre.fecha.year == now.year &&
              cierre.fecha.month == now.month &&
              cierre.fecha.day == now.day;
          final esCierreConVentas = cierre.totalNeto > 0;
          return esHoy && esCierreConVentas;
        }).toList();
        if (cierresConVentas.isNotEmpty) {
          cierresConVentas.sort((a, b) => b.fecha.compareTo(a.fecha));
          final ultimoCierre = cierresConVentas.first;
          if (ultimoCierre.fecha.isAfter(fechaInicio)) {
            fechaInicio = ultimoCierre.fecha;
          }
        }
        break;
    }

    // Filtrar pagos según el rango de fechas (inicio inclusivo)
    final isAyer = periodo == 'ayer';
    final filteredPayments = _payments.where((payment) {
      final t = payment.timestamp;
      final despuesOIgualInicio = !t.isBefore(fechaInicio);
      if (!despuesOIgualInicio) return false;
      // Ayer: fin exclusivo (antes de las 00:00 de hoy). Resto: fin inclusivo (hasta fechaFin).
      if (isAyer) return t.isBefore(fechaFin);
      return !t.isAfter(fechaFin);
    }).toList();

    // Agrupar por método de pago
    final efectivoPayments = <Map<String, dynamic>>[];
    final tarjetaPayments = <Map<String, dynamic>>[];
    final transferenciaPayments = <Map<String, dynamic>>[];
    final mixtoPayments = <Map<String, dynamic>>[];
    final tipsDetails = <Map<String, dynamic>>[];

    double totalEfectivo = 0;
    double totalTarjeta = 0;
    double totalTransferencia = 0;
    double totalMixto = 0;
    double totalTips = 0;

    for (final payment in filteredPayments) {
      // NO depender del BillRepository (después de cobrar, el bill se elimina)
      // Usar metadata guardada en el PaymentModel; si falta, fallback al bill (compatibilidad)
      final bill = _billRepository.getBill(payment.billId);
      final ordenIdValue = payment.ordenId ?? bill?.ordenId;
      final ordenIdStr = ordenIdValue != null ? 'ORD-${ordenIdValue.toString().padLeft(6, '0')}' : '—';
      final waiterName = payment.waiterName ?? bill?.waiterName;
      final mesaInfo = payment.tableNumber != null
          ? 'Mesa ${payment.tableNumber}'
          : (bill?.isTakeaway == true ? 'Para llevar' : 'Para llevar');

      final paymentInfo = {
        'id': payment.id,
        'ordenId': ordenIdStr,
        'mesa': mesaInfo,
        'monto': payment.totalAmount,
        'fecha': payment.timestamp,
        'waiterName': waiterName,
      };

      final paymentTypeLower = payment.type.toLowerCase();
      if (paymentTypeLower.contains('cash') || paymentTypeLower.contains('efectivo')) {
        efectivoPayments.add(paymentInfo);
        totalEfectivo += payment.totalAmount;
        if (payment.tipAmount != null && payment.tipAmount! > 0) {
          totalTips += payment.tipAmount!;
          tipsDetails.add({
            'ordenId': ordenIdStr,
            'mesa': mesaInfo,
            'metodo': 'Efectivo',
            'monto': payment.tipAmount!,
            'waiterName': waiterName,
            'fecha': payment.timestamp,
          });
        }
      } else if (paymentTypeLower.contains('card') || paymentTypeLower.contains('tarjeta')) {
        final cardType = payment.cardMethod == 'credito' ? 'Tarjeta Crédito' : 'Tarjeta Débito';
        tarjetaPayments.add({
          ...paymentInfo,
          'tipoTarjeta': cardType,
        });
        totalTarjeta += payment.totalAmount;
        if (payment.tipAmount != null && payment.tipAmount! > 0) {
          totalTips += payment.tipAmount!;
          tipsDetails.add({
            'ordenId': ordenIdStr,
            'mesa': mesaInfo,
            'metodo': cardType,
            'monto': payment.tipAmount!,
            'waiterName': waiterName,
            'fecha': payment.timestamp,
          });
        }
      } else if (paymentTypeLower.contains('transfer') || paymentTypeLower.contains('transferencia')) {
        transferenciaPayments.add({
          ...paymentInfo,
          'banco': payment.bankName,
          'referencia': payment.reference,
        });
        totalTransferencia += payment.totalAmount;
        if (payment.tipAmount != null && payment.tipAmount! > 0) {
          totalTips += payment.tipAmount!;
          tipsDetails.add({
            'ordenId': ordenIdStr,
            'mesa': mesaInfo,
            'metodo': 'Transferencia',
            'monto': payment.tipAmount!,
            'waiterName': waiterName,
            'fecha': payment.timestamp,
          });
        }
      } else if (paymentTypeLower.contains('mixed') || paymentTypeLower.contains('mixto')) {
        mixtoPayments.add({
          ...paymentInfo,
          'efectivo': payment.cashApplied ?? 0,
          'otro': payment.totalAmount - (payment.cashApplied ?? 0),
        });
        totalMixto += payment.totalAmount;
        if (payment.tipAmount != null && payment.tipAmount! > 0) {
          totalTips += payment.tipAmount!;
          tipsDetails.add({
            'ordenId': ordenIdStr,
            'mesa': mesaInfo,
            'metodo': 'Pago Mixto',
            'monto': payment.tipAmount!,
            'waiterName': waiterName,
            'fecha': payment.timestamp,
          });
        }
      }
    }

    // Ordenar propinas por fecha (más reciente primero)
    tipsDetails.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    return {
      'efectivo': {
        'total': totalEfectivo,
        'pagos': efectivoPayments,
      },
      'tarjeta': {
        'total': totalTarjeta,
        'pagos': tarjetaPayments,
      },
      'transferencia': {
        'total': totalTransferencia,
        'pagos': transferenciaPayments,
      },
      'mixto': {
        'total': totalMixto,
        'pagos': mixtoPayments,
      },
      'propinas': {
        'total': totalTips,
        'detalles': tipsDetails,
      },
      'totalGeneral': totalEfectivo + totalTarjeta + totalTransferencia + totalMixto,
    };
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
  // Una apertura se identifica por: efectivoInicial > 0 y totalNeto = 0 (o muy bajo)
  // Nota: No usamos pedidosParaLlevar porque se mapea incorrectamente desde el backend (usa numeroOrdenes)
  CashCloseModel? getTodayCashOpening() {
    // Usar AppDateUtils.now() para asegurar que estamos comparando con la misma zona horaria
    final hoy = date_utils.AppDateUtils.now();
    print('🔍 Cajero.getTodayCashOpening: Buscando apertura para hoy ${hoy.year}-${hoy.month}-${hoy.day} (hora: ${hoy.hour}:${hoy.minute})');
    print('🔍 Cajero.getTodayCashOpening: Total de cierres cargados: ${_cashClosures.length}');
    
    // Buscar aperturas del día de hoy o del día anterior (para manejar zonas horarias)
    // Una apertura es válida si fue creada hoy o si fue creada ayer después de las 6pm
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final inicioAyer18h = DateTime(ayer.year, ayer.month, ayer.day, 18); // 6pm de ayer
    
    final aperturas = _cashClosures.where((cierre) {
      // Verificar que sea del día de hoy (comparar año, mes y día)
      final esHoy =
          cierre.fecha.year == hoy.year &&
          cierre.fecha.month == hoy.month &&
          cierre.fecha.day == hoy.day;
      
      // También considerar como "hoy" si fue creado ayer después de las 6pm
      // (esto maneja el caso de zonas horarias y cierres nocturnos)
      final esAyerNoche = cierre.fecha.isAfter(inicioAyer18h) && cierre.fecha.isBefore(inicioHoy);

      // Verificar que sea una apertura: tiene efectivo inicial y no tiene ventas significativas
      // No usamos pedidosParaLlevar porque se mapea con numeroOrdenes del backend
      final esApertura =
          cierre.efectivoInicial > 0 &&
          (cierre.totalNeto == 0 || cierre.totalNeto < 1.0);

      print('🔍 Cajero.getTodayCashOpening: Cierre ${cierre.id} - Fecha: ${cierre.fecha.year}-${cierre.fecha.month}-${cierre.fecha.day} ${cierre.fecha.hour}:${cierre.fecha.minute}, esHoy: $esHoy, esAyerNoche: $esAyerNoche, efectivoInicial: ${cierre.efectivoInicial}, totalNeto: ${cierre.totalNeto}, esApertura: $esApertura');

      return (esHoy || esAyerNoche) && esApertura;
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

    // Usar AppDateUtils.now() para asegurar que estamos comparando con la misma zona horaria
    final hoy = date_utils.AppDateUtils.now();
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
      case PaymentType.transfer:
        return Colors.teal;
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

  /// Descompone un total con IVA (16%) en subtotal e IVA. México CDMX.
  static double _subtotalFromTotalConIva(double totalConIva) {
    if (totalConIva <= 0) return 0.0;
    return totalConIva / 1.16;
  }

  static double _ivaFromTotalConIva(double totalConIva) {
    return totalConIva - _subtotalFromTotalConIva(totalConIva);
  }

  // Exportar cierres de caja a CSV
  Future<void> exportCashClosuresToCSV() async {
    try {
      final hoy = date_utils.AppDateUtils.nowCdmx();
      final cierresDelDia = _cashClosures.where((cierre) {
        return cierre.fecha.year == hoy.year &&
            cierre.fecha.month == hoy.month &&
            cierre.fecha.day == hoy.day;
      }).toList();

      // Ordenar por fecha descendente
      cierresDelDia.sort((a, b) => b.fecha.compareTo(a.fecha));

      // Construir contenido CSV
      final csvLines = <String>[];
      final bool showIva = _ivaHabilitado;

      // Encabezados (con columnas IVA cuando está habilitado)
      if (showIva) {
        csvLines.add(
          'Fecha,Hora,Cajero,Subtotal,IVA (16%),Total Ventas,Efectivo,Tarjeta,Otros Ingresos,Propinas,Estado,Efectivo Inicial,Notas',
        );
      } else {
        csvLines.add(
          'Fecha,Hora,Cajero,Total Ventas,Efectivo,Tarjeta,Otros Ingresos,Propinas,Estado,Efectivo Inicial,Notas',
        );
      }

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

        if (showIva) {
          final subtotal = _subtotalFromTotalConIva(cierre.totalNeto);
          final iva = _ivaFromTotalConIva(cierre.totalNeto);
          csvLines.add(
            [
              fechaStr,
              horaStr,
              cierre.usuario,
              subtotal.toStringAsFixed(2),
              iva.toStringAsFixed(2),
              cierre.totalNeto.toStringAsFixed(2),
              cierre.efectivo.toStringAsFixed(2),
              cierre.tarjeta.toStringAsFixed(2),
              cierre.otrosIngresos.toStringAsFixed(2),
              (cierre.propinasTarjeta + cierre.propinasEfectivo).toStringAsFixed(2),
              estadoStr,
              cierre.efectivoInicial.toStringAsFixed(2),
              notas,
            ].join(','),
          );
        } else {
          csvLines.add(
            [
              fechaStr,
              horaStr,
              cierre.usuario,
              cierre.totalNeto.toStringAsFixed(2),
              cierre.efectivo.toStringAsFixed(2),
              cierre.tarjeta.toStringAsFixed(2),
              cierre.otrosIngresos.toStringAsFixed(2),
              (cierre.propinasTarjeta + cierre.propinasEfectivo).toStringAsFixed(2),
              estadoStr,
              cierre.efectivoInicial.toStringAsFixed(2),
              notas,
            ].join(','),
          );
        }
      }

      // Resumen del día a partir de los mismos cierres exportados
      double resumenVentas = 0;
      double resumenEfectivo = 0;
      double resumenTarjeta = 0;
      double resumenPropinas = 0;
      for (final cierre in cierresDelDia) {
        resumenVentas += cierre.totalNeto;
        resumenEfectivo += cierre.efectivo;
        resumenTarjeta += cierre.tarjeta;
        resumenPropinas += cierre.propinasTarjeta + cierre.propinasEfectivo;
      }
      csvLines.add('');
      csvLines.add('RESUMEN DEL DÍA');
      if (showIva) {
        final resumenSubtotal = _subtotalFromTotalConIva(resumenVentas);
        final resumenIva = _ivaFromTotalConIva(resumenVentas);
        csvLines.add('Subtotal,${resumenSubtotal.toStringAsFixed(2)}');
        csvLines.add('IVA (16%),${resumenIva.toStringAsFixed(2)}');
        csvLines.add('Total Ventas,${resumenVentas.toStringAsFixed(2)}');
      } else {
        csvLines.add('Total Ventas,${resumenVentas.toStringAsFixed(2)}');
      }
      csvLines.add('Total Efectivo,${resumenEfectivo.toStringAsFixed(2)}');
      csvLines.add('Total Tarjeta,${resumenTarjeta.toStringAsFixed(2)}');
      csvLines.add('Total Propinas,${resumenPropinas.toStringAsFixed(2)}');

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
      // Recargar cierres y pagos desde el backend para que el PDF use datos reales
      await loadCashClosures();
      await _loadPaymentsFromBackend();
      notifyListeners();

      final hoy = date_utils.AppDateUtils.nowCdmx();
      final cierresDelDia = _cashClosures.where((cierre) {
        return cierre.fecha.year == hoy.year &&
            cierre.fecha.month == hoy.month &&
            cierre.fecha.day == hoy.day;
      }).toList();

      // Ordenar por fecha descendente
      cierresDelDia.sort((a, b) => b.fecha.compareTo(a.fecha));

      // Resumen del día a partir de los mismos cierres del día (igual que en CSV)
      double resumenVentas = 0;
      double resumenEfectivo = 0;
      double resumenTarjeta = 0;
      for (final cierre in cierresDelDia) {
        resumenVentas += cierre.totalNeto;
        resumenEfectivo += cierre.efectivo;
        resumenTarjeta += cierre.tarjeta;
      }
      final resumenSubtotal = _ivaHabilitado ? _subtotalFromTotalConIva(resumenVentas) : 0.0;
      final resumenIva = _ivaHabilitado ? _ivaFromTotalConIva(resumenVentas) : 0.0;
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
                      if (_ivaHabilitado) ...[
                        pdf_widgets.Row(
                          mainAxisAlignment:
                              pdf_widgets.MainAxisAlignment.spaceBetween,
                          children: [
                            pdf_widgets.Text('Subtotal:'),
                            pdf_widgets.Text(formatCurrency(resumenSubtotal)),
                          ],
                        ),
                        pdf_widgets.Row(
                          mainAxisAlignment:
                              pdf_widgets.MainAxisAlignment.spaceBetween,
                          children: [
                            pdf_widgets.Text('IVA (16%):'),
                            pdf_widgets.Text(formatCurrency(resumenIva)),
                          ],
                        ),
                      ],
                      pdf_widgets.Row(
                        mainAxisAlignment:
                            pdf_widgets.MainAxisAlignment.spaceBetween,
                        children: [
                          pdf_widgets.Text('Total Ventas:'),
                          pdf_widgets.Text(
                            formatCurrency(resumenVentas),
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
                          pdf_widgets.Text(formatCurrency(resumenEfectivo)),
                        ],
                      ),
                      pdf_widgets.Row(
                        mainAxisAlignment:
                            pdf_widgets.MainAxisAlignment.spaceBetween,
                        children: [
                          pdf_widgets.Text('Total Tarjeta:'),
                          pdf_widgets.Text(formatCurrency(resumenTarjeta)),
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
                        // Encabezados (con Subtotal e IVA cuando está habilitado)
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
                            if (_ivaHabilitado) ...[
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  'Subtotal',
                                  style: pdf_widgets.TextStyle(
                                    fontWeight: pdf_widgets.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pdf_widgets.Padding(
                                padding: const pdf_widgets.EdgeInsets.all(5),
                                child: pdf_widgets.Text(
                                  'IVA (16%)',
                                  style: pdf_widgets.TextStyle(
                                    fontWeight: pdf_widgets.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                              if (_ivaHabilitado) ...[
                                pdf_widgets.Padding(
                                  padding: const pdf_widgets.EdgeInsets.all(5),
                                  child: pdf_widgets.Text(
                                    formatCurrency(_subtotalFromTotalConIva(cierre.totalNeto)),
                                    style: const pdf_widgets.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                pdf_widgets.Padding(
                                  padding: const pdf_widgets.EdgeInsets.all(5),
                                  child: pdf_widgets.Text(
                                    formatCurrency(_ivaFromTotalConIva(cierre.totalNeto)),
                                    style: const pdf_widgets.TextStyle(
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
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
                'Generado el ${date_utils.AppDateUtils.formatDateTime(date_utils.AppDateUtils.nowCdmx())}',
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

      // Guardar PDF en bytes y abrir diálogo de compartir/descargar (permite guardar en archivo)
      final bytes = await pdfDoc.save();
      final filename =
          'reporte-cierres-caja_${hoy.year}_${hoy.month.toString().padLeft(2, '0')}_${hoy.day.toString().padLeft(2, '0')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);

      print('✅ PDF generado correctamente');
    } catch (e) {
      print('❌ Error al generar PDF: $e');
      rethrow;
    }
  }
}
