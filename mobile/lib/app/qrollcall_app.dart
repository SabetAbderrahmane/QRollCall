import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/admin_dashboard/data/admin_dashboard_api_service.dart';
import '../features/admin_dashboard/presentation/controllers/admin_dashboard_controller.dart';
import '../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../features/auth/data/firebase_auth_service.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';

class QRollCallApp extends StatelessWidget {
  const QRollCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRollCall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    if (authController.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authController.currentUser == null) {
      return const LoginScreen();
    }

    final role = authController.currentUser!.role.toUpperCase();

    if (role == 'ADMIN') {
      return ChangeNotifierProvider(
        create: (_) => AdminDashboardController(
          apiService: AdminDashboardApiService(
            firebaseAuthService: context.read<FirebaseAuthService>(),
          ),
        )..loadDashboard(),
        child: const AdminDashboardScreen(),
      );
    }

    return const HomeScreen();
  }
}