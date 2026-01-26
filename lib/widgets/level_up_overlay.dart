import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/motion.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/providers/progress_provider.dart';

class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onContinue;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onContinue,
  });

  static Future<void> show(BuildContext context, int level) {
    SoundManager().playUiSound(SoundManager.sfxGameWin); // Or level up specific
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LevelUpOverlay(
        newLevel: level,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  static const Map<int, String> levelUnlocks = {
    2: "Daily Challenges",
    3: "Stat Tracking",
    5: "Custom Themes",
    10: "Golden Profile",
    15: "Grandmaster Title",
    20: "Legendary Badge",
    30: "Developer Mode (Joke)",
    50: "The Crown 👑",
  };

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  late ConfettiController _confettiController;
  
  String get _unlockText {
    return LevelUpOverlay.levelUnlocks[widget.newLevel] ?? "You're getting stronger!";
  }

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
    final progressProvider = context.read<ProgressProvider>();
    final badge = progressProvider.getLevelBadge();

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppConstants.primaryColor,
              AppConstants.secondaryColor,
              AppConstants.accentGold,
              Colors.white,
            ],
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Text(
                "LEVEL UP!",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.accentGold,
                  letterSpacing: 4.0,
                  shadows: [
                    BoxShadow(color: AppConstants.accentGold, blurRadius: 40),
                  ],
                ),
              ).animate().scale(duration: AppMotion.durationMedium, curve: AppMotion.curveEmphasized),

              const SizedBox(height: 40),

              // Level Badge Circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge,
                      style: const TextStyle(fontSize: 48),
                    ),
                    Text(
                      '${widget.newLevel}',
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: AppMotion.durationShort, duration: AppMotion.durationMedium, curve: AppMotion.curveEmphasized),

              const SizedBox(height: 40),

              // Rewards / Unlocks (Dynamic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (LevelUpOverlay.levelUnlocks.containsKey(widget.newLevel))
                      const Text(
                        "UNLOCKED:",
                        style: TextStyle(
                          color: AppConstants.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    if (LevelUpOverlay.levelUnlocks.containsKey(widget.newLevel))
                      const SizedBox(height: 4),
                    Text(
                      _unlockText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: AppMotion.durationMedium).slideY(begin: 0.5, end: 0, duration: AppMotion.durationMedium, curve: AppMotion.curveStandard),

              const SizedBox(height: 60),

              AddictivePrimaryButton(
                label: "AWESOME!",
                fullWidth: false,
                onPressed: widget.onContinue,
              ).animate().fadeIn(delay: AppMotion.durationLong).scale(curve: AppMotion.curveStandard, duration: AppMotion.durationShort),
            ],
          ),
        ],
      ),
    );
  }
}
