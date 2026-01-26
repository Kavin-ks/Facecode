import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/motion.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/services/sound_manager.dart';

class StreakCelebrationOverlay extends StatefulWidget {
  final int streakDays;
  final VoidCallback onContinue;

  const StreakCelebrationOverlay({
    super.key,
    required this.streakDays,
    required this.onContinue,
  });

  static Future<void> show(BuildContext context, int days) {
    SoundManager().playGameSound(SoundManager.sfxGameWin); // Reusing win sound for now
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StreakCelebrationOverlay(
        streakDays: days,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(300.ms, () => _confettiController.play());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.orange,
              Colors.deepOrange,
              Colors.yellow,
              Colors.white,
            ],
            gravity: 0.2,
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fire Animation
              const Text(
                "🔥",
                style: TextStyle(fontSize: 100),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.2, duration: 1.seconds, curve: Curves.easeInOut)
              .then()
              .shake(hz: 4, curve: Curves.easeInOut),

              const SizedBox(height: 30),

              Text(
                "${widget.streakDays} DAY STREAK!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter', // Default fallback
                  letterSpacing: 2.0,
                  shadows: [
                     BoxShadow(color: Colors.orange, blurRadius: 40, spreadRadius: 10),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, curve: AppMotion.curveStandard),

              const SizedBox(height: 16),

              Text(
                "Keep it up! The fire is burning bright.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 60),

              AddictivePrimaryButton(
                label: "CONTINUE",
                fullWidth: false,
                onPressed: widget.onContinue,
              ).animate(delay: 800.ms).fadeIn().scale(),
            ],
          ),
        ],
      ),
    );
  }
}
