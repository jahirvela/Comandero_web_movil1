import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as date_utils;

class PaymentModel {
  final String id;
  final String type; // 'cash', 'card', 'mixed', 'transfer'
  final double totalAmount;
  final double? cashReceived;
  final double? tipAmount;
  final bool tipDelivered;
  final double? cashApplied;
  final double? change;
  final String? notes;
  final String? reference;
  final String? bankName;
  final int? tableNumber;
  // Metadata para historial (no depender del BillRepository después de cobrar)
  final int? ordenId;
  final List<int>? ordenIds; // Para cuentas agrupadas (imprimir ticket completo)
  final String? waiterName;
  final String billId;
  final DateTime timestamp;
  final String cashierName;
  // Campos para pagos con tarjeta
  final String? cardMethod; // 'debito', 'credito'
  final String? terminal;
  final String? transactionId;
  final String? authorizationCode;
  final String? last4Digits;
  final String? cardBrand; // 'Visa', 'Mastercard', etc.
  final bool? voucherPrinted;
  final DateTime? cardPaymentDate;

  PaymentModel({
    required this.id,
    required this.type,
    required this.totalAmount,
    this.cashReceived,
    this.tipAmount,
    this.tipDelivered = false,
    this.cashApplied,
    this.change,
    this.notes,
    this.reference,
    this.bankName,
    this.tableNumber,
    this.ordenId,
    this.ordenIds,
    this.waiterName,
    required this.billId,
    required this.timestamp,
    required this.cashierName,
    this.cardMethod,
    this.terminal,
    this.transactionId,
    this.authorizationCode,
    this.last4Digits,
    this.cardBrand,
    this.voucherPrinted,
    this.cardPaymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      type: json['type'],
      totalAmount: json['totalAmount'].toDouble(),
      cashReceived: json['cashReceived']?.toDouble(),
      tipAmount: json['tipAmount']?.toDouble(),
      tipDelivered: json['tipDelivered'] ?? false,
      cashApplied: json['cashApplied']?.toDouble(),
      change: json['change']?.toDouble(),
      notes: json['notes'],
      reference: json['reference'],
      bankName: json['bankName'],
      tableNumber: json['tableNumber'],
      ordenId: (json['ordenId'] as num?)?.toInt(),
      ordenIds: json['ordenIds'] != null
          ? (json['ordenIds'] as List).map((e) => (e as num).toInt()).toList()
          : null,
      waiterName: json['waiterName'],
      billId: json['billId'],
      timestamp: date_utils.AppDateUtils.parseToLocal(json['timestamp']),
      cashierName: json['cashierName'],
      cardMethod: json['cardMethod'],
      terminal: json['terminal'],
      transactionId: json['transactionId'],
      authorizationCode: json['authorizationCode'],
      last4Digits: json['last4Digits'],
      cardBrand: json['cardBrand'],
      voucherPrinted: json['voucherPrinted'],
      cardPaymentDate: json['cardPaymentDate'] != null
          ? date_utils.AppDateUtils.parseToLocal(json['cardPaymentDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'totalAmount': totalAmount,
      'cashReceived': cashReceived,
      'tipAmount': tipAmount,
      'tipDelivered': tipDelivered,
      'cashApplied': cashApplied,
      'change': change,
      'notes': notes,
      'reference': reference,
      'bankName': bankName,
      'tableNumber': tableNumber,
      'ordenId': ordenId,
      'ordenIds': ordenIds,
      'waiterName': waiterName,
      'billId': billId,
      'timestamp': timestamp.toIso8601String(),
      'cashierName': cashierName,
      'cardMethod': cardMethod,
      'terminal': terminal,
      'transactionId': transactionId,
      'authorizationCode': authorizationCode,
      'last4Digits': last4Digits,
      'cardBrand': cardBrand,
      'voucherPrinted': voucherPrinted,
      'cardPaymentDate': cardPaymentDate?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? type,
    double? totalAmount,
    double? cashReceived,
    double? tipAmount,
    bool? tipDelivered,
    double? cashApplied,
    double? change,
    String? notes,
    String? reference,
    String? bankName,
    int? tableNumber,
    int? ordenId,
    String? waiterName,
    String? billId,
    DateTime? timestamp,
    String? cashierName,
    String? cardMethod,
    String? terminal,
    String? transactionId,
    String? authorizationCode,
    String? last4Digits,
    String? cardBrand,
    bool? voucherPrinted,
    DateTime? cardPaymentDate,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      cashReceived: cashReceived ?? this.cashReceived,
      tipAmount: tipAmount ?? this.tipAmount,
      tipDelivered: tipDelivered ?? this.tipDelivered,
      cashApplied: cashApplied ?? this.cashApplied,
      change: change ?? this.change,
      notes: notes ?? this.notes,
      reference: reference ?? this.reference,
      bankName: bankName ?? this.bankName,
      tableNumber: tableNumber ?? this.tableNumber,
      ordenId: ordenId ?? this.ordenId,
      waiterName: waiterName ?? this.waiterName,
      billId: billId ?? this.billId,
      timestamp: timestamp ?? this.timestamp,
      cashierName: cashierName ?? this.cashierName,
      cardMethod: cardMethod ?? this.cardMethod,
      terminal: terminal ?? this.terminal,
      transactionId: transactionId ?? this.transactionId,
      authorizationCode: authorizationCode ?? this.authorizationCode,
      last4Digits: last4Digits ?? this.last4Digits,
      cardBrand: cardBrand ?? this.cardBrand,
      voucherPrinted: voucherPrinted ?? this.voucherPrinted,
      cardPaymentDate: cardPaymentDate ?? this.cardPaymentDate,
    );
  }
}

class BillModel {
  final String id;
  final int? tableNumber;
  /// Código o nombre de la mesa para mostrar (ej: "1", "Terraza"). Usar en tickets y cuentas por cobrar.
  final String? mesaCodigo;
  final int? ordenId; // ID de la orden en la BD (requerido para pagos)
  final List<int>? ordenIds; // IDs de todas las órdenes (para cuentas agrupadas)
  final bool? isGrouped; // Flag para indicar si es una cuenta agrupada
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final double discount; // Descuento aplicado
  final String status; // 'pending', 'paid', 'cancelled'
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final bool isTakeaway;
  final String? waiterName;
  final String? waiterNotes; // Notas del mesero
  final bool isPrinted; // Si el ticket ya fue impreso
  final String? printedBy; // Quien imprimió el ticket
  final DateTime? printedAt; // Fecha y hora de impresión
  final bool requestedByWaiter; // Si fue solicitado por mesero
  final int splitCount; // Número de personas para dividir la cuenta
  final String? paymentMethod; // Método de pago (ej: 'Efectivo', 'Tarjeta', etc.)
  final double? tipAmount; // Propina del pago
  final String? paymentNotes; // Notas del pago (referencia del pago)
  // Campos para cuenta dividida por persona
  final bool isDividedAccount; // Si es true, la cuenta está dividida por persona
  final List<PersonAccount>? personAccounts; // Lista de personas con sus productos (solo si isDividedAccount = true)

  BillModel({
    required this.id,
    this.tableNumber,
    this.mesaCodigo,
    this.ordenId, // ID de la orden en la BD
    this.ordenIds, // IDs de todas las órdenes (para cuentas agrupadas)
    this.isGrouped, // Flag para indicar si es una cuenta agrupada
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discount = 0.0,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.isTakeaway = false,
    this.waiterName,
    this.waiterNotes,
    this.isPrinted = false,
    this.printedBy,
    this.printedAt,
    this.requestedByWaiter = false,
    this.splitCount = 1,
    this.paymentMethod,
    this.tipAmount,
    this.paymentNotes,
    this.isDividedAccount = false,
    this.personAccounts,
  });

  /// Calcula el total real sumando precio * cantidad de cada item
  /// Esto asegura que siempre se muestre el precio correcto
  /// Si es solo número → "Mesa 1"; si tiene texto → tal cual; para llevar → "Para llevar"
  String get tableDisplayLabel {
    if (isTakeaway) return 'Para llevar';
    if (mesaCodigo != null && mesaCodigo!.isNotEmpty) {
      final c = mesaCodigo!.trim();
      final n = int.tryParse(c);
      return (n != null && n.toString() == c) ? 'Mesa $c' : mesaCodigo!;
    }
    if (tableNumber != null) return 'Mesa $tableNumber';
    return 'N/A';
  }

  double get calculatedTotal {
    final totalFromItems = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return totalFromItems - discount + tax;
  }

  /// Genera un ID de visualización claro y legible para el cajero
  /// Ejemplos:
  /// - "BILL-MESA-2-30-31-32" -> "Cuenta agrupada (3 órdenes)"
  /// - "CUENTA-AGRUPADA-000084-000085-000086" -> "Cuenta agrupada (3 órdenes)"
  /// - "BILL-ORD-30" -> "ORD-000030"
  String get displayId {
    // Si es formato CUENTA-AGRUPADA- (tickets del administrador)
    if (id.startsWith('CUENTA-AGRUPADA-')) {
      final parts = id.replaceFirst('CUENTA-AGRUPADA-', '').split('-');
      final ordenIds = parts
          .map((part) => int.tryParse(part))
          .whereType<int>()
          .toList();
      if (ordenIds.length > 1) {
        return 'Cuenta agrupada (${ordenIds.length} órdenes)';
      } else if (ordenIds.length == 1) {
        return 'ORD-${ordenIds.first.toString().padLeft(6, '0')}';
      }
    }
    
    // Si el ID contiene múltiples órdenes (formato BILL-MESA-X-Y-Z)
    if (id.contains('BILL-MESA-') && id.contains('-')) {
      final parts = id.split('-');
      if (parts.length >= 4) {
        final ordenIdsCount =
            parts.length - 3; // Número de órdenes después de "BILL-MESA-X"

        if (ordenIdsCount > 1) {
          // Para múltiples órdenes: mostrar solo el número de órdenes (el badge ya muestra la mesa)
          return 'Cuenta agrupada ($ordenIdsCount órdenes)';
        } else if (ordenIdsCount == 1) {
          // Una sola orden en formato mesa
          final ordenId = parts[3];
          return 'ORD-${ordenId.padLeft(6, '0')}';
        }
      }
    }

    // Si es formato BILL-ORD-X
    if (id.startsWith('BILL-ORD-')) {
      final ordenId = id.replaceFirst('BILL-ORD-', '');
      return 'ORD-${ordenId.padLeft(6, '0')}';
    }

    // Si es formato BILL-TEMP-X (temporal)
    if (id.startsWith('BILL-TEMP-')) {
      if (tableNumber != null) {
        return 'Mesa $tableNumber - Cuenta temporal';
      }
      return 'Cuenta temporal';
    }

    // Por defecto, devolver el ID tal cual
    return id;
  }

  /// Extrae los IDs de órdenes del billId para mostrar información detallada (como strings)
  List<String> get ordenIdsFromBillId {
    if (id.contains('BILL-MESA-') && id.contains('-')) {
      final parts = id.split('-');
      if (parts.length >= 4) {
        // Obtener todas las partes después de "BILL-MESA-X"
        final ordenIds = parts.sublist(3);
        return ordenIds.map((id) => 'ORD-${id.padLeft(6, '0')}').toList();
      }
    }

    if (id.startsWith('BILL-ORD-')) {
      final ordenId = id.replaceFirst('BILL-ORD-', '');
      return ['ORD-${ordenId.padLeft(6, '0')}'];
    }

    // Para BILL-TAKEAWAY-X-Y-Z
    if (id.startsWith('BILL-TAKEAWAY-')) {
      final parts = id.split('-');
      final ordenIds = <String>[];
      // Recorrer desde el final hacia adelante para encontrar los números (ordenIds)
      for (var i = parts.length - 1; i >= 2; i--) {
        final posibleOrdenId = int.tryParse(parts[i]);
        if (posibleOrdenId != null) {
          ordenIds.insert(0, 'ORD-${parts[i].padLeft(6, '0')}');
        } else {
          break; // Ya pasamos todos los ordenIds
        }
      }
      return ordenIds;
    }

    return [];
  }

  /// Extrae los IDs de órdenes del billId como números (int) para enviarlos al backend
  List<int> get ordenIdsFromBillIdInt {
    if (id.contains('BILL-MESA-') && id.contains('-')) {
      final parts = id.split('-');
      if (parts.length >= 4) {
        // Obtener todas las partes después de "BILL-MESA-X"
        final ordenIds = parts.sublist(3);
        return ordenIds
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList();
      }
    }

    if (id.startsWith('BILL-ORD-')) {
      final ordenId = id.replaceFirst('BILL-ORD-', '');
      final ordenIdInt = int.tryParse(ordenId);
      if (ordenIdInt != null) {
        return [ordenIdInt];
      }
    }

    // Para BILL-TAKEAWAY-X-Y-Z
    if (id.startsWith('BILL-TAKEAWAY-')) {
      final parts = id.split('-');
      final ordenIds = <int>[];
      // Recorrer desde el final hacia adelante para encontrar los números (ordenIds)
      for (var i = parts.length - 1; i >= 2; i--) {
        final posibleOrdenId = int.tryParse(parts[i]);
        if (posibleOrdenId != null) {
          ordenIds.insert(0, posibleOrdenId);
        } else {
          break; // Ya pasamos todos los ordenIds
        }
      }
      return ordenIds;
    }

    return [];
  }

  // Helper estático para parsear fechas
  static DateTime _parseDateTime(dynamic fecha) {
    // Usar AppDateUtils para el parseo correcto de zona horaria
    return date_utils.AppDateUtils.parseToLocal(fecha);
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      tableNumber: json['tableNumber'] is int ? json['tableNumber'] as int? : (int.tryParse(json['tableNumber']?.toString() ?? '')),
      mesaCodigo: json['mesaCodigo'] as String?,
      ordenId: json['ordenId'],
      ordenIds: json['ordenIds'] != null
          ? (json['ordenIds'] as List).map((e) => (e as num).toInt()).toList()
          : null,
      isGrouped: json['isGrouped'] as bool?,
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'],
      createdAt: _parseDateTime(json['createdAt']),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      isTakeaway: json['isTakeaway'] ?? false,
      waiterName: json['waiterName'],
      waiterNotes: json['waiterNotes'],
      isPrinted: json['isPrinted'] ?? false,
      printedBy: json['printedBy'],
      printedAt: json['printedAt'] != null
          ? _parseDateTime(json['printedAt'])
          : null,
      requestedByWaiter: json['requestedByWaiter'] ?? false,
      splitCount: (json['splitCount'] as num?)?.toInt() ?? 1,
      paymentMethod: json['paymentMethod'] as String?,
      tipAmount: json['tipAmount']?.toDouble(),
      paymentNotes: json['paymentNotes'] as String?,
      isDividedAccount: json['isDividedAccount'] as bool? ?? false,
      personAccounts: json['personAccounts'] != null
          ? (json['personAccounts'] as List)
              .map((pa) => PersonAccount.fromJson(pa))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'mesaCodigo': mesaCodigo,
      'ordenId': ordenId,
      'ordenIds': ordenIds,
      'isGrouped': isGrouped,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'discount': discount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'isTakeaway': isTakeaway,
      'waiterName': waiterName,
      'waiterNotes': waiterNotes,
      'isPrinted': isPrinted,
      'printedBy': printedBy,
      'printedAt': printedAt?.toIso8601String(),
      'requestedByWaiter': requestedByWaiter,
      'splitCount': splitCount,
      'paymentMethod': paymentMethod,
      'tipAmount': tipAmount,
      'paymentNotes': paymentNotes,
      'isDividedAccount': isDividedAccount,
      if (personAccounts != null)
        'personAccounts': personAccounts!.map((pa) => pa.toJson()).toList(),
    };
  }

  BillModel copyWith({
    String? id,
    int? tableNumber,
    String? mesaCodigo,
    int? ordenId,
    List<int>? ordenIds,
    bool? isGrouped,
    List<BillItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    double? discount,
    String? status,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    bool? isTakeaway,
    String? waiterName,
    String? waiterNotes,
    bool? isPrinted,
    String? printedBy,
    DateTime? printedAt,
    bool? requestedByWaiter,
    int? splitCount,
    String? paymentMethod,
    double? tipAmount,
    String? paymentNotes,
    bool? isDividedAccount,
    List<PersonAccount>? personAccounts,
  }) {
    return BillModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      mesaCodigo: mesaCodigo ?? this.mesaCodigo,
      ordenId: ordenId ?? this.ordenId,
      ordenIds: ordenIds ?? this.ordenIds,
      isGrouped: isGrouped ?? this.isGrouped,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      waiterName: waiterName ?? this.waiterName,
      waiterNotes: waiterNotes ?? this.waiterNotes,
      isPrinted: isPrinted ?? this.isPrinted,
      printedBy: printedBy ?? this.printedBy,
      printedAt: printedAt ?? this.printedAt,
      requestedByWaiter: requestedByWaiter ?? this.requestedByWaiter,
      splitCount: splitCount ?? this.splitCount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tipAmount: tipAmount ?? this.tipAmount,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      isDividedAccount: isDividedAccount ?? this.isDividedAccount,
      personAccounts: personAccounts ?? this.personAccounts,
    );
  }
}

