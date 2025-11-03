import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart' as payment_models;

class AdminController extends ChangeNotifier {
  // Estado de usuarios
  List<AdminUser> _users = [];

  // Estado de inventario
  List<InventoryItem> _inventory = [];

  // Estado de cierres de caja
  List<CashCloseModel> _cashClosures = [];

  // Estado de menú
  List<MenuItem> _menuItems = [];

  // Estado de categorías personalizadas
  List<String> _customCategories =
      []; // Categorías creadas por el admin además de las predeterminadas

  // Estado de mesas
  List<TableModel> _tables = [];

  // Estado de reportes
  final List<SalesReport> _salesReports = [];

  // Estado de tickets
  List<payment_models.BillModel> _tickets = [];

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
  String _selectedTableArea =
      'todos'; // 'todos', 'area_principal', 'area_lateral'
  String _selectedConsumptionFilter =
      'todos'; // 'todos', 'para_llevar', 'mesas'
  String _searchQuery = '';

  // Estado de consumo del día (órdenes/pedidos)
  List<OrderModel> _dailyConsumption = [];

  // Filtros de tickets
  String _selectedTicketStatus = 'todos';

  // Filtros de cierre de caja
  String _selectedCashClosePeriod =
      'hoy'; // 'hoy', 'ayer', 'semana', 'mes', 'personalizado'
  String _selectedCashCloseStatus = 'todos';
  DateTime? _cashCloseStartDate;
  DateTime? _cashCloseEndDate;
  String _cashCloseSearchQuery = '';

  // Vista actual
  String _currentView = 'dashboard';

