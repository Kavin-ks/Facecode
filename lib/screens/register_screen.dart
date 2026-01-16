import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/home_screen.dart';

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
      Navigator.of(context).pushAndRemoveUntil(AppRoute.fadeSlide(const HomeScreen()), (_) => false);
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
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
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
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                obscureText: _obscure,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _confirmController, 
                decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_clock)), 
                obscureText: _obscure,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: auth.isBusy ? null : _submit, 
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: auth.isBusy ? const CircularProgressIndicator() : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
