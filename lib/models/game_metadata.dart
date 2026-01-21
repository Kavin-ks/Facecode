import 'package:flutter/material.dart';
import 'package:facecode/models/game_difficulty.dart';

/// Categories for organizing games
enum GameCategory {
  party,
  brain,
  fast,
  classic,
}

extension GameCategoryExtension on GameCategory {
  String get name {
    switch (this) {
      case GameCategory.party:
        return 'Party';
      case GameCategory.brain:
        return 'Brain';
      case GameCategory.fast:
        return 'Fast';
      case GameCategory.classic:
        return 'Classic';
    }
  }

  Color get color {
    switch (this) {
      case GameCategory.party:
        return const Color(0xFFFF4081);
      case GameCategory.brain:
        return const Color(0xFF7C4DFF);
      case GameCategory.fast:
        return const Color(0xFF00E5FF);
      case GameCategory.classic:
        return const Color(0xFFFFD700);
    }
  }

  IconData get icon {
    switch (this) {
      case GameCategory.party:
        return Icons.celebration;
      case GameCategory.brain:
        return Icons.psychology;
      case GameCategory.fast:
        return Icons.bolt;
      case GameCategory.classic:
        return Icons.stars;
    }
  }
}

/// Metadata for each mini-game
class GameMetadata {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final GameCategory category;
  final int minPlayers;
  final int maxPlayers;
  final String route;
  final List<Color> gradientColors;
  final GameDifficulty difficulty;
  final bool isFeatured;
  final String bannerImage; // Emoji or URL
  final List<String> tags;
  final int xpReward;

  const GameMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.minPlayers = 1,
    this.maxPlayers = 8,
    required this.route,
    required this.gradientColors,
    this.difficulty = GameDifficulty.medium,
    this.isFeatured = false,
    this.bannerImage = '🎮',
    this.tags = const [],
    this.xpReward = 20,
  });
}
