import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// Reusable timer display for games
/// Shows remaining time with optional progress bar
class GameTimerDisplay extends StatelessWidget {
  final Duration remaining;
  final Duration total;
  final bool showProgress;
  final bool showIcon;

  const GameTimerDisplay({
    super.key,
    required this.remaining,
    required this.total,
    this.showProgress = true,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total.inMilliseconds > 0
        ? remaining.inMilliseconds / total.inMilliseconds
        : 0.0;

    final isLowTime = progress < 0.2;
    final color = isLowTime ? AppConstants.errorColor : AppConstants.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.timer,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _formatDuration(remaining),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: AppConstants.surfaceColor,
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
}
