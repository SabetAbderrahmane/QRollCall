import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 32),
                      child,
                      const SizedBox(height: 24),
                      footer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -140,
          left: 80,
          right: 80,
          child: Container(
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGlow,
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x221D4ED8),
            ),
          ),
        ),
      ],
    );
  }
}