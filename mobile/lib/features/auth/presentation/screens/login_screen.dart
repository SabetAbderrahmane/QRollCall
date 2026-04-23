import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    final authController = context.read<AuthController>();
    final success = await authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || success) return;
    _showError(authController.errorMessage);
  }

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();

    final authController = context.read<AuthController>();
    final success = await authController.signInWithGoogle();

    if (!mounted || success) return;
    _showError(authController.errorMessage);
  }

  Future<void> _forgotPassword() async {
    final authController = context.read<AuthController>();

    try {
      await authController.sendPasswordReset(_emailController.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
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
      title: 'Welcome to QRollCall',
      subtitle: 'Sign in to manage your digital attendance registry.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: authController.isSubmitting
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
            child: const Text(
              'Sign Up',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
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
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: authController.isSubmitting ? null : _forgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: authController.isSubmitting ? null : _signIn,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          GoogleSignInButton(
            onPressed: _googleSignIn,
            isLoading: authController.isSubmitting,
          ),
        ],
      ),
    );
  }
}