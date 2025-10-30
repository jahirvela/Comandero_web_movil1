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
      timestamp: DateTime.parse(json['timestamp']),
      cashierName: json['cashierName'],
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
    );
  }
}

class BillModel {
  final String id;
  final int? tableNumber;
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // 'pending', 'paid', 'cancelled'
  final DateTime createdAt;
  final String? customerName;
  final bool isTakeaway;

  BillModel({
    required this.id,
    this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.isTakeaway = false,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      tableNumber: json['tableNumber'],
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      customerName: json['customerName'],
      isTakeaway: json['isTakeaway'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'isTakeaway': isTakeaway,
    };
  }

  BillModel copyWith({
    String? id,
    int? tableNumber,
    List<BillItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    DateTime? createdAt,
    String? customerName,
    bool? isTakeaway,
  }) {
    return BillModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      isTakeaway: isTakeaway ?? this.isTakeaway,
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

class CashCloseModel {
  final String id;
  final DateTime fecha;
  final String periodo;
  final String usuario;
  final double totalNeto;
  final double efectivo;
  final double tarjeta;
  final double propinasTarjeta;
  final double propinasEfectivo;
  final int pedidosParaLlevar;
  final String estado;
  final double efectivoContado;
  final double totalTarjeta;
  final double otrosIngresos;
  final String? otrosIngresosTexto;
  final String? notaCajero;
  final double totalDeclarado;
  final List<AuditLogEntry> auditLog;

  CashCloseModel({
    required this.id,
    required this.fecha,
    required this.periodo,
    required this.usuario,
    required this.totalNeto,
    required this.efectivo,
    required this.tarjeta,
    required this.propinasTarjeta,
    required this.propinasEfectivo,
    required this.pedidosParaLlevar,
    required this.estado,
    required this.efectivoContado,
    required this.totalTarjeta,
    required this.otrosIngresos,
    this.otrosIngresosTexto,
    this.notaCajero,
    required this.totalDeclarado,
    required this.auditLog,
  });

  factory CashCloseModel.fromJson(Map<String, dynamic> json) {
    return CashCloseModel(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      periodo: json['periodo'],
      usuario: json['usuario'],
      totalNeto: json['totalNeto'].toDouble(),
      efectivo: json['efectivo'].toDouble(),
      tarjeta: json['tarjeta'].toDouble(),
      propinasTarjeta: json['propinasTarjeta'].toDouble(),
      propinasEfectivo: json['propinasEfectivo'].toDouble(),
      pedidosParaLlevar: json['pedidosParaLlevar'],
      estado: json['estado'],
      efectivoContado: json['efectivoContado'].toDouble(),
      totalTarjeta: json['totalTarjeta'].toDouble(),
      otrosIngresos: json['otrosIngresos'].toDouble(),
      otrosIngresosTexto: json['otrosIngresosTexto'],
      notaCajero: json['notaCajero'],
      totalDeclarado: json['totalDeclarado'].toDouble(),
      auditLog: (json['auditLog'] as List)
          .map((entry) => AuditLogEntry.fromJson(entry))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'periodo': periodo,
      'usuario': usuario,
      'totalNeto': totalNeto,
      'efectivo': efectivo,
      'tarjeta': tarjeta,
      'propinasTarjeta': propinasTarjeta,
      'propinasEfectivo': propinasEfectivo,
      'pedidosParaLlevar': pedidosParaLlevar,
      'estado': estado,
      'efectivoContado': efectivoContado,
      'totalTarjeta': totalTarjeta,
      'otrosIngresos': otrosIngresos,
      'otrosIngresosTexto': otrosIngresosTexto,
      'notaCajero': notaCajero,
      'totalDeclarado': totalDeclarado,
      'auditLog': auditLog.map((entry) => entry.toJson()).toList(),
    };
  }
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String action;
  final String usuario;
  final String mensaje;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.usuario,
    required this.mensaje,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'],
      usuario: json['usuario'],
      mensaje: json['mensaje'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'usuario': usuario,
      'mensaje': mensaje,
    };
  }
}

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
  static const String paid = 'paid';
  static const String cancelled = 'cancelled';

  static String getStatusText(String status) {
    switch (status) {
      case pending:
        return 'Pendiente';
      case paid:
        return 'Pagado';
      case cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }
}

// Estados de cierre de caja
class CashCloseStatus {
  static const String pending = 'Pendiente verificación';
  static const String approved = 'Aprobado';
  static const String rejected = 'Rechazado';
  static const String clarification = 'Requiere aclaración';

  static String getStatusText(String status) {
    switch (status) {
      case pending:
        return 'Pendiente verificación';
      case approved:
        return 'Aprobado';
      case rejected:
        return 'Rechazado';
      case clarification:
        return 'Requiere aclaración';
      default:
        return 'Desconocido';
    }
  }
}

