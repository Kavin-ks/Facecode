import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/models/user_progress.dart';

/// Provider for managing user progression, XP, levels, streaks, and daily challenges
class ProgressProvider extends ChangeNotifier {
  UserProgress _progress = const UserProgress();
  
  UserProgress get progress => _progress;
  
  static const String _storageKey = 'user_progress';

  /// Initialize and load saved progress
  Future<void> initialize() async {
    await _loadProgress();
    await _checkDailyChallenge();
    await _updateStreak();
  }

  /// Load progress from storage
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _progress = UserProgress.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading progress: $e');
      }
    }
  }

  /// Save progress to storage
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_progress.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Award XP and check for level up
  Future<void> awardXP(int amount, {bool showLevelUp = true}) async {
    int newXP = _progress.currentXP + amount;
    int newLevel = _progress.level;
    int xpForNext = _progress.xpForNextLevel;

    // Check for level up
    while (newXP >= xpForNext) {
      newXP -= xpForNext;
      newLevel++;
      xpForNext = UserProgress.xpForLevel(newLevel);
      
      if (showLevelUp) {
        // Could trigger a level up animation/dialog here
        debugPrint('🎉 LEVEL UP! Now level $newLevel');
      }
    }

    _progress = _progress.copyWith(
      level: newLevel,
      currentXP: newXP,
      xpForNextLevel: xpForNext,
    );

    await _saveProgress();
    notifyListeners();
  }

  /// Record a game completion
  Future<void> recordGamePlayed({bool won = false}) async {
    _progress = _progress.copyWith(
      totalGamesPlayed: _progress.totalGamesPlayed + 1,
      totalWins: won ? _progress.totalWins + 1 : _progress.totalWins,
      lastPlayedDate: DateTime.now(),
    );

    // Award XP
    int xpAmount = won ? 50 : 25;
    
    // Bonus XP for streak
    if (_progress.currentStreak > 0) {
      xpAmount += min(_progress.currentStreak * 5, 50);
    }

    await awardXP(xpAmount);
    await _saveProgress();
  }

  /// Record a specific game result with stats + badges
  Future<void> recordGameResult({
    required String gameId,
    required bool won,
    required int xpAward,
  }) async {
    final plays = Map<String, int>.from(_progress.gamePlays);
    final wins = Map<String, int>.from(_progress.gameWins);
    final currentStreaks = Map<String, int>.from(_progress.gameCurrentStreak);
    final bestStreaks = Map<String, int>.from(_progress.gameBestStreak);

    plays[gameId] = (plays[gameId] ?? 0) + 1;
    if (won) {
      wins[gameId] = (wins[gameId] ?? 0) + 1;
      currentStreaks[gameId] = (currentStreaks[gameId] ?? 0) + 1;
      final current = currentStreaks[gameId] ?? 0;
      final best = bestStreaks[gameId] ?? 0;
      if (current > best) bestStreaks[gameId] = current;
    } else {
      currentStreaks[gameId] = 0;
    }

    _progress = _progress.copyWith(
      totalGamesPlayed: _progress.totalGamesPlayed + 1,
      totalWins: won ? _progress.totalWins + 1 : _progress.totalWins,
      lastPlayedDate: DateTime.now(),
      gamePlays: plays,
      gameWins: wins,
      gameCurrentStreak: currentStreaks,
      gameBestStreak: bestStreaks,
    );

    await awardXP(xpAward);
    await _saveProgress();
    await _checkAndAwardBadges();
    notifyListeners();
  }

  /// Update daily streak
  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final lastPlayed = _progress.lastPlayedDate;

    if (lastPlayed == null) {
      // First time playing
      _progress = _progress.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastPlayedDate: now,
      );
      await _saveProgress();
      return;
    }

    final daysSinceLastPlayed = now.difference(lastPlayed).inDays;

    if (daysSinceLastPlayed == 0) {
      // Same day, no change
      return;
    } else if (daysSinceLastPlayed == 1) {
      // Consecutive day!
      final newStreak = _progress.currentStreak + 1;
      _progress = _progress.copyWith(
        currentStreak: newStreak,
        longestStreak: max(newStreak, _progress.longestStreak),
        lastPlayedDate: now,
      );
    } else {
      // Streak broken
      _progress = _progress.copyWith(
        currentStreak: 1,
        lastPlayedDate: now,
      );
    }

    await _saveProgress();
    notifyListeners();
  }

  /// Check and generate daily challenge
  Future<void> _checkDailyChallenge() async {
    final now = DateTime.now();
    final lastPlayed = _progress.lastPlayedDate;

    // Check if we need a new daily challenge
    if (lastPlayed == null || 
        now.day != lastPlayed.day || 
        now.month != lastPlayed.month ||
        now.year != lastPlayed.year) {
      
      // Generate new daily challenge
      await _generateDailyChallenge();
    }
  }

  /// Generate a random daily challenge game
  Future<void> _generateDailyChallenge() async {
    final gameIds = ['emoji_translator', 'truth_dare', 'would_rather', 'reaction_time'];
    final random = Random();
    final challengeGameId = gameIds[random.nextInt(gameIds.length)];

    _progress = _progress.copyWith(
      dailyChallengeGameId: challengeGameId,
      dailyChallengeCompleted: false,
    );

    await _saveProgress();
    notifyListeners();
  }

  /// Complete daily challenge
  Future<void> completeDailyChallenge() async {
    if (!_progress.dailyChallengeCompleted) {
      _progress = _progress.copyWith(
        dailyChallengeCompleted: true,
      );

      // Award bonus XP
      await awardXP(100); // Big bonus for daily challenge!
      
      await _saveProgress();
      notifyListeners();
    }
  }

  Future<void> _checkAndAwardBadges() async {
    final earned = Set<String>.from(_progress.badges);

    if (_progress.totalGamesPlayed >= 10) earned.add('rookie_10_games');
    if (_progress.totalGamesPlayed >= 50) earned.add('veteran_50_games');
    if (_progress.totalWins >= 1) earned.add('first_win');
    if (_progress.totalWins >= 10) earned.add('ten_wins');
    if (_progress.currentStreak >= 3) earned.add('streak_3');
    if (_progress.currentStreak >= 10) earned.add('streak_10');

    if (earned.length != _progress.badges.length) {
      _progress = _progress.copyWith(badges: earned.toList());
      await _saveProgress();
    }
  }

  /// Get level badge emoji
  String getLevelBadge() {
    final level = _progress.level;
    if (level >= 50) return '👑'; // King
    if (level >= 40) return '💎'; // Diamond
    if (level >= 30) return '⭐'; // Star
    if (level >= 20) return '🔥'; // Fire
    if (level >= 10) return '🎯'; // Target
    return '🌟'; // Beginner
  }

  /// Reset progress (for testing)
  Future<void> resetProgress() async {
    _progress = const UserProgress();
    await _saveProgress();
    notifyListeners();
  }
}
