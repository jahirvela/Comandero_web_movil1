import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../../../services/ordenes_service.dart';
import '../../../services/pagos_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/date_utils.dart' as date_utils;

class RealTimeSalesWebView extends StatefulWidget {
  const RealTimeSalesWebView({super.key});

  @override
  State<RealTimeSalesWebView> createState() => _RealTimeSalesWebViewState();
}

class _RealTimeSalesWebViewState extends State<RealTimeSalesWebView> {
  String _selectedTimeframe = 'hoy';
  bool _autoRefresh = true;
  List<Map<String, dynamic>> realTimeSales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealTimeSales();
    // Actualización automática cada 30 segundos
    if (_autoRefresh) {
      _startAutoRefresh();
    }
  }

  Future<void> _loadRealTimeSales() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ordenesService = OrdenesService();
      final pagosService = PagosService();
      
      // Obtener órdenes recientes
      final ordenes = await ordenesService.getOrdenes();
      
      // Obtener pagos recientes
      final pagos = await pagosService.getPagos();
      
      // Filtrar por timeframe
      final ahora = date_utils.AppDateUtils.nowCdmx();
      DateTime fechaInicio;
      
      switch (_selectedTimeframe) {
        case 'hoy':
          fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
          break;
        case 'semana':
          fechaInicio = ahora.subtract(const Duration(days: 7));
          break;
        case 'mes':
          fechaInicio = DateTime(ahora.year, ahora.month, 1);
          break;
        default:
          fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
      }

      // Combinar órdenes y pagos para crear ventas en tiempo real
      final ventas = <Map<String, dynamic>>[];
      
      // Procesar pagos recientes
      for (final pago in pagos) {
        final creadoEnRaw = pago['creadoEn'];
        final creadoEn = creadoEnRaw != null 
            ? date_utils.AppDateUtils.parseToLocal(creadoEnRaw)
            : null;
        
        if (creadoEn != null && creadoEn.isAfter(fechaInicio)) {
          final ordenId = pago['ordenId'] as int?;
          Map<String, dynamic> orden = <String, dynamic>{};
          if (ordenId != null && ordenes.isNotEmpty) {
            try {
              orden = ordenes.firstWhere(
                (o) => o['id'] == ordenId,
                orElse: () => <String, dynamic>{},
              );
            } catch (e) {
              orden = <String, dynamic>{};
            }
          }
          
          final items = orden['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            for (final item in items) {
              final productoNombre = item['productoNombre'] as String? ?? 'Producto';
              final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 1.0;
              final precioUnitario = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
              final monto = cantidad * precioUnitario;
              
              final mesaId = orden['mesaId'] as int?;
              final mesaTexto = mesaId != null ? 'Mesa $mesaId' : 'Para Llevar';
              
              ventas.add({
                'time': date_utils.AppDateUtils.formatTime(creadoEn),
                'product': productoNombre,
                'amount': monto,
                'table': mesaTexto,
              });
            }
          } else {
            // Si no hay items, usar el monto del pago
            final monto = (pago['monto'] as num?)?.toDouble() ?? 0.0;
            final mesaId = orden['mesaId'] as int?;
            final mesaTexto = mesaId != null ? 'Mesa $mesaId' : 'Para Llevar';
            
            ventas.add({
              'time': date_utils.AppDateUtils.formatTime(creadoEn),
              'product': 'Pago',
              'amount': monto,
              'table': mesaTexto,
            });
          }
        }
      }

      // Ordenar por tiempo (más reciente primero)
      ventas.sort((a, b) => b['time'].compareTo(a['time']));
      
      // Limitar a las últimas 20 ventas
      realTimeSales = ventas.take(20).toList();
    } catch (e) {
      print('Error al cargar ventas en tiempo real: $e');
      realTimeSales = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_autoRefresh && mounted) {
        _loadRealTimeSales();
        _startAutoRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estadísticas en tiempo real
                  _buildHeader(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Controles y filtros
                  _buildControlsSection(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Gráficos principales
                  _buildMainCharts(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Tabla de ventas en tiempo real
                  _buildRealTimeTable(controller, isTablet, isDesktop),
                  const SizedBox(height: 24),

                  // Análisis detallado
                  _buildDetailedAnalysis(controller, isTablet, isDesktop),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final stats = controller.dashboardStats;
    final now = date_utils.AppDateUtils.nowCdmx();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.primary,
                  size: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ventas en Tiempo Real',
                  style: TextStyle(
                    fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Indicador de tiempo real
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tiempo Real',
                        style: TextStyle(
                          fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  date_utils.AppDateUtils.formatTime(now),
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Ventas Hoy',
                          '\$${stats.todaySales}',
                          Colors.green,
                          Icons.trending_up,
                          '+12.5%',
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Órdenes Activas',
                          '${stats.totalOrders}',
                          Colors.blue,
                          Icons.receipt_long,
                          '+8',
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Ticket Promedio',
                          '\$${stats.averageTicket}',
                          Colors.orange,
                          Icons.shopping_cart,
                          '+5.2%',
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Conversión',
                          '${(stats.totalOrders * 0.15).toStringAsFixed(1)}%',
                          Colors.purple,
                          Icons.people,
                          '+2.1%',
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Ventas Hoy',
                              '\$${stats.todaySales}',
                              Colors.green,
                              Icons.trending_up,
                              '+12.5%',
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Órdenes Activas',
                              '${stats.totalOrders}',
                              Colors.blue,
                              Icons.receipt_long,
                              '+8',
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Ticket Promedio',
                              '\$${stats.averageTicket}',
                              Colors.orange,
                              Icons.shopping_cart,
                              '+5.2%',
                              isTablet,
                              isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Conversión',
                              '${(stats.totalOrders * 0.15).toStringAsFixed(1)}%',
                              Colors.purple,
                              Icons.people,
                              '+2.1%',
                              isTablet,
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    String change,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                color: color,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
        child: Row(
          children: [
            Icon(
              Icons.settings,
              color: AppColors.primary,
              size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            ),
            const SizedBox(width: 8),
            Text(
              'Controles',
              style: TextStyle(
                fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),

            // Selector de período
            DropdownButton<String>(
              value: _selectedTimeframe,
              onChanged: (value) {
                setState(() {
                  _selectedTimeframe = value!;
                });
                _loadRealTimeSales();
              },
              items: const [
                DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                DropdownMenuItem(value: 'ayer', child: Text('Ayer')),
                DropdownMenuItem(value: 'semana', child: Text('Esta Semana')),
                DropdownMenuItem(value: 'mes', child: Text('Este Mes')),
              ],
            ),
            const SizedBox(width: 16),

            // Toggle auto-refresh
            Row(
              children: [
                Switch(
                  value: _autoRefresh,
                  onChanged: (value) {
                    setState(() {
                      _autoRefresh = value;
                      if (value) {
                        _startAutoRefresh();
                      }
                    });
                  },
                  activeThumbColor: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-actualizar',
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Botón de actualización manual
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCharts(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1000) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSalesChart(controller, isTablet, isDesktop),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildTopProductsChart(controller, isTablet, isDesktop),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSalesChart(controller, isTablet, isDesktop),
              const SizedBox(height: 20),
              _buildTopProductsChart(controller, isTablet, isDesktop),
            ],
          );
        }
      },
    );
  }

  Widget _buildSalesChart(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final stats = controller.dashboardStats;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ventas por Hora',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Última hora: \$${(stats.todaySales * 0.15).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: isDesktop ? 300.0 : (isTablet ? 200.0 : 150.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stats.salesByHour.length,
                itemBuilder: (context, index) {
                  final entry = stats.salesByHour.entries.elementAt(index);
                  final maxValue = stats.salesByHour.values.reduce(
                    (a, b) => a > b ? a : b,
                  );
                  final height =
                      (entry.value / maxValue) *
                      (isDesktop ? 240.0 : (isTablet ? 160.0 : 120.0));

                  return Container(
                    width: isDesktop ? 60.0 : (isTablet ? 50.0 : 40.0),
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          width: isDesktop ? 50.0 : (isTablet ? 40.0 : 30.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.8),
                                AppColors.primary.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: isDesktop
                                ? 12.0
                                : (isTablet ? 10.0 : 8.0),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${entry.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isDesktop ? 10.0 : (isTablet ? 8.0 : 6.0),
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    final stats = controller.dashboardStats;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Top Productos',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ...stats.topProducts
                .take(5)
                .map(
                  (product) => _buildProductItem(product, isTablet, isDesktop),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(SalesItem product, bool isTablet, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 16.0 : (isTablet ? 12.0 : 8.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 40.0 : 32.0,
            height: isDesktop ? 40.0 : 32.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              size: isDesktop ? 20.0 : 16.0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${product.quantity} vendidos',
                  style: TextStyle(
                    fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${product.revenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeTable(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (realTimeSales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No hay ventas registradas en el período seleccionado',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: EdgeInsets.all(
              isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ventas en Tiempo Real',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${realTimeSales.length} transacciones',
                    style: TextStyle(
                      fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isDesktop ? 24.0 : (isTablet ? 16.0 : 12.0),
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.05),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Hora',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Producto',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Mesa',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Monto',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: realTimeSales
                  .map((sale) => _buildSaleRow(sale, isTablet, isDesktop))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildSaleRow(
    Map<String, dynamic> sale,
    bool isTablet,
    bool isDesktop,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Text(
              sale['time'],
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            sale['product'],
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              sale['table'],
              style: TextStyle(
                fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '\$${sale['amount'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: isDesktop ? 16.0 : 14.0,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                'Completado',
                style: TextStyle(
                  fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalysis(
    AdminController controller,
    bool isTablet,
    bool isDesktop,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                ),
                const SizedBox(width: 12),
                Text(
                  'Análisis Detallado',
                  style: TextStyle(
                    fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildAnalysisCard(
                          'Horario Pico',
                          '14:00 - 16:00',
                          'Máxima actividad',
                          Colors.red,
                          Icons.schedule,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalysisCard(
                          'Producto Estrella',
                          'Mix Barbacoa',
                          'Más vendido hoy',
                          Colors.orange,
                          Icons.star,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalysisCard(
                          'Mesa Activa',
                          'Mesa 5',
                          'Mayor rotación',
                          Colors.blue,
                          Icons.table_bar,
                          isTablet,
                          isDesktop,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAnalysisCard(
                        'Horario Pico',
                        '14:00 - 16:00',
                        'Máxima actividad',
                        Colors.red,
                        Icons.schedule,
                        isTablet,
                        isDesktop,
                      ),
                      const SizedBox(height: 16),
                      _buildAnalysisCard(
                        'Producto Estrella',
                        'Mix Barbacoa',
                        'Más vendido hoy',
                        Colors.orange,
                        Icons.star,
                        isTablet,
                        isDesktop,
                      ),
                      const SizedBox(height: 16),
                      _buildAnalysisCard(
                        'Mesa Activa',
                        'Mesa 5',
                        'Mayor rotación',
                        Colors.blue,
                        Icons.table_bar,
                        isTablet,
                        isDesktop,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    String description,
    Color color,
    IconData icon,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0),
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
