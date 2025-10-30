import 'package:flutter/material.dart';
import '../models/admin_model.dart';

class AdminController extends ChangeNotifier {
  // Estado de usuarios
  List<AdminUser> _users = [];

  // Estado de inventario
  List<InventoryItem> _inventory = [];

  // Estado de cierres de caja
  List<CashCloseModel> _cashClosures = [];

  // Estado de menú
  List<MenuItem> _menuItems = [];

  // Estado de mesas
  List<TableModel> _tables = [];

  // Estado de reportes
  final List<SalesReport> _salesReports = [];

  // Estadísticas del dashboard
  DashboardStats _dashboardStats = DashboardStats(
    todaySales: 0,
    yesterdaySales: 0,
    salesGrowth: 0,
    totalOrders: 0,
    activeUsers: 0,
    lowStockItems: 0,
    averageTicket: 0,
    totalTips: 0,
    salesByHour: {},
    topProducts: [],
  );

  // Filtros
  String _selectedUserRole = 'todos';
  String _selectedUserStatus = 'todos';
  String _selectedInventoryCategory = 'todos';
  String _selectedInventoryStatus = 'todos';
  String _selectedMenuCategory = 'todos';
  String _selectedTableStatus = 'todos';
  String _searchQuery = '';

  // Vista actual
  String _currentView = 'dashboard';

  // Getters
  List<AdminUser> get users => _users;
  List<InventoryItem> get inventory => _inventory;
  List<InventoryItem> get inventoryItems => _inventory;
  List<CashCloseModel> get cashClosures => _cashClosures;
  List<MenuItem> get menuItems => _menuItems;
  List<TableModel> get tables => _tables;
  List<SalesReport> get salesReports => _salesReports;
  DashboardStats get dashboardStats => _dashboardStats;
  String get selectedUserRole => _selectedUserRole;
  String get selectedUserStatus => _selectedUserStatus;
  String get selectedInventoryCategory => _selectedInventoryCategory;
  String get selectedInventoryStatus => _selectedInventoryStatus;
  String get selectedMenuCategory => _selectedMenuCategory;
  String get selectedTableStatus => _selectedTableStatus;
  String get searchQuery => _searchQuery;
  String get currentView => _currentView;

  // Obtener usuarios filtrados
  List<AdminUser> get filteredUsers {
    return _users.where((user) {
      final roleMatch =
          _selectedUserRole == 'todos' ||
          user.roles.contains(_selectedUserRole);
      final statusMatch =
          _selectedUserStatus == 'todos' ||
          (_selectedUserStatus == 'activos' && user.isActive) ||
          (_selectedUserStatus == 'inactivos' && !user.isActive);
      final searchMatch =
          _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return roleMatch && statusMatch && searchMatch;
    }).toList();
  }

  // Obtener inventario filtrado
  List<InventoryItem> get filteredInventory {
    return _inventory.where((item) {
      final categoryMatch =
          _selectedInventoryCategory == 'todos' ||
          item.category == _selectedInventoryCategory;
      final statusMatch =
          _selectedInventoryStatus == 'todos' ||
          item.status == _selectedInventoryStatus;
      final searchMatch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && statusMatch && searchMatch;
    }).toList();
  }

