import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/providers/auth_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
// import 'package:facecode/screens/auth_gate_screen.dart'; // Unused

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Define vibrant colors for the background orbs
    final orbColors = [
      AppConstants.primaryColor,
      AppConstants.secondaryColor,
      AppConstants.accentNeon,
      AppConstants.cardPink,
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          // --- Animated Background Orbs ---
          // Orb 1: Top Left (Purple)
          Positioned(
            top: -100,
            left: -100,
            child: _AnimatedOrb(color: orbColors[0], size: 400),
          ),
          // Orb 2: Bottom Right (Cyan)
          Positioned(
            bottom: -100,
            right: -100,
            child: _AnimatedOrb(color: orbColors[1], size: 350, delay: 1.seconds),
          ),
          // Orb 3: Center Right (Pink)
          Positioned(
            top: mediaQuery.size.height * 0.3,
            right: -50,
            child: _AnimatedOrb(color: orbColors[3], size: 250, delay: 2.seconds),
          ),
          // Orb 4: Bottom Left (Orange)
          Positioned(
            bottom: mediaQuery.size.height * 0.1,
            left: -50,
            child: _AnimatedOrb(color: orbColors[2], size: 200, delay: 1.5.seconds),
          ),

          // --- Glassmorphism Blur ---
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: AppConstants.backgroundColor.withValues(alpha: 0.3), // Transparent dark overlay
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. Logo + tagline
                _buildHeader(),

                const Spacer(flex: 1),

                // 2. Hero Animation (Looping Game Previews)
                _buildSlidingPreviews(mediaQuery.size.width),

                const Spacer(flex: 2),

                // 3. Social Proof
                _buildSocialProof(),

                const SizedBox(height: 30),

                // 4. Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Using native ElevatedButton to guarantee clicks work
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            debugPrint('🎮🎮🎮 PLAY BUTTON CLICKED!');
                            _handlePlayNow();
                          },
                          icon: const Icon(Icons.flash_on_rounded, size: 24),
                          label: const Text(
                            'PLAY INSTANTLY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppConstants.primaryColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Login button also with native button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            debugPrint('🔐🔐🔐 LOGIN BUTTON CLICKED');
                            Navigator.pushNamed(context, '/login');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            side: BorderSide(
                              color: AppConstants.primaryColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'LOGIN TO SAVE PROGRESS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Icon
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.secondaryColor.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 36),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.2, duration: 1.5.seconds),
            
            const SizedBox(width: 12),
            
            // Gradient Text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppConstants.secondaryColor, AppConstants.cardPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "FACECODE",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  color: Colors.white, // Required for ShaderMask
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Instant Multiplayer Games",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 1.0,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildSlidingPreviews(double screenWidth) {
    return SizedBox(
      height: 240, // Slightly taller
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card (Left)
          Transform.translate(
            offset: const Offset(-50, 0), // Spread out more
            child: Transform.rotate(
              angle: -0.2,
              child: Opacity(
                opacity: 0.6,
                child: _GamePreviewCard(
                  color: AppConstants.primaryColor,
                  emoji: "🎨",
                  title: "Draw",
                ),
              ),
            ),
          ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.5, end: 0, curve: Curves.easeOutBack),

          // Background Card (Right)
          Transform.translate(
            offset: const Offset(50, 0),
            child: Transform.rotate(
              angle: 0.2,
              child: Opacity(
                opacity: 0.6,
                child: _GamePreviewCard(
                  color: AppConstants.secondaryColor,
                  emoji: "🤔",
                  title: "Choice",
                  textColor: Colors.black, // Cyan bg needs dark text? Or keep white.
                ),
              ),
            ),
          ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.5, end: 0, curve: Curves.easeOutBack),

          // Center Hero Card
          Transform.scale(
            scale: 1.1,
            child: Container(
              decoration: BoxDecoration(
                 boxShadow: [
                   BoxShadow(
                     color: AppConstants.cardPink.withValues(alpha: 0.5),
                     blurRadius: 40,
                     spreadRadius: 5,
                   ),
                 ],
                 borderRadius: BorderRadius.circular(20),
              ),
              child: _GamePreviewCard(
                color: AppConstants.cardPink, // Vibrant Pink
                emoji: "🎯",
                title: "Truth?",
                isHero: true,
              ),
            ),
          ).animate(delay: 600.ms)
           .fadeIn()
           .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.1, 1.1), curve: Curves.elasticOut)
           // Subtle floating loop
           .then()
           .animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -15, duration: 2.5.seconds, curve: Curves.easeInOut),
        ],
      ),
    );
  }

  Widget _buildSocialProof() {
    final progress = context.watch<ProgressProvider>().progress;

    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Align(
                widthFactor: 0.7,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: index % 2 == 0 ? AppConstants.primaryColor : AppConstants.accentNeon,
                  ),
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                progress.totalGamesPlayed > 0 ? 'You played ${progress.totalGamesPlayed} games' : 'Be the first to play!',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                progress.totalDrawings > 0 ? '🎨 ${progress.totalDrawings} drawings' : 'Create your first drawing',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20, end: 0);
  }

  void _handlePlayNow() {
    debugPrint('🎮 Play Instantly button clicked!');
    
    // Simplified: Just navigate directly - anonymous auth happens in PublicGamesScreen if needed
    debugPrint('Navigating to /public-games...');
    Navigator.pushReplacementNamed(context, '/public-games');
  }
}

class _AnimatedOrb extends StatelessWidget {
  final Color color;
  final double size;
  final Duration delay;

  const _AnimatedOrb({
    required this.color,
    required this.size,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true), delay: delay)
    .scaleXY(begin: 0.8, end: 1.2, duration: 4.seconds, curve: Curves.easeInOut)
    .move(begin: const Offset(0, 0), end: const Offset(30, -30), duration: 5.seconds);
  }
}

class _GamePreviewCard extends StatelessWidget {
  final Color color;
  final String emoji;
  final String title;
  final bool isHero;
  final Color textColor;

  const _GamePreviewCard({
    required this.color,
    required this.emoji,
    required this.title,
    this.isHero = false,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 190,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        // No heavy shadow here, relying on outer container or subtle defaults
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          if (isHero) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "HOT",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ]
        ],
      ),
    );
  }
}

