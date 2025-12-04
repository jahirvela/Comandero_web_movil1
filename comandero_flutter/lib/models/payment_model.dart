import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as date_utils;

class PaymentModel {
  final String id;
  final String type; // 'cash', 'card', 'mixed'
  final double totalAmount;
  final double? cashReceived;
  final double? tipAmount;
  final bool tipDelivered;
  final double? cashApplied;
  final double? change;
  final String? notes;
  final int? tableNumber;
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
    this.tableNumber,
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
      tableNumber: json['tableNumber'],
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
      'tableNumber': tableNumber,
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
    int? tableNumber,
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
      tableNumber: tableNumber ?? this.tableNumber,
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
  final int? ordenId; // ID de la orden en la BD (requerido para pagos)
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

  BillModel({
    required this.id,
    this.tableNumber,
    this.ordenId, // ID de la orden en la BD
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
  });

  /// Calcula el total real sumando precio * cantidad de cada item
  /// Esto asegura que siempre se muestre el precio correcto
  double get calculatedTotal {
    final totalFromItems = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return totalFromItems - discount + tax;
  }

  /// Genera un ID de visualización claro y legible para el cajero
  /// Ejemplos:
  /// - "BILL-MESA-2-30-31-32" -> "Cuenta agrupada - Mesa 2"
  /// - "BILL-ORD-30" -> "ORD-000030"
  String get displayId {
    // Si el ID contiene múltiples órdenes (formato BILL-MESA-X-Y-Z)
    if (id.contains('BILL-MESA-') && id.contains('-')) {
      final parts = id.split('-');
      if (parts.length >= 4) {
        final mesaNumero = parts[2];
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

  /// Extrae los IDs de órdenes del billId para mostrar información detallada
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
      tableNumber: json['tableNumber'],
      ordenId: json['ordenId'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'ordenId': ordenId,
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
    };
  }

  BillModel copyWith({
    String? id,
    int? tableNumber,
    int? ordenId,
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
  }) {
    return BillModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      ordenId: ordenId ?? this.ordenId,
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
    );
  }
}

class BillItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  BillItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      total: json['total'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'price': price, 'total': total};
  }
}

// CashCloseModel y AuditLogEntry se han movido a admin_model.dart
// Importar desde allí: import '../models/admin_model.dart';

// Tipos de pago
class PaymentType {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String mixed = 'mixed';

  static String getTypeText(String type) {
    switch (type) {
      case cash:
        return 'Efectivo';
      case card:
        return 'Tarjeta';
      case mixed:
        return 'Mixto';
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