  // Obtener menú filtrado
  List<MenuItem> get filteredMenuItems {
    return _menuItems.where((item) {
      final categoryMatch =
          _selectedMenuCategory == 'todos' ||
          item.category == _selectedMenuCategory;
      final searchMatch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();
  }

  // Obtener mesas filtradas
  List<TableModel> get filteredTables {
    return _tables.where((table) {
      final statusMatch =
          _selectedTableStatus == 'todos' ||
          table.status == _selectedTableStatus;
      return statusMatch;
    }).toList();
  }

  AdminController() {
    _initializeData();
  }

  void _initializeData() {
    // Inicializar usuarios de ejemplo
    _users = [
      AdminUser(
        id: 'user_001',
        name: 'María González',
        username: 'admin',
        email: 'maria@comandix.com',
        phone: '55 1234 5678',
        roles: [UserRole.admin],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
        createdBy: 'system',
      ),
      AdminUser(
        id: 'user_002',
        name: 'Juan Martínez',
        username: 'mesero',
        email: 'juan@comandix.com',
        phone: '55 2345 6789',
        roles: [UserRole.mesero],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
        createdBy: 'user_001',
      ),
      AdminUser(
        id: 'user_003',
        name: 'Carlos López',
        username: 'cocina',
        email: 'carlos@comandix.com',
        phone: '55 3456 7890',
        roles: [UserRole.cocinero],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastLogin: DateTime.now().subtract(const Duration(minutes: 15)),
        createdBy: 'user_001',
      ),
      AdminUser(
        id: 'user_004',
        name: 'Ana Rodríguez',
        username: 'cajero',
        email: 'ana@comandix.com',
        phone: '55 4567 8901',
        roles: [UserRole.cajero],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastLogin: DateTime.now().subtract(const Duration(minutes: 45)),
        createdBy: 'user_001',
      ),
      AdminUser(
        id: 'user_005',
        name: 'Roberto Silva',
        username: 'capitan',
        email: 'roberto@comandix.com',
        phone: '55 5678 9012',
        roles: [UserRole.capitan],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastLogin: DateTime.now().subtract(const Duration(minutes: 5)),
        createdBy: 'user_001',
      ),
    ];

    // Inicializar inventario de ejemplo
    _inventory = [
      InventoryItem(
        id: 'inv_001',
        name: 'Carne de Res',
        category: InventoryCategory.carnes,
        currentStock: 15.5,
        minStock: 10.0,
        maxStock: 50.0,
        minimumStock: 10.0,
        unit: 'kg',
        cost: 120.0,
        price: 150.0,
        unitPrice: 150.0,
        supplier: 'Carnes Premium',
        lastRestock: DateTime.now().subtract(const Duration(days: 2)),
        status: InventoryStatus.available,
        notes: 'Carne de res premium para barbacoa',
        description: 'Carne de res premium para barbacoa',
      ),
      InventoryItem(
        id: 'inv_002',
        name: 'Cebolla',
        category: InventoryCategory.verduras,
        currentStock: 8.0,
        minStock: 15.0,
        maxStock: 30.0,
        minimumStock: 15.0,
        unit: 'kg',
        cost: 25.0,
        price: 35.0,
        unitPrice: 35.0,
        supplier: 'Verduras Frescas',
        lastRestock: DateTime.now().subtract(const Duration(days: 1)),
        status: InventoryStatus.lowStock,
        notes: 'Cebolla blanca para tacos',
        description: 'Cebolla blanca para tacos',
      ),
      InventoryItem(
        id: 'inv_003',
        name: 'Refresco Coca-Cola',
        category: InventoryCategory.bebidas,
        currentStock: 0.0,
        minStock: 5.0,
        maxStock: 20.0,
        minimumStock: 5.0,
        unit: 'botellas',
        cost: 15.0,
        price: 25.0,
        unitPrice: 25.0,
        supplier: 'Bebidas del Norte',
        lastRestock: DateTime.now().subtract(const Duration(days: 5)),
        status: InventoryStatus.outOfStock,
        notes: 'Refresco de cola 600ml',
        description: 'Refresco de cola 600ml',
      ),
    ];

    // Inicializar menú de ejemplo
    _menuItems = [
      MenuItem(
        id: 'menu_001',
        name: 'Taco de Barbacoa',
        category: MenuCategory.tacos,
        description: 'Taco de barbacoa con cebolla y cilantro',
        price: 22.0,
        isAvailable: true,
        ingredients: ['Carne de res', 'Cebolla', 'Cilantro', 'Tortilla'],
        allergens: [],
        preparationTime: 5,
        notes: 'Especialidad de la casa',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      MenuItem(
        id: 'menu_002',
        name: 'Consomé Grande',
        category: MenuCategory.consomes,
        description: 'Consomé de barbacoa con verduras',
        price: 35.0,
        isAvailable: true,
        ingredients: ['Caldo de res', 'Verduras', 'Especias'],
        allergens: [],
        preparationTime: 10,
        notes: 'Perfecto para días fríos',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      MenuItem(
        id: 'menu_003',
        name: 'Agua de Horchata',
        category: MenuCategory.bebidas,
        description: 'Agua de horchata natural',
        price: 18.0,
        isAvailable: true,
        ingredients: ['Arroz', 'Canela', 'Azúcar'],
        allergens: [],
        preparationTime: 2,
        notes: 'Bebida tradicional',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    // Inicializar mesas de ejemplo
    _tables = [
      TableModel(id: 1, number: 1, status: TableStatus.libre, seats: 4),
      TableModel(
        id: 2,
        number: 2,
        status: TableStatus.ocupada,
        seats: 2,
        customers: 2,
        waiter: 'Juan Martínez',
        currentTotal: 89.0,
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      TableModel(
        id: 3,
        number: 3,
        status: TableStatus.reservada,
        seats: 6,
        notes: 'Reserva para 14:30 - Familia López',
      ),
      TableModel(id: 4, number: 4, status: TableStatus.enLimpieza, seats: 4),
      TableModel(
        id: 5,
        number: 5,
        status: TableStatus.ocupada,
        seats: 4,
        customers: 3,
        waiter: 'Juan Martínez',
        currentTotal: 159.0,
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];

    // Inicializar cierres de caja de ejemplo
    _cashClosures = [
      CashCloseModel(
        id: 'close_001',
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        periodo: 'Día',
        usuario: 'Juan Martínez',
        totalNeto: 2500.0,
        efectivo: 1500.0,
        tarjeta: 1000.0,
        propinasTarjeta: 150.0,
        propinasEfectivo: 100.0,
        pedidosParaLlevar: 5,
        estado: CashCloseStatus.approved,
        efectivoContado: 1500.0,
        totalTarjeta: 1000.0,
        otrosIngresos: 0.0,
        totalDeclarado: 2500.0,
        auditLog: [
          AuditLogEntry(
            id: 'log_001',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            action: 'enviado',
            usuario: 'Juan Martínez',
            mensaje: 'Cierre enviado por Juan Martínez',
          ),
          AuditLogEntry(
            id: 'log_002',
            timestamp: DateTime.now().subtract(
              const Duration(days: 1, hours: -2),
            ),
            action: 'aprobado',
            usuario: 'Admin',
            mensaje: 'Cierre aprobado por Admin',
          ),
        ],
      ),
    ];

    // Inicializar estadísticas del dashboard
    _dashboardStats = DashboardStats(
      todaySales: 3250.0,
      yesterdaySales: 2890.0,
      salesGrowth: 12.5,
      totalOrders: 24,
      activeUsers: 5,
      lowStockItems: 2,
      averageTicket: 135.42,
      totalTips: 325.0,
      salesByHour: {
        '10:00': 150.0,
        '11:00': 200.0,
        '12:00': 350.0,
        '13:00': 400.0,
        '14:00': 300.0,
        '15:00': 250.0,
        '16:00': 200.0,
        '17:00': 180.0,
        '18:00': 220.0,
        '19:00': 300.0,
        '20:00': 400.0,
        '21:00': 300.0,
      },
      topProducts: [
        SalesItem(
          name: 'Taco de Barbacoa',
          quantity: 45,
          revenue: 990.0,
          category: 'Tacos',
        ),
        SalesItem(
          name: 'Consomé Grande',
          quantity: 20,
          revenue: 700.0,
          category: 'Consomes',
        ),
        SalesItem(
          name: 'Agua de Horchata',
          quantity: 30,
          revenue: 540.0,
          category: 'Bebidas',
        ),
      ],
    );

    notifyListeners();
  }

  // Cambiar filtro de rol de usuario
  void setSelectedUserRole(String role) {
    _selectedUserRole = role;
    notifyListeners();
  }

  // Cambiar filtro de estado de usuario
  void setSelectedUserStatus(String status) {
    _selectedUserStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de categoría de inventario
  void setSelectedInventoryCategory(String category) {
    _selectedInventoryCategory = category;
    notifyListeners();
  }

  // Cambiar filtro de estado de inventario
  void setSelectedInventoryStatus(String status) {
    _selectedInventoryStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de categoría de menú
  void setSelectedMenuCategory(String category) {
    _selectedMenuCategory = category;
    notifyListeners();
  }

  // Cambiar filtro de estado de mesa
  void setSelectedTableStatus(String status) {
    _selectedTableStatus = status;
    notifyListeners();
  }

  // Cambiar consulta de búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Cambiar vista actual
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Gestión de usuarios
  void addUser(AdminUser user) {
    _users.insert(0, user);
    notifyListeners();
  }

  void updateUser(AdminUser user) {
    _users = _users.map((u) => u.id == user.id ? user : u).toList();
    notifyListeners();
  }

  void deleteUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
    notifyListeners();
  }

  void toggleUserStatus(String userId) {
    _users = _users.map((user) {
      if (user.id == userId) {
        return user.copyWith(isActive: !user.isActive);
      }
      return user;
    }).toList();
    notifyListeners();
  }

  // Gestión de inventario
  void addInventoryItem(InventoryItem item) {
    _inventory.insert(0, item);
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem item) {
    _inventory = _inventory.map((i) => i.id == item.id ? item : i).toList();
    notifyListeners();
  }

  void deleteInventoryItem(String itemId) {
    _inventory.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void restockInventoryItem(String itemId, double quantity) {
    _inventory = _inventory.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          currentStock: item.currentStock + quantity,
          lastRestock: DateTime.now(),
        );
      }
      return item;
    }).toList();
    notifyListeners();
  }

  // Gestión de menú
  void addMenuItem(MenuItem item) {
    _menuItems.insert(0, item);
    notifyListeners();
  }

  void updateMenuItem(MenuItem item) {
    _menuItems = _menuItems.map((i) => i.id == item.id ? item : i).toList();
    notifyListeners();
  }

  void deleteMenuItem(String itemId) {
    _menuItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void toggleMenuItemAvailability(String itemId) {
    _menuItems = _menuItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isAvailable: !item.isAvailable);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  // Gestión de mesas
  void updateTableStatus(int tableNumber, String newStatus) {
    _tables = _tables.map((table) {
      if (table.number == tableNumber) {
        return table.copyWith(status: newStatus);
      }
      return table;
    }).toList();
    notifyListeners();
  }

  void assignTableToWaiter(int tableNumber, String waiterName) {
    _tables = _tables.map((table) {
      if (table.number == tableNumber) {
        return table.copyWith(waiter: waiterName);
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Obtener estadísticas
  Map<String, int> getUserStats() {
    final stats = <String, int>{};
    for (final user in _users) {
      for (final role in user.roles) {
        stats[role] = (stats[role] ?? 0) + 1;
      }
    }
    return stats;
  }

  Map<String, int> getInventoryStats() {
    final stats = <String, int>{};
    for (final item in _inventory) {
      stats[item.status] = (stats[item.status] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getTableStats() {
    final stats = <String, int>{};
    for (final table in _tables) {
      stats[table.status] = (stats[table.status] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getMenuStats() {
    final stats = <String, int>{};
    for (final item in _menuItems) {
      stats[item.category] = (stats[item.category] ?? 0) + 1;
    }
    return stats;
  }

  // Obtener items con stock bajo
  List<InventoryItem> getLowStockItems() {
    return _inventory
        .where((item) => item.status == InventoryStatus.lowStock)
        .toList();
  }

  // Obtener items sin stock
  List<InventoryItem> getOutOfStockItems() {
    return _inventory
        .where((item) => item.status == InventoryStatus.outOfStock)
        .toList();
  }

  // Obtener mesas ocupadas
  List<TableModel> getOccupiedTables() {
    return _tables
        .where((table) => table.status == TableStatus.ocupada)
        .toList();
  }

  // Obtener mesas libres
  List<TableModel> getAvailableTables() {
    return _tables.where((table) => table.status == TableStatus.libre).toList();
  }

  // Obtener usuarios activos
  List<AdminUser> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Obtener usuarios inactivos
  List<AdminUser> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }

  // Obtener items de menú disponibles
  List<MenuItem> getAvailableMenuItems() {
    return _menuItems.where((item) => item.isAvailable).toList();
  }

  // Obtener items de menú no disponibles
  List<MenuItem> getUnavailableMenuItems() {
    return _menuItems.where((item) => !item.isAvailable).toList();
  }

  // Formatear moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Formatear fecha
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Formatear fecha y hora
  String formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Obtener color de estado de inventario
  Color getInventoryStatusColor(String status) {
    switch (status) {
      case InventoryStatus.available:
        return Colors.green;
      case InventoryStatus.lowStock:
        return Colors.orange;
      case InventoryStatus.outOfStock:
        return Colors.red;
      case InventoryStatus.expired:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de estado de mesa
  Color getTableStatusColor(String status) {
    switch (status) {
      case TableStatus.libre:
        return Colors.green;
      case TableStatus.ocupada:
        return Colors.red;
      case TableStatus.enLimpieza:
        return Colors.orange;
      case TableStatus.reservada:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de rol de usuario
  Color getUserRoleColor(String role) {
    switch (role) {
      case UserRole.mesero:
        return Colors.blue;
      case UserRole.cocinero:
        return Colors.orange;
      case UserRole.cajero:
        return Colors.green;
      case UserRole.capitan:
        return Colors.purple;
      case UserRole.admin:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtener color de categoría de inventario
  Color getInventoryCategoryColor(String category) {
    switch (category) {
      case InventoryCategory.carnes:
        return Colors.red;
      case InventoryCategory.verduras:
        return Colors.green;
      case InventoryCategory.bebidas:
        return Colors.blue;
      case InventoryCategory.condimentos:
        return Colors.orange;
      case InventoryCategory.utensilios:
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  // Obtener color de categoría de menú
  Color getMenuCategoryColor(String category) {
    switch (category) {
      case MenuCategory.tacos:
        return Colors.orange;
      case MenuCategory.consomes:
        return Colors.brown;
      case MenuCategory.bebidas:
        return Colors.blue;
      case MenuCategory.postres:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Obtener categorías de inventario
  List<String> getInventoryCategories() {
    return _inventory.map((item) => item.category).toSet().toList();
  }

  // Gestión de cierres de caja
  void addCashClose(CashCloseModel cashClose) {
    _cashClosures.insert(0, cashClose);
    notifyListeners();
  }

  void updateCashClose(CashCloseModel cashClose) {
    _cashClosures = _cashClosures
        .map((c) => c.id == cashClose.id ? cashClose : c)
        .toList();
    notifyListeners();
  }

  void deleteCashClose(String cashCloseId) {
    _cashClosures.removeWhere((cashClose) => cashClose.id == cashCloseId);
    notifyListeners();
  }
}
