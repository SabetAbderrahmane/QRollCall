import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_theme.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qrollcall_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().clear();
    });

    return const DashboardScreen();
  }
}