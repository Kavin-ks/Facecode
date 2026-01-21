enum TruthDareMode { withQuestions, withoutQuestions }

enum TdCategory { trending, mostAsked, newest, spicy, couples, friends, deep, social, fun }

enum TdAgeGroup { kids, teens, adults, mature } // 10-15, 16-18, 18+, 21+

enum TdDifficulty { easy, medium, hard, extreme }

enum TdType { truth, dare }

class TdQuestion {
  final String id;
  final String text;
  final TdType type;
  final TdCategory category;
  final TdAgeGroup ageGroup;
  final TdDifficulty difficulty;
  final int usageCount;
  final DateTime? lastUsed;

  TdQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.category,
    required this.ageGroup,
    required this.difficulty,
    this.usageCount = 0,
    this.lastUsed,
  });

  factory TdQuestion.fromMap(String id, Map<String, dynamic> map) {
    return TdQuestion(
      id: id,
      text: map['text'] ?? '',
      type: TdType.values.firstWhere((e) => e.name == map['type'], orElse: () => TdType.truth),
      category: TdCategory.values.firstWhere((e) => e.name == map['category'], orElse: () => TdCategory.newest),
      ageGroup: TdAgeGroup.values.firstWhere((e) => e.name == map['ageGroup'], orElse: () => TdAgeGroup.kids),
      difficulty: TdDifficulty.values.firstWhere((e) => e.name == map['difficulty'], orElse: () => TdDifficulty.easy),
      usageCount: map['usageCount'] ?? 0,
      lastUsed: map['lastUsed'] != null ? DateTime.tryParse(map['lastUsed']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.name,
      'category': category.name,
      'ageGroup': ageGroup.name,
      'difficulty': difficulty.name,
      'usageCount': usageCount,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
}
