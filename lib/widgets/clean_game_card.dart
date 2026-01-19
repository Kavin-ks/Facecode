import 'package:flutter/material.dart';
import 'package:facecode/models/game_metadata.dart';

/// Minimal clean game card for production-like listing
class CleanGameCard extends StatelessWidget {
  final GameMetadata game;
  final VoidCallback onPlay;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const CleanGameCard({
    super.key,
    required this.game,
    required this.onPlay,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon / Banner
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: game.gradientColors.first.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    game.bannerImage,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Player count & Play button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        game.minPlayers == game.maxPlayers
                            ? '${game.minPlayers} '
                            : '${game.minPlayers}-${game.maxPlayers}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 72,
                    child: OutlinedButton(
                      onPressed: onPlay,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.9)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Play', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
