import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/app_controller.dart';
import 'utils/app_colors.dart';
import 'views/mesero/mesero_app.dart';
import 'views/cocinero/cocinero_app.dart';
import 'views/cajero/cajero_app.dart';
import 'views/captain/captain_app.dart';
import 'views/admin/admin_app.dart';
import 'views/admin/admin_web_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ComanderoApp());
}

class ComanderoApp extends StatelessWidget {
  const ComanderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AppController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
          return MaterialApp.router(
            title: 'Comandero Flutter',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              // Esquema de colores basado en el proyecto React original
              primaryColor: AppColors.primary,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
                error: AppColors.error,
              ),
              textTheme: GoogleFonts.robotoTextTheme().copyWith(
                bodyLarge: const TextStyle(color: AppColors.textPrimary),
                bodyMedium: const TextStyle(color: AppColors.textPrimary),
                titleLarge: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                centerTitle: true,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.surface,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderFocus),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              scaffoldBackgroundColor: AppColors.background,
            ),
            routerConfig: _createRouter(authController),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthController authController) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authController.isLoggedIn;
        final currentPath = state.uri.toString();

        // Si está en splash y ya está logueado, ir a home
        if (currentPath == '/splash' && isLoggedIn) {
          return '/home';
        }

        // Si no está logueado y no está en login o splash, ir a login
        if (!isLoggedIn &&
            currentPath != '/login' &&
            currentPath != '/splash') {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // Redirigir según el rol del usuario
            final userRole = authController.userRole;
            if (userRole == 'mesero') {
              return const MeseroApp();
            } else if (userRole == 'cocinero') {
              return const CocineroApp();
            } else if (userRole == 'cajero') {
              return const CajeroApp();
            } else if (userRole == 'capitan') {
              return const CaptainApp();
            } else if (userRole == 'admin') {
              return const AdminApp();
            } else {
              return const HomeScreen();
            }
          },
        ),
        GoRoute(
          path: '/admin-web',
          builder: (context, state) {
            // Dashboard web privado para administradores
            return const AdminWebApp();
          },
        ),
      ],
    );
  }
}
