import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/game_hub_screen.dart';
import 'package:facecode/screens/login_screen.dart';
import 'package:facecode/routing/app_route.dart';

/// Premium splash screen with FaceCode branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const bool _isTest = bool.fromEnvironment('FLUTTER_TEST');
  Timer? _navTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
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
      final destination = auth.isSignedIn ? const GameHubScreen() : const LoginScreen();
      Navigator.of(context).pushReplacement(
        AppRoute.fadeSlide(destination),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppRoute.fadeSlide(const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _pulseController.dispose();
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
                Color(0xFF0D0D12),
                Color(0xFF1A1A2E),
                Color(0xFF0D0D12),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GlowPainter(
                        progress: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
              
              // Main content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo with glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withAlpha(80),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: const Text(
                          '😎',
                          style: TextStyle(fontSize: 100),
                        ),
                      )
                          .animate()
                          .scale(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                          )
                          .fadeIn()
                          .then()
                          .shimmer(
                            duration: const Duration(seconds: 2),
                            color: Colors.white.withAlpha(30),
                          ),
                      
                      const SizedBox(height: AppConstants.xlPadding),
                      
                      // App Name with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppConstants.neonGradient,
                        ).createShader(bounds),
                        child: const Text(
                          'FaceCode',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400))
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                          ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppConstants.secondaryColor.withAlpha(50),
                          ),
                        ),
                        child: const Text(
                          '✨ Express with Emojis ✨',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppConstants.secondaryColor,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 700))
                          .scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                ),
              ),

              // Loading indicator at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: AppConstants.surfaceColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor.withAlpha(200),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 1000)),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 12,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 1200)),
                  ],
                ),
              ),

              // Version at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppConstants.textMuted.withAlpha(100),
                      fontSize: 11,
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

/// Custom painter for animated background glow
class _GlowPainter extends CustomPainter {
  final double progress;

  _GlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final radius = 150 + (progress * 50);
    
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppConstants.primaryColor.withAlpha((40 * progress).toInt()),
          AppConstants.secondaryColor.withAlpha((20 * progress).toInt()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.progress != progress;
}
