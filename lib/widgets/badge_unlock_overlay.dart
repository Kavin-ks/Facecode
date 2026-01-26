import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/models/badge_data.dart';

class BadgeUnlockOverlay extends StatefulWidget {
  final BadgeData badge;
  final VoidCallback onContinue;

  const BadgeUnlockOverlay({
    super.key,
    required this.badge,
    required this.onContinue,
  });

  static Future<void> show(BuildContext context, BadgeData badge) {
    SoundManager().playUiSound(SoundManager.sfxBadgeUnlock);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BadgeUnlockOverlay(
        badge: badge,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<BadgeUnlockOverlay> createState() => _BadgeUnlockOverlayState();
}

class _BadgeUnlockOverlayState extends State<BadgeUnlockOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    Future.delayed(const Duration(milliseconds: 300), () => _confettiController.play());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final color = badge.color;

    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rarity Glow Background
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [color, Colors.white, AppConstants.accentGold],
              emissionFrequency: 0.05,
              numberOfParticles: 30,
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                "BADGE UNLOCKED!",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ).animate().slideY(begin: -2, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 16),
              
              // Rarity Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge.rarityLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),

              // Badge Icon Display
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .shimmer(delay: 1.seconds, duration: 1.5.seconds, color: Colors.white.withValues(alpha: 0.4)),

              const SizedBox(height: 32),

              Text(
                badge.label,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 8),

              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 60),

              AddictivePrimaryButton(
                label: "COLLECT",
                fullWidth: false,
                onPressed: widget.onContinue,
              ).animate().fadeIn(delay: 1.seconds).scale(),
            ],
          ),
        ],
      ),
    );
  }
}
