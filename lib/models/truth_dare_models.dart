enum TruthDareMode { withQuestions, withoutQuestions }

enum TdCategory { trending, mostAsked, newest, spicy, couples, friends, deep, social, fun, party, crazy, clean }

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
  final int viewCount;
  final int likeCount;
  final int dislikeCount;
  final DateTime? lastUsed;
  final DateTime? createdAt;
  final bool isTrending;
  final bool isBookmarked;

  TdQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.category,
    required this.ageGroup,
    required this.difficulty,
    this.usageCount = 0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.lastUsed,
    this.createdAt,
    this.isTrending = false,
    this.isBookmarked = false,
  });

  factory TdQuestion.fromMap(String id, Map<String, dynamic> map) {
    return TdQuestion(
      id: id,
      text: map['text'] ?? '',
      type: TdType.values.firstWhere((e) => e.name == map['type'], orElse: () => TdType.truth),
      category: TdCategory.values.firstWhere((e) => e.name == map['category'], orElse: () => TdCategory.clean),
      ageGroup: TdAgeGroup.values.firstWhere((e) => e.name == map['ageGroup'], orElse: () => TdAgeGroup.kids),
      difficulty: TdDifficulty.values.firstWhere((e) => e.name == map['difficulty'], orElse: () => TdDifficulty.easy),
      usageCount: map['usageCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
      dislikeCount: map['dislikeCount'] ?? 0,
      lastUsed: map['lastUsed'] != null ? DateTime.tryParse(map['lastUsed']) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      isTrending: map['isTrending'] ?? false,
      isBookmarked: map['isBookmarked'] ?? false,
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
      'viewCount': viewCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'lastUsed': lastUsed?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'isTrending': isTrending,
      'isBookmarked': isBookmarked,
    };
  }

  TdQuestion copyWith({
    String? id,
    String? text,
    TdType? type,
    TdCategory? category,
    TdAgeGroup? ageGroup,
    TdDifficulty? difficulty,
    int? usageCount,
    int? viewCount,
    int? likeCount,
    int? dislikeCount,
    DateTime? lastUsed,
    DateTime? createdAt,
    bool? isTrending,
    bool? isBookmarked,
  }) {
    return TdQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      category: category ?? this.category,
      ageGroup: ageGroup ?? this.ageGroup,
      difficulty: difficulty ?? this.difficulty,
      usageCount: usageCount ?? this.usageCount,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
      isTrending: isTrending ?? this.isTrending,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  double get popularityScore {
    // Calculate popularity based on likes, views, and usage
    final likesWeight = likeCount * 3;
    final viewsWeight = viewCount * 0.5;
    final usageWeight = usageCount * 2;
    final dislikes = dislikeCount * -2;
    return likesWeight + viewsWeight + usageWeight + dislikes;
  }
}
