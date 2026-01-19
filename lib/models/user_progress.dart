/// User progression data
class UserProgress {
  final int level;
  final int currentXP;
  final int xpForNextLevel;
  final int totalGamesPlayed;
  final int totalWins;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPlayedDate;
  final String? dailyChallengeGameId;
  final bool dailyChallengeCompleted;

  const UserProgress({
    this.level = 1,
    this.currentXP = 0,
    this.xpForNextLevel = 100,
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPlayedDate,
    this.dailyChallengeGameId,
    this.dailyChallengeCompleted = false,
  });

  /// Calculate XP needed for a given level
  static int xpForLevel(int level) {
    return 100 + (level - 1) * 50; // Progressive XP requirement
  }

  /// Get progress percentage to next level
  double get progressPercent => currentXP / xpForNextLevel;

  /// Copy with new values
  UserProgress copyWith({
    int? level,
    int? currentXP,
    int? xpForNextLevel,
    int? totalGamesPlayed,
    int? totalWins,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPlayedDate,
    String? dailyChallengeGameId,
    bool? dailyChallengeCompleted,
  }) {
    return UserProgress(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      dailyChallengeGameId: dailyChallengeGameId ?? this.dailyChallengeGameId,
      dailyChallengeCompleted: dailyChallengeCompleted ?? this.dailyChallengeCompleted,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentXP': currentXP,
      'xpForNextLevel': xpForNextLevel,
      'totalGamesPlayed': totalGamesPlayed,
      'totalWins': totalWins,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPlayedDate': lastPlayedDate?.toIso8601String(),
      'dailyChallengeGameId': dailyChallengeGameId,
      'dailyChallengeCompleted': dailyChallengeCompleted,
    };
  }

  /// Create from JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      level: json['level'] ?? 1,
      currentXP: json['currentXP'] ?? 0,
      xpForNextLevel: json['xpForNextLevel'] ?? 100,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null 
          ? DateTime.parse(json['lastPlayedDate'])
          : null,
      dailyChallengeGameId: json['dailyChallengeGameId'],
      dailyChallengeCompleted: json['dailyChallengeCompleted'] ?? false,
    );
  }
}
