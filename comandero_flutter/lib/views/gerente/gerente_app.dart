import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../cajero/cajero_app.dart';
import '../cocinero/cocinero_app.dart';
import '../mesero/mesero_app.dart';

/// Tamaños y espaciados según ancho de pantalla (teléfono / tableta / escritorio).
class _GerenteLayout {
  const _GerenteLayout({
    required this.panelTitleSize,
    required this.welcomeSize,
    required this.subtitleSize,
    required this.cardTitleSize,
    required this.cardSubtitleSize,
    required this.iconBoxSize,
    required this.iconSize,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardMaxWidth,
    required this.horizontalPadding,
    required this.sectionGap,
    required this.cardsGap,
  });

  final double panelTitleSize;
  final double welcomeSize;
  final double subtitleSize;
  final double cardTitleSize;
  final double cardSubtitleSize;
  final double iconBoxSize;
  final double iconSize;
  final double cardPadding;
  final double cardRadius;
  final double cardMaxWidth;
  final double horizontalPadding;
  final double sectionGap;
  final double cardsGap;

  static _GerenteLayout fromWidth(double w) {
    // Teléfono estrecho
    if (w < 400) {
      return const _GerenteLayout(
        panelTitleSize: 20,
        welcomeSize: 18,
        subtitleSize: 12,
        cardTitleSize: 16,
        cardSubtitleSize: 12,
        iconBoxSize: 48,
        iconSize: 26,
        cardPadding: 14,
        cardRadius: 16,
        cardMaxWidth: 320,
        horizontalPadding: 16,
        sectionGap: 6,
        cardsGap: 12,
      );
    }
    if (w < 600) {
      return const _GerenteLayout(
        panelTitleSize: 22,
        welcomeSize: 20,
        subtitleSize: 13,
        cardTitleSize: 17,
        cardSubtitleSize: 13,
        iconBoxSize: 52,
        iconSize: 28,
        cardPadding: 16,
        cardRadius: 18,
        cardMaxWidth: 340,
        horizontalPadding: 20,
        sectionGap: 8,
        cardsGap: 14,
      );
    }
    // Tableta
    if (w < 900) {
      return const _GerenteLayout(
        panelTitleSize: 24,
        welcomeSize: 22,
        subtitleSize: 14,
        cardTitleSize: 18,
        cardSubtitleSize: 13,
        iconBoxSize: 56,
        iconSize: 30,
        cardPadding: 16,
        cardRadius: 18,
        cardMaxWidth: 220,
        horizontalPadding: 24,
        sectionGap: 10,
        cardsGap: 16,
      );
    }
    // Escritorio / ancho
    return const _GerenteLayout(
      panelTitleSize: 26,
      welcomeSize: 22,
      subtitleSize: 14,
      cardTitleSize: 18,
      cardSubtitleSize: 13,
      iconBoxSize: 58,
      iconSize: 28,
      cardPadding: 18,
      cardRadius: 18,
      cardMaxWidth: 220,
      horizontalPadding: 32,
      sectionGap: 10,
      cardsGap: 16,
    );
  }
}

class GerenteApp extends StatefulWidget {
  const GerenteApp({super.key});

  @override
  State<GerenteApp> createState() => _GerenteAppState();
}

class _GerenteAppState extends State<GerenteApp> {
  String? _selectedModule;

  @override
  Widget build(BuildContext context) {
    if (_selectedModule == 'mesero') {
      return MeseroApp(
        roleLabel: 'Gerente / Mesero',
        onLogoutPressed: _goBackToManagerPanel,
      );
    }
    if (_selectedModule == 'cajero') {
      return CajeroApp(
        roleLabel: 'Gerente / Cajero',
        onLogoutPressed: _goBackToManagerPanel,
      );
    }
    if (_selectedModule == 'cocinero') {
      return CocineroApp(
        roleLabel: 'Gerente / Cocina',
        onLogoutPressed: _goBackToManagerPanel,
      );
    }

    return _buildManagerPanel(context);
  }

  void _goBackToManagerPanel() {
    if (!mounted) return;
    setState(() {
      _selectedModule = null;
    });
  }