class BillItem {
  final String name;
  final int quantity;
  final double price;
  final double total;
  final String? personId; // Para cuenta dividida: ID de la persona a la que pertenece este item

  BillItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.personId,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      total: json['total'].toDouble(),
      personId: json['personId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'total': total,
      if (personId != null) 'personId': personId,
    };
  }

  BillItem copyWith({
    String? name,
    int? quantity,
    double? price,
    double? total,
    String? personId,
  }) {
    return BillItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
      personId: personId ?? this.personId,
    );
  }
}

/// Representa una persona en una cuenta dividida con sus productos asignados
class PersonAccount {
  final String id; // ID único de la persona (ej: "person_1", "person_2")
  final String name; // Nombre de la persona (ej: "Persona 1", "Juan", etc.)
  final List<BillItem> items; // Productos asignados a esta persona
  final double subtotal; // Subtotal de esta persona
  final double tax; // Impuestos de esta persona
  final double discount; // Descuento de esta persona
  final double total; // Total de esta persona

  PersonAccount({
    required this.id,
    required this.name,
    required this.items,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
  });

  factory PersonAccount.fromJson(Map<String, dynamic> json) {
    return PersonAccount(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
    };
  }

  PersonAccount copyWith({
    String? id,
    String? name,
    List<BillItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
  }) {
    return PersonAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }
}

// CashCloseModel y AuditLogEntry se han movido a admin_model.dart
// Importar desde allí: import '../models/admin_model.dart';

// Tipos de pago
class PaymentType {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String mixed = 'mixed';
  static const String transfer = 'transfer';

  static String getTypeText(String type) {
    switch (type) {
      case cash:
        return 'Efectivo';
      case card:
        return 'Tarjeta';
      case mixed:
        return 'Mixto';
      case transfer:
        return 'Transferencia';
      default:
        return 'Desconocido';
    }
  }
}

// Estados de factura
class BillStatus {
  static const String pending = 'pending';
  static const String printed = 'printed';
  static const String delivered = 'delivered';
  static const String paid = 'paid';
  static const String cancelled = 'cancelled';

  static String getStatusText(String status) {
    switch (status) {
      case pending:
        return 'Pendiente';
      case printed:
        return 'Impreso';
      case delivered:
        return 'Entregado';
      case paid:
        return 'Pagado';
      case cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case printed:
        return Colors.blue;
      case delivered:
        return Colors.green;
      case paid:
        return Colors.green;
      case cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// CashCloseStatus se ha movido a admin_model.dart
// Importar desde allí: import '../models/admin_model.dart';
