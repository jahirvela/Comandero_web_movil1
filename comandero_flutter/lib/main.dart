import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'controllers/auth_controller.dart';
import 'utils/app_theme.dart';
import 'views/admin/access_denied_view.dart';
import 'services/payment_repository.dart';
import 'services/bill_repository.dart';
import 'services/api_service.dart';
import 'views/admin/admin_app.dart';
import 'views/admin/admin_web_app.dart';
import 'views/cajero/cajero_app.dart';
import 'views/captain/captain_app.dart';
import 'views/cocinero/cocinero_app.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'views/mesero/mesero_app.dart';
import 'views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar en paralelo para mejor rendimiento
  await Future.wait([
    // Configurar localización en español de México (puede tardar)
    initializeDateFormatting('es_MX', null).then((_) {
      Intl.defaultLocale = 'es_MX';
    }),
    // Inicializar el servicio de API (no bloqueante)
    Future(() => ApiService().initialize()),
  ]);

  // Iniciar la app inmediatamente (no esperar más)
  runApp(const ComanderoApp());
}

class ComanderoApp extends StatelessWidget {
  const ComanderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillRepository()),
        ChangeNotifierProvider(create: (_) => PaymentRepository()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AppController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
          return MaterialApp.router(
            title: 'Comandero Flutter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authController),
            // Configurar localización en español de México
            locale: const Locale('es', 'MX'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'MX'), // Español de México
              Locale('es'), // Español genérico como fallback
            ],
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
          redirect: (context, state) {
            // Guard: Solo admin puede acceder en web
            final userRole = authController.userRole;
            final isLoggedIn = authController.isLoggedIn;

            // Si no está logueado, ir a login
            if (!isLoggedIn) {
              return '/login';
            }

            // Si no es web, redirigir a home
            if (!kIsWeb) {
              return '/home';
            }

            // Si no es admin, redirigir a acceso denegado
            if (userRole != 'admin') {
              return '/access-denied';
            }

            return null; // Permitir acceso
          },
          builder: (context, state) {
            // Dashboard web privado para administradores
            return const AdminWebApp();
          },
        ),
        GoRoute(
          path: '/access-denied',
          builder: (context, state) => const AccessDeniedView(),
        ),
      ],
    );
  }
}
