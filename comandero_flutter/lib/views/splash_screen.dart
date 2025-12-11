import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppTheme.durationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Verificar estado de autenticación (no bloquear si tarda)
    final authController = context.read<AuthController>();
    
    // Ejecutar verificación y animación en paralelo para más rapidez
    await Future.wait([
      // Verificar autenticación con timeout corto
      authController.checkAuthStatus().timeout(
        const Duration(seconds: 1),
        onTimeout: () => null,
      ),
      // Esperar un mínimo para la animación (reducido de 800ms a 400ms)
      Future.delayed(const Duration(milliseconds: 400)),
    ]);

    // Navegar inmediatamente después
    if (mounted) {
      if (authController.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo del restaurante
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing2XL),

                    // Título de la app
                    Text(
                      'Comandix',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize4XL,
                        fontWeight: AppTheme.fontWeightBold,
                        color: Colors.white,
                        letterSpacing: AppTheme.letterSpacingWide,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingSM),

                    // Subtítulo
                    Text(
                      'Sistema de Gestión Restaurante',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeBase,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: AppTheme.letterSpacingNormal,
                        fontWeight: AppTheme.fontWeightNormal,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing4XL),

                    // Indicador de carga
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
