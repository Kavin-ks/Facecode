import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/models/user_progress.dart';
import 'package:facecode/models/badge_data.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/services/event_logging_service.dart';
import 'package:facecode/models/game_event.dart';

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

  // Queue for UI events
  bool _pendingLevelUp = false;
  bool _pendingStreakMilestone = false;
  bool _dailyTitleAnnouncementPending = false;
  int _lastLevelUp = 1;
  final List<BadgeData> _pendingBadges = [];

  bool get hasLevelUpPending => _pendingLevelUp;
  bool get hasStreakMilestonePending => _pendingStreakMilestone;
  bool get hasDailyTitlesPending => _dailyTitleAnnouncementPending;
  int get pendingLevel => _lastLevelUp;
  bool get hasBadgesPending => _pendingBadges.isNotEmpty;
  BadgeData? get nextPendingBadge => _pendingBadges.isNotEmpty ? _pendingBadges.first : null;

  /// Consume the pending level up event
  void consumeLevelUpEvent() {
    _pendingLevelUp = false;
    notifyListeners();
  }

  /// Check if streak is active for today
  bool get isStreakActiveToday {
    if (_progress.lastPlayedDate == null) return false;
    final now = DateTime.now();
    final last = _progress.lastPlayedDate!;
    return now.year == last.year && now.month == last.month && now.day == last.day;
  }

  /// Check if streak is at risk (played yesterday but not today)
  bool get isStreakAtRisk {
    if (_progress.lastPlayedDate == null) return false;
    if (isStreakActiveToday) return false; // Already safe
    
    final now = DateTime.now();
    final last = _progress.lastPlayedDate!;
    
    // Simple check: if difference is exactly 1 day (yesterday), it's at risk of breaking tomorrow
    // Note: difference inDays truncates, so we might need more robust day checking logic
    // But for "yesterday", diff >= 1 unless we are strict about calendar days.
    // Let's use strict calendar day check for yesterday:
    final yesterday = now.subtract(const Duration(days: 1));
    final playedYesterday = yesterday.year == last.year && 
                           yesterday.month == last.month && 
                           yesterday.day == last.day;
                           
    return playedYesterday;
  }

  /// Check if the user has already won a game today
  bool get isFirstWinToday {
    if (_progress.lastWinDate == null) return true;
    final now = DateTime.now();
    final last = _progress.lastWinDate!;
    return !(now.year == last.year && now.month == last.month && now.day == last.day);
  }

  /// Consume the pending streak event
  void consumeStreakEvent() {
    _pendingStreakMilestone = false;
    notifyListeners();
  }

  /// Consume the pending daily title announcement
  void consumeDailyTitlesEvent() {
    _dailyTitleAnnouncementPending = false;
    notifyListeners();
  }

  /// Consume the next pending badge
  void consumeBadgeEvent() {
    if (_pendingBadges.isNotEmpty) {
      _pendingBadges.removeAt(0);
      notifyListeners();
    }
  }

  // Rewards & XP
  int get currentXP => _progress.currentXP;
  int get xpForNextLevel => _progress.xpForNextLevel;
  
  // Pending Rewards
  int _pendingRewardXp = 0;
  int _pendingRewardCoins = 0;
  bool _isMysteryReward = false;
  int get pendingRewardXp => _pendingRewardXp;
  int get pendingRewardCoins => _pendingRewardCoins;
  bool get isMysteryReward => _isMysteryReward;
  bool get hasPendingRewards => _pendingRewardXp > 0 || _pendingRewardCoins > 0;

  /// Award XP and check for level up
  Future<void> awardXP(int amount, {bool showLevelUp = true}) async {
    int newXP = _progress.currentXP + amount;
    int newLevel = _progress.level;
    int xpForNext = _progress.xpForNextLevel;
    bool leveledUp = false;

    // Check for level up
    while (newXP >= xpForNext) {
      newXP -= xpForNext;
      newLevel++;
      xpForNext = UserProgress.xpForLevel(newLevel);
      leveledUp = true;
    }

    if (leveledUp && showLevelUp) {
      _pendingLevelUp = true;
      _lastLevelUp = newLevel;
      debugPrint('🎉 LEVEL UP! Now level $newLevel');
      SoundManager().playGameSound(SoundManager.sfxLevelUp, haptic: HapticType.heavy);
      
      // Award Coins for Level Up
      _progress = _progress.copyWith(
        coins: _progress.coins + 100,
      );
    } else if (amount > 0) {
      // Throttle XP "ding" to avoid spamming if called rapidly
      SoundManager().playGameSound(SoundManager.sfxXpGain, throttleMs: 200, volumeScale: 0.6, haptic: HapticType.light);
    }

    _progress = _progress.copyWith(
      level: newLevel,
      currentXP: newXP,
      xpForNextLevel: xpForNext,
      dailyXpGained: _progress.dailyXpGained + amount,
    );

    await _saveProgress();
    
    // Log XP gain event
    EventLoggingService().logEvent(
      GameEvent.xpGained(amount: amount, source: 'general'),
    );
    
    notifyListeners();
  }

  /// Record a game completion
  Future<void> recordGamePlayed({bool won = false}) async {
    _progress = _progress.copyWith(
      totalGamesPlayed: _progress.totalGamesPlayed + 1,
      totalWins: won ? _progress.totalWins + 1 : _progress.totalWins,
    );

    // Award XP
    int xpAmount = won ? 50 : 25;
    
    // Aggressive Bonus XP for streak (Doubled from 5 per day to 10 per day, max 100)
    if (_progress.currentStreak > 0) {
      xpAmount += min(_progress.currentStreak * 10, 100);
    }

    await awardXP(xpAmount);

    // Update streak after recording the play (uses previous lastPlayedDate to determine consecutive days)
    await _updateStreak();

    await _saveProgress();
    notifyListeners();
  }

  /// Record a specific game result with stats + badges
  Future<void> recordGameResult({
    required String gameId,
    required bool won,
    required int xpAward,
    int drawingsCreated = 0,
    int? reactionTimeMs,
    required AnalyticsProvider analytics,
  }) async {
    analytics.trackGameEnd(completed: true);
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
      totalDrawings: _progress.totalDrawings + drawingsCreated,
      lastPlayedDate: DateTime.now(),
      gamePlays: plays,
      gameWins: wins,
      gameCurrentStreak: currentStreaks,
      gameBestStreak: bestStreaks,
    );

    // Consolation XP for losses: always award at least a minimum to keep momentum
    int finalXp = xpAward;
    bool isMystery = false;
    final random = Random();

    if (!won) {
      // Award 25% of the intended XP, but at least 15
      finalXp = max(15, xpAward ~/ 4);
      debugPrint('🛡️ Consolation XP awarded: $finalXp');
      
      // 2% chance for a Lucky Charm badge even on loss (would need to implement badge awarding logic separately)
      // TODO: Implement forced badge award system if needed
      // if (random.nextDouble() < 0.02) {
      //   _checkAndAwardBadges(forcedBadgeId: 'lucky_charm');
      // }
    } else {
      // 5% chance for a CRITICAL WIN (Double XP)
      if (random.nextDouble() < 0.05) {
        finalXp *= 2;
        debugPrint('🔥 CRITICAL WIN! Double XP: $finalXp');
      }
      
      // 10% chance for a Mystery Box
      if (random.nextDouble() < 0.10) {
        isMystery = true;
        debugPrint('🎁 MYSTERY BOX TRIGGERED!');
      }
    }

    // Store as pending rewards instead of awarding immediately
    _pendingRewardXp = finalXp;
    _isMysteryReward = isMystery;

    // Award Coins for Win
    if (won) {
      int coinsAward = xpAward;
      
      // First Win of the Day Bonus
      if (isFirstWinToday) {
        coinsAward += 250; // Constants.firstWinBonus
        debugPrint('💰 FIRST WIN OF THE DAY! Bonus 250 coins');
        // We'll update lastWinDate here
        _progress = _progress.copyWith(lastWinDate: DateTime.now());
      }

      _pendingRewardCoins = coinsAward;
    } else {
      _pendingRewardCoins = 0;
    }

    await _saveProgress();

    // Track Daily High Score per game
    final currentDailyBest = _progress.dailyHighScore[gameId] ?? 0;
    if (finalXp > currentDailyBest) {
      final newDailyHighs = Map<String, int>.from(_progress.dailyHighScore);
      newDailyHighs[gameId] = finalXp;
      _progress = _progress.copyWith(dailyHighScore: newDailyHighs);
      debugPrint('📈 New Daily High Score for $gameId: $finalXp');
    }

    await _checkAndAwardBadges(reactionTimeMs: reactionTimeMs);

    // Check Daily Challenge
    if (won && gameId == _progress.dailyChallengeGameId && !_progress.dailyChallengeCompleted) {
      // Daily challenge rewards also become pending
      _pendingRewardXp += 100;
      _pendingRewardCoins += 100;
      _progress = _progress.copyWith(dailyChallengeCompleted: true);
      await _saveProgress();
    }

    notifyListeners();
  }

  /// Claim all pending rewards
  Future<void> claimRewards() async {
    if (!hasPendingRewards) return;

    final xp = _pendingRewardXp;
    final coins = _pendingRewardCoins;

    // Clear pending status first to prevent double-claiming
    _pendingRewardXp = 0;
    _pendingRewardCoins = 0;
    _isMysteryReward = false;
    
    // Award XP
    await awardXP(xp);
    
    // Award Coins
    _progress = _progress.copyWith(
      coins: _progress.coins + coins,
    );

    await _saveProgress();
    notifyListeners();
  }

  /// Update daily streak
  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final lastPlayed = _progress.lastPlayedDate;

    // If the user has never played before, do not auto-start a streak.
    if (lastPlayed == null) {
      return;
    }

    final daysSinceLastPlayed = now.difference(lastPlayed).inDays;

    if (daysSinceLastPlayed == 0) {
      // Same day, no change
      return;
    } else if (daysSinceLastPlayed == 1) {
      // Consecutive day!
      final newStreak = _progress.currentStreak + 1;
      _pendingStreakMilestone = true;
      _progress = _progress.copyWith(
        currentStreak: newStreak,
        longestStreak: max(newStreak, _progress.longestStreak),
        lastPlayedDate: now,
      );
    } else {
      // Streak broken — reset to 1 (today)
      _progress = _progress.copyWith(
        currentStreak: 1,
        lastPlayedDate: now,
      );
    }

    // Today's Best Logic (Mocked threshold for simulation)
    // In a real app, this would compare against server-side leaderboards.
    List<String> wonTitles = [];
    
    // Overall Daily Best: 1000+ XP in a day
    if (_progress.dailyXpGained >= 1000) {
      wonTitles.add('overall');
    }
    
    // Game Specific Bests: 300+ XP in a specific game
    _progress.dailyHighScore.forEach((gameId, score) {
      if (score >= 300) {
        wonTitles.add(gameId);
      }
    });

    if (wonTitles.isNotEmpty) {
      debugPrint('🏆 WON DAILY TITLES: $wonTitles');
      _progress = _progress.copyWith(
        activeDailyTitles: wonTitles,
        titleAwardedDate: now,
      );
      _dailyTitleAnnouncementPending = true;
    } else if (_progress.titleAwardedDate != null && now.difference(_progress.titleAwardedDate!).inDays >= 1) {
      // Clear titles after 24 hours
      _progress = _progress.copyWith(
        activeDailyTitles: [],
        titleAwardedDate: null,
      );
      debugPrint('🧹 Daily titles cleared.');
    }

    // Reset daily stats for the new day
    _progress = _progress.copyWith(
      dailyXpGained: 0,
      dailyHighScore: {},
    );

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
      
      // Award bonus Coins
      _progress = _progress.copyWith(
        coins: _progress.coins + 100,
      );

      await _saveProgress();
      notifyListeners();
    }
  }


  Future<void> _checkAndAwardBadges({int? reactionTimeMs}) async {
    final currentBadges = Set<String>.from(_progress.badges);
    final badgesToAward = <String>[];

    void check(String id, bool condition) {
      if (condition && !currentBadges.contains(id)) {
        badgesToAward.add(id);
      }
    }

    // Check conditions against BadgeData definitions
    check('newbie', _progress.totalGamesPlayed >= 1);
    check('first_win', _progress.totalWins >= 1);
    check('hot_streak', _progress.currentStreak >= 5);
    check('artist', _progress.totalDrawings >= 10);
    check('thinker', (_progress.gameWins['game-would-rather'] ?? 0) >= 3);
    check('party_king', _progress.totalWins >= 20 || _progress.level >= 10);
    check('veteran_50_games', _progress.totalGamesPlayed >= 50);
    check('streak_10', _progress.currentStreak >= 10);
    
    // Party Starter: Played 3 different games
    check('party_starter', _progress.gamePlays.keys.length >= 3);
    
    // Game Master
    check('game_master', _progress.level >= 20 && _progress.totalWins >= 50);
    
    // Fast Thinker (Passed explicitly)
    if (reactionTimeMs != null) {
      check('fast_thinker', reactionTimeMs < 200);
    }

    if (badgesToAward.isNotEmpty) {
      final newBadgesList = [..._progress.badges, ...badgesToAward];
      _progress = _progress.copyWith(badges: newBadgesList);
      
      // Queue for UI
      for (var id in badgesToAward) {
        final badge = BadgeData.getById(id);
        if (badge != null) {
          _pendingBadges.add(badge);
        }
      }
      
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

  /// Update progress from shop (purchases/equipment)
  Future<void> updateShopProgress(UserProgress newProgress) async {
    _progress = newProgress;
    await _saveProgress();
    notifyListeners();
  }

  /// Reset progress (for testing)
  Future<void> resetProgress() async {
    _progress = const UserProgress();
    await _saveProgress();
    notifyListeners();
  }
}
