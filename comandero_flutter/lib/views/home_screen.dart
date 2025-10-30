import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/app_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, AppController>(
      builder: (context, authController, appController, child) {
        final userRole = authController.userRole;
        final userName = authController.userName;

        return Scaffold(
          appBar: AppBar(
            title: Text('Bienvenido, $userName'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final navigator = GoRouter.of(context);
                  await authController.logout();
                  if (mounted) {
                    navigator.go('/login');
                  }
                },
              ),
            ],
          ),
          body: _buildBody(userRole),
          bottomNavigationBar: _buildBottomNavigationBar(
            userRole,
            appController,
          ),
        );
      },
    );
  }

  Widget _buildBody(String userRole) {
    switch (userRole) {
      case 'admin':
        return _buildAdminDashboard();
      case 'mesero':
        return _buildMeseroView();
      case 'cocinero':
        return _buildCocineroView();
      case 'cajero':
        return _buildCajeroView();
      case 'capitan':
        return _buildCapitanView();
      default:
        return _buildDefaultView();
    }
  }

  Widget _buildAdminDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  'Inventario',
                  Icons.inventory,
                  Colors.blue,
                  () {
                    // Navegar a inventario
                  },
                ),
                _buildDashboardCard(
                  'Cortes de Caja',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () {
                    // Navegar a cortes de caja
                  },
                ),
                _buildDashboardCard(
                  'Ventas',
                  Icons.trending_up,
                  Colors.orange,
                  () {
                    // Navegar a ventas
                  },
                ),
                _buildDashboardCard(
                  'Usuarios',
                  Icons.people,
                  Colors.purple,
                  () {
                    // Navegar a usuarios
                  },
                ),
                _buildDashboardCard(
                  'Reportes',
                  Icons.analytics,
                  Colors.red,
                  () {
                    // Navegar a reportes
                  },
                ),
                _buildDashboardCard(
                  'Configuración',
                  Icons.settings,
                  Colors.grey,
                  () {
                    // Navegar a configuración
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeseroView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant, size: 80, color: Color(0xFFE65100)),
          SizedBox(height: 20),
          Text(
            'Módulo del Mesero',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Gestión de mesas y pedidos',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCocineroView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Color(0xFFE65100)),
          SizedBox(height: 20),
          Text(
            'Módulo del Cocinero',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Preparación de platillos',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCajeroView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 80, color: Color(0xFFE65100)),
          SizedBox(height: 20),
          Text(
            'Módulo del Cajero',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Gestión de cobros y tickets',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitanView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.supervisor_account, size: 80, color: Color(0xFFE65100)),
          SizedBox(height: 20),
          Text(
            'Módulo del Capitán',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Supervisión y coordinación',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultView() {
    return const Center(
      child: Text(
        'Rol de usuario no reconocido',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomNavigationBar(
    String userRole,
    AppController appController,
  ) {
    if (userRole == 'admin') {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: appController.selectedIndex,
        onTap: (index) {
          appController.setSelectedIndex(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      );
    }
    return null;
  }
}
