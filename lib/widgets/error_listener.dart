import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/models/game_error.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/utils/app_dialogs.dart';

/// Listens for provider errors and shows a friendly dialog.
///
/// Put this near the top of a screen so errors surface consistently.
class ErrorListener extends StatelessWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, GameError?>(
      selector: (_, p) => p.uiError,
      builder: (context, error, _) {
        if (error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            await AppDialogs.showError(
              context,
              title: error.title,
              message: error.message,
              actionLabel: error.actionLabel,
              onAction: () {
                context.read<GameProvider>().clearError();

                if (!context.mounted) return;
                switch (error.type) {
                  case GameErrorType.roomNotFound:
                    Navigator.of(context).maybePop();
                    break;
                  case GameErrorType.disconnect:
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    break;
                  case GameErrorType.network:
                  case GameErrorType.validation:
                  case GameErrorType.timeExpired:
                  case GameErrorType.invalidEmoji:
                  case GameErrorType.unknown:
                    break;
                }
              },
            );
          });
        }
        return child;
      },
    );
  }
}
