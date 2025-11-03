import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../services/kitchen_order_service.dart';
import 'floor_view.dart';
import 'table_view.dart';
import 'menu_view.dart';
import 'cart_view.dart';

class MeseroApp extends StatelessWidget {
  const MeseroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) {
        final controller = MeseroController();
        // Registrar controller en el servicio para notificaciones
        KitchenOrderService().registerMeseroController(controller);
        return controller;
      })],
      child: Consumer2<MeseroController, AuthController>(
        builder: (context, meseroController, authController, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth > 900;

              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: _buildAppBar(
                  context,
                  meseroController,
                  authController,
                  isTablet,
                  isDesktop,
                ),
                body: _buildBody(context, meseroController),
                floatingActionButton: _buildFloatingStatusButton(isTablet),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MeseroController meseroController,
    AuthController authController,
    bool isTablet,
    bool isDesktop,
  ) {
    final totalCartItems = meseroController.totalCartItems;

    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: isTablet ? 32.0 : 28.0,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comandix',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${authController.userName} • Mesero',
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Botón de notificaciones
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // TODO: Implementar notificaciones
              },
              icon: Icon(
                Icons.notifications_outlined,
                size: isTablet ? 28.0 : 24.0,
              ),
            ),
            // Badge de notificaciones (mock)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),

        // Botón de carrito
        Stack(
          children: [
            IconButton(
              onPressed: () {
                meseroController.setCurrentView('cart');
              },
              icon: Icon(
                Icons.shopping_cart_outlined,
                size: isTablet ? 28.0 : 24.0,
              ),
            ),
            if (totalCartItems > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$totalCartItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        // Botón de logout
        IconButton(
          onPressed: () async {
            await authController.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          icon: Icon(Icons.logout, size: isTablet ? 28.0 : 24.0),
        ),

        const SizedBox(width: 8),
      ],
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    );
  }

  Widget _buildBody(BuildContext context, MeseroController meseroController) {
    return Consumer<MeseroController>(
      builder: (context, controller, child) {
        switch (controller.currentView) {
          case 'floor':
            return const FloorView();
          case 'table':
            return const TableView();
          case 'menu':
            return const MenuView();
          case 'cart':
            return const CartView();
          default:
            return const FloorView();
        }
      },
    );
  }

  Widget _buildFloatingStatusButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar cambio de estado del puesto
        },
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_circle),
        label: Text(
          isTablet ? 'Puesto Abierto' : 'Abierto',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }
}
