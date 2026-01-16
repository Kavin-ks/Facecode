import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/home_screen.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/routing/app_route.dart';

/// Splash screen with FaceCode logo and animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _scheduleNavigate();
    }
  }

  /// Navigate based on auth state after splash duration
  void _scheduleNavigate() {
    _navTimer?.cancel();
    _navTimer = Timer(AppConstants.splashDuration, () {
      _navigateNow();
    });
  }

  /// Navigate immediately (used for tap-to-skip)
  void _navigateNow() {
    _navTimer?.cancel();
    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final destination = auth.isSignedIn ? const HomeScreen() : const LoginScreen();
      Navigator.of(context).pushReplacement(
        AppRoute.fadeSlide(destination),
      );
    } catch (_) {
      // If provider isn't ready yet, navigate to Login as fallback
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppRoute.fadeSlide(const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateNow,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryColor,
                AppConstants.secondaryColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo / Icon
                    const Text(
                      '😎',
                      style: TextStyle(fontSize: 120),
                    )
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(),
                    
                    const SizedBox(height: AppConstants.largePadding),
                    
                    // App Name
                    const Text(
                      'FaceCode',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 300))
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        ),
                    
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Tagline
                    const Text(
                      'Guess with Emojis!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 600))
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        ),
                  ],
                ),
              ),

              // Tap hint at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: Center(
                  child: Text(
                    'Tap to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
