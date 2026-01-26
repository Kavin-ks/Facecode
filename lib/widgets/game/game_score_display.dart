import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// Reusable score display for games
/// Shows current score with optional best score comparison
class GameScoreDisplay extends StatelessWidget {
  final int current;
  final int? best;
  final String label;
  final IconData icon;
  final List<Color>? gradientColors;

  const GameScoreDisplay({
    super.key,
    required this.current,
    this.best,
    this.label = 'Score',
    this.icon = Icons.star,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = best != null && current > best!;
    final colors = gradientColors ?? AppConstants.primaryGradient;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (best != null) ...[
            const SizedBox(height: 4),
            Text(
              isNewBest ? '🏆 NEW BEST!' : 'Best: $best',
              style: TextStyle(
                color: isNewBest ? AppConstants.accentGold : Colors.white60,
                fontSize: 10,
                fontWeight: isNewBest ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