  // Getters
  List<AdminUser> get users => _users;
  List<InventoryItem> get inventory => _inventory;
  List<InventoryItem> get inventoryItems => _inventory;
  List<CashCloseModel> get cashClosures => _cashClosures;
  List<MenuItem> get menuItems => _menuItems;
  List<String> get customCategories => _customCategories;
  List<TableModel> get tables => _tables;
  List<SalesReport> get salesReports => _salesReports;
  List<payment_models.BillModel> get tickets => _tickets;
  DashboardStats get dashboardStats => _dashboardStats;
  String get selectedUserRole => _selectedUserRole;
  String get selectedUserStatus => _selectedUserStatus;
  String get selectedInventoryCategory => _selectedInventoryCategory;
  String get selectedInventoryStatus => _selectedInventoryStatus;
  String get selectedMenuCategory => _selectedMenuCategory;
  String get selectedTableStatus => _selectedTableStatus;
  String get selectedTableArea => _selectedTableArea;
  String get selectedConsumptionFilter => _selectedConsumptionFilter;
  String get selectedTicketStatus => _selectedTicketStatus;
  String get selectedCashClosePeriod => _selectedCashClosePeriod;
  String get selectedCashCloseStatus => _selectedCashCloseStatus;
  DateTime? get cashCloseStartDate => _cashCloseStartDate;
  DateTime? get cashCloseEndDate => _cashCloseEndDate;
  String get cashCloseSearchQuery => _cashCloseSearchQuery;
  String get searchQuery => _searchQuery;
  String get currentView => _currentView;
  List<OrderModel> get dailyConsumption => _dailyConsumption;

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
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());
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
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.supplier != null &&
              item.supplier!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));
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
      final areaMatch =
          _selectedTableArea == 'todos' || table.section == _selectedTableArea;
      return statusMatch && areaMatch;
    }).toList();
  }

  // Obtener consumo del día filtrado
  List<OrderModel> get filteredDailyConsumption {
    return _dailyConsumption.where((order) {
      final filterMatch =
          _selectedConsumptionFilter == 'todos' ||
          (_selectedConsumptionFilter == 'para_llevar' && order.isTakeaway) ||
          (_selectedConsumptionFilter == 'mesas' && !order.isTakeaway);
      return filterMatch;
    }).toList();
  }

  // Obtener tickets filtrados
  List<payment_models.BillModel> get filteredTickets {
    return _tickets.where((ticket) {
      final statusMatch =
          _selectedTicketStatus == 'todos' ||
          ticket.status == _selectedTicketStatus;
      final searchMatch =
          _searchQuery.isEmpty ||
          ticket.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ticket.tableNumber != null &&
              ticket.tableNumber.toString().contains(_searchQuery)) ||
          (ticket.waiterName != null &&
              ticket.waiterName!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          (ticket.printedBy != null &&
              ticket.printedBy!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));
      return statusMatch && searchMatch;
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

    // Inicializar categorías personalizadas (ejemplo)
    _customCategories = [
      'Consomes',
    ]; // Ya existe, se puede eliminar o modificar

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
        hasSizes: false,
        serveHot: true,
        isSpicy: false,
        allowSauces: true,
        allowExtraIngredients: true,
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
        hasSizes: false,
        serveHot: true,
        isSpicy: false,
        allowSauces: false,
        allowExtraIngredients: false,
      ),
      MenuItem(
        id: 'menu_003',
        name: 'Agua de Horchata',
        category: MenuCategory.bebidas,
        description: 'Agua de horchata natural',
        price: null, // Usa tamaños
        isAvailable: true,
        ingredients: ['Arroz', 'Canela', 'Azúcar'],
        allergens: [],
        preparationTime: 2,
        notes: 'Bebida tradicional',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        hasSizes: true,
        sizes: [
          MenuSize(name: 'Chica', price: 18.0),
          MenuSize(name: 'Mediana', price: 25.0),
          MenuSize(name: 'Grande', price: 32.0),
        ],
        serveHot: false,
        isSpicy: false,
        allowSauces: false,
        allowExtraIngredients: false,
      ),
    ];

    // Inicializar mesas de ejemplo
    _tables = [
      TableModel(
        id: 1,
        number: 1,
        status: TableStatus.libre,
        seats: 4,
        section: 'area_principal',
      ),
      TableModel(
        id: 2,
        number: 2,
        status: TableStatus.ocupada,
        seats: 2,
        customers: 2,
        waiter: 'Juan Martínez',
        currentTotal: 89.0,
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 30)),
        section: 'area_principal',
      ),
      TableModel(
        id: 3,
        number: 3,
        status: TableStatus.reservada,
        seats: 6,
        notes: 'Reserva para 14:30 - Familia López',
        section: 'area_principal',
      ),
      TableModel(
        id: 4,
        number: 4,
        status: TableStatus.enLimpieza,
        seats: 4,
        section: 'area_lateral',
      ),
      TableModel(
        id: 5,
        number: 5,
        status: TableStatus.ocupada,
        seats: 4,
        customers: 3,
        waiter: 'Juan Martínez',
        currentTotal: 159.0,
        lastOrderTime: DateTime.now().subtract(const Duration(minutes: 25)),
        section: 'area_lateral',
      ),
      TableModel(
        id: 6,
        number: 6,
        status: TableStatus.libre,
        seats: 2,
        section: 'area_lateral',
      ),
    ];

    // Inicializar consumo del día de ejemplo
    _dailyConsumption = [
      OrderModel(
        id: 'ORD-DAY-001',
        tableNumber: 5,
        items: [
          OrderItem(
            id: 1,
            name: 'Taco de Barbacoa',
            quantity: 3,
            station: KitchenStation.tacos,
            notes: '',
          ),
          OrderItem(
            id: 2,
            name: 'Consomé Grande',
            quantity: 1,
            station: KitchenStation.consomes,
            notes: '',
          ),
        ],
        status: OrderStatus.listo,
        orderTime: DateTime.now().subtract(const Duration(minutes: 45)),
        estimatedTime: 15,
        waiter: 'Juan Martínez',
        priority: OrderPriority.normal,
        isTakeaway: false,
      ),
      OrderModel(
        id: 'ORD-DAY-002',
        tableNumber: null,
        items: [
          OrderItem(
            id: 3,
            name: 'Quesadilla de Barbacoa',
            quantity: 2,
            station: KitchenStation.tacos,
            notes: '',
          ),
          OrderItem(
            id: 4,
            name: 'Refresco',
            quantity: 3,
            station: KitchenStation.bebidas,
            notes: '',
          ),
        ],
        status: OrderStatus.listo,
        orderTime: DateTime.now().subtract(const Duration(minutes: 120)),
        estimatedTime: 10,
        waiter: 'María González',
        priority: OrderPriority.normal,
        isTakeaway: true,
        customerName: 'Jahir',
        customerPhone: '55 1234 5678',
      ),
      OrderModel(
        id: 'ORD-DAY-003',
        tableNumber: 2,
        items: [
          OrderItem(
            id: 5,
            name: 'Mix Barbacoa',
            quantity: 1,
            station: KitchenStation.consomes,
            notes: '',
          ),
        ],
        status: OrderStatus.listo,
        orderTime: DateTime.now().subtract(const Duration(minutes: 60)),
        estimatedTime: 12,
        waiter: 'Juan Martínez',
        priority: OrderPriority.normal,
        isTakeaway: false,
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

    // Inicializar tickets de ejemplo
    _tickets = [
      payment_models.BillModel(
        id: 'BILL-001',
        tableNumber: 5,
        items: [
          payment_models.BillItem(
            name: 'Taco de Barbacoa',
            quantity: 3,
            price: 22.0,
            total: 66.0,
          ),
          payment_models.BillItem(
            name: 'Consomé Grande',
            quantity: 1,
            price: 35.0,
            total: 35.0,
          ),
          payment_models.BillItem(
            name: 'Agua de Horchata',
            quantity: 2,
            price: 18.0,
            total: 36.0,
          ),
        ],
        subtotal: 137.0,
        tax: 0.0,
        total: 137.0,
        status: payment_models.BillStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        waiterName: 'María González',
        isPrinted: false,
      ),
      payment_models.BillModel(
        id: 'BILL-002',
        tableNumber: 3,
        items: [
          payment_models.BillItem(
            name: 'Mix Barbacoa',
            quantity: 2,
            price: 45.0,
            total: 90.0,
          ),
          payment_models.BillItem(
            name: 'Coca Cola',
            quantity: 3,
            price: 20.0,
            total: 60.0,
          ),
        ],
        subtotal: 150.0,
        tax: 0.0,
        total: 150.0,
        status: payment_models.BillStatus.printed,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        waiterName: 'Juan Martínez',
        isPrinted: true,
        printedBy: 'Admin',
      ),
      payment_models.BillModel(
        id: 'BILL-003',
        isTakeaway: true,
        customerName: 'Pedro López',
        items: [
          payment_models.BillItem(
            name: 'Taco de Barbacoa',
            quantity: 5,
            price: 22.0,
            total: 110.0,
          ),
        ],
        subtotal: 110.0,
        tax: 0.0,
        total: 110.0,
        status: payment_models.BillStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        waiterName: 'María González',
        isPrinted: true,
        printedBy: 'Admin',
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

  // Cambiar filtro de estado de ticket
  void setSelectedTicketStatus(String status) {
    _selectedTicketStatus = status;
    notifyListeners();
  }

  // Cambiar filtro de período de cierre de caja
  void setSelectedCashClosePeriod(String period) {
    _selectedCashClosePeriod = period;
    if (period != 'personalizado') {
      _cashCloseStartDate = null;
      _cashCloseEndDate = null;
    }
    notifyListeners();
  }

  // Cambiar filtro de estado de cierre de caja
  void setSelectedCashCloseStatus(String status) {
    _selectedCashCloseStatus = status;
    notifyListeners();
  }

  // Establecer rango de fechas personalizado
  void setCashCloseDateRange(DateTime startDate, DateTime endDate) {
    _cashCloseStartDate = startDate;
    _cashCloseEndDate = endDate;
    notifyListeners();
  }

  // Cambiar búsqueda de cierre de caja
  void setCashCloseSearchQuery(String query) {
    _cashCloseSearchQuery = query;
    notifyListeners();
  }

  // Exportar tickets a CSV
  void exportTicketsToCSV() {
    // En una implementación real, esto generaría un archivo CSV
    // Por ahora solo notificamos
    notifyListeners();
  }

  // Obtener cierres de caja filtrados
  List<CashCloseModel> get filteredCashClosures {
    return _cashClosures.where((closure) {
      // Filtro por estado
      final statusMatch =
          _selectedCashCloseStatus == 'todos' ||
          closure.estado == _selectedCashCloseStatus;

      // Filtro por período
      bool periodMatch = false;
      final now = DateTime.now();
      switch (_selectedCashClosePeriod) {
        case 'hoy':
          periodMatch =
              closure.fecha.year == now.year &&
              closure.fecha.month == now.month &&
              closure.fecha.day == now.day;
          break;
        case 'ayer':
          final yesterday = now.subtract(const Duration(days: 1));
          periodMatch =
              closure.fecha.year == yesterday.year &&
              closure.fecha.month == yesterday.month &&
              closure.fecha.day == yesterday.day;
          break;
        case 'semana':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          periodMatch =
              closure.fecha.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              closure.fecha.isBefore(now.add(const Duration(days: 1)));
          break;
        case 'mes':
          periodMatch =
              closure.fecha.year == now.year &&
              closure.fecha.month == now.month;
          break;
        case 'personalizado':
          if (_cashCloseStartDate != null && _cashCloseEndDate != null) {
            periodMatch =
                closure.fecha.isAfter(
                  _cashCloseStartDate!.subtract(const Duration(days: 1)),
                ) &&
                closure.fecha.isBefore(
                  _cashCloseEndDate!.add(const Duration(days: 1)),
                );
          } else {
            periodMatch = true;
          }
          break;
        default:
          periodMatch = true;
      }

      // Filtro por búsqueda
      final searchMatch =
          _cashCloseSearchQuery.isEmpty ||
          closure.usuario.toLowerCase().contains(
            _cashCloseSearchQuery.toLowerCase(),
          ) ||
          closure.id.toLowerCase().contains(
            _cashCloseSearchQuery.toLowerCase(),
          );

      return statusMatch && periodMatch && searchMatch;
    }).toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  // Exportar cierres de caja a CSV
  void exportCashClosuresToCSV() {
    // En una implementación real, esto generaría un archivo CSV
    notifyListeners();
  }

  // Generar PDF de cierres de caja
  void generateCashClosuresPDF() {
    // En una implementación real, esto generaría un archivo PDF
    notifyListeners();
  }

  // Marcar cierre como verificado
  void markCashCloseAsVerified(String closureId) {
    final index = _cashClosures.indexWhere(
      (closure) => closure.id == closureId,
    );
    if (index != -1) {
      final closure = _cashClosures[index];
      final updatedLog = List<AuditLogEntry>.from(closure.auditLog)
        ..add(
          AuditLogEntry(
            id: 'log_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            action: 'verificado',
            usuario: 'Admin',
            mensaje: 'Cierre verificado por administrador',
          ),
        );
      _cashClosures[index] = closure.copyWith(
        estado: CashCloseStatus.approved,
        auditLog: updatedLog,
      );
      notifyListeners();
    }
  }

  // Solicitar aclaración de cierre
  void requestCashCloseClarification(String closureId, String reason) {
    final index = _cashClosures.indexWhere(
      (closure) => closure.id == closureId,
    );
    if (index != -1) {
      final closure = _cashClosures[index];
      final updatedLog = List<AuditLogEntry>.from(closure.auditLog)
        ..add(
          AuditLogEntry(
            id: 'log_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            action: 'aclaracion_solicitada',
            usuario: 'Admin',
            mensaje: reason,
          ),
        );
      _cashClosures[index] = closure.copyWith(
        estado: CashCloseStatus.clarification,
        auditLog: updatedLog,
      );
      notifyListeners();
    }
  }

  // Imprimir ticket
  void printTicket(String ticketId, String printedBy) {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        status: payment_models.BillStatus.printed,
        isPrinted: true,
        printedBy: printedBy,
      );
      notifyListeners();
      // En una implementación real, aquí se enviaría una notificación al mesero
    }
  }

  // Marcar ticket como entregado
  void markTicketAsDelivered(String ticketId) {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        status: payment_models.BillStatus.delivered,
      );
      notifyListeners();
    }
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

  // Cambiar contraseña de usuario
  void changeUserPassword(String userId, String newPassword) {
    // Nota: En una implementación real, esto se haría a través del backend
    // Por ahora solo notificamos el cambio
    notifyListeners();
  }

  // Generar contraseña aleatoria
  String generatePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    final uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final lowercase = 'abcdefghijklmnopqrstuvwxyz';
    final numbers = '0123456789';
    final symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeLowercase) chars += lowercase;
    if (includeUppercase) chars += uppercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();

    for (int i = 0; i < length; i++) {
      final index = (random + i) % chars.length;
      password.write(chars[index]);
    }

    // Asegurar que tenga al menos un carácter de cada tipo requerido
    final passwordStr = password.toString();
    if (includeUppercase && !passwordStr.contains(RegExp(r'[A-Z]'))) {
      return passwordStr.substring(0, length - 1) +
          uppercase[random % uppercase.length];
    }
    if (includeLowercase && !passwordStr.contains(RegExp(r'[a-z]'))) {
      return passwordStr.substring(0, length - 1) +
          lowercase[random % lowercase.length];
    }
    if (includeNumbers && !passwordStr.contains(RegExp(r'[0-9]'))) {
      return passwordStr.substring(0, length - 1) +
          numbers[random % numbers.length];
    }
    if (includeSymbols &&
        !passwordStr.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return passwordStr.substring(0, length - 1) +
          symbols[random % symbols.length];
    }

    return passwordStr;
  }

  // Validar fortaleza de contraseña
  PasswordStrength validatePasswordStrength(String password) {
    int score = 0;
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(
      RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'),
    );

    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSymbol) score++;

    if (score <= 2) {
      return PasswordStrength.weak;
    } else if (score <= 4) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.strong;
    }
  }

  // Obtener siguiente ID disponible para usuario
  String getNextUserId() {
    if (_users.isEmpty) return 'user_001';
    final maxId = _users
        .map((user) {
          final match = RegExp(r'user_(\d+)').firstMatch(user.id);
          return match != null ? int.parse(match.group(1)!) : 0;
        })
        .reduce((a, b) => a > b ? a : b);
    return 'user_${(maxId + 1).toString().padLeft(3, '0')}';
  }

  // Verificar si existe un username
  bool usernameExists(String username, {String? excludeId}) {
    return _users.any(
      (user) =>
          user.username.toLowerCase() == username.toLowerCase() &&
          (excludeId == null || user.id != excludeId),
    );
  }

  // Paginación de usuarios
  int _currentUserPage = 1;
  int _usersPerPage = 10;

  int get currentUserPage => _currentUserPage;
  int get usersPerPage => _usersPerPage;
  int get totalUserPages => (filteredUsers.length / _usersPerPage).ceil();

  List<AdminUser> get paginatedUsers {
    final startIndex = (_currentUserPage - 1) * _usersPerPage;
    return filteredUsers.skip(startIndex).take(_usersPerPage).toList();
  }

  void setUserPage(int page) {
    _currentUserPage = page;
    notifyListeners();
  }

  void nextUserPage() {
    if (_currentUserPage < totalUserPages) {
      _currentUserPage++;
      notifyListeners();
    }
  }

  void previousUserPage() {
    if (_currentUserPage > 1) {
      _currentUserPage--;
      notifyListeners();
    }
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

  // Actualizar estado de mesa (método legacy - usar updateTableStatus con tableId)
  @Deprecated('Use updateTableStatus with tableId instead')
  void updateTableStatusLegacy(int tableNumber, String newStatus) {
    // Método mantenido para compatibilidad pero no usado
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

  // Cambiar filtro de consumo del día
  void setSelectedConsumptionFilter(String filter) {
    _selectedConsumptionFilter = filter;
    notifyListeners();
  }

  // Cambiar filtro de área de mesa
  void setSelectedTableArea(String area) {
    _selectedTableArea = area;
    notifyListeners();
  }

  // Establecer consumo del día (se llamará desde la vista o servicio)
  void setDailyConsumption(List<OrderModel> orders) {
    _dailyConsumption = orders;
    notifyListeners();
  }

  // Agregar orden al consumo del día
  void addDailyConsumptionOrder(OrderModel order) {
    _dailyConsumption.insert(0, order);
    notifyListeners();
  }

  // Gestión de mesas
  void addTable(TableModel table) {
    _tables.insert(0, table);
    notifyListeners();
  }

  void updateTable(TableModel table) {
    _tables = _tables.map((t) => t.id == table.id ? table : t).toList();
    notifyListeners();
  }

  void deleteTable(int tableId) {
    _tables.removeWhere((table) => table.id == tableId);
    notifyListeners();
  }

  void updateTableStatus(int tableId, String newStatus) {
    _tables = _tables.map((table) {
      if (table.id == tableId) {
        return table.copyWith(
          status: newStatus,
          customers:
              (newStatus == TableStatus.libre ||
                  newStatus == TableStatus.enLimpieza)
              ? null
              : table.customers,
          currentTotal:
              (newStatus == TableStatus.libre ||
                  newStatus == TableStatus.enLimpieza)
              ? null
              : table.currentTotal,
        );
      }
      return table;
    }).toList();
    notifyListeners();
  }

  // Obtener siguiente ID disponible para mesa
  int getNextTableId() {
    if (_tables.isEmpty) return 1;
    return _tables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  // Verificar si existe una mesa con ese número
  bool tableNumberExists(int number, {int? excludeId}) {
    return _tables.any(
      (table) =>
          table.number == number &&
          (excludeId == null || table.id != excludeId),
    );
  }

  // Gestión de categorías personalizadas
  void addCustomCategory(String categoryName) {
    if (!_customCategories.contains(categoryName)) {
      _customCategories.add(categoryName);
      notifyListeners();
    }
  }

  void updateCustomCategory(String oldName, String newName) {
    final index = _customCategories.indexOf(oldName);
    if (index != -1) {
      _customCategories[index] = newName;
      // Actualizar productos que usan esta categoría
      _menuItems = _menuItems.map((item) {
        if (item.category == oldName) {
          return item.copyWith(category: newName);
        }
        return item;
      }).toList();
      notifyListeners();
    }
  }

  void deleteCustomCategory(String categoryName) {
    // Solo permitir eliminar si no hay productos usando esta categoría
    if (!_menuItems.any((item) => item.category == categoryName)) {
      _customCategories.remove(categoryName);
      notifyListeners();
    }
  }

  // Obtener todas las categorías (predeterminadas + personalizadas)
  List<String> getAllCategories() {
    final defaultCategories = [
      MenuCategory.tacos,
      'Platos especiales',
      'Acompañamientos',
      MenuCategory.bebidas,
      'Extras',
      MenuCategory.consomes,
    ];
    return [...defaultCategories, ..._customCategories];
  }

  // Obtener siguiente ID disponible para producto
  String getNextMenuItemId() {
    if (_menuItems.isEmpty) return 'menu_001';
    final maxId = _menuItems
        .map((item) {
          final match = RegExp(r'menu_(\d+)').firstMatch(item.id);
          return match != null ? int.parse(match.group(1)!) : 0;
        })
        .reduce((a, b) => a > b ? a : b);
    return 'menu_${(maxId + 1).toString().padLeft(3, '0')}';
  }

  // Obtener ingredientes sugeridos del inventario
  List<String> getSuggestedIngredients() {
    return _inventory
        .where((item) => item.status == InventoryStatus.available)
        .map((item) => '${item.name} ${item.unit}')
        .toList();
  }
}
