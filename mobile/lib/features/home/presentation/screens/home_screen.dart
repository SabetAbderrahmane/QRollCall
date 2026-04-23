import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRollCall'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            onPressed: authController.isSubmitting
                ? null
                : () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backend-authenticated session',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Email: ${user.email}'),
                        const SizedBox(height: 6),
                        Text('Role: ${user.role}'),
                        const SizedBox(height: 6),
                        Text('Backend user ID: ${user.id}'),
                        const SizedBox(height: 6),
                        Text('Active: ${user.isActive}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Next frontend batch: dashboard, scanner, attendance history.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}