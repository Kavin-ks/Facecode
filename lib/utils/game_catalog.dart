import 'package:flutter/material.dart';
import 'package:facecode/models/game_metadata.dart';
import 'package:facecode/models/game_difficulty.dart';
import 'package:facecode/utils/constants.dart';

/// Catalog of all available mini-games in FaceCode
class GameCatalog {
  static final List<GameMetadata> allGames = [
    // Party Games
    const GameMetadata(
      id: 'emoji_translator',
      name: 'Emoji Translator',
      description: 'Communicate using only emojis!',
      icon: Icons.emoji_emotions,
      category: GameCategory.party,
      minPlayers: 2,
      maxPlayers: 8,
      route: '/mode-selection',
      gradientColors: AppConstants.primaryGradient,
      difficulty: GameDifficulty.easy,
      isFeatured: true,
      bannerImage: '🎭',
      tags: ['multiplayer', 'fun', 'creative'],
    ),
    const GameMetadata(
      id: 'truth_dare',
      name: 'Truth or Dare',
      description: 'Classic party game with a twist',
      icon: Icons.help_outline,
      category: GameCategory.party,
      minPlayers: 2,
      maxPlayers: 10,
      route: '/truth-dare',
      gradientColors: [Color(0xFFFF4081), Color(0xFFFF6E40)],
      difficulty: GameDifficulty.easy,
      isFeatured: true,
      bannerImage: '🎲',
      tags: ['party', 'fun', 'social'],
    ),
    const GameMetadata(
      id: 'would_rather',
      name: 'Would You Rather',
      description: 'Tough choices, fun debates',
      icon: Icons.compare_arrows,
      category: GameCategory.party,
      minPlayers: 2,
      maxPlayers: 10,
      route: '/would-rather',
      gradientColors: [Color(0xFF00E5FF), Color(0xFF536DFE)],
      difficulty: GameDifficulty.easy,
      isFeatured: true,
      bannerImage: '🤔',
      tags: ['choices', 'debate', 'fun'],
    ),
    const GameMetadata(
      id: 'two_truths',
      name: 'Two Truths One Lie',
      description: 'Can you spot the lie?',
      icon: Icons.psychology,
      category: GameCategory.party,
      minPlayers: 3,
      maxPlayers: 8,
      route: '/two-truths',
      gradientColors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
      difficulty: GameDifficulty.medium,
      bannerImage: '🎭',
      tags: ['bluffing', 'social', 'tricky'],
    ),
    
    // Fast Games
    const GameMetadata(
      id: 'reaction_time',
      name: 'Reaction Time',
      description: 'How fast are your reflexes?',
      icon: Icons.flash_on,
      category: GameCategory.fast,
      minPlayers: 1,
      maxPlayers: 1,
      route: '/reaction-time',
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFA000)],
      difficulty: GameDifficulty.easy,
      isFeatured: true,
      bannerImage: '⚡',
      tags: ['speed', 'reflexes', 'solo'],
    ),
    const GameMetadata(
      id: 'fastest_finger',
      name: 'Fastest Finger',
      description: 'First to tap wins!',
      icon: Icons.touch_app,
      category: GameCategory.fast,
      minPlayers: 2,
      maxPlayers: 6,
      route: '/fastest-finger',
      gradientColors: [Color(0xFFFF5722), Color(0xFFFF9800)],
      difficulty: GameDifficulty.medium,
      bannerImage: '👆',
      tags: ['speed', 'competitive', 'multiplayer'],
    ),
    
    // Brain Games
    const GameMetadata(
      id: 'memory_cards',
      name: 'Memory Cards',
      description: 'Match pairs and train your brain',
      icon: Icons.grid_on,
      category: GameCategory.brain,
      minPlayers: 1,
      maxPlayers: 1,
      route: '/memory-cards',
      gradientColors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
      difficulty: GameDifficulty.medium,
      bannerImage: '🧠',
      tags: ['memory', 'puzzle', 'solo'],
    ),
    const GameMetadata(
      id: 'simon_says',
      name: 'Simon Says',
      description: 'Repeat the color pattern',
      icon: Icons.palette,
      category: GameCategory.brain,
      minPlayers: 1,
      maxPlayers: 1,
      route: '/simon-says',
      gradientColors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
      difficulty: GameDifficulty.hard,
      bannerImage: '🎨',
      tags: ['memory', 'pattern', 'challenging'],
    ),
    
    // Classic Games
    const GameMetadata(
      id: 'tic_tac_toe',
      name: 'Tic Tac Toe',
      description: 'Classic X and O strategy',
      icon: Icons.grid_4x4,
      category: GameCategory.classic,
      minPlayers: 2,
      maxPlayers: 2,
      route: '/tic-tac-toe',
      gradientColors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      difficulty: GameDifficulty.easy,
      bannerImage: '⭕',
      tags: ['strategy', 'classic', '2-player'],
    ),
    const GameMetadata(
      id: 'draw_guess',
      name: 'Draw & Guess',
      description: 'Draw and let others guess',
      icon: Icons.brush,
      category: GameCategory.classic,
      minPlayers: 2,
      maxPlayers: 8,
      route: '/draw-guess',
      gradientColors: [Color(0xFFE91E63), Color(0xFFF06292)],
      difficulty: GameDifficulty.medium,
      bannerImage: '🎨',
      tags: ['creative', 'drawing', 'multiplayer'],
    ),
  ];

  /// Get games by category
  static List<GameMetadata> getByCategory(GameCategory category) {
    return allGames.where((game) => game.category == category).toList();
  }

  /// Get game by ID
  static GameMetadata? getById(String id) {
    try {
      return allGames.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all categories
  static List<GameCategory> get categories => GameCategory.values;

  /// Get featured games
  static List<GameMetadata> get featuredGames {
    return allGames.where((game) => game.isFeatured).toList();
  }

  /// Get games by difficulty
  static List<GameMetadata> getByDifficulty(GameDifficulty difficulty) {
    return allGames.where((game) => game.difficulty == difficulty).toList();
  }

  /// Search games by query
  static List<GameMetadata> search(String query) {
    final lowerQuery = query.toLowerCase();
    return allGames.where((game) {
      return game.name.toLowerCase().contains(lowerQuery) ||
          game.description.toLowerCase().contains(lowerQuery) ||
          game.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
