/**
 * Modelo para alertas de cocina (nuevo sistema)
 * 
 * Este modelo corresponde a KitchenAlertPayload del backend.
 * Representa una alerta enviada desde el mesero hacia los cocineros.
 */

enum AlertType {
  NEW_ORDER,
  UPDATE_ORDER,
  CANCEL_ORDER,
  EXTRA_ITEM;

  static AlertType? fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NEW_ORDER':
        return AlertType.NEW_ORDER;
      case 'UPDATE_ORDER':
        return AlertType.UPDATE_ORDER;
      case 'CANCEL_ORDER':
        return AlertType.CANCEL_ORDER;
      case 'EXTRA_ITEM':
        return AlertType.EXTRA_ITEM;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.NEW_ORDER:
        return 'Nueva Orden';
      case AlertType.UPDATE_ORDER:
        return 'Actualización';
      case AlertType.CANCEL_ORDER:
        return 'Cancelación';
      case AlertType.EXTRA_ITEM:
        return 'Item Extra';
    }
  }
}

enum StationType {
  tacos,
  consomes,
  bebidas,
  general;

  static StationType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tacos':
        return StationType.tacos;
      case 'consomes':
        return StationType.consomes;
      case 'bebidas':
        return StationType.bebidas;
      case 'general':
        return StationType.general;
      default:
        return StationType.general;
    }
  }

  String get displayName {
    switch (this) {
      case StationType.tacos:
        return 'Tacos';
      case StationType.consomes:
        return 'Consomes';
      case StationType.bebidas:
        return 'Bebidas';
      case StationType.general:
        return 'General';
    }
  }
}

class KitchenAlert {
  final int? id;                  // ID de la alerta en BD (opcional)
  final int orderId;              // ID de la orden
  final int? tableId;             // ID de la mesa (null si es para llevar)
  final String? mesaCodigo;       // Código visible de la mesa (ej: "1")
  final StationType station;      // Estación de cocina
  final AlertType type;           // Tipo de alerta
  final String message;           // Mensaje descriptivo
  final int createdByUserId;      // ID del usuario que creó la alerta
  final DateTime? createdAt;      // Fecha de creación
  final String priority;          // Prioridad: 'Normal' o 'Urgente'
  final String? createdByUsername; // Username del usuario que envía
  final String? createdByRole;     // Rol: 'mesero' o 'capitan'

  KitchenAlert({
    this.id,
    required this.orderId,
    this.tableId,
    this.mesaCodigo,
    required this.station,
    required this.type,
    required this.message,
    required this.createdByUserId,
    this.createdAt,
    this.priority = 'Normal',     // Por defecto es Normal
    this.createdByUsername,
    this.createdByRole,
  });

  factory KitchenAlert.fromJson(Map<String, dynamic> json) {
    return KitchenAlert(
      id: json['id'] as int?,
      orderId: json['orderId'] as int,
      tableId: json['tableId'] as int?,
      mesaCodigo: json['mesaCodigo'] as String?,
      station: StationType.fromString(json['station'] as String? ?? 'general') ?? StationType.general,
      type: AlertType.fromString(json['type'] as String? ?? 'NEW_ORDER') ?? AlertType.NEW_ORDER,
      message: json['message'] as String,
      createdByUserId: json['createdByUserId'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      priority: json['priority'] as String? ?? 'Normal',
      createdByUsername: json['createdByUsername'] as String?,
      createdByRole: json['createdByRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      if (tableId != null) 'tableId': tableId,
      if (mesaCodigo != null) 'mesaCodigo': mesaCodigo,
      'station': station.name,
      'type': type.name,
      'message': message,
      'createdByUserId': createdByUserId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'priority': priority,
      if (createdByUsername != null) 'createdByUsername': createdByUsername,
      if (createdByRole != null) 'createdByRole': createdByRole,
    };
  }

  KitchenAlert copyWith({
    int? id,
    int? orderId,
    int? tableId,
    String? mesaCodigo,
    StationType? station,
    AlertType? type,
    String? message,
    int? createdByUserId,
    DateTime? createdAt,
    String? priority,
    String? createdByUsername,
    String? createdByRole,
  }) {
    return KitchenAlert(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      mesaCodigo: mesaCodigo ?? this.mesaCodigo,
      station: station ?? this.station,
      type: type ?? this.type,
      message: message ?? this.message,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      createdByRole: createdByRole ?? this.createdByRole,
    );
  }

  @override
  String toString() {
    return 'KitchenAlert(id: $id, orderId: $orderId, station: ${station.name}, type: ${type.name}, message: $message)';
  }
}

