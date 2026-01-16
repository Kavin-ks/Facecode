import 'package:facecode/models/game_prompt.dart';

/// Random prompt generator for the game
class PromptGenerator {
  static final List<GamePrompt> _moviePrompts = [
    GamePrompt(category: 'Movie', text: 'Frozen', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Movie', text: 'Finding Nemo', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Movie', text: 'Toy Story', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Movie', text: 'The Lion King', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Movie', text: 'Spider-Man', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Movie', text: 'Harry Potter', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Movie', text: 'Star Wars', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Movie', text: 'The Avengers', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Movie', text: 'Jurassic Park', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Movie', text: 'The Matrix', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Movie', text: 'Titanic', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Movie', text: 'Black Panther', difficulty: PromptDifficulty.hard),
  ];

  static final List<GamePrompt> _songPrompts = [
    GamePrompt(category: 'Song', text: 'Baby Shark', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Song', text: 'Happy Birthday', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Song', text: 'Let It Go', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Song', text: 'Firework', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Song', text: 'Shake It Off', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Song', text: 'Eye of the Tiger', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Song', text: 'Bohemian Rhapsody', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Song', text: 'Hotel California', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Song', text: 'Somewhere Over the Rainbow', difficulty: PromptDifficulty.hard),
  ];

  static final List<GamePrompt> _phrasePrompts = [
    GamePrompt(category: 'Phrase', text: 'Piece of cake', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Phrase', text: 'Time flies', difficulty: PromptDifficulty.easy),
    GamePrompt(category: 'Phrase', text: 'Break a leg', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Phrase', text: 'Under the weather', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Phrase', text: 'Spill the beans', difficulty: PromptDifficulty.medium),
    GamePrompt(category: 'Phrase', text: 'Raining cats and dogs', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Phrase', text: 'Kill two birds with one stone', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Phrase', text: 'Bite off more than you can chew', difficulty: PromptDifficulty.hard),
    GamePrompt(category: 'Phrase', text: 'The early bird catches the worm', difficulty: PromptDifficulty.hard),
  ];

  static final List<GamePrompt> _allPrompts = [
    ..._moviePrompts,
    ..._songPrompts,
    ..._phrasePrompts,
  ];

  /// Get a random prompt from all categories
  static GamePrompt getRandomPrompt({PromptDifficulty? difficulty}) {
    final pool = (difficulty == null)
        ? List<GamePrompt>.from(_allPrompts)
        : _allPrompts.where((p) => p.difficulty == difficulty).toList();
    pool.shuffle();
    return pool.isEmpty ? _allPrompts.first : pool.first;
  }

  /// Get a random prompt from a specific category
  static GamePrompt getRandomPromptByCategory(
    String category, {
    PromptDifficulty? difficulty,
  }) {
    List<GamePrompt> prompts;
    switch (category.toLowerCase()) {
      case 'movie':
        prompts = List.from(_moviePrompts);
        break;
      case 'song':
        prompts = List.from(_songPrompts);
        break;
      case 'phrase':
        prompts = List.from(_phrasePrompts);
        break;
      default:
        prompts = List.from(_allPrompts);
    }

    if (difficulty != null) {
      prompts = prompts.where((p) => p.difficulty == difficulty).toList();
    }
    prompts.shuffle();
    return prompts.first;
  }
}
