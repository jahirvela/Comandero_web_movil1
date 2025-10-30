import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cajero_controller.dart';
import '../../utils/app_colors.dart';

class CashManagementView extends StatefulWidget {
  const CashManagementView({super.key});

  @override
  State<CashManagementView> createState() => _CashManagementViewState();
}

class _CashManagementViewState extends State<CashManagementView> {
  String selectedOperation = 'Todas';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header
              _buildHeader(context, isTablet),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumen general
                      _buildGeneralSummary(isTablet),
                      const SizedBox(height: 24),

                      // Filtros
                      _buildFilters(isTablet),
                      const SizedBox(height: 24),

                      // Operaciones rápidas
                      _buildQuickOperations(isTablet),
                      const SizedBox(height: 24),

                      // Historial de operaciones
                      _buildOperationsHistory(isTablet, isDesktop),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Botón flotante de nueva operación
          floatingActionButton: _buildFloatingActionButton(isTablet),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Row(
            children: [
              // Botón de regreso
              IconButton(
                onPressed: () {
                  context.read<CajeroController>().setCurrentView('main');
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 16),

              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Efectivo',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Juan Martínez • Cajero',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de configuración
              IconButton(
                onPressed: () {
                  _showCashSettingsDialog(context);
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSummary(bool isTablet) {
    return Consumer<CajeroController>(
      builder: (context, controller, child) {
        final stats = controller.getPaymentStats();
        final cashInDrawer = 1500.0; // Mock data
        final cashReceived = stats['totalCash']!;
        final cashChange = 200.0; // Mock data

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: isTablet ? 24.0 : 20.0,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Estado del Efectivo',
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Efectivo en Caja',
                        controller.formatCurrency(cashInDrawer),
                        AppColors.success,
                        Icons.money,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Efectivo Recibido',
                        controller.formatCurrency(cashReceived),
                        AppColors.info,
                        Icons.trending_up,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Cambio Entregado',
                        controller.formatCurrency(cashChange),
                        AppColors.warning,
                        Icons.trending_down,
                        isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Balance Neto',
                        controller.formatCurrency(
                          cashInDrawer + cashReceived - cashChange,
                        ),
                        AppColors.primary,
                        Icons.balance,
                        isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isTablet ? 24.0 : 20.0),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: isTablet ? 12.0 : 10.0, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Operación',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedOperation,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 12.0,
                            vertical: isTablet ? 16.0 : 12.0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Todas',
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem(
                            value: 'Ingreso',
                            child: Text('Ingreso'),
                          ),
                          DropdownMenuItem(
                            value: 'Egreso',
                            child: Text('Egreso'),
                          ),
                          DropdownMenuItem(
                            value: 'Cambio',
                            child: Text('Cambio'),
                          ),
                          DropdownMenuItem(
                            value: 'Apertura',
                            child: Text('Apertura'),
                          ),
                          DropdownMenuItem(
                            value: 'Cierre',
                            child: Text('Cierre'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedOperation = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: 'Hoy',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 12.0,
                            vertical: isTablet ? 16.0 : 12.0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Hoy', child: Text('Hoy')),
                          DropdownMenuItem(value: 'Ayer', child: Text('Ayer')),
                          DropdownMenuItem(
                            value: 'Esta Semana',
                            child: Text('Esta Semana'),
                          ),
                          DropdownMenuItem(
                            value: 'Este Mes',
                            child: Text('Este Mes'),
                          ),
                        ],
                        onChanged: (value) {
                          // TODO: Implementar filtro por período
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOperations(bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operaciones Rápidas',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOperationCard(
                    'Apertura de Caja',
                    Icons.lock_open,
                    AppColors.success,
                    () => _showOpeningDialog(),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOperationCard(
                    'Retiro de Efectivo',
                    Icons.remove_circle,
                    AppColors.warning,
                    () => _showWithdrawalDialog(),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOperationCard(
                    'Depósito',
                    Icons.add_circle,
                    AppColors.info,
                    () => _showDepositDialog(),
                    isTablet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOperationCard(
                    'Conteo',
                    Icons.calculate,
                    AppColors.primary,
                    () => _showCountDialog(),
                    isTablet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isTablet ? 24.0 : 20.0),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 10.0,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsHistory(bool isTablet, bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Operaciones',
              style: TextStyle(
                fontSize: isTablet ? 18.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildOperationsList(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsList(bool isTablet) {
    // Mock data para operaciones
    final operations = [
      {
        'id': 'OP-001',
        'type': 'Ingreso',
        'amount': 150.0,
        'description': 'Pago mesa 5',
        'time': '14:30',
        'user': 'Juan Martínez',
        'color': AppColors.success,
      },
      {
        'id': 'OP-002',
        'type': 'Egreso',
        'amount': 50.0,
        'description': 'Cambio entregado',
        'time': '14:25',
        'user': 'Juan Martínez',
        'color': AppColors.warning,
      },
      {
        'id': 'OP-003',
        'type': 'Ingreso',
        'amount': 200.0,
        'description': 'Pago mesa 3',
        'time': '14:20',
        'user': 'Juan Martínez',
        'color': AppColors.success,
      },
      {
        'id': 'OP-004',
        'type': 'Apertura',
        'amount': 1000.0,
        'description': 'Apertura de caja',
        'time': '08:00',
        'user': 'Juan Martínez',
        'color': AppColors.info,
      },
    ];

    return Column(
      children: operations.map((operation) {
        return _buildOperationItem(operation, isTablet);
      }).toList(),
    );
  }

  Widget _buildOperationItem(Map<String, dynamic> operation, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 40.0 : 32.0,
            height: isTablet ? 40.0 : 32.0,
            decoration: BoxDecoration(
              color: operation['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: operation['color'].withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _getOperationIcon(operation['type']),
              color: operation['color'],
              size: isTablet ? 20.0 : 16.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation['description'],
                  style: TextStyle(
                    fontSize: isTablet ? 14.0 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${operation['type']} • ${operation['time']}',
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 10.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${operation['amount'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: FontWeight.bold,
                  color: operation['color'],
                ),
              ),
              Text(
                operation['user'],
                style: TextStyle(
                  fontSize: isTablet ? 10.0 : 8.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          _showNewOperationDialog();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          isTablet ? 'Nueva Operación' : 'Nueva',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  IconData _getOperationIcon(String type) {
    switch (type) {
      case 'Ingreso':
        return Icons.add_circle;
      case 'Egreso':
        return Icons.remove_circle;
      case 'Cambio':
        return Icons.swap_horiz;
      case 'Apertura':
        return Icons.lock_open;
      case 'Cierre':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  void _showOpeningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apertura de Caja'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Monto inicial de efectivo'),
            Text('• Verificación de billetes'),
            Text('• Confirmación de apertura'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retiro de Efectivo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Monto a retirar'),
            Text('• Motivo del retiro'),
            Text('• Autorización requerida'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Depósito de Efectivo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Monto a depositar'),
            Text('• Origen del efectivo'),
            Text('• Confirmación de depósito'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conteo de Efectivo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Conteo por denominaciones'),
            Text('• Verificación de total'),
            Text('• Registro de diferencias'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showNewOperationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Operación'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Tipo de operación'),
            Text('• Monto'),
            Text('• Descripción'),
            Text('• Autorización'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCashSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Efectivo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('• Límites de efectivo'),
            Text('• Alertas automáticas'),
            Text('• Denominaciones'),
            Text('• Autorizaciones'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
