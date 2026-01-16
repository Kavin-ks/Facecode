/// Represents a prompt/challenge for the emoji player
enum PromptDifficulty {
  easy,
  medium,
  hard,
}

class GamePrompt {
  final String category;
  final String text;
  final PromptDifficulty difficulty;

  GamePrompt({
    required this.category,
    required this.text,
    this.difficulty = PromptDifficulty.medium,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'text': text,
        'difficulty': difficulty.name,
      };

  factory GamePrompt.fromJson(Map<String, dynamic> map) => GamePrompt(
        category: map['category'] ?? '',
        text: map['text'] ?? '',
        difficulty: PromptDifficulty.values.firstWhere(
          (e) => e.name == (map['difficulty'] ?? ''),
          orElse: () => PromptDifficulty.medium,
        ),
      );
}
