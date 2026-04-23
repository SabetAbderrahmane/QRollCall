import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: AppColors.textMuted),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}