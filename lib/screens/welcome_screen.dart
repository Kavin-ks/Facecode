import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/screens/main_shell.dart';
import 'package:facecode/routing/app_route.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Auto play confetti
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _getStarted() {
    Navigator.of(context).pushReplacement(AppRoute.fadeSlide(const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient
          Positioned.fill(
             child: Container(
               decoration: const BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: AppConstants.backgroundGradient,
                 ),
               ),
             ),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppConstants.primaryColor,
                AppConstants.secondaryColor,
                AppConstants.accentNeon,
                Colors.white,
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Welcome Icon
                const Icon(Icons.celebration_rounded, color: AppConstants.accentGold, size: 80)
                    .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 24),
                
                const Text(
                  "Welcome to FaceCode!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 16),
                
                Text(
                  "Get ready to draw, guess, and party with friends.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const Spacer(),
                
                // Features mini-grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeatureItem(icon: Icons.brush_rounded, label: "Draw"),
                    _FeatureItem(icon: Icons.question_mark_rounded, label: "Guess"),
                    _FeatureItem(icon: Icons.emoji_events_rounded, label: "Win"),
                  ],
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                
                const Spacer(),
                
                AddictivePrimaryButton(
                  label: "START PLAYING",
                  onPressed: _getStarted,
                ).animate().fadeIn(delay: 1.seconds).scale(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
