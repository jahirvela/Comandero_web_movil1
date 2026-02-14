class TableModel {
  final int id;
  /// Código o nombre de la mesa (ej: "1", "Terraza", "VIP 1"). Se usa en tickets, cocina, cuentas por cobrar.
  final String codigo;
  final int number; // Compatibilidad/orden: int.parse(codigo) si es numérico
  final String status;
  final int seats;
  final int? customers;
  final double? orderValue;
  final String? reservation;
  final TablePosition position;
  final String? section; // Área/sección de la mesa

  TableModel({
    required this.id,
    required this.codigo,
    required this.number,
    required this.status,
    required this.seats,
    this.customers,
    this.orderValue,
    this.reservation,
    required this.position,
    this.section,
  });

  /// Etiqueta para mostrar: si el código es solo número → "Mesa 1"; si tiene texto → tal cual (ej: "Terraza", "Mesa de Prueba")
  String get displayLabel {
    final c = codigo.trim();
    if (c.isEmpty) return codigo;
    final n = int.tryParse(c);
    return (n != null && n.toString() == c) ? 'Mesa $c' : codigo;
  }

  /// Genera la etiqueta de mesa a partir de código o número (para usar sin un TableModel).
  static String displayLabelFromCodigo(String? codigo, [int? fallbackNumber]) {
    if (codigo != null && codigo.isNotEmpty) {
      final c = codigo.trim();
      final n = int.tryParse(c);
      return (n != null && n.toString() == c) ? 'Mesa $c' : codigo;
    }
    if (fallbackNumber != null) return 'Mesa $fallbackNumber';
    return 'N/A';
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    final codigo = (json['codigo'] as String?) ?? json['number']?.toString() ?? '0';
    final number = json['number'] is int ? json['number'] as int : (int.tryParse(codigo) ?? 0);
    return TableModel(
      id: json['id'],
      codigo: codigo,
      number: number,
      status: json['status'],
      seats: json['seats'],
      customers: json['customers'],
      orderValue: json['orderValue']?.toDouble(),
      reservation: json['reservation'],
      position: TablePosition.fromJson(json['position']),
      section: json['section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'number': number,
      'status': status,
      'seats': seats,
      'customers': customers,
      'orderValue': orderValue,
      'reservation': reservation,
      'position': position.toJson(),
      'section': section,
    };
  }

  TableModel copyWith({
    int? id,
    String? codigo,
    int? number,
    String? status,
    int? seats,
    int? customers,
    double? orderValue,
    String? reservation,
    TablePosition? position,
    String? section,
  }) {
    return TableModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      number: number ?? this.number,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      customers: customers ?? this.customers,
      orderValue: orderValue ?? this.orderValue,
      reservation: reservation ?? this.reservation,
      position: position ?? this.position,
      section: section ?? this.section,
    );
  }
}

class TablePosition {
  final int x;
  final int y;

  TablePosition({required this.x, required this.y});

  factory TablePosition.fromJson(Map<String, dynamic> json) {
    return TablePosition(x: json['x'], y: json['y']);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }
}

// Estados de mesa
class TableStatus {
  static const String libre = 'libre';
  static const String ocupada = 'ocupada';
  static const String enLimpieza = 'en-limpieza';
  static const String reservada = 'reservada';

  static String getStatusText(String status) {
    switch (status) {
      case libre:
        return 'Libre';
      case ocupada:
        return 'Ocupada';
      case enLimpieza:
        return 'En Limpieza';
      case reservada:
        return 'Reservada';
      default:
        return 'Desconocido';
    }
  }

  static String getStatusIcon(String status) {
    switch (status) {
      case libre:
        return '🟢';
      case ocupada:
        return '🔴';
      case enLimpieza:
        return '⚪';
      case reservada:
        return '🟡';
      default:
        return '⚪';
    }
  }
}

