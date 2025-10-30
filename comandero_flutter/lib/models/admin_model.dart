import 'package:flutter/material.dart';

class AdminUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final List<String> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? createdBy;

  AdminUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    required this.roles,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    this.createdBy,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      roles: List<String>.from(json['roles']),
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'roles': roles,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  AdminUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    List<String>? roles,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? createdBy,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double currentStock;
  final double minStock;
  final double maxStock;
  final double minimumStock;
  final String unit;
  final double cost;
  final double price;
  final double unitPrice;
  final String? supplier;
  final DateTime? lastRestock;
  final DateTime? expiryDate;
  final String status; // 'available', 'low_stock', 'out_of_stock', 'expired'
  final String? notes;
  final String? description;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.minimumStock,
    required this.unit,
    required this.cost,
    required this.price,
    required this.unitPrice,
    this.supplier,
    this.lastRestock,
    this.expiryDate,
    required this.status,
    this.notes,
    this.description,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      currentStock: json['currentStock'].toDouble(),
      minStock: json['minStock'].toDouble(),
      maxStock: json['maxStock'].toDouble(),
      minimumStock:
          json['minimumStock']?.toDouble() ?? json['minStock'].toDouble(),
      unit: json['unit'],
      cost: json['cost'].toDouble(),
      price: json['price'].toDouble(),
      unitPrice: json['unitPrice']?.toDouble() ?? json['price'].toDouble(),
      supplier: json['supplier'],
      lastRestock: json['lastRestock'] != null
          ? DateTime.parse(json['lastRestock'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      status: json['status'],
      notes: json['notes'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'minStock': minStock,
      'maxStock': maxStock,
      'minimumStock': minimumStock,
      'unit': unit,
      'cost': cost,
      'price': price,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'lastRestock': lastRestock?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'description': description,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    double? minStock,
    double? maxStock,
    double? minimumStock,
    String? unit,
    double? cost,
    double? price,
    double? unitPrice,
    String? supplier,
    DateTime? lastRestock,
    DateTime? expiryDate,
    String? status,
    String? notes,
    String? description,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      cost: cost ?? this.cost,
      price: price ?? this.price,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      lastRestock: lastRestock ?? this.lastRestock,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      description: description ?? this.description,
    );
  }
}

class SalesReport {
  final String id;
  final DateTime date;
  final double totalSales;
  final double cashSales;
  final double cardSales;
  final int totalOrders;
  final int tableOrders;
  final int takeawayOrders;
  final double averageTicket;
  final double tips;
  final Map<String, double> salesByCategory;
  final Map<String, int> ordersByHour;
  final List<SalesItem> topProducts;

  SalesReport({
    required this.id,
    required this.date,
    required this.totalSales,
    required this.cashSales,
    required this.cardSales,
    required this.totalOrders,
    required this.tableOrders,
    required this.takeawayOrders,
    required this.averageTicket,
    required this.tips,
    required this.salesByCategory,
    required this.ordersByHour,
    required this.topProducts,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      id: json['id'],
      date: DateTime.parse(json['date']),
      totalSales: json['totalSales'].toDouble(),
      cashSales: json['cashSales'].toDouble(),
      cardSales: json['cardSales'].toDouble(),
      totalOrders: json['totalOrders'],
      tableOrders: json['tableOrders'],
      takeawayOrders: json['takeawayOrders'],
      averageTicket: json['averageTicket'].toDouble(),
      tips: json['tips'].toDouble(),
      salesByCategory: Map<String, double>.from(json['salesByCategory']),
      ordersByHour: Map<String, int>.from(json['ordersByHour']),
      topProducts: (json['topProducts'] as List)
          .map((item) => SalesItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalSales': totalSales,
      'cashSales': cashSales,
      'cardSales': cardSales,
      'totalOrders': totalOrders,
      'tableOrders': tableOrders,
      'takeawayOrders': takeawayOrders,
      'averageTicket': averageTicket,
      'tips': tips,
      'salesByCategory': salesByCategory,
      'ordersByHour': ordersByHour,
      'topProducts': topProducts.map((item) => item.toJson()).toList(),
    };
  }
}

class SalesItem {
  final String name;
  final int quantity;
  final double revenue;
  final String category;

  SalesItem({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.category,
  });

