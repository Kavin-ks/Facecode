import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:facecode/models/game_error.dart';

class PremiumErrorDialog extends StatelessWidget {
  final GameError error;
  final VoidCallback? onAction;

  const PremiumErrorDialog({
    super.key,
    required this.error,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon (Animated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorColor,
                size: 48,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              error.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddictivePrimaryButton(
                  label: error.actionLabel,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAction?.call();
                  },
                ),
                
                const SizedBox(height: 16),
                
                AddictiveSecondaryButton(
                  label: "Dismiss",
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ).animate()
      .fadeIn(duration: 200.ms)
      .scale(duration: 300.ms, curve: Curves.easeOutBack), // Nice pop-in
    );
  }
}
