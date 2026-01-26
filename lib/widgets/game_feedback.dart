import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/widgets/level_up_overlay.dart';
import 'package:facecode/widgets/badge_unlock_overlay.dart';
import 'package:provider/provider.dart';

class GameFeedback {
  /// Show a premium "You Win" overlay with confetti and sound
  static Future<void> showWin(BuildContext context, {int xpEarned = 0, VoidCallback? onNext}) {
    SoundManager().playUiSound(SoundManager.sfxGameWin);
    return _showOverlay(
      context,
      _FeedbackContent(
        icon: Icons.emoji_events_rounded,
        iconColor: AppConstants.accentGold,
        title: "YOU WON!",
        subtitle: "Incredible performance.",
        xpEarned: xpEarned,
        isWin: true,
        onAction: onNext,
        actionLabel: "CONTINUE",
      ),
    );
  }

  /// Show a premium "Game Over" overlay
  static Future<void> showLose(BuildContext context, {VoidCallback? onRetry}) {
    SoundManager().playUiSound(SoundManager.sfxGameOver);
    return _showOverlay(
      context,
      _FeedbackContent(
        icon: Icons.sentiment_dissatisfied_rounded,
        iconColor: AppConstants.errorColor,
        title: "GAME OVER",
        subtitle: "Don't give up! Try again?",
        isWin: false,
        onAction: onRetry,
        actionLabel: "TRY AGAIN",
      ),
    );
  }

  static Future<void> _showOverlay(BuildContext context, Widget content) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackContent extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int xpEarned;
  final bool isWin;
  final VoidCallback? onAction;
  final String actionLabel;

  const _FeedbackContent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isWin,
    this.xpEarned = 0,
    this.onAction,
    required this.actionLabel,
  });

  @override
  State<_FeedbackContent> createState() => _FeedbackContentState();
}

class _FeedbackContentState extends State<_FeedbackContent> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.isWin) {
      Future.delayed(const Duration(milliseconds: 300), () => _confettiController.play());
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.isWin)
          Positioned(
            top: -100,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppConstants.primaryColor,
                AppConstants.secondaryColor,
                AppConstants.accentGold,
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: widget.isWin ? AppConstants.accentGold : AppConstants.borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isWin ? AppConstants.accentGold : Colors.black).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconColor.withValues(alpha: 0.1),
                ),
                child: Icon(widget.icon, size: 48, color: widget.iconColor),
              ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ).animate().fadeIn(delay: 400.ms),

              if (widget.xpEarned > 0) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+ ${widget.xpEarned} XP",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(),
              ],

              const SizedBox(height: 32),

              AddictivePrimaryButton(
                label: widget.actionLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  
                  // Check for level up after closing feedback
                  final progress = context.read<ProgressProvider>();
                  
                  void checkNextEvent() {
                     if (progress.hasLevelUpPending) {
                       LevelUpOverlay.show(context, progress.pendingLevel).then((_) {
                         progress.consumeLevelUpEvent();
                         // Chain: Check for badges after Level Up overlay closes
                         checkNextEvent();
                       });
                     } else if (progress.hasBadgesPending) {
                       final badge = progress.nextPendingBadge;
                       if (badge != null) {
                         BadgeUnlockOverlay.show(context, badge).then((_) {
                           progress.consumeBadgeEvent();
                           // Chain: Check for more badges
                           checkNextEvent();
                         });
                       }
                     }
                  }

                  // Slight delay to allow feedback to close
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (context.mounted) {
                      checkNextEvent();
                    }
                  });

                  widget.onAction?.call();
                },
                fullWidth: true,
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ],
    );
  }
}
