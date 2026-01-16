import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/home_screen.dart';
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
      Navigator.of(context).pushReplacement(AppRoute.fadeSlide(const HomeScreen()));
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
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: auth.isBusy ? const CircularProgressIndicator() : const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(AppRoute.fadeSlide(const RegisterScreen())),
                child: const Text('Don\'t have an account? Create one'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