  Widget _buildManagerPanel(BuildContext context) {
    final auth = context.watch<AuthController>();
    final name = auth.userName.trim();
    final saludo = name.isEmpty
        ? '¡Bienvenido!'
        : (name.toLowerCase().endsWith('a')
            ? '¡Bienvenida $name!'
            : '¡Bienvenido $name!');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final lay = _GerenteLayout.fromWidth(w);
            final textScaler = MediaQuery.textScalerOf(context);
            // En pantallas muy bajas, reduce padding vertical
            final topPad = h < 520 ? 8.0 : 12.0;
            final minScrollHeight = (h - 24).clamp(0.0, double.infinity);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: lay.horizontalPadding,
                      vertical: topPad,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minScrollHeight,
                        maxWidth: 900,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Panel de Gerente',
                              style: TextStyle(
                                fontSize: textScaler.scale(lay.panelTitleSize),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: lay.sectionGap),
                            Text(
                              saludo,
                              style: TextStyle(
                                fontSize: textScaler.scale(lay.welcomeSize),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: lay.sectionGap + 2),
                            Text(
                              'Selecciona el módulo al que deseas acceder para gestionar las operaciones del restaurante',
                              style: TextStyle(
                                fontSize: textScaler.scale(lay.subtitleSize),
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: lay.sectionGap + 16),
                            // Tarjetas: una columna en móvil; fila en tableta/ancho
                            if (w < 600)
                              Column(
                                children: [
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Mesero',
                                    subtitle:
                                        'Gestión de mesas, pedidos y servicio',
                                    icon: Icons.person_add_alt_1,
                                    color: const Color(0xFFF59E0B),
                                    onTap: () => setState(
                                        () => _selectedModule = 'mesero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                  SizedBox(height: lay.cardsGap),
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Cajero',
                                    subtitle:
                                        'Cobros, pagos y cierre de caja',
                                    icon: Icons.calculate,
                                    color: const Color(0xFF2563EB),
                                    onTap: () => setState(
                                        () => _selectedModule = 'cajero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                  SizedBox(height: lay.cardsGap),
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Cocina',
                                    subtitle:
                                        'Preparación y control de pedidos',
                                    icon: Icons.restaurant,
                                    color: const Color(0xFFEA580C),
                                    onTap: () => setState(
                                        () => _selectedModule = 'cocinero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                ],
                              )
                            else
                              Wrap(
                                spacing: lay.cardsGap,
                                runSpacing: lay.cardsGap,
                                alignment: WrapAlignment.center,
                                children: [
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Mesero',
                                    subtitle:
                                        'Gestión de mesas, pedidos y servicio',
                                    icon: Icons.person_add_alt_1,
                                    color: const Color(0xFFF59E0B),
                                    onTap: () => setState(
                                        () => _selectedModule = 'mesero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Cajero',
                                    subtitle:
                                        'Cobros, pagos y cierre de caja',
                                    icon: Icons.calculate,
                                    color: const Color(0xFF2563EB),
                                    onTap: () => setState(
                                        () => _selectedModule = 'cajero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                  _moduleCard(
                                    layout: lay,
                                    title: 'Cocina',
                                    subtitle:
                                        'Preparación y control de pedidos',
                                    icon: Icons.restaurant,
                                    color: const Color(0xFFEA580C),
                                    onTap: () => setState(
                                        () => _selectedModule = 'cocinero'),
                                    maxWidth: lay.cardMaxWidth,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    lay.horizontalPadding,
                    8,
                    lay.horizontalPadding,
                    16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _moduleCard({
    required _GerenteLayout layout,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double maxWidth,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(layout.cardRadius),
            child: Ink(
              padding: EdgeInsets.all(layout.cardPadding),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(layout.cardRadius),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: layout.iconBoxSize,
                    height: layout.iconBoxSize,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        layout.cardRadius * 0.75,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: layout.iconSize,
                    ),
                  ),
                  SizedBox(height: layout.sectionGap + 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: textScaler.scale(layout.cardTitleSize),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: layout.sectionGap * 0.5),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: textScaler.scale(layout.cardSubtitleSize),
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
