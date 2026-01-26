import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/screens/register_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Sign in required', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Text(message, style: const TextStyle(color: AppConstants.textSecondary, height: 1.4)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(AppRoute.fadeSlide(const RegisterScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(AppRoute.fadeSlide(const LoginScreen())),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('LOG IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: auth.isBusy
                    ? null
                    : () async {
                        await context.read<AuthProvider>().signInAnonymously();
                        if (!context.mounted) return;
                        Navigator.of(context).maybePop();
                      },
                child: const Text('CONTINUE AS GUEST', style: TextStyle(color: AppConstants.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
