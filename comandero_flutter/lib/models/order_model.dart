class OrderModel {
  final String id;
  final int? tableNumber;
  final List<OrderItem> items;
  final String status;
  final DateTime orderTime;
  final int estimatedTime;
  final String waiter;
  final String priority;
  final bool isTakeaway;
  final String? customerName;
  final String? customerPhone;
  final String? pickupTime;

  OrderModel({
    required this.id,
    this.tableNumber,
    required this.items,
    required this.status,
    required this.orderTime,
    required this.estimatedTime,
    required this.waiter,
    required this.priority,
    this.isTakeaway = false,
    this.customerName,
    this.customerPhone,
    this.pickupTime,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      tableNumber: json['tableNumber'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'],
      orderTime: DateTime.parse(json['orderTime']),
      estimatedTime: json['estimatedTime'],
      waiter: json['waiter'],
      priority: json['priority'],
      isTakeaway: json['isTakeaway'] ?? false,
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      pickupTime: json['pickupTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'orderTime': orderTime.toIso8601String(),
      'estimatedTime': estimatedTime,
      'waiter': waiter,
      'priority': priority,
      'isTakeaway': isTakeaway,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupTime': pickupTime,
    };
  }

  OrderModel copyWith({
    String? id,
    int? tableNumber,
    List<OrderItem>? items,
    String? status,
    DateTime? orderTime,
    int? estimatedTime,
    String? waiter,
    String? priority,
    bool? isTakeaway,
    String? customerName,
    String? customerPhone,
    String? pickupTime,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      status: status ?? this.status,
      orderTime: orderTime ?? this.orderTime,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      waiter: waiter ?? this.waiter,
      priority: priority ?? this.priority,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupTime: pickupTime ?? this.pickupTime,
    );
  }
}

class OrderItem {
  final int id;
  final String name;
  final int quantity;
  final String station;
  final String notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.station,
    this.notes = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      station: json['station'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'station': station,
      'notes': notes,
    };
  }

  OrderItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? station,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      station: station ?? this.station,
      notes: notes ?? this.notes,
    );
  }
}

// Estados de pedidos
class OrderStatus {
  static const String pendiente = 'pendiente';
  static const String enPreparacion = 'en_preparacion';
  static const String listo = 'listo';
  static const String listoParaRecoger = 'listo_para_recoger';

  static String getStatusText(String status) {
    switch (status) {
      case pendiente:
        return 'Pendiente';
      case enPreparacion:
        return 'En Preparación';
      case listo:
        return 'Listo';
      case listoParaRecoger:
        return 'Listo para Recoger';
      default:
        return 'Desconocido';
    }
  }

  static String getStatusColor(String status) {
    switch (status) {
      case pendiente:
        return 'red';
      case enPreparacion:
        return 'yellow';
      case listo:
        return 'green';
      case listoParaRecoger:
        return 'green';
      default:
        return 'gray';
    }
  }
}

// Prioridades de pedidos
class OrderPriority {
  static const String alta = 'alta';
  static const String normal = 'normal';

  static String getPriorityText(String priority) {
    switch (priority) {
      case alta:
        return 'Alta';
      case normal:
        return 'Normal';
      default:
        return 'Normal';
    }
  }

  static String getPriorityColor(String priority) {
    switch (priority) {
      case alta:
        return 'red';
      case normal:
        return 'blue';
      default:
        return 'blue';
    }
  }
}

// Estaciones de cocina
class KitchenStation {
  static const String tacos = 'tacos';
  static const String consomes = 'consomes';
  static const String bebidas = 'bebidas';

  static String getStationName(String station) {
    switch (station) {
      case tacos:
        return 'Tacos';
      case consomes:
        return 'Consomes';
      case bebidas:
        return 'Bebidas';
      default:
        return 'Sin estación';
    }
  }

  static String getStationIcon(String station) {
    switch (station) {
      case tacos:
        return '🍽️';
      case consomes:
        return '🍲';
      case bebidas:
        return '🥤';
      default:
        return '🍽️';
    }
  }
}
