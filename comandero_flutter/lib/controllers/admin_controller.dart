import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart' as payment_models;
import '../services/payment_repository.dart';
import '../services/usuarios_service.dart';
import '../services/productos_service.dart';
import '../services/inventario_service.dart';
import '../services/mesas_service.dart';
import '../services/categorias_service.dart';
import '../services/roles_service.dart';
import '../services/socket_service.dart';
import '../services/tickets_service.dart';
import '../services/cierres_service.dart';
import '../services/ordenes_service.dart';
import '../utils/date_utils.dart' as date_utils;

class AdminController extends ChangeNotifier {
  AdminController({
    required PaymentRepository paymentRepository,
  }) : _paymentRepository = paymentRepository {
    _paymentRepository.addListener(_handlePaymentsChanged);
    _initializeData();
  }

  final PaymentRepository _paymentRepository;
  final UsuariosService _usuariosService = UsuariosService();
  final ProductosService _productosService = ProductosService();
  final InventarioService _inventarioService = InventarioService();
  final MesasService _mesasService = MesasService();
  final CategoriasService _categoriasService = CategoriasService();
  final RolesService _rolesService = RolesService();
  final TicketsService _ticketsService = TicketsService();
  final CierresService _cierresService = CierresService();
  final OrdenesService _ordenesService = OrdenesService();

