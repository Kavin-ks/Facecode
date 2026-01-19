import 'package:flutter/material.dart';

/// Difficulty levels for games
enum GameDifficulty {
  easy,
  medium,
  hard,
}

extension GameDifficultyExtension on GameDifficulty {
  String get name {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  Color get color {
    switch (this) {
      case GameDifficulty.easy:
        return const Color(0xFF4CAF50);
      case GameDifficulty.medium:
        return const Color(0xFFFF9800);
      case GameDifficulty.hard:
        return const Color(0xFFF44336);
    }
  }

  IconData get icon {
    switch (this) {
      case GameDifficulty.easy:
        return Icons.sentiment_satisfied;
      case GameDifficulty.medium:
        return Icons.sentiment_neutral;
      case GameDifficulty.hard:
        return Icons.whatshot;
    }
  }
}
