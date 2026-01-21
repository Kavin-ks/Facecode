import 'package:flutter/material.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/premium_ui.dart';

/// Modern game card matching Play Store game hub style
class GameCardModern extends StatelessWidget {
  final GameMetadata game;
  final VoidCallback onTap;

  const GameCardModern({
    super.key,
    required this.game,
    required this.onTap,
  });

  Color get _cardColor {
    switch (game.category) {
      case GameCategory.party:
        return AppConstants.cardPink;
      case GameCategory.brain:
        return AppConstants.cardBlue;
      case GameCategory.fast:
        return AppConstants.cardOrange;
      case GameCategory.classic:
        return AppConstants.cardGreen;
    }
  }

  int get _xpReward {
    return game.isFeatured ? 500 : 250;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 18,
        child: Row(
          children: [
            // Game Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cardColor.withAlpha(60),
                    _cardColor.withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: Center(
                child: Text(
                  game.bannerImage,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Game Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.people_outline_rounded,
                        label: game.minPlayers == game.maxPlayers
                            ? '${game.minPlayers}'
                            : '${game.minPlayers}-${game.maxPlayers}',
                      ),
                      const SizedBox(width: 10),
                      _buildXpChip(_xpReward),
                    ],
                  ),
                ],
              ),
            ),

            // Play button
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor.withAlpha(90),
                    AppConstants.primaryColor.withAlpha(30),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppConstants.textMuted,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildXpChip(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppConstants.accentGold.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppConstants.accentGold,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: TextStyle(
              color: AppConstants.accentGold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
