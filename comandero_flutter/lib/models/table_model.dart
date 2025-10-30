class TableModel {
  final int id;
  final int number;
  final String status;
  final int seats;
  final int? customers;
  final double? orderValue;
  final String? reservation;
  final TablePosition position;

  TableModel({
    required this.id,
    required this.number,
    required this.status,
    required this.seats,
    this.customers,
    this.orderValue,
    this.reservation,
    required this.position,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      number: json['number'],
      status: json['status'],
      seats: json['seats'],
      customers: json['customers'],
      orderValue: json['orderValue']?.toDouble(),
      reservation: json['reservation'],
      position: TablePosition.fromJson(json['position']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'seats': seats,
      'customers': customers,
      'orderValue': orderValue,
      'reservation': reservation,
      'position': position.toJson(),
    };
  }

  TableModel copyWith({
    int? id,
    int? number,
    String? status,
    int? seats,
    int? customers,
    double? orderValue,
    String? reservation,
    TablePosition? position,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      customers: customers ?? this.customers,
      orderValue: orderValue ?? this.orderValue,
      reservation: reservation ?? this.reservation,
      position: position ?? this.position,
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

