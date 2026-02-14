import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../widgets/logout_button.dart';
import '../../services/kitchen_order_service.dart';
import '../../services/bill_repository.dart';
import 'floor_view.dart';
import 'table_view.dart';
import 'menu_view.dart';
import 'cart_view.dart';
import 'takeaway_view.dart';
import 'divided_account_view.dart';

class MeseroApp extends StatelessWidget {
  const MeseroApp({super.key});

  String _formatTimeAgo(DateTime timestamp) {
    return date_utils.AppDateUtils.formatTimeAgoShort(
      timestamp,
      now: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final controller = MeseroController(
              billRepository: context.read<BillRepository>(),
            );
            // Registrar controller en el servicio para notificaciones
            KitchenOrderService().registerMeseroController(controller);
            return controller;
          },
        ),
      ],
      child: Consumer2<MeseroController, AuthController>(
        builder: (context, meseroController, authController, child) {
          // Asegurar que el controller conozca el usuario logueado (sin notify)
          meseroController.setLoggedUserName(authController.userName);
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
    // En Cuenta Dividida: mostrar solo los ítems pendientes de la persona seleccionada,
    // para no confundir (los enviados a cocina ya no deben verse como "en el carrito").
    final int cartBadgeCount;
    if (meseroController.currentView == 'divided_account' &&
        meseroController.isDividedAccountMode &&
        meseroController.selectedPersonId != null) {
      cartBadgeCount = meseroController
          .getItemsForPerson(meseroController.selectedPersonId!)
          .length;
    } else {
      cartBadgeCount = meseroController.totalCartItems;
    }

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
        // Botón de notificaciones - Mejorado para mejor respuesta táctil
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Mostrar notificaciones pendientes
              final pendingNotifications =
                  meseroController.pendingNotifications;
              if (pendingNotifications.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay notificaciones pendientes'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (dialogContext) => _NotificationsDialog(
                    controller: meseroController,
                    dialogContext: dialogContext,
                    formatTimeAgo: _formatTimeAgo,
                  ),
                );
                }
              },
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: isTablet ? 28.0 : 24.0,
                    color: Colors.white,
                  ),
                  // Badge de notificaciones - IgnorePointer para no bloquear toques
                  if (meseroController.pendingNotifications.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${meseroController.pendingNotifications.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Botón de carrito - Mejorado para mejor respuesta táctil
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              meseroController.setCurrentView('cart');
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: isTablet ? 28.0 : 24.0,
                  ),
                  if (cartBadgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IgnorePointer(
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
                            '$cartBadgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Botón de logout
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: LogoutButton(
            isTablet: isTablet,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                // Usar go_router en lugar de Navigator.pushReplacementNamed
                context.go('/login');
              }
            },
          ),
        ),
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
          case 'takeaway':
            return const TakeawayView();
          case 'menu':
            return const MenuView();
          case 'cart':
            return const CartView();
          case 'divided_account':
            return const DividedAccountView();
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

/// Diálogo de notificaciones que recibe el controller por parámetro (el overlay
/// del showDialog no tiene acceso al Provider<MeseroController>).
class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog({
    required this.controller,
    required this.dialogContext,
    required this.formatTimeAgo,
  });
  final MeseroController controller;
  final BuildContext dialogContext;
  final String Function(DateTime) formatTimeAgo;

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.controller.pendingNotifications;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Notificaciones'),
          const Spacer(),
          if (list.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${list.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final notification = list[index];
            final timestamp = notification['timestamp'] as DateTime?;
            final meseroNombre = notification['meseroNombre'] as String?;
            final timeAgo = timestamp != null
                ? widget.formatTimeAgo(timestamp)
                : 'Ahora';
            final ordenId = notification['ordenId'] as int?;
            final tipo = notification['tipo'] as String? ?? 'general';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant_menu, color: AppColors.success, size: 20),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (meseroNombre != null && meseroNombre.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'De: $meseroNombre',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      notification['title'] ?? 'Notificación',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification['message'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  splashRadius: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    widget.controller.removeNotificationByOrderAndType(ordenId, tipo);
                    if (widget.controller.pendingNotifications.isEmpty) {
                      Navigator.of(widget.dialogContext).pop();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.controller.clearAllNotifications();
            Navigator.of(widget.dialogContext).pop();
          },
          child: const Text('Limpiar todas'),
        ),
        TextButton(
          onPressed: () => Navigator.of(widget.dialogContext).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
