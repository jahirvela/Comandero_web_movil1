import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as date_utils;

class CaptainAlert {
  final String id;
  final String type; // 'table_delayed', 'order_delayed', 'service_issue'
  final String title;
  final String message;
  final int? tableNumber;
  final String? orderNumber;
  final int minutes;
  final String priority; // 'high', 'medium', 'low'
  final DateTime timestamp;
  final bool isRead;

  CaptainAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.tableNumber,
    this.orderNumber,
    required this.minutes,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
  });

  factory CaptainAlert.fromJson(Map<String, dynamic> json) {
    return CaptainAlert(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      tableNumber: json['tableNumber'],
      orderNumber: json['orderNumber'],
      minutes: json['minutes'],
      priority: json['priority'],
      timestamp: date_utils.AppDateUtils.parseToLocal(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'tableNumber': tableNumber,
      'orderNumber': orderNumber,
      'minutes': minutes,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  CaptainAlert copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    int? tableNumber,
    String? orderNumber,
    int? minutes,
    String? priority,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return CaptainAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      tableNumber: tableNumber ?? this.tableNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      minutes: minutes ?? this.minutes,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class CaptainOrder {
  final String id;
  final int tableNumber;
  final String status;
  final DateTime orderTime;
  final int elapsedMinutes;
  final String waiter;
  final double total;
  final List<CaptainOrderItem> items;
  final String priority;
  final bool isUrgent;

  CaptainOrder({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.orderTime,
    required this.elapsedMinutes,
    required this.waiter,
    required this.total,
    required this.items,
    required this.priority,
    this.isUrgent = false,
  });

  factory CaptainOrder.fromJson(Map<String, dynamic> json) {
    return CaptainOrder(
      id: json['id'],
      tableNumber: json['tableNumber'],
      status: json['status'],
      orderTime: date_utils.AppDateUtils.parseToLocal(json['orderTime']),
      elapsedMinutes: json['elapsedMinutes'],
      waiter: json['waiter'],
      total: json['total'].toDouble(),
      items: (json['items'] as List)
          .map((item) => CaptainOrderItem.fromJson(item))
          .toList(),
      priority: json['priority'],
      isUrgent: json['isUrgent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'status': status,
      'orderTime': orderTime.toIso8601String(),
      'elapsedMinutes': elapsedMinutes,
      'waiter': waiter,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
      'priority': priority,
      'isUrgent': isUrgent,
    };
  }
}

class CaptainOrderItem {
  final String name;
  final int quantity;
  final String station;
  final String status;
  final String notes;

  CaptainOrderItem({
    required this.name,
    required this.quantity,
    required this.station,
    required this.status,
    this.notes = '',
  });

  factory CaptainOrderItem.fromJson(Map<String, dynamic> json) {
    return CaptainOrderItem(
      name: json['name'],
      quantity: json['quantity'],
      station: json['station'],
      status: json['status'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'station': station,
      'status': status,
      'notes': notes,
    };
  }
}

class CaptainTable {
  final String codigo;
  final int number;
  final String status;
  final int? customers;
  final String? waiter;
  final DateTime? lastOrderTime;
  final double? currentTotal;
  final bool hasActiveOrder;
  final String? notes;

  CaptainTable({
    required this.codigo,
    required this.number,
    required this.status,
    this.customers,
    this.waiter,
    this.lastOrderTime,
    this.currentTotal,
    this.hasActiveOrder = false,
    this.notes,
  });

  /// Si el código es solo número → "Mesa 1"; si tiene texto → tal cual (ej: "Terraza", "Mesa de Prueba")
  String get displayLabel {
    final c = codigo.trim();
    if (c.isEmpty) return codigo;
    final n = int.tryParse(c);
    return (n != null && n.toString() == c) ? 'Mesa $c' : codigo;
  }

  factory CaptainTable.fromJson(Map<String, dynamic> json) {
    final codigo = (json['codigo'] as String?) ?? json['number']?.toString() ?? '0';
    final number = json['number'] is int ? json['number'] as int : (int.tryParse(codigo) ?? 0);
    return CaptainTable(
      codigo: codigo,
      number: number,
      status: json['status'],
      customers: json['customers'],
      waiter: json['waiter'],
      lastOrderTime: json['lastOrderTime'] != null
          ? date_utils.AppDateUtils.parseToLocal(json['lastOrderTime'])
          : null,
      currentTotal: json['currentTotal']?.toDouble(),
      hasActiveOrder: json['hasActiveOrder'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'number': number,
      'status': status,
      'customers': customers,
      'waiter': waiter,
      'lastOrderTime': lastOrderTime?.toIso8601String(),
      'currentTotal': currentTotal,
      'hasActiveOrder': hasActiveOrder,
      'notes': notes,
    };
  }

  CaptainTable copyWith({
    String? codigo,
    int? number,
    String? status,
    int? customers,
    String? waiter,
    DateTime? lastOrderTime,
    double? currentTotal,
    bool? hasActiveOrder,
    String? notes,
  }) {
    return CaptainTable(
      codigo: codigo ?? this.codigo,
      number: number ?? this.number,
      status: status ?? this.status,
      customers: customers ?? this.customers,
      waiter: waiter ?? this.waiter,
      lastOrderTime: lastOrderTime ?? this.lastOrderTime,
      currentTotal: currentTotal ?? this.currentTotal,
      hasActiveOrder: hasActiveOrder ?? this.hasActiveOrder,
      notes: notes ?? this.notes,
    );
  }
}

class CaptainStats {
  final double todaySales;
  final String variation;
  final double avgTicket;
  final int totalOrders;
  final int activeTables;
  final int pendingOrders;
  final int urgentOrders;

  CaptainStats({
    required this.todaySales,
    required this.variation,
    required this.avgTicket,
    required this.totalOrders,
    required this.activeTables,
    required this.pendingOrders,
    required this.urgentOrders,
  });

  factory CaptainStats.fromJson(Map<String, dynamic> json) {
    return CaptainStats(
      todaySales: json['todaySales'].toDouble(),
      variation: json['variation'],
      avgTicket: json['avgTicket'].toDouble(),
      totalOrders: json['totalOrders'],
      activeTables: json['activeTables'],
      pendingOrders: json['pendingOrders'],
      urgentOrders: json['urgentOrders'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaySales': todaySales,
      'variation': variation,
      'avgTicket': avgTicket,
      'totalOrders': totalOrders,
      'activeTables': activeTables,
      'pendingOrders': pendingOrders,
      'urgentOrders': urgentOrders,
    };
  }
}

// Tipos de alertas
class AlertType {
  static const String tableDelayed = 'table_delayed';
  static const String orderDelayed = 'order_delayed';
  static const String serviceIssue = 'service_issue';

  static String getTypeText(String type) {
    switch (type) {
      case tableDelayed:
        return 'Mesa Retrasada';
      case orderDelayed:
        return 'Orden Retrasada';
      case serviceIssue:
        return 'Problema de Servicio';
      default:
        return 'Alerta';
    }
  }

  static IconData getTypeIcon(String type) {
    switch (type) {
      case tableDelayed:
        return Icons.table_bar;
      case orderDelayed:
        return Icons.access_time;
      case serviceIssue:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

// Prioridades de alertas
class AlertPriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';

  static String getPriorityText(String priority) {
    switch (priority) {
      case high:
        return 'Alta';
      case medium:
        return 'Media';
      case low:
        return 'Baja';
      default:
        return 'Normal';
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case high:
        return Colors.red;
      case medium:
        return Colors.orange;
      case low:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Estados de mesas para el capitán
class CaptainTableStatus {
  static const String disponible = 'disponible';
  static const String ocupada = 'ocupada';
  static const String cuenta = 'cuenta';
  static const String reservada = 'reservada';
  static const String servicio = 'servicio';

  static String getStatusText(String status) {
    switch (status) {
      case disponible:
        return 'Disponible';
      case ocupada:
        return 'Ocupada';
      case cuenta:
        return 'Cuenta';
      case reservada:
        return 'Reservada';
      case servicio:
        return 'En Servicio';
      default:
        return 'Desconocido';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case disponible:
        return Colors.green;
      case ocupada:
        return Colors.red;
      case cuenta:
        return Colors.orange;
      case reservada:
        return Colors.blue;
      case servicio:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// Estados de órdenes para el capitán
class CaptainOrderStatus {
  static const String preparando = 'preparando';
  static const String listo = 'listo';
  static const String entregado = 'entregado';
  static const String cancelado = 'cancelado';

  static String getStatusText(String status) {
    switch (status) {
      case preparando:
        return 'Preparando';
      case listo:
        return 'Listo';
      case entregado:
        return 'Entregado';
      case cancelado:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case preparando:
        return Colors.yellow;
      case listo:
        return Colors.green;
      case entregado:
        return Colors.blue;
      case cancelado:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
