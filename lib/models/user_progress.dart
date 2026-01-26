import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// Rank information for a user
class RankInfo {
  final String label;
  final Color color;
  final String icon;

  const RankInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// User progression data
class UserProgress {
  final int level;
  final int currentXP;
  final int xpForNextLevel;
  final int totalGamesPlayed;
  final int totalWins;
  final int totalDrawings; // Added for Artist badge
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPlayedDate;
  final String? dailyChallengeGameId;
  final bool dailyChallengeCompleted;
  final Map<String, int> gamePlays;
  final Map<String, int> gameWins;
  final Map<String, int> gameCurrentStreak;
  final Map<String, int> gameBestStreak;
  final List<String> badges;
  final int coins;
  final List<String> inventory;
  final Map<String, String> equippedItems;
  final bool isElite;
  final DateTime? eliteSince;
  final String? eliteTier;
  final DateTime? lastWinDate;
  final int dailyXpGained;
  final Map<String, int> dailyHighScore;
  final List<String> activeDailyTitles;
  final DateTime? titleAwardedDate;

  const UserProgress({
    this.level = 1,
    this.currentXP = 0,
    this.xpForNextLevel = 100,
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.totalDrawings = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPlayedDate,
    this.dailyChallengeGameId,
    this.dailyChallengeCompleted = false,
    this.gamePlays = const {},
    this.gameWins = const {},
    this.gameCurrentStreak = const {},
    this.gameBestStreak = const {},
    this.badges = const [],
    this.coins = 0,
    this.inventory = const [],
    this.equippedItems = const {},
    this.isElite = false,
    this.eliteSince,
    this.eliteTier,
    this.lastWinDate,
    this.dailyXpGained = 0,
    this.dailyHighScore = const {},
    this.activeDailyTitles = const [],
    this.titleAwardedDate,
  });

  /// Calculate XP needed for a given level
  static int xpForLevel(int level) {
    return 100 + (level - 1) * 50; // Progressive XP requirement
  }

  /// Get progress percentage to next level
  double get progressPercent => currentXP / xpForNextLevel;

  /// Get player rank title based on stats
  RankInfo get playerRank {
    if (level >= 20 && totalWins >= 100) {
      return const RankInfo(
        label: 'Legend',
        color: AppConstants.accentGold,
        icon: '👑',
      );
    }
    if (level >= 15 && totalWins >= 50) {
      return const RankInfo(
        label: 'Game Master',
        color: AppConstants.cardPink,
        icon: '🧙‍♂️',
      );
    }
    if (level >= 10 && totalWins >= 25) {
      return const RankInfo(
        label: 'Crowd Favorite',
        color: AppConstants.cardOrange,
        icon: '🌟',
      );
    }
    if (level >= 5 && totalWins >= 10) {
      return const RankInfo(
        label: 'Party Starter',
        color: AppConstants.primaryColor,
        icon: '🎉',
      );
    }
    return const RankInfo(
      label: 'Newbie',
      color: AppConstants.textMuted,
      icon: '🐣',
    );
  }

  /// Copy with new values
  UserProgress copyWith({
    int? level,
    int? currentXP,
    int? xpForNextLevel,
    int? totalGamesPlayed,
    int? totalWins,
    int? totalDrawings,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPlayedDate,
    String? dailyChallengeGameId,
    bool? dailyChallengeCompleted,
    Map<String, int>? gamePlays,
    Map<String, int>? gameWins,
    Map<String, int>? gameCurrentStreak,
    Map<String, int>? gameBestStreak,
    List<String>? badges,
    int? coins,
    List<String>? inventory,
    Map<String, String>? equippedItems,
    bool? isElite,
    DateTime? eliteSince,
    String? eliteTier,
    DateTime? lastWinDate,
    int? dailyXpGained,
    Map<String, int>? dailyHighScore,
    List<String>? activeDailyTitles,
    DateTime? titleAwardedDate,
  }) {
    return UserProgress(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      totalDrawings: totalDrawings ?? this.totalDrawings,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      dailyChallengeGameId: dailyChallengeGameId ?? this.dailyChallengeGameId,
      dailyChallengeCompleted: dailyChallengeCompleted ?? this.dailyChallengeCompleted,
      gamePlays: gamePlays ?? this.gamePlays,
      gameWins: gameWins ?? this.gameWins,
      gameCurrentStreak: gameCurrentStreak ?? this.gameCurrentStreak,
      gameBestStreak: gameBestStreak ?? this.gameBestStreak,
      badges: badges ?? this.badges,
      coins: coins ?? this.coins,
      inventory: inventory ?? this.inventory,
      equippedItems: equippedItems ?? this.equippedItems,
      isElite: isElite ?? this.isElite,
      eliteSince: eliteSince ?? this.eliteSince,
      eliteTier: eliteTier ?? this.eliteTier,
      lastWinDate: lastWinDate ?? this.lastWinDate,
      dailyXpGained: dailyXpGained ?? this.dailyXpGained,
      dailyHighScore: dailyHighScore ?? this.dailyHighScore,
      activeDailyTitles: activeDailyTitles ?? this.activeDailyTitles,
      titleAwardedDate: titleAwardedDate ?? this.titleAwardedDate,
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
      'totalDrawings': totalDrawings,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPlayedDate': lastPlayedDate?.toIso8601String(),
      'dailyChallengeGameId': dailyChallengeGameId,
      'dailyChallengeCompleted': dailyChallengeCompleted,
      'gamePlays': gamePlays,
      'gameWins': gameWins,
      'gameCurrentStreak': gameCurrentStreak,
      'gameBestStreak': gameBestStreak,
      'badges': badges,
      'coins': coins,
      'inventory': inventory,
      'equippedItems': equippedItems,
      'isElite': isElite,
      'eliteSince': eliteSince?.toIso8601String(),
      'eliteTier': eliteTier,
      'lastWinDate': lastWinDate?.toIso8601String(),
      'dailyXpGained': dailyXpGained,
      'dailyHighScore': dailyHighScore,
      'activeDailyTitles': activeDailyTitles,
      'titleAwardedDate': titleAwardedDate?.toIso8601String(),
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
      totalDrawings: json['totalDrawings'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null 
          ? DateTime.parse(json['lastPlayedDate'])
          : null,
      dailyChallengeGameId: json['dailyChallengeGameId'],
      dailyChallengeCompleted: json['dailyChallengeCompleted'] ?? false,
      gamePlays: (json['gamePlays'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      gameWins: (json['gameWins'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      gameCurrentStreak: (json['gameCurrentStreak'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      gameBestStreak: (json['gameBestStreak'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      coins: json['coins'] ?? 0,
      inventory: (json['inventory'] as List?)?.map((e) => e.toString()).toList() ?? [],
      equippedItems: (json['equippedItems'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      isElite: json['isElite'] ?? false,
      eliteSince: json['eliteSince'] != null ? DateTime.parse(json['eliteSince']) : null,
      eliteTier: json['eliteTier'],
      lastWinDate: json['lastWinDate'] != null ? DateTime.parse(json['lastWinDate']) : null,
      dailyXpGained: json['dailyXpGained'] ?? 0,
      dailyHighScore: (json['dailyHighScore'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      activeDailyTitles: (json['activeDailyTitles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      titleAwardedDate: json['titleAwardedDate'] != null ? DateTime.parse(json['titleAwardedDate']) : null,
    );
  }
}
