import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/app/qrollcall_app.dart';
import 'package:qrollcall_mobile/features/auth/data/auth_api_service.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qrollcall_mobile/features/dashboard/data/dashboard_api_service.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:qrollcall_mobile/features/qr_scanner/data/qr_scanner_api_service.dart';
import 'package:qrollcall_mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApiService>(
          create: (_) => AuthApiService(),
        ),
        Provider<FirebaseAuthService>(
          create: (_) => FirebaseAuthService(),
        ),
        Provider<DashboardApiService>(
          create: (context) => DashboardApiService(
            firebaseAuthService: context.read<FirebaseAuthService>(),
          ),
        ),
        Provider<QrScannerApiService>(
          create: (context) => QrScannerApiService(
            firebaseAuthService: context.read<FirebaseAuthService>(),
          ),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            apiService: context.read<AuthApiService>(),
            firebaseAuthService: context.read<FirebaseAuthService>(),
          )..bootstrapSession(),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (context) => DashboardController(
            dashboardApiService: context.read<DashboardApiService>(),
          ),
        ),
      ],
      child: const QRollCallApp(),
    ),
  );
}