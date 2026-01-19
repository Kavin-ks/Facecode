import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/game_hub_screen.dart';
import 'package:facecode/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      await AppDialogs.showGameError(context, const GameError(type: GameErrorType.validation, title: 'Empty Fields', message: 'Please fill in email and password.', actionLabel: 'OK'));
      return;
    }
    await auth.login(email, password);
    if (auth.isSignedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(AppRoute.fadeSlide(const GameHubScreen()));
      AppDialogs.showSnack(context, 'Welcome back!');
    } else if (auth.authError != null) {
      if (!mounted) return;
      await AppDialogs.showGameError(context, auth.authError!);
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D12),
              Color(0xFF1A1A2E),
              Color(0xFF0D0D12),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withAlpha(50),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      '😎',
                      style: TextStyle(fontSize: 70),
                    ),
                  ),
                )
                    .animate()
                    .scale(curve: Curves.elasticOut, duration: 800.ms)
                    .fadeIn(),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Title
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Center(
                  child: Text(
                    'Sign in to continue playing',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: AppConstants.xlPadding),
                
                // Form Card
                Container(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor.withAlpha(150),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppConstants.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      _buildPremiumTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Password field
                      _buildPremiumTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      
                      const SizedBox(height: AppConstants.xlPadding),
                      
                      // Login button
                      _buildPremiumButton(
                        onPressed: auth.isBusy ? null : _submit,
                        isLoading: auth.isBusy,
                        label: 'SIGN IN',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(AppRoute.fadeSlide(const RegisterScreen())),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppConstants.neonGradient,
                        ).createShader(bounds),
                        child: const Text(
                          'Create one',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && _obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppConstants.textMuted),
          prefixIcon: Icon(icon, color: AppConstants.textMuted, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppConstants.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPremiumButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: onPressed != null
            ? const LinearGradient(colors: AppConstants.premiumGradient)
            : null,
        color: onPressed == null ? AppConstants.surfaceColor : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