  String _normalizeInventoryCategory(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Otros';
    if (raw.length == 1) return raw.toUpperCase();
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Map<String, dynamic> _recipeIngredientToBackend(RecipeIngredient ingredient) {
    return {
      'inventarioItemId': ingredient.inventoryItemId != null
          ? int.tryParse(ingredient.inventoryItemId!)
          : null,
      'categoria': _normalizeInventoryCategory(ingredient.category),
      'nombre': ingredient.name.trim(),
      'unidad': ingredient.unit.trim(),
      'cantidadPorPorcion': ingredient.quantityPerPortion,
      'descontarAutomaticamente': ingredient.autoDeduct,
      'esPersonalizado': ingredient.isCustom,
    };
  }

  // Estado de usuarios
  List<AdminUser> _users = [];

  // Estado de roles
  List<Role> _roles = [];
  List<Permiso> _permisos = [];

  // Estado de inventario
  List<InventoryItem> _inventory = [];
  List<String> _inventoryCategories = ['todos'];

  // Estado de cierres de caja
  List<CashCloseModel> _cashClosures = [];
  bool _isLoadingCashClosures = false;

  // Estado de menú
  List<MenuItem> _menuItems = [];

  // Estado de categorías personalizadas
  List<String> _customCategories =
      []; // Categorías creadas por el admin además de las predeterminadas

  // Estado de mesas
  List<TableModel> _tables = [];
  
  // Cache de contraseñas de usuarios (solo para mostrar al administrador)
  final Map<String, String> _userPasswords = {};

  // Estado de reportes
  final List<SalesReport> _salesReports = [];

  // Estado de tickets
  List<payment_models.BillModel> _tickets = [];
  bool _isLoadingTickets = false;

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
  List<String> _tableAreas = ['todos', 'Área Principal', 'Área Lateral'];
  String _selectedConsumptionFilter =
      'todos'; // 'todos', 'para_llevar', 'mesas'
  String _searchQuery = '';

  // Estado de consumo del día (órdenes/pedidos)
  List<OrderModel> _dailyConsumption = [];

  // Filtros de tickets
  String _selectedTicketStatus = 'todos';
  String _selectedTicketPeriod = 'todos'; // 'todos', 'hoy', 'ayer', 'semana', 'mes', 'personalizado'
  DateTime? _ticketStartDate;
  DateTime? _ticketEndDate;

  // Filtros de cierre de caja
  String _selectedCashClosePeriod =
      'hoy'; // 'hoy', 'ayer', 'semana', 'mes', 'personalizado' - Por defecto 'hoy' para ver cierres del día actual
  String _selectedCashCloseStatus = 'todos';
  DateTime? _cashCloseStartDate;
  DateTime? _cashCloseEndDate;
  String _cashCloseSearchQuery = '';

  // Vista actual
  String _currentView = 'dashboard';

  // Getters
  List<AdminUser> get users => _users;
  List<Role> get roles => _roles;
  List<Permiso> get permisos => _permisos;
  List<InventoryItem> get inventory => _inventory;
  List<InventoryItem> get inventoryItems => _inventory;
  List<CashCloseModel> get cashClosures => _cashClosures;
  bool get isLoadingCashClosures => _isLoadingCashClosures;
  List<MenuItem> get menuItems => _menuItems;
  List<String> get customCategories => _customCategories;
  List<TableModel> get tables => _tables;
  List<SalesReport> get salesReports => _salesReports;
  List<payment_models.BillModel> get tickets => _tickets;
  bool get isLoadingTickets => _isLoadingTickets;
  DashboardStats get dashboardStats => _dashboardStats;
  String get selectedUserRole => _selectedUserRole;
  String get selectedUserStatus => _selectedUserStatus;
  String get selectedInventoryCategory => _selectedInventoryCategory;
  String get selectedInventoryStatus => _selectedInventoryStatus;
  String get selectedMenuCategory => _selectedMenuCategory;
  String get selectedTableStatus => _selectedTableStatus;
  String get selectedTableArea => _selectedTableArea;
  List<String> get tableAreas => List.unmodifiable(_tableAreas);
  String get selectedConsumptionFilter => _selectedConsumptionFilter;
  String get selectedTicketStatus => _selectedTicketStatus;
  String get selectedTicketPeriod => _selectedTicketPeriod;
  DateTime? get ticketStartDate => _ticketStartDate;
  DateTime? get ticketEndDate => _ticketEndDate;
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
      // Comparación de categoría insensible a mayúsculas/minúsculas
      final categoryMatch = _selectedMenuCategory == 'todos' ||
          item.category.toLowerCase() == _selectedMenuCategory.toLowerCase();
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
      // Filtro por estado
      final statusMatch =
          _selectedTicketStatus == 'todos' ||
          ticket.status == _selectedTicketStatus;
      
      // Filtro por búsqueda
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
      
      // Filtro por período de fecha
      bool periodMatch = true;
      if (_selectedTicketPeriod != 'todos') {
        final ticketDate = ticket.createdAt;
        final now = DateTime.now();
        
        switch (_selectedTicketPeriod) {
          case 'hoy':
            periodMatch =
                ticketDate.year == now.year &&
                ticketDate.month == now.month &&
                ticketDate.day == now.day;
            break;
          case 'ayer':
            final yesterday = now.subtract(const Duration(days: 1));
            periodMatch =
                ticketDate.year == yesterday.year &&
                ticketDate.month == yesterday.month &&
                ticketDate.day == yesterday.day;
            break;
          case 'semana':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            periodMatch =
                ticketDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                ticketDate.isBefore(now.add(const Duration(days: 1)));
            break;
          case 'mes':
            periodMatch =
                ticketDate.year == now.year &&
                ticketDate.month == now.month;
            break;
          case 'personalizado':
            if (_ticketStartDate != null && _ticketEndDate != null) {
              periodMatch =
                  ticketDate.isAfter(
                    _ticketStartDate!.subtract(const Duration(days: 1)),
                  ) &&
                  ticketDate.isBefore(
                    _ticketEndDate!.add(const Duration(days: 1)),
                  );
            } else {
              periodMatch = true;
            }
            break;
          default:
            periodMatch = true;
        }
      }
      
      return statusMatch && searchMatch && periodMatch;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Cargar datos desde el backend
  Future<void> loadUsers() async {
    try {
      final usuariosBackend = await _usuariosService.listarUsuarios();
      
      // Actualizar usuarios y preservar contraseñas del cache si existen
      _users = usuariosBackend.map((user) {
        // Si tenemos la contraseña en el cache, usarla
        final cachedPassword = _userPasswords[user.id];
        if (cachedPassword != null) {
          return user.copyWith(password: cachedPassword);
        }
        return user;
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error al cargar usuarios: $e');
      // Si falla, mantener lista vacía
      _users = [];
      notifyListeners();
    }
  }

  Future<void> loadMenuItems() async {
    try {
      final productos = await _productosService.getProductos();
      _menuItems = productos.map((p) => _mapBackendToMenuItem(p as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      print('Error al cargar productos: $e');
      _menuItems = [];
      notifyListeners();
    }
  }

  Future<void> loadInventory() async {
    try {
      final items = await _inventarioService.getItems();
      _inventory = items.map((i) => _mapBackendToInventoryItem(i as Map<String, dynamic>)).toList();
      // Cargar categorías dinámicamente
      await loadInventoryCategories();
      notifyListeners();
    } catch (e) {
      print('Error al cargar inventario: $e');
      _inventory = [];
      notifyListeners();
    }
  }

  Future<void> loadInventoryCategories() async {
    try {
      final categories = await _inventarioService.getCategories();
      _inventoryCategories = ['todos', ...categories];
      notifyListeners();
    } catch (e) {
      print('Error al cargar categorías: $e');
      _inventoryCategories = ['todos'];
      notifyListeners();
    }
  }

  List<String> get inventoryCategories => _inventoryCategories;

  Future<void> loadTables() async {
    try {
      final mesas = await _mesasService.getMesas();
      // Filtrar mesas inactivas (activo = false) - el backend marca como inactivo en lugar de eliminar
      final mesasActivas = mesas.where((m) {
        final data = m as Map<String, dynamic>;
        return (data['activo'] as bool?) ?? true; // Solo incluir mesas activas
      }).toList();
      
      final nuevasMesas = mesasActivas.map((m) => _mapBackendToTableModel(m as Map<String, dynamic>)).toList();
      
      // Preservar estados locales si el mapeo parece incorrecto
      for (var i = 0; i < nuevasMesas.length; i++) {
        final nuevaMesa = nuevasMesas[i];
        final mesaExistente = _tables.firstWhere(
          (t) => t.id == nuevaMesa.id,
          orElse: () => nuevaMesa,
        );
        
        // Si el backend devuelve "libre" pero localmente tenemos otro estado (especialmente "en limpieza"),
        // puede ser un error de mapeo - mantener el estado local temporalmente
        if (mesaExistente.id == nuevaMesa.id && 
            mesaExistente.status != nuevaMesa.status &&
            nuevaMesa.status == TableStatus.libre &&
            mesaExistente.status == TableStatus.enLimpieza) {
          print('⚠️ Posible mapeo incorrecto para Mesa ${nuevaMesa.id}: Backend devuelve "libre" pero localmente es "en limpieza"');
          // Usar el estado local en lugar del del backend
          nuevasMesas[i] = TableModel(
            id: nuevaMesa.id,
            number: nuevaMesa.number,
            status: mesaExistente.status,
            seats: nuevaMesa.seats,
            customers: nuevaMesa.customers,
            waiter: nuevaMesa.waiter,
            currentTotal: nuevaMesa.currentTotal,
            lastOrderTime: nuevaMesa.lastOrderTime,
            notes: nuevaMesa.notes,
            section: nuevaMesa.section,
          );
        }
      }
      
      _tables = nuevasMesas;
      // Cargar áreas únicas desde las mesas existentes
      _loadAreasFromTables();
      notifyListeners();
    } catch (e) {
      print('Error al cargar mesas: $e');
      _tables = [];
      notifyListeners();
    }
  }

  // Cargar roles desde el backend
  Future<void> loadRoles() async {
    try {
      _roles = await _rolesService.listarRoles();
      notifyListeners();
    } catch (e) {
      print('Error al cargar roles: $e');
      _roles = [];
      notifyListeners();
    }
  }

  // Cargar permisos desde el backend
  Future<void> loadPermisos() async {
    try {
      _permisos = await _rolesService.listarPermisos();
      notifyListeners();
    } catch (e) {
      print('Error al cargar permisos: $e');
      _permisos = [];
      notifyListeners();
    }
  }

  // Crear un nuevo rol
  Future<void> crearRol({
    required String nombre,
    String? descripcion,
    required List<int> permisos,
  }) async {
    try {
      final nuevoRol = await _rolesService.crearRol(
        nombre: nombre,
        descripcion: descripcion,
        permisos: permisos,
      );
      _roles.add(nuevoRol);
      notifyListeners();
    } catch (e) {
      print('Error al crear rol: $e');
      rethrow;
    }
  }

  // Actualizar un rol existente
  Future<void> actualizarRol({
    required int id,
    String? nombre,
    String? descripcion,
    List<int>? permisos,
  }) async {
    try {
      final rolActualizado = await _rolesService.actualizarRol(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        permisos: permisos,
      );
      final index = _roles.indexWhere((r) => r.id == id);
      if (index != -1) {
        _roles[index] = rolActualizado;
        notifyListeners();
      }
    } catch (e) {
      print('Error al actualizar rol: $e');
      rethrow;
    }
  }

  // Eliminar un rol
  Future<void> eliminarRol(int id) async {
    try {
      await _rolesService.eliminarRol(id);
      _roles.removeWhere((r) => r.id == id);
    notifyListeners();
    } catch (e) {
      print('Error al eliminar rol: $e');
      rethrow;
    }
  }

  // Cargar todos los datos desde el backend
  Future<void> loadAllData() async {
    await Future.wait([
      loadUsers(),
      loadCategorias(), // Cargar categorías primero para que estén disponibles
      loadMenuItems(),
      loadInventory(),
      loadTables(),
      loadRoles(),
      loadPermisos(),
      loadTickets(),
      loadCashClosures(),
      loadDailyConsumption(), // Cargar consumo del día (órdenes)
    ]);
  }

  void _initializeData() {
    // Cargar datos desde el backend en lugar de usar datos de ejemplo
    loadAllData();
    _setupSocketListeners();
  }

  // Timer para debounce de actualizaciones
  DateTime? _lastTicketsUpdate;
  DateTime? _lastCashClosuresUpdate;
  static const _debounceMilliseconds = 2000; // 2 segundos de debounce
  
  // Verificar si debe hacer debounce
  bool _shouldDebounce(DateTime? lastUpdate) {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate).inMilliseconds < _debounceMilliseconds;
  }
  
  // Cargar tickets con debounce (para eventos de socket)
  void _loadTicketsDebounced() {
    if (_shouldDebounce(_lastTicketsUpdate)) {
      print('⏳ AdminController: Debounce activo para tickets, omitiendo...');
      return;
    }
    _lastTicketsUpdate = DateTime.now();
    loadTickets(silent: true);
  }
  
  // Cargar cierres con debounce (para eventos de socket)
  void _loadCashClosuresDebounced() {
    if (_shouldDebounce(_lastCashClosuresUpdate)) {
      print('⏳ AdminController: Debounce activo para cierres, omitiendo...');
      return;
    }
    _lastCashClosuresUpdate = DateTime.now();
    loadCashClosures(silent: true);
  }

  // Configurar listeners de Socket.IO para recibir todas las actualizaciones
  void _setupSocketListeners() {
    final socketService = SocketService();
    
    // Escuchar nuevas órdenes creadas
    socketService.onOrderCreated((dynamic data) {
      try {
        print('Admin: Nueva orden creada - ID: ${data['id']}, Mesa: ${data['mesaCodigo'] ?? data['mesaId']}');
        // Recargar consumo del día para reflejar la nueva orden
        loadDailyConsumption();
        // Recargar tickets por si se crea una cuenta asociada (con debounce)
        _loadTicketsDebounced();
        // No recargar menú ya que no cambia con nuevas órdenes
      } catch (e) {
        print('Error al procesar nueva orden en admin: $e');
      }
    });

    // Escuchar actualizaciones de órdenes
    socketService.onOrderUpdated((dynamic data) {
      try {
        print('Admin: Orden actualizada - ID: ${data['id']}');
        // Actualizar consumo del día con la orden modificada
        loadDailyConsumption();
        // Recargar tickets por si cambió el estado de pago (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar actualización de orden en admin: $e');
      }
    });

    // Escuchar cancelaciones de órdenes
    socketService.onOrderCancelled((dynamic data) {
      try {
        print('Admin: Orden cancelada - ID: ${data['id']}');
        // Actualizar consumo del día para reflejar la cancelación
        loadDailyConsumption();
        // Recargar tickets por si se canceló una cuenta (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar cancelación de orden en admin: $e');
      }
    });

    // Escuchar alertas de pago
    socketService.onAlertaPago((dynamic data) {
      try {
        print('Admin: Alerta de pago recibida - Orden ${data['ordenId']}, Total: \$${data['total']}');
        // Recargar tickets y cierres cuando hay cambios en pagos (con debounce)
        _loadTicketsDebounced();
        _loadCashClosuresDebounced();
        // Actualizar consumo del día por si cambió el estado de la orden
        loadDailyConsumption();
      } catch (e) {
        print('Error al procesar alerta de pago en admin: $e');
      }
    });

    // Escuchar alertas de caja
    socketService.onAlertaCaja((dynamic data) {
      try {
        print('Admin: Alerta de caja recibida - ${data['mensaje'] ?? 'Cambio en caja'}');
        // Recargar cierres de caja cuando hay cambios (con debounce)
        _loadCashClosuresDebounced();
        // Recargar tickets por si hay cambios relacionados (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar alerta de caja en admin: $e');
      }
    });

    // Escuchar alertas de inventario
    socketService.onAlerta((String tipo, dynamic data) {
      try {
        if (tipo.contains('inventario') || tipo.contains('stock')) {
          // Recargar inventario cuando hay alertas
          loadInventory();
        }
      } catch (e) {
        print('Error al procesar alerta en admin: $e');
      }
    });

    // Escuchar eventos de pagos (desde cajero)
    socketService.onPaymentCreated((dynamic data) {
      try {
        print('Admin: Pago creado - Orden ${data['ordenId']}, Monto: \$${data['monto']}');
        // Recargar tickets y cierres cuando se crea un pago (con debounce)
        _loadTicketsDebounced();
        _loadCashClosuresDebounced();
        // Actualizar consumo del día por si cambió el estado de la orden
        loadDailyConsumption();
      } catch (e) {
        print('Error al procesar pago creado en admin: $e');
      }
    });

    socketService.onPaymentUpdated((dynamic data) {
      try {
        print('Admin: Pago actualizado - Orden ${data['ordenId']}');
        // Recargar tickets y cierres cuando se actualiza un pago (con debounce)
        _loadTicketsDebounced();
        _loadCashClosuresDebounced();
        // Actualizar consumo del día
        loadDailyConsumption();
      } catch (e) {
        print('Error al procesar pago actualizado en admin: $e');
      }
    });

    // Escuchar eventos de mesas
    socketService.onTableCreated((dynamic data) {
      try {
        // Recargar mesas cuando se crea una nueva
        loadTables();
        notifyListeners();
      } catch (e) {
        print('Error al procesar mesa creada en admin: $e');
      }
    });

    socketService.onTableUpdated((dynamic data) {
      try {
        print('📢 Admin: Mesa actualizada recibida vía socket - Mesa ID: ${data['id']}, Estado: ${data['estadoNombre']}');
        // Recargar mesas cuando se actualiza una mesa (desde otro rol)
        // Esto asegura que los cambios del mesero o capitán se reflejen en admin
        loadTables();
        notifyListeners();
      } catch (e) {
        print('Error al procesar mesa actualizada en admin: $e');
      }
    });

    socketService.onTableDeleted((dynamic data) {
      try {
        // Recargar mesas cuando se elimina una mesa
        loadTables();
        notifyListeners();
      } catch (e) {
        print('Error al procesar mesa eliminada en admin: $e');
      }
    });

    // Escuchar cuando se envía una cuenta al cajero (desde mesero)
    socketService.on('cuenta.enviada', (dynamic data) {
      try {
        print('Admin: Cuenta enviada al cajero - Mesa ${data['tableNumber']}, Total: \$${data['total']}');
        // Recargar tickets para reflejar la nueva cuenta (con debounce)
        _loadTicketsDebounced();
        // Recargar cierres de caja para actualizar estadísticas (con debounce)
        _loadCashClosuresDebounced();
        // Actualizar consumo del día por si hay cambios en órdenes
        loadDailyConsumption();
      } catch (e) {
        print('Error al procesar cuenta enviada en admin: $e');
      }
    });

    // Escuchar alertas de cocina (demora, cancelación, modificación)
    // Estas alertas se reflejan en el consumo del día y dashboard
    socketService.onAlertaDemora((dynamic data) {
      try {
        print('Admin: Alerta de demora recibida - Orden ${data['ordenId']}');
        // Actualizar consumo del día para reflejar el estado de la orden
        loadDailyConsumption();
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de demora en admin: $e');
      }
    });

    socketService.onAlertaCancelacion((dynamic data) {
      try {
        print('Admin: Alerta de cancelación recibida - Orden ${data['ordenId']}');
        // Actualizar consumo del día para reflejar la cancelación
        loadDailyConsumption();
        // Recargar tickets por si se canceló una cuenta (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar alerta de cancelación en admin: $e');
      }
    });

    socketService.onAlertaModificacion((dynamic data) {
      try {
        print('Admin: Alerta de modificación recibida - Orden ${data['ordenId']}');
        // Actualizar consumo del día para reflejar la modificación
        loadDailyConsumption();
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de modificación en admin: $e');
      }
    });

    // Escuchar alertas generales de cocina (emitidas por meseros)
    socketService.onCocinaAlerta((dynamic data) {
      try {
        print('Admin: Alerta de cocina recibida - ${data['mensaje']}');
        // Actualizar consumo del día si hay información de orden
        if (data['ordenId'] != null) {
          loadDailyConsumption();
        }
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cocina en admin: $e');
      }
    });

    // Escuchar alertas de cocina del sistema
    socketService.onAlertaCocina((dynamic data) {
      try {
        print('Admin: Alerta de cocina del sistema recibida - ${data['mensaje']}');
        // Actualizar consumo del día si hay información de orden
        if (data['ordenId'] != null) {
          loadDailyConsumption();
        }
        notifyListeners();
      } catch (e) {
        print('Error al procesar alerta de cocina del sistema en admin: $e');
      }
    });

    // ============ EVENTOS DE TICKETS ============
    // Escuchar cuando se crea un nuevo ticket
    socketService.onTicketCreated((dynamic data) {
      try {
        print('🎫 Admin: Nuevo ticket creado - $data');
        // Recargar tickets para reflejar el nuevo ticket (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar ticket creado en admin: $e');
      }
    });

    // Escuchar cuando se imprime un ticket
    socketService.onTicketPrinted((dynamic data) {
      try {
        print('🖨️ Admin: Ticket impreso - Orden ${data['ordenId']}, Por: ${data['impresoPor']}');
        // Recargar tickets para reflejar el estado de impresión (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar ticket impreso en admin: $e');
      }
    });

    // Escuchar cuando se actualiza un ticket
    socketService.onTicketUpdated((dynamic data) {
      try {
        print('🎫 Admin: Ticket actualizado - $data');
        // Recargar tickets para reflejar los cambios (con debounce)
        _loadTicketsDebounced();
      } catch (e) {
        print('Error al procesar ticket actualizado en admin: $e');
      }
    });

    // ============ EVENTOS DE CIERRES DE CAJA ============
    // Escuchar cuando el cajero crea un cierre de caja
    socketService.onCashClosureCreated((dynamic data) {
      try {
        print('💰 Admin: Nuevo cierre de caja creado - ID: ${data['id']}, Usuario: ${data['usuario'] ?? data['creadoPorNombre']}');
        print('💰 Admin: Datos del cierre recibido: $data');
        // Forzar recarga de cierres sin debounce para que aparezca inmediatamente
        loadCashClosures(force: true, silent: true);
      } catch (e) {
        print('Error al procesar cierre de caja creado en admin: $e');
      }
    });

    // Escuchar cuando se actualiza un cierre de caja
    socketService.onCashClosureUpdated((dynamic data) {
      try {
        print('💰 Admin: Cierre de caja actualizado - ID: ${data['id']}');
        print('💰 Admin: Datos del cierre actualizado: $data');
        // Forzar recarga de cierres sin debounce para que aparezca inmediatamente
        loadCashClosures(force: true, silent: true);
      } catch (e) {
        print('Error al procesar cierre de caja actualizado en admin: $e');
      }
    });
  }

  // Los datos ahora se cargan desde el backend a través de loadAllData()
  // El código de ejemplo comentado ha sido eliminado para evitar problemas de parsing

  List<payment_models.PaymentModel> get payments =>
      _paymentRepository.payments;

  List<payment_models.PaymentModel> get todayPayments {
    final now = DateTime.now();
    return payments.where((payment) {
      final timestamp = payment.timestamp;
      return timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day;
    }).toList();
  }

  List<payment_models.PaymentModel> get filteredDailyPayments {
    final payments = todayPayments;
    switch (_selectedConsumptionFilter) {
      case 'para_llevar':
        return payments.where((payment) => payment.tableNumber == null).toList();
      case 'mesas':
        return payments.where((payment) => payment.tableNumber != null).toList();
      default:
        return payments;
    }
  }

  double get todayTotalSales {
    return todayPayments.fold(
      0.0,
      (sum, payment) => sum + payment.totalAmount,
    );
  }

  double get todayCardSales {
    return todayPayments.fold(0.0, (sum, payment) {
      if (payment.type == payment_models.PaymentType.card) {
        return sum + payment.totalAmount;
      }
      if (payment.type == payment_models.PaymentType.mixed) {
        final cashPortion = payment.cashApplied ?? 0;
        return sum + (payment.totalAmount - cashPortion);
      }
      return sum;
    });
  }

  double get todayCashSales {
    return todayPayments.fold(0.0, (sum, payment) {
      if (payment.type == payment_models.PaymentType.cash) {
        return sum + payment.totalAmount;
      }
      if (payment.type == payment_models.PaymentType.mixed) {
        return sum + (payment.cashApplied ?? 0);
      }
      return sum;
    });
  }

  double get todayLocalSales {
    return todayPayments
        .where((payment) => payment.tableNumber != null)
        .fold(0.0, (sum, payment) => sum + payment.totalAmount);
  }

  int get todayLocalOrdersCount {
    return todayPayments.where((payment) => payment.tableNumber != null).length;
  }

  // Obtener órdenes activas (pendientes, en preparación, listas)
  List<OrderModel> get activeOrders {
    return _dailyConsumption.where((order) {
      final status = order.status.toLowerCase();
      return status == 'pendiente' || 
             status == 'en preparación' || 
             status == 'en preparacion' ||
             status == 'listo' ||
             status == 'ready';
    }).toList();
  }

  // Obtener órdenes en cocina (en preparación)
  List<OrderModel> get ordersInKitchen {
    return _dailyConsumption.where((order) {
      final status = order.status.toLowerCase();
      return status == 'en preparación' || status == 'en preparacion';
    }).toList();
  }

  // Obtener mesas ocupadas
  int get occupiedTablesCount {
    return _tables.where((table) => 
      table.status == TableStatus.ocupada
    ).length;
  }

  // Obtener total de mesas
  int get totalTablesCount {
    return _tables.length;
  }

  // Obtener porcentaje de ocupación
  double get tableOccupancyRate {
    if (totalTablesCount == 0) return 0.0;
    return (occupiedTablesCount / totalTablesCount) * 100;
  }

  // Obtener items con stock crítico (bajo o sin stock)
  List<InventoryItem> get criticalStockItems {
    return _inventory.where((item) => 
      item.status == InventoryStatus.lowStock || 
      item.status == InventoryStatus.outOfStock
    ).toList();
  }

  // Obtener nombres de items con stock crítico (para mostrar en subtítulo)
  String get criticalStockItemsNames {
    final items = criticalStockItems.take(3).map((item) => item.name).toList();
    if (items.isEmpty) return 'Ninguno';
    return items.join(', ');
  }

  // Calcular ventas de ayer para comparación
  double get yesterdayTotalSales {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return payments.where((payment) {
      final timestamp = payment.timestamp;
      return timestamp.year == yesterday.year &&
          timestamp.month == yesterday.month &&
          timestamp.day == yesterday.day;
    }).fold(0.0, (sum, payment) => sum + payment.totalAmount);
  }

  // Calcular crecimiento de ventas vs ayer
  double get salesGrowthPercentage {
    if (yesterdayTotalSales == 0) {
      return todayTotalSales > 0 ? 100.0 : 0.0;
    }
    return ((todayTotalSales - yesterdayTotalSales) / yesterdayTotalSales) * 100;
  }

  double get todayTakeawaySales {
    return todayPayments
        .where((payment) => payment.tableNumber == null)
        .fold(0.0, (sum, payment) => sum + payment.totalAmount);
  }

  int get todayTakeawayOrdersCount {
    return todayPayments.where((payment) => payment.tableNumber == null).length;
  }

  double get pendingCollectionsTotal {
    return _tickets
        .where((ticket) => ticket.status == payment_models.BillStatus.pending)
        .fold(0.0, (sum, ticket) => sum + ticket.total);
  }

  int get pendingCollectionsCount {
    return _tickets
        .where((ticket) => ticket.status == payment_models.BillStatus.pending)
        .length;
  }

  void _handlePaymentsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentRepository.removeListener(_handlePaymentsChanged);
    super.dispose();
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

  // Cambiar filtro de período de tickets
  void setSelectedTicketPeriod(String period) {
    _selectedTicketPeriod = period;
    if (period != 'personalizado') {
      _ticketStartDate = null;
      _ticketEndDate = null;
    }
    notifyListeners();
  }

  // Establecer rango de fechas personalizado para tickets
  void setTicketDateRange(DateTime startDate, DateTime endDate) {
    _ticketStartDate = startDate;
    _ticketEndDate = endDate;
    _selectedTicketPeriod = 'personalizado';
    notifyListeners();
  }

  // Cargar tickets desde el backend
  Future<void> loadTickets({bool silent = false, bool force = false}) async {
    // Si force es true, ignorar el flag de carga
    if (!force && _isLoadingTickets) {
      print('⏳ AdminController: Ya se está cargando tickets, omitiendo...');
      return;
    }
    
    try {
      _isLoadingTickets = true;
      // Solo notificar si no es silencioso (evita parpadeo en actualizaciones de socket)
      if (!silent) {
        notifyListeners();
      }
      
      print('🔄 AdminController: Iniciando carga de tickets... (force: $force)');
      
      // Agregar timeout para evitar que la carga se quede colgada
      _tickets = await _ticketsService.listarTickets().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ AdminController: Timeout al cargar tickets');
          return <payment_models.BillModel>[];
        },
      );
      print('✅ AdminController: ${_tickets.length} tickets cargados');
    } catch (e, stackTrace) {
      print('❌ AdminController: Error al cargar tickets: $e');
      print('Stack trace: $stackTrace');
      _tickets = [];
    } finally {
      _isLoadingTickets = false;
      // Siempre notificar al final para mostrar los datos cargados
      notifyListeners();
    }
  }

  // Cambiar filtro de período de cierre de caja
  void setSelectedCashClosePeriod(String period) {
    _selectedCashClosePeriod = period;
    if (period != 'personalizado') {
      _cashCloseStartDate = null;
      _cashCloseEndDate = null;
    }
    // Recargar cierres cuando cambia el período
    loadCashClosures();
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
    // Recargar cierres cuando se establece el rango personalizado
    loadCashClosures();
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

  // Cargar cierres de caja desde el backend
  Future<void> loadCashClosures({bool silent = false, bool force = false}) async {
    // Si force es true, ignorar el flag de carga
    if (!force && _isLoadingCashClosures) {
      print('⏳ AdminController: Ya se está cargando cierres, omitiendo...');
      return;
    }
    
    try {
      _isLoadingCashClosures = true;
      // Solo notificar si no es silencioso (evita parpadeo en actualizaciones de socket)
      if (!silent) {
        notifyListeners();
      }
      
      print('🔄 AdminController: Iniciando carga de cierres de caja... (force: $force)');
      DateTime? fechaInicio;
      DateTime? fechaFin;
      
      // Aplicar filtros según el período seleccionado
      // IMPORTANTE: Usar hora CDMX para filtros precisos
      final now = date_utils.AppDateUtils.now();
      switch (_selectedCashClosePeriod) {
        case 'hoy':
          fechaInicio = date_utils.AppDateUtils.startOfDay(now);
          fechaFin = date_utils.AppDateUtils.endOfDay(now);
          break;
        case 'ayer':
          final ayer = now.subtract(const Duration(days: 1));
          fechaInicio = date_utils.AppDateUtils.startOfDay(ayer);
          fechaFin = date_utils.AppDateUtils.endOfDay(ayer);
          break;
        case 'semana':
          fechaInicio = now.subtract(const Duration(days: 7));
          fechaFin = now;
          break;
        case 'mes':
          fechaInicio = DateTime(now.year, now.month, 1);
          fechaFin = now;
          break;
        case 'personalizado':
          fechaInicio = _cashCloseStartDate;
          fechaFin = _cashCloseEndDate;
          break;
        default:
          // Si no hay período seleccionado, cargar todos (últimos 30 días)
          fechaInicio = now.subtract(const Duration(days: 30));
          fechaFin = now;
          break;
      }

      print('📅 AdminController: Filtros aplicados - Inicio: $fechaInicio, Fin: $fechaFin, Período: $_selectedCashClosePeriod');
      
      // Agregar timeout para evitar que la carga se quede colgada
      _cashClosures = await _cierresService.listarCierresCaja(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ AdminController: Timeout al cargar cierres');
          return <CashCloseModel>[];
        },
      );
      print('✅ AdminController: ${_cashClosures.length} cierres cargados');
      if (_cashClosures.isNotEmpty) {
        print('📋 AdminController: Primer cierre cargado - ID: ${_cashClosures.first.id}, Usuario: ${_cashClosures.first.usuario}, Fecha: ${_cashClosures.first.fecha}, Total: ${_cashClosures.first.totalNeto}');
      }
    } catch (e, stackTrace) {
      print('❌ AdminController: Error al cargar cierres de caja: $e');
      print('Stack trace: $stackTrace');
      _cashClosures = [];
    } finally {
      _isLoadingCashClosures = false;
      // Siempre notificar al final para mostrar los datos cargados
      notifyListeners();
    }
  }

  // Obtener cierres de caja filtrados
  List<CashCloseModel> get filteredCashClosures {
    print('🔍 AdminController: Filtrando ${_cashClosures.length} cierres - Período: $_selectedCashClosePeriod, Estado: $_selectedCashCloseStatus');
    final filtered = _cashClosures.where((closure) {
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
          print('🔍 AdminController: Cierre ${closure.id} - Fecha: ${closure.fecha} (${closure.fecha.year}-${closure.fecha.month}-${closure.fecha.day}), Hoy: ${now.year}-${now.month}-${now.day}, Match: $periodMatch');
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

      final matches = statusMatch && periodMatch && searchMatch;
      if (!matches && _cashClosures.length <= 5) {
        print('❌ AdminController: Cierre ${closure.id} filtrado - Status: $statusMatch, Period: $periodMatch, Search: $searchMatch');
      }
      return matches;
    }).toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
    
    print('✅ AdminController: ${filtered.length} cierres después del filtro (de ${_cashClosures.length} totales)');
    return filtered;
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

  // Actualizar estado de un cierre de caja
  Future<void> actualizarEstadoCierre({
    required int cierreId,
    required String estado,
    String? comentarioRevision,
  }) async {
    try {
      await _cierresService.actualizarEstadoCierre(
        cierreId: cierreId,
        estado: estado,
        comentarioRevision: comentarioRevision,
      );
      
      // Recargar cierres para reflejar el cambio
      await loadCashClosures(force: true);
      
      notifyListeners();
    } catch (e) {
      print('Error al actualizar estado del cierre: $e');
      rethrow;
    }
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
  Future<void> printTicket(String ticketId, String printedBy) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index != -1) {
      final ticket = _tickets[index];
      final ordenId = ticket.ordenId;
      
      // Si hay ordenId, imprimir el ticket en el backend
      if (ordenId != null) {
        try {
          final result = await _ticketsService.imprimirTicket(
            ordenId: ordenId,
            incluirCodigoBarras: true,
          );
          
          if (!result['success']) {
            print('Error al imprimir ticket: ${result['error']}');
            // Continuar de todas formas para marcar como impreso localmente
          }
        } catch (e) {
          print('Error al imprimir ticket: $e');
          // Continuar de todas formas para marcar como impreso localmente
        }
      }

      // Marcar como impreso localmente
      _tickets[index] = ticket.copyWith(
        status: payment_models.BillStatus.printed,
        isPrinted: true,
        printedBy: printedBy,
      );
      notifyListeners();
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
    // Recargar datos cuando se cambia a vistas específicas
    // SIEMPRE forzar recarga para asegurar datos frescos después de logout/login
    if (view == 'tickets') {
      print('🔄 AdminController: Cambiando a vista tickets, forzando recarga...');
      // Usar force: true para forzar la recarga aunque ya esté cargando
      loadTickets(force: true);
    } else if (view == 'cash_closures') {
      print('🔄 AdminController: Cambiando a vista cash_closures, forzando recarga...');
      // Usar force: true para forzar la recarga aunque ya esté cargando
      loadCashClosures(force: true);
    }
    notifyListeners();
  }

  // Gestión de usuarios
  Future<void> addUser(AdminUser user) async {
    try {
      // Crear usuario en el backend (devuelve la contraseña en la respuesta)
      final usuarioCreado = await _usuariosService.crearUsuario(
        nombre: user.name,
        username: user.username,
        password: user.password,
        telefono: user.phone,
        roles: user.roles,
        activo: user.isActive,
      );
      
      // Guardar la contraseña en el cache
      if (usuarioCreado.password.isNotEmpty) {
        _userPasswords[usuarioCreado.id] = usuarioCreado.password;
      }
      
      // Recargar usuarios desde el backend para asegurar sincronización
      await loadUsers();
    } catch (e) {
      // Re-lanzar el error para que el UI pueda manejarlo
      rethrow;
    }
  }

  Future<void> updateUser(AdminUser user) async {
    try {
      final userId = int.tryParse(user.id);
      if (userId == null) {
        throw Exception('ID de usuario inválido: ${user.id}');
      }
      
      // Si se está actualizando la contraseña, guardarla en el cache
      final passwordToUpdate = user.password.isNotEmpty ? user.password : null;
      
      final usuarioActualizado = await _usuariosService.actualizarUsuario(
        id: userId,
        nombre: user.name,
        telefono: user.phone,
        activo: user.isActive,
        roles: user.roles,
        password: passwordToUpdate,
      );
      
      // Si se actualizó la contraseña, guardarla en el cache
      if (passwordToUpdate != null && usuarioActualizado.password.isNotEmpty) {
        _userPasswords[user.id] = usuarioActualizado.password;
      }
      
      // Recargar usuarios desde el backend para asegurar sincronización
      await loadUsers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final id = int.tryParse(userId);
      if (id == null) {
        throw Exception('ID de usuario inválido: $userId');
      }
      await _usuariosService.eliminarUsuario(id);
      // Recargar usuarios desde el backend para asegurar sincronización
      await loadUsers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(isActive: !user.isActive);
      // updateUser ya recarga desde el backend
      await updateUser(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  // Cambiar contraseña de usuario
  Future<void> changeUserPassword(String userId, String newPassword) async {
    try {
      final id = int.tryParse(userId);
      if (id == null) {
        throw Exception('ID de usuario inválido: $userId');
      }
      
      final usuarioActualizado = await _usuariosService.actualizarUsuario(
        id: id,
        password: newPassword,
      );
      
      // Guardar la contraseña en el cache
      if (usuarioActualizado.password.isNotEmpty) {
        _userPasswords[userId] = usuarioActualizado.password;
      }
      
      // Recargar usuarios desde el backend para asegurar sincronización
      await loadUsers();
    } catch (e) {
      rethrow;
    }
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
  final int _usersPerPage = 10;

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
  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      final Map<String, dynamic> data = {
        'nombre': item.name,
        'categoria': _normalizeInventoryCategory(item.category),
        'unidad': item.unit,
        'cantidadActual': item.currentStock,
        'stockMinimo': item.minStock,
        'stockMaximo': item.maxStock,
        'costoUnitario': item.cost,
        'proveedor': item.supplier,
        'activo': true,
      };
      await _inventarioService.createItem(data);
      // Recargar inventario y categorías desde el backend para asegurar sincronización
      await loadInventory();
      // Si la categoría no estaba en la lista, agregarla
      final normalizedCategory = _normalizeInventoryCategory(item.category);
      if (!_inventoryCategories.contains(normalizedCategory) && normalizedCategory != 'Otros') {
        addInventoryCategory(normalizedCategory);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final itemId = int.tryParse(item.id);
      if (itemId == null) {
        throw Exception('ID de inventario inválido: ${item.id}');
      }
      
      final Map<String, dynamic> data = {
        'nombre': item.name,
        'categoria': _normalizeInventoryCategory(item.category),
        'unidad': item.unit,
        'cantidadActual': item.currentStock,
        'stockMinimo': item.minStock,
        'stockMaximo': item.maxStock,
        'costoUnitario': item.cost,
        'proveedor': item.supplier,
        'activo': item.status != InventoryStatus.expired,
      };
      await _inventarioService.updateItem(itemId, data);
      // Recargar inventario desde el backend para asegurar sincronización
      await loadInventory();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(String itemId) async {
    try {
      final id = int.tryParse(itemId);
      if (id == null) {
        throw Exception('ID de inventario inválido: $itemId');
      }
      await _inventarioService.eliminarItem(id);
      // Recargar inventario desde el backend para asegurar sincronización
      await loadInventory();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restockInventoryItem(String itemId, double quantity) async {
    try {
      final id = int.tryParse(itemId);
      if (id == null) {
        throw Exception('ID de inventario inválido: $itemId');
      }
      
      // Registrar movimiento de entrada
      final movimientoData = {
        'inventarioItemId': id,
        'tipo': 'entrada',
        'cantidad': quantity,
        'motivo': 'Reabastecimiento manual',
        'origen': 'compra',
      };
      
      await _inventarioService.registrarMovimiento(movimientoData);
      
      // Recargar inventario desde el backend para asegurar sincronización
      await loadInventory();
    } catch (e) {
      rethrow;
    }
  }

  // Helper para mapear datos del backend a InventoryItem
  InventoryItem _mapBackendToInventoryItem(Map<String, dynamic> data) {
    final cantidadActual = (data['cantidadActual'] as num?)?.toDouble() ?? 0.0;
    final stockMinimo = (data['stockMinimo'] as num?)?.toDouble() ?? 0.0;
    final costoUnitario = (data['costoUnitario'] as num?)?.toDouble();
    final categoriaEntrada = data['categoria'] ?? data['category'];
    final normalizedCategory = _normalizeInventoryCategory(
      categoriaEntrada?.toString(),
    );
    
    // Calcular status basado en stock
    String status = InventoryStatus.available;
    if (cantidadActual <= 0) {
      status = InventoryStatus.outOfStock;
    } else if (cantidadActual <= stockMinimo) {
      status = InventoryStatus.lowStock;
    }
    
    final stockMaximo = (data['stockMaximo'] as num?)?.toDouble();
    // Si no hay stockMaximo en el backend, usar stockMinimo * 2 como fallback
    final maxStock = stockMaximo ?? (stockMinimo * 2);
    
    return InventoryItem(
      id: data['id'].toString(),
      name: data['nombre'] as String,
      category: normalizedCategory,
      currentStock: cantidadActual,
      minStock: stockMinimo,
      maxStock: maxStock,
      minimumStock: stockMinimo,
      unit: data['unidad'] as String,
      cost: costoUnitario ?? 0.0,
      price: costoUnitario ?? 0.0,
      unitPrice: costoUnitario ?? 0.0,
      supplier: data['proveedor'] as String?,
      lastRestock: data['actualizadoEn'] != null 
          ? date_utils.AppDateUtils.parseToLocal(data['actualizadoEn'])
          : null,
      expiryDate: null,
      status: status,
      notes: null,
      description: null,
    );
  }

  // Gestión de menú
  Future<void> addMenuItem(MenuItem item) async {
    try {
      // Validar que el nombre no esté vacío
      if (item.name.trim().isEmpty) {
        throw Exception('El nombre del producto no puede estar vacío');
      }
      
      // Validar que el nombre tenga al menos 2 caracteres (requisito del backend)
      if (item.name.trim().length < 2) {
        throw Exception('El nombre del producto debe tener al menos 2 caracteres');
      }
      
      // Validar que el precio sea mayor a 0 si no tiene tamaños
      if (!item.hasSizes && (item.price == null || item.price! <= 0)) {
        throw Exception('El precio debe ser mayor a 0');
      }
      
      // Obtener categoría ID por nombre
      final categoriaId = await _getCategoriaIdByName(item.category);
      
      // Si tiene tamaños, usar el precio del primer tamaño o 0.0
      // Si no tiene tamaños, usar el precio del item
      final precioFinal = item.hasSizes 
          ? (item.sizes?.isNotEmpty == true 
              ? item.sizes!.first.price 
              : 0.0)
          : (item.price ?? 0.0);
      
      // Validar precio final
      if (precioFinal <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }
      
      final data = <String, dynamic>{
        'categoriaId': categoriaId,
        'nombre': item.name.trim(),
        'descripcion': item.description.trim().isEmpty ? null : item.description.trim(),
        'precio': precioFinal,
        'disponible': item.isAvailable,
        'sku': null,
        'inventariable': false,
      };

      if (item.hasSizes && (item.sizes?.isNotEmpty ?? false)) {
        data['tamanos'] = item.sizes!
            .map((size) => {
                  'nombre': size.name.trim(),
                  'precio': size.price,
                })
            .toList();
      }

      data['ingredientes'] = item.recipeIngredients?.isNotEmpty == true
          ? item.recipeIngredients!.map(_recipeIngredientToBackend).toList()
          : [];
      
      await _productosService.createProducto(data);
      // Recargar productos y categorías desde el backend para asegurar sincronización
      await Future.wait([
        loadMenuItems(),
        loadCategorias(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItem item) async {
    try {
      final itemId = int.tryParse(item.id);
      if (itemId == null) {
        throw Exception('ID de producto inválido: ${item.id}');
      }
      
      // Obtener categoría ID por nombre
      final categoriaId = await _getCategoriaIdByName(item.category);
      
      final basePrice = item.hasSizes
          ? (item.sizes?.isNotEmpty == true ? item.sizes!.first.price : item.price ?? 0.0)
          : (item.price ?? 0.0);

      final data = <String, dynamic>{
        'categoriaId': categoriaId,
        'nombre': item.name,
        'descripcion': item.description,
        'precio': basePrice,
        'disponible': item.isAvailable,
      };

      if (item.hasSizes) {
        data['tamanos'] = item.sizes
            ?.map((size) => {
                  'nombre': size.name.trim(),
                  'precio': size.price,
                })
            .toList();
      } else {
        data['tamanos'] = [];
      }

      data['ingredientes'] = item.recipeIngredients?.isNotEmpty == true
          ? item.recipeIngredients!.map(_recipeIngredientToBackend).toList()
          : [];
      
      await _productosService.updateProducto(itemId, data);
      // Recargar productos desde el backend para asegurar sincronización
      await loadMenuItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      final id = int.tryParse(itemId);
      if (id == null) {
        throw Exception('ID de producto inválido: $itemId');
      }
      await _productosService.desactivarProducto(id);
      // Recargar productos desde el backend para asegurar sincronización
      await loadMenuItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleMenuItemAvailability(String itemId) async {
    try {
      final item = _menuItems.firstWhere((i) => i.id == itemId);
      final updatedItem = item.copyWith(isAvailable: !item.isAvailable);
      // updateMenuItem ya recarga desde el backend
      await updateMenuItem(updatedItem);
    } catch (e) {
      rethrow;
    }
  }

  // Helper para obtener ID de categoría por nombre
  Future<int> _getCategoriaIdByName(String categoryName) async {
    try {
      final categorias = await _categoriasService.getCategorias();
      if (categorias.isEmpty) {
        throw Exception('No hay categorías disponibles en el sistema');
      }
      final categoria = categorias.firstWhere(
        (c) {
          final nombre = c['nombre'] as String?;
          return nombre != null && nombre.toLowerCase() == categoryName.toLowerCase();
        },
        orElse: () => <String, dynamic>{},
      );
      if (categoria.isEmpty) {
        throw Exception('Categoría no encontrada: $categoryName');
      }
      final id = categoria['id'];
      if (id == null) {
        throw Exception('La categoría "$categoryName" no tiene un ID válido');
      }
      return id as int;
    } catch (e) {
      throw Exception('Error al buscar categoría "$categoryName": $e');
    }
  }

  // Helper para mapear datos del backend a MenuItem
  MenuItem _mapBackendToMenuItem(Map<String, dynamic> data) {
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool _parseBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return fallback;
    }

    final tamanos = (data['tamanos'] as List<dynamic>?)
            ?.map((size) => MenuSize.fromJson(size as Map<String, dynamic>))
            .where((size) => size.name.isNotEmpty && size.price > 0)
            .toList() ??
        [];

    final ingredientesData = (data['ingredientes'] as List<dynamic>?) ??
        (data['recipeIngredients'] as List<dynamic>?);

    final ingredientes = ingredientesData
        ?.map((raw) {
          final ingredienteMap = Map<String, dynamic>.from(raw as Map);
          final quantity = _parseDouble(
            ingredienteMap['cantidadPorPorcion'] ??
                ingredienteMap['cantidad_por_porcion'] ??
                0,
          );
          final autoDeduct = _parseBool(
            ingredienteMap['descontarAutomaticamente'] ??
                ingredienteMap['descontar_automaticamente'],
            fallback: true,
          );
          final isCustom = _parseBool(
            ingredienteMap['esPersonalizado'] ??
                ingredienteMap['es_personalizado'],
          );
          final inventoryItemId =
              (ingredienteMap['inventarioItemId'] ??
                      ingredienteMap['inventario_item_id'])
                  ?.toString();
          final categoriaEntrada = ingredienteMap['categoria'] ??
              ingredienteMap['category'] ??
              'Otros';

          return RecipeIngredient(
            id: (ingredienteMap['id'] ??
                    DateTime.now().millisecondsSinceEpoch)
                .toString(),
            name: (ingredienteMap['nombre'] ?? ingredienteMap['name'] ?? '')
                .toString(),
            unit: (ingredienteMap['unidad'] ?? ingredienteMap['unit'] ?? '')
                .toString(),
            quantityPerPortion: quantity,
            autoDeduct: autoDeduct,
            isCustom: isCustom,
            category: _normalizeInventoryCategory(categoriaEntrada.toString()),
            inventoryItemId: inventoryItemId,
          );
        })
        .toList();

    return MenuItem(
      id: data['id'].toString(),
      name: data['nombre'] as String,
      category: data['categoriaNombre'] as String? ?? 'Otros',
      description: data['descripcion'] as String? ?? '',
      price: (data['precio'] as num?)?.toDouble(),
      isAvailable: data['disponible'] as bool? ?? true,
      image: null,
      ingredients: [],
      allergens: [],
      preparationTime: 0,
      notes: null,
      createdAt: data['creadoEn'] != null
          ? date_utils.AppDateUtils.parseToLocal(data['creadoEn'])
          : DateTime.now(),
      updatedAt: data['actualizadoEn'] != null
          ? date_utils.AppDateUtils.parseToLocal(data['actualizadoEn'])
          : null,
      hasSizes: tamanos.isNotEmpty,
      sizes: tamanos.isNotEmpty ? tamanos : null,
      serveHot: false,
      isSpicy: false,
      allowSauces: false,
      allowExtraIngredients: false,
      recipeIngredients: ingredientes,
    );
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
    final categories = _inventory
        .map((item) => _normalizeInventoryCategory(item.category))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final hasOtros = categories.any((category) => category.toLowerCase() == 'otros');
    if (!hasOtros) {
      categories.add('Otros');
    }
    return categories;
  }

  List<InventoryItem> getInventoryItemsByCategory(String category) {
    final normalized = _normalizeInventoryCategory(category).toLowerCase();
    final items = _inventory
        .where(
          (item) =>
              item.status == InventoryStatus.available &&
              item.category.toLowerCase() == normalized,
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
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

  // Agregar nueva área de mesa
  void addTableArea(String areaName) {
    final trimmedArea = areaName.trim();
    if (trimmedArea.isNotEmpty && !_tableAreas.contains(trimmedArea)) {
      _tableAreas.add(trimmedArea);
      notifyListeners();
    }
  }
  
  // Eliminar área de mesa y actualizar mesas en la BD
  Future<void> deleteTableArea(String areaName) async {
    try {
      // Obtener área de reemplazo (primera disponible que no sea 'todos' ni la que se elimina)
      final availableAreas = _tableAreas
          .where((a) => a != 'todos' && a != areaName)
          .toList();
      final replacementArea = availableAreas.isNotEmpty 
          ? availableAreas.first 
          : null;
      
      // Obtener todas las mesas que usan esta área
      final mesasConArea = _tables.where((t) => t.section == areaName).toList();
      
      // ACTUALIZAR LOCALMENTE PRIMERO (respuesta inmediata)
      for (var mesa in mesasConArea) {
        final mesaIndex = _tables.indexWhere((t) => t.id == mesa.id);
        if (mesaIndex != -1) {
          _tables[mesaIndex] = TableModel(
            id: mesa.id,
            number: mesa.number,
            status: mesa.status,
            seats: mesa.seats,
            customers: mesa.customers,
            waiter: mesa.waiter,
            currentTotal: mesa.currentTotal,
            lastOrderTime: mesa.lastOrderTime,
            notes: mesa.notes,
            section: replacementArea,
          );
        }
      }
      
      // Eliminar el área de la lista
      _tableAreas.remove(areaName);
      
      // Si el área eliminada estaba seleccionada, cambiar a 'todos'
      if (_selectedTableArea == areaName) {
        _selectedTableArea = 'todos';
      }
      
      // Notificar cambios inmediatamente
      notifyListeners();
      
      // ACTUALIZAR EN EL BACKEND EN SEGUNDO PLANO (NO BLOQUEANTE)
      // Esto se ejecuta sin esperar, permitiendo que el método retorne inmediatamente
      if (mesasConArea.isNotEmpty) {
        _updateMesasInBackground(mesasConArea, replacementArea, areaName).catchError((e) {
          print('❌ Error al actualizar mesas en segundo plano: $e');
          // Si hay error, recargar desde el backend para restaurar estado correcto
          loadTables();
        });
      } else {
        print('✅ Área "$areaName" eliminada. No había mesas usando esta área.');
      }
    } catch (e) {
      print('❌ Error al eliminar área: $e');
      // Si hay error, recargar desde el backend para restaurar estado correcto
      await loadTables();
      rethrow;
    }
  }
  
  // Método auxiliar para actualizar mesas en segundo plano (no bloqueante)
  Future<void> _updateMesasInBackground(
    List<TableModel> mesasConArea,
    String? replacementArea,
    String areaName,
  ) async {
    try {
      // Procesar en chunks de 5 mesas a la vez para evitar sobrecargar el servidor
      const chunkSize = 5;
      for (var i = 0; i < mesasConArea.length; i += chunkSize) {
        final chunk = mesasConArea.sublist(
          i,
          i + chunkSize > mesasConArea.length ? mesasConArea.length : i + chunkSize,
        );
        
        // Actualizar chunk en paralelo
        // Cada actualización emitirá un evento de socket que el mesero recibirá
        await Future.wait(
          chunk.map((mesa) {
            final data = {
              'codigo': mesa.number.toString(),
              'nombre': 'Mesa ${mesa.number}',
              'capacidad': mesa.seats,
              'ubicacion': replacementArea,
            };
            return _mesasService.updateMesa(mesa.id, data);
          }),
        );
        
        // Pequeño delay entre chunks para evitar saturar el servidor
        if (i + chunkSize < mesasConArea.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      print('✅ Área "$areaName" eliminada. ${mesasConArea.length} mesa(s) actualizada(s) en el backend.');
      print('📢 Eventos de socket emitidos para sincronizar con mesero.');
    } catch (e) {
      print('❌ Error al actualizar mesas en segundo plano: $e');
      rethrow;
    }
  }
  
  // Cargar áreas únicas desde las mesas existentes
  void _loadAreasFromTables() {
    final areasFromTables = _tables
        .where((t) => t.section != null && t.section!.isNotEmpty)
        .map((t) => t.section!)
        .toSet();
    
    for (final area in areasFromTables) {
      if (!_tableAreas.contains(area)) {
        _tableAreas.add(area);
      }
    }
  }

  // Agregar nueva categoría de inventario
  void addInventoryCategory(String categoryName) {
    final trimmedCategory = categoryName.trim();
    if (trimmedCategory.isNotEmpty && !_inventoryCategories.contains(trimmedCategory)) {
      // Agregar después de 'todos' si existe, sino al inicio
      if (_inventoryCategories.contains('todos')) {
        _inventoryCategories.insert(1, trimmedCategory);
      } else {
        _inventoryCategories.add(trimmedCategory);
      }
      notifyListeners();
    }
  }

  // Cargar consumo del día desde el backend
  Future<void> loadDailyConsumption() async {
    try {
      final ordenes = await _ordenesService.getOrdenes();
      
      // Convertir órdenes del backend a OrderModel
      final orders = ordenes.map((ordenData) {
        return _mapBackendToOrderModel(ordenData as Map<String, dynamic>);
      }).toList();
      
      // Ordenar por fecha (más recientes primero)
      orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      
      _dailyConsumption = orders;
      notifyListeners();
    } catch (e) {
      print('Error al cargar consumo del día: $e');
      _dailyConsumption = [];
      notifyListeners();
    }
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

  // Mapear datos del backend a OrderModel
  OrderModel _mapBackendToOrderModel(Map<String, dynamic> data) {
    final ordenId = data['id'] as int? ?? 0;
    final estadoNombre = (data['estadoNombre'] as String?)?.toLowerCase() ?? 'pendiente';
    
    // Mapear estado (usando strings como en OrderModel)
    String status = OrderStatus.pendiente;
    if (estadoNombre.contains('cancel')) {
      status = OrderStatus.cancelada;
    } else if (estadoNombre.contains('listo') && estadoNombre.contains('recoger')) {
      status = OrderStatus.listoParaRecoger;
    } else if (estadoNombre.contains('listo') || estadoNombre.contains('completado')) {
      status = OrderStatus.listo;
    } else if (estadoNombre.contains('preparacion') || estadoNombre.contains('preparación')) {
      status = OrderStatus.enPreparacion;
    }

    // Obtener items (simplificado, se puede mejorar obteniendo el detalle completo)
    final items = <OrderItem>[];
    // Si hay items en los datos, mapearlos
    if (data['items'] != null && data['items'] is List) {
      final itemsData = data['items'] as List<dynamic>;
      for (var itemData in itemsData) {
        if (itemData is Map<String, dynamic>) {
          // Determinar estación basada en el nombre del producto
          String station = KitchenStation.tacos;
          final productName = ((itemData['productoNombre'] as String?) ?? 
                               (itemData['nombre'] as String?) ?? 
                               '').toLowerCase();
          if (productName.contains('consom') || productName.contains('mix')) {
            station = KitchenStation.consomes;
          } else if (productName.contains('agua') ||
              productName.contains('horchata') ||
              productName.contains('refresco') ||
              productName.contains('bebida')) {
            station = KitchenStation.bebidas;
          }

          items.add(OrderItem(
            id: (itemData['id'] as num?)?.toInt() ?? 
                (itemData['ordenItemId'] as num?)?.toInt() ?? 
                DateTime.now().millisecondsSinceEpoch,
            name: itemData['productoNombre'] as String? ?? 
                  itemData['nombre'] as String? ?? 
                  'Producto',
            quantity: (itemData['cantidad'] as num?)?.toInt() ?? 1,
            station: station,
            notes: (itemData['nota'] as String?) ?? 
                   (itemData['notas'] as String?) ?? 
                   '',
          ));
        }
      }
    }

    // Obtener mesa
    final mesaId = data['mesaId'] as int?;
    final mesaCodigo = data['mesaCodigo'] as String?;
    final tableNumber = mesaCodigo != null 
        ? int.tryParse(mesaCodigo.replaceAll('Mesa ', '').trim()) 
        : (mesaId != null ? mesaId : null);

    // Obtener fechas
    DateTime orderTime;
    if (data['creadoEn'] != null) {
      try {
        orderTime = date_utils.AppDateUtils.parseToLocal(data['creadoEn']);
      } catch (e) {
        orderTime = DateTime.now();
      }
    } else {
      orderTime = DateTime.now();
    }

    // Mapear prioridad
    String priority = OrderPriority.normal;
    final prioridadBackend = (data['prioridad'] as String?)?.toLowerCase();
    if (prioridadBackend == 'alta' || prioridadBackend == 'urgente') {
      priority = OrderPriority.alta;
    }

    return OrderModel(
      id: ordenId.toString(),
      tableNumber: tableNumber,
      items: items,
      status: status,
      orderTime: orderTime,
      estimatedTime: 15, // Tiempo estimado por defecto
      waiter: data['creadoPorNombre'] as String? ?? 
              data['creadoPorUsuarioNombre'] as String? ?? 
              'Mesero',
      priority: priority,
      isTakeaway: mesaId == null,
      customerName: data['clienteNombre'] as String?,
      customerPhone: data['clienteTelefono'] as String?,
    );
  }

  // Gestión de mesas
  Future<void> addTable(TableModel table) async {
    try {
      // Obtener estado inicial (libre)
      final estados = await _mesasService.getEstadosMesa();
      final estadoLibre = estados.firstWhere(
        (e) => (e['nombre'] as String).toLowerCase() == 'libre',
        orElse: () => estados.isNotEmpty ? estados[0] : {'id': 1},
      );
      
      final data = {
        'codigo': table.number.toString(),
        'nombre': 'Mesa ${table.number}',
        'capacidad': table.seats,
        'ubicacion': table.section,
        'estadoMesaId': estadoLibre['id'] as int,
        'activo': true,
      };
      
      await _mesasService.createMesa(data);
      // Recargar mesas desde el backend para asegurar sincronización
      await loadTables();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTable(TableModel table) async {
    try {
      final data = {
        'codigo': table.number.toString(),
        'nombre': 'Mesa ${table.number}',
        'capacidad': table.seats,
        'ubicacion': table.section,
      };
      
      await _mesasService.updateMesa(table.id, data);
      // Recargar mesas desde el backend para asegurar sincronización
      await loadTables();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTable(int tableId) async {
    try {
      // ELIMINAR LOCALMENTE PRIMERO (respuesta inmediata)
      _tables.removeWhere((t) => t.id == tableId);
      notifyListeners(); // Notificar inmediatamente para que desaparezca de la UI
      
      // Eliminar en el backend (marca como inactiva)
      await _mesasService.eliminarMesa(tableId);
      
      // Recargar mesas desde el backend para asegurar sincronización
      // Esto también sincronizará con el mesero a través del evento de socket
      await loadTables();
    } catch (e) {
      // Si hay error, recargar desde el backend para restaurar estado correcto
      await loadTables();
      rethrow;
    }
  }

  Future<void> updateTableStatus(int tableId, String newStatus) async {
    try {
      // Obtener estados disponibles primero
      final estados = await _mesasService.getEstadosMesa();
      
      // Mapear nombre de estado a ID
      int? estadoId;
      final statusMap = {
        'libre': 'libre',
        'ocupada': 'ocupada',
        'en-limpieza': 'en limpieza',
        'reservada': 'reservada',
      };
      
      final statusNormalized = statusMap[newStatus] ?? newStatus.toLowerCase();
      
      // Buscar el estado que coincida (puede ser exacto o contener el texto)
      estadoId = null;
      for (final e in estados) {
        final nombreEstado = (e['nombre'] as String).toLowerCase().trim();
        if (nombreEstado == statusNormalized || 
            nombreEstado.contains(statusNormalized) ||
            statusNormalized.contains(nombreEstado)) {
          estadoId = e['id'] as int;
          print('✅ Estado encontrado: "${e['nombre']}" (ID: $estadoId) para "$newStatus"');
          break;
        }
      }
      
      // Si no se encontró, usar el primero disponible o lanzar error
      if (estadoId == null) {
        print('⚠️ Estado no encontrado: "$statusNormalized". Estados disponibles: ${estados.map((e) => e['nombre']).toList()}');
        if (estados.isNotEmpty) {
          estadoId = estados[0]['id'] as int;
          print('⚠️ Usando estado por defecto: ${estados[0]['nombre']} (ID: $estadoId)');
        } else {
          throw Exception('No se encontró el estado "$newStatus" y no hay estados disponibles');
        }
      }
      
      // Cambiar estado en el backend
      await _mesasService.cambiarEstadoMesa(tableId, estadoId);
      
      // Actualizar estado localmente después de confirmar en el backend
      final mesaIndex = _tables.indexWhere((t) => t.id == tableId);
      if (mesaIndex != -1) {
        final mesaActualizada = TableModel(
          id: _tables[mesaIndex].id,
          number: _tables[mesaIndex].number,
          status: newStatus,
          seats: _tables[mesaIndex].seats,
          customers: _tables[mesaIndex].customers,
          waiter: _tables[mesaIndex].waiter,
          currentTotal: _tables[mesaIndex].currentTotal,
          lastOrderTime: _tables[mesaIndex].lastOrderTime,
          notes: _tables[mesaIndex].notes,
          section: _tables[mesaIndex].section,
        );
        _tables[mesaIndex] = mesaActualizada;
        notifyListeners(); // Notificar inmediatamente para actualizar UI
      }
      
      // NO recargar inmediatamente - el estado ya está actualizado localmente
      // El evento de socket se encargará de sincronizar con otros roles
      // Solo recargar en segundo plano después de un delay para verificar sincronización
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await loadTables();
        } catch (e) {
          print('⚠️ Error al recargar mesas en segundo plano: $e');
        }
      });
    } catch (e) {
      print('❌ Error al actualizar estado de mesa: $e');
      // Si hay error, recargar desde el backend para restaurar estado correcto
      await loadTables();
      rethrow;
    }
  }

  // Helper para mapear datos del backend a TableModel
  TableModel _mapBackendToTableModel(Map<String, dynamic> data) {
    final codigo = data['codigo'] as String;
    final numero = int.tryParse(codigo) ?? 0;
    final estadoNombreRaw = data['estadoNombre'] as String?;
    final estadoNombre = estadoNombreRaw?.toLowerCase().trim() ?? 'libre';
    
    // Mapear estado del backend a estado del frontend
    String status = TableStatus.libre;
    
    // Verificar primero coincidencias exactas
    if (estadoNombre == 'libre') {
      status = TableStatus.libre;
    } else if (estadoNombre == 'ocupada' || estadoNombre == 'ocupado') {
      status = TableStatus.ocupada;
    } else if (estadoNombre == 'reservada' || estadoNombre == 'reservado') {
      status = TableStatus.reservada;
    } else if (estadoNombre == 'en limpieza' || 
               estadoNombre == 'en-limpieza' || 
               estadoNombre == 'limpieza') {
      status = TableStatus.enLimpieza;
    } 
    // Luego verificar coincidencias parciales
    else if (estadoNombre.contains('ocupad')) {
      status = TableStatus.ocupada;
    } else if (estadoNombre.contains('limpieza')) {
      status = TableStatus.enLimpieza;
    } else if (estadoNombre.contains('reservad')) {
      status = TableStatus.reservada;
    } else if (estadoNombre.contains('libre')) {
      status = TableStatus.libre;
    }
    
    // Debug: imprimir el mapeo para verificar
    if (estadoNombreRaw != null && estadoNombreRaw.isNotEmpty && estadoNombre != 'libre') {
      print('🔍 Mapeando estado del backend: "$estadoNombreRaw" (normalizado: "$estadoNombre") -> "$status"');
    }
    
    return TableModel(
      id: data['id'] as int,
      number: numero,
      status: status,
      seats: data['capacidad'] as int? ?? 4,
      customers: null,
      waiter: null,
      currentTotal: null,
      lastOrderTime: null,
      notes: null,
      section: data['ubicacion'] as String?,
    );
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

  // Gestión de categorías personalizadas (ahora conectado al backend)
  Future<void> addCustomCategory(String categoryName) async {
    try {
      // Verificar si ya existe localmente
      if (_customCategories.contains(categoryName)) {
        throw Exception('Ya existe una categoría con ese nombre');
      }
      
      // Crear categoría en el backend
      final data = {
        'nombre': categoryName,
        'descripcion': null,
        'activo': true,
      };
      
      await _categoriasService.createCategoria(data);
      
      // Recargar categorías desde el backend para asegurar sincronización
      await loadCategorias();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomCategory(String oldName, String newName) async {
    try {
      // Obtener el ID de la categoría antigua
      final categorias = await _categoriasService.getCategorias();
      final categoriaAntigua = categorias.firstWhere(
        (c) => (c['nombre'] as String) == oldName,
        orElse: () => <String, dynamic>{},
      );
      
      if (categoriaAntigua.isEmpty) {
        throw Exception('Categoría no encontrada: $oldName');
      }
      
      final categoriaId = categoriaAntigua['id'] as int;
      
      // Actualizar categoría en el backend
      final data = {
        'nombre': newName,
        'descripcion': categoriaAntigua['descripcion'],
        'activo': (categoriaAntigua['activo'] as bool?) ?? true,
      };
      
      await _categoriasService.updateCategoria(categoriaId, data);
      
      // Actualizar productos que usan esta categoría (esto se hará automáticamente cuando se recarguen)
      // Recargar categorías y productos desde el backend
      await Future.wait([
        loadCategorias(),
        loadMenuItems(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteCustomCategory(String categoryName) async {
    try {
    if (!canDeleteCategory(categoryName)) {
        throw Exception('No se puede eliminar la categoría porque tiene productos asociados');
      }

      // Obtener el ID de la categoría
      final categorias = await _categoriasService.getCategorias();
      final categoria = categorias.firstWhere(
        (c) => (c['nombre'] as String) == categoryName,
        orElse: () => <String, dynamic>{},
      );
      
      if (categoria.isEmpty) {
        throw Exception('Categoría no encontrada: $categoryName');
      }
      
      final categoriaId = categoria['id'] as int;
      
      // Eliminar categoría en el backend
      await _categoriasService.eliminarCategoria(categoriaId);
      
      // Recargar categorías desde el backend
      await loadCategorias();
      
      // Si la categoría eliminada estaba seleccionada, cambiar a 'todos'
      if (_selectedMenuCategory.toLowerCase() == categoryName.toLowerCase()) {
        _selectedMenuCategory = 'todos';
      }
      
      // Notificar cambios para actualizar la UI
      notifyListeners();
      
    return true;
    } catch (e) {
      rethrow;
    }
  }

  bool canDeleteCategory(String categoryName) {
    return _customCategories.contains(categoryName) &&
        !_menuItems.any((item) => item.category == categoryName);
  }

  bool isCustomCategory(String categoryName) {
    return _customCategories.contains(categoryName);
  }

  bool categoryHasProducts(String categoryName) {
    return _menuItems.any((item) => item.category == categoryName);
  }

  // Cargar categorías desde el backend
  Future<void> loadCategorias() async {
    try {
      final categorias = await _categoriasService.getCategorias();
      // Actualizar categorías personalizadas con las del backend
      _customCategories = categorias
          .map((c) => c['nombre'] as String?)
          .where((nombre) => nombre != null && nombre.isNotEmpty)
          .cast<String>()
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error al cargar categorías: $e');
      // Si falla, mantener categorías predeterminadas
    }
  }

  // Obtener todas las categorías (del backend y de los productos existentes)
  List<String> getAllCategories() {
    // Obtener categorías de productos existentes
    final productCategories = _menuItems
        .map((item) => item.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    
    // Combinar categorías del backend y de productos
    final allCategories = <String>{};
    allCategories.addAll(_customCategories);
    allCategories.addAll(productCategories);
    
    // Normalizar: convertir primera letra a mayúscula y ordenar
    return allCategories
        .map((categoria) {
          if (categoria.isEmpty) return categoria;
          return categoria[0].toUpperCase() + categoria.substring(1).toLowerCase();
        })
        .toSet() // Eliminar duplicados después de normalizar
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
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
}