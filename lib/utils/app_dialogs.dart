import 'package:flutter/material.dart';
import 'package:facecode/models/game_error.dart';

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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  /// Convenience method for GameError
  static Future<void> showGameError(BuildContext context, GameError error) {
    return showError(
      context,
      title: error.title,
      message: error.message,
    );
  }

  /// Show a quick snackbar
  static void showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
