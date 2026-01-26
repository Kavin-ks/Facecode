import 'package:flutter/material.dart';
import 'package:facecode/widgets/premium_error_dialog.dart';
import 'package:facecode/widgets/premium_snackbar.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/services/sound_manager.dart';

/// Centralized dialogs used across the app.
class AppDialogs {
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;

    final error = GameError(
      type: GameErrorType.unknown,
      title: title,
      message: message,
      actionLabel: actionLabel,
    );

    // Play Haptic
    SoundManager().playUiSound(SoundManager.sfxUiTap); // Error sound logic should be in dialog or here

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8), // Darker barrier
      builder: (context) => PremiumErrorDialog(error: error, onAction: onAction),
    );
  }

  /// Convenience method for GameError
  static Future<void> showGameError(BuildContext context, GameError error) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => PremiumErrorDialog(error: error, onAction: () {}),
    );
  }

  /// Show a premium floating snackbar
  static void showSnack(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    
    PremiumSnackBar.show(
      context,
      title: isError ? "Alert" : "Info", // Could be refined
      message: message,
      icon: isError ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
      colorOverride: isError ? AppConstants.errorColor : AppConstants.primaryColor,
    );
  }
}
