import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    final authController = context.read<AuthController>();
    final success = await authController.signUp(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || success) return;
    _showError(authController.errorMessage);
  }

  void _showError(String? message) {
    if (message == null || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AuthShell(
      title: 'Create your account',
      subtitle: 'Register your secure QRollCall identity to access attendance, reports, and notifications.',
      footer: TextButton.icon(
        onPressed: authController.isSubmitting
            ? null
            : () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text(
          'Back to Login',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      child: Column(
        children: [
          AuthTextField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Repeat your password',
            prefixIcon: Icons.verified_user_outlined,
            obscureText: _obscureConfirmPassword,
            onToggleObscure: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: authController.isSubmitting ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: authController.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}