import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/game_hub_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      await AppDialogs.showGameError(context, const GameError(type: GameErrorType.validation, title: 'Empty Fields', message: 'Please fill all fields.', actionLabel: 'OK'));
      return;
    }

    if (pass != confirm) {
      await AppDialogs.showGameError(context, const GameError(type: GameErrorType.validation, title: 'Mismatch', message: 'Passwords do not match.', actionLabel: 'OK'));
      return;
    }

    await auth.register(name, email, pass);
    if (auth.isSignedIn) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(AppRoute.fadeSlide(const GameHubScreen()), (_) => false);
      AppDialogs.showSnack(context, 'Account created!');
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
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor.withAlpha(150),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 30),
                
                // Title
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Center(
                  child: Text(
                    'Join the emoji guessing fun!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
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
                      _buildPremiumTextField(
                        controller: _nameController,
                        label: 'Display Name',
                        icon: Icons.person_outline,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      _buildPremiumTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      _buildPremiumTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      _buildPremiumTextField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        showToggle: false,
                      ),
                      
                      const SizedBox(height: AppConstants.xlPadding),
                      
                      _buildPremiumButton(
                        onPressed: auth.isBusy ? null : _submit,
                        isLoading: auth.isBusy,
                        label: 'CREATE ACCOUNT',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppConstants.neonGradient,
                        ).createShader(bounds),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
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
    bool showToggle = true,
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
          suffixIcon: isPassword && showToggle
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
