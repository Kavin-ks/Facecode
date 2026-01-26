import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/services/sound_manager.dart';

class MysteryRewardOverlay extends StatefulWidget {
  final int xp;
  final int coins;
  final VoidCallback onContinue;

  const MysteryRewardOverlay({
    super.key,
    required this.xp,
    required this.coins,
    required this.onContinue,
  });

  static Future<void> show(BuildContext context, {required int xp, required int coins}) {
    SoundManager().playUiSound(SoundManager.sfxBadgeUnlock); // Re-using a celebratory sound
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MysteryRewardOverlay(
        xp: xp,
        coins: coins,
        onContinue: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<MysteryRewardOverlay> createState() => _MysteryRewardOverlayState();
}

class _MysteryRewardOverlayState extends State<MysteryRewardOverlay> {
  late ConfettiController _confettiController;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _confettiController.play();
    SoundManager().playUiSound(SoundManager.sfxUiTap);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _revealed ? "SURPRISE!" : "MYSTERY BOX",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn().scale(),
              
              const SizedBox(height: 40),
              
              GestureDetector(
                onTap: _reveal,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_revealed) ...[
                      Align(
                        alignment: Alignment.center,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          colors: [AppConstants.primaryColor, AppConstants.accentGold, Colors.white],
                        ),
                      ),
                    ],
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _revealed ? AppConstants.primaryColor : Colors.white24,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_revealed ? AppConstants.primaryColor : AppConstants.accentGold).withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _revealed 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("🎁", style: TextStyle(fontSize: 60)),
                                const SizedBox(height: 12),
                                Text(
                                  "+${widget.xp} XP",
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                if (widget.coins > 0)
                                  Text(
                                    "+${widget.coins} Coins",
                                    style: const TextStyle(color: AppConstants.accentGold, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            )
                          : const Text("🎁", style: TextStyle(fontSize: 80))
                              .animate(onPlay: (c) => c.repeat())
                              .shake(hz: 3, duration: 2.seconds)
                              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 500.ms),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (!_revealed)
                const Text(
                  "TAP TO OPEN",
                  style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(delay: 1.seconds),
              
              if (_revealed)
                AddictivePrimaryButton(
                  label: "AWESOME!",
                  onPressed: widget.onContinue,
                ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }
}