  factory SalesItem.fromJson(Map<String, dynamic> json) {
    return SalesItem(
      name: json['name'],
      quantity: json['quantity'],
      revenue: json['revenue'].toDouble(),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'revenue': revenue,
      'category': category,
    };
  }
}

class DashboardStats {
  final double todaySales;
  final double yesterdaySales;
  final double salesGrowth;
  final int totalOrders;
  final int activeUsers;
  final int lowStockItems;
  final double averageTicket;
  final double totalTips;
  final Map<String, double> salesByHour;
  final List<SalesItem> topProducts;

  DashboardStats({
    required this.todaySales,
    required this.yesterdaySales,
    required this.salesGrowth,
    required this.totalOrders,
    required this.activeUsers,
    required this.lowStockItems,
    required this.averageTicket,
    required this.totalTips,
    required this.salesByHour,
    required this.topProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todaySales: json['todaySales'].toDouble(),
      yesterdaySales: json['yesterdaySales'].toDouble(),
      salesGrowth: json['salesGrowth'].toDouble(),
      totalOrders: json['totalOrders'],
      activeUsers: json['activeUsers'],
      lowStockItems: json['lowStockItems'],
      averageTicket: json['averageTicket'].toDouble(),
      totalTips: json['totalTips'].toDouble(),
      salesByHour: Map<String, double>.from(json['salesByHour']),
      topProducts: (json['topProducts'] as List)
          .map((item) => SalesItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaySales': todaySales,
      'yesterdaySales': yesterdaySales,
      'salesGrowth': salesGrowth,
      'totalOrders': totalOrders,
      'activeUsers': activeUsers,
      'lowStockItems': lowStockItems,
      'averageTicket': averageTicket,
      'totalTips': totalTips,
      'salesByHour': salesByHour,
      'topProducts': topProducts.map((item) => item.toJson()).toList(),
    };
  }
}

class MenuItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final bool isAvailable;
  final String? image;
  final List<String> ingredients;
  final List<String> allergens;
  final int preparationTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.isAvailable,
    this.image,
    required this.ingredients,
    required this.allergens,
    required this.preparationTime,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      price: json['price'].toDouble(),
      isAvailable: json['isAvailable'],
      image: json['image'],
      ingredients: List<String>.from(json['ingredients']),
      allergens: List<String>.from(json['allergens']),
      preparationTime: json['preparationTime'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'isAvailable': isAvailable,
      'image': image,
      'ingredients': ingredients,
      'allergens': allergens,
      'preparationTime': preparationTime,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? price,
    bool? isAvailable,
    String? image,
    List<String>? ingredients,
    List<String>? allergens,
    int? preparationTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      image: image ?? this.image,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      preparationTime: preparationTime ?? this.preparationTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TableModel {
  final int id;
  final int number;
  final String status;
  final int seats;
  final int? customers;
  final String? waiter;
  final double? currentTotal;
  final DateTime? lastOrderTime;
  final String? notes;

  TableModel({
    required this.id,
    required this.number,
    required this.status,
    required this.seats,
    this.customers,
    this.waiter,
    this.currentTotal,
    this.lastOrderTime,
    this.notes,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      number: json['number'],
      status: json['status'],
      seats: json['seats'],
      customers: json['customers'],
      waiter: json['waiter'],
      currentTotal: json['currentTotal']?.toDouble(),
      lastOrderTime: json['lastOrderTime'] != null
          ? DateTime.parse(json['lastOrderTime'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'seats': seats,
      'customers': customers,
      'waiter': waiter,
      'currentTotal': currentTotal,
      'lastOrderTime': lastOrderTime?.toIso8601String(),
      'notes': notes,
    };
  }

  TableModel copyWith({
    int? id,
    int? number,
    String? status,
    int? seats,
    int? customers,
    String? waiter,
    double? currentTotal,
    DateTime? lastOrderTime,
    String? notes,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      customers: customers ?? this.customers,
      waiter: waiter ?? this.waiter,
      currentTotal: currentTotal ?? this.currentTotal,
      lastOrderTime: lastOrderTime ?? this.lastOrderTime,
      notes: notes ?? this.notes,
    );
  }
}

// Estados de inventario
class InventoryStatus {
  static const String available = 'available';
  static const String lowStock = 'low_stock';
  static const String outOfStock = 'out_of_stock';
  static const String expired = 'expired';

  static String getStatusText(String status) {
    switch (status) {
      case available:
        return 'Disponible';
      case lowStock:
        return 'Stock Bajo';
      case outOfStock:
        return 'Sin Stock';
      case expired:
        return 'Vencido';
      default:
        return 'Desconocido';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case available:
        return Colors.green;
      case lowStock:
        return Colors.orange;
      case outOfStock:
        return Colors.red;
      case expired:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Roles de usuario
class UserRole {
  static const String mesero = 'mesero';
  static const String cocinero = 'cocinero';
  static const String cajero = 'cajero';
  static const String capitan = 'capitan';
  static const String admin = 'admin';

  static String getRoleText(String role) {
    switch (role) {
      case mesero:
        return 'Mesero';
      case cocinero:
        return 'Cocinero';
      case cajero:
        return 'Cajero';
      case capitan:
        return 'Capitán';
      case admin:
        return 'Administrador';
      default:
        return 'Desconocido';
    }
  }

  static Color getRoleColor(String role) {
    switch (role) {
      case mesero:
        return Colors.blue;
      case cocinero:
        return Colors.orange;
      case cajero:
        return Colors.green;
      case capitan:
        return Colors.purple;
      case admin:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  static Color getStatusColor(String status) {
    switch (status) {
      case libre:
        return Colors.green;
      case ocupada:
        return Colors.red;
      case enLimpieza:
        return Colors.orange;
      case reservada:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Categorías de inventario
class InventoryCategory {
  static const String carnes = 'carnes';
  static const String verduras = 'verduras';
  static const String bebidas = 'bebidas';
  static const String condimentos = 'condimentos';
  static const String utensilios = 'utensilios';

  static String getCategoryText(String category) {
    switch (category) {
      case carnes:
        return 'Carnes';
      case verduras:
        return 'Verduras';
      case bebidas:
        return 'Bebidas';
      case condimentos:
        return 'Condimentos';
      case utensilios:
        return 'Utensilios';
      default:
        return 'Otros';
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case carnes:
        return Colors.red;
      case verduras:
        return Colors.green;
      case bebidas:
        return Colors.blue;
      case condimentos:
        return Colors.orange;
      case utensilios:
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }
}

// Categorías de menú
class MenuCategory {
  static const String tacos = 'tacos';
  static const String consomes = 'consomes';
  static const String bebidas = 'bebidas';
  static const String postres = 'postres';

  static String getCategoryText(String category) {
    switch (category) {
      case tacos:
        return 'Tacos';
      case consomes:
        return 'Consomes';
      case bebidas:
        return 'Bebidas';
      case postres:
        return 'Postres';
      default:
        return 'Otros';
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case tacos:
        return Colors.orange;
      case consomes:
        return Colors.brown;
      case bebidas:
        return Colors.blue;
      case postres:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

// Modelo para cierres de caja
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
      'totalDeclarado': totalDeclarado,
      'auditLog': auditLog.map((entry) => entry.toJson()).toList(),
    };
  }

  CashCloseModel copyWith({
    String? id,
    DateTime? fecha,
    String? periodo,
    String? usuario,
    double? totalNeto,
    double? efectivo,
    double? tarjeta,
    double? propinasTarjeta,
    double? propinasEfectivo,
    int? pedidosParaLlevar,
    String? estado,
    double? efectivoContado,
    double? totalTarjeta,
    double? otrosIngresos,
    double? totalDeclarado,
    List<AuditLogEntry>? auditLog,
  }) {
    return CashCloseModel(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      periodo: periodo ?? this.periodo,
      usuario: usuario ?? this.usuario,
      totalNeto: totalNeto ?? this.totalNeto,
      efectivo: efectivo ?? this.efectivo,
      tarjeta: tarjeta ?? this.tarjeta,
      propinasTarjeta: propinasTarjeta ?? this.propinasTarjeta,
      propinasEfectivo: propinasEfectivo ?? this.propinasEfectivo,
      pedidosParaLlevar: pedidosParaLlevar ?? this.pedidosParaLlevar,
      estado: estado ?? this.estado,
      efectivoContado: efectivoContado ?? this.efectivoContado,
      totalTarjeta: totalTarjeta ?? this.totalTarjeta,
      otrosIngresos: otrosIngresos ?? this.otrosIngresos,
      totalDeclarado: totalDeclarado ?? this.totalDeclarado,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}

// Modelo para entradas de auditoría
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

// Estados de cierre de caja
class CashCloseStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String clarification = 'clarification';

  static String getStatusText(String status) {
    switch (status) {
      case pending:
        return 'Pendiente';
      case approved:
        return 'Aprobado';
      case rejected:
        return 'Rechazado';
      case clarification:
        return 'Aclaración';
      default:
        return 'Desconocido';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      case approved:
        return Colors.green;
      case rejected:
        return Colors.red;
      case clarification:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
