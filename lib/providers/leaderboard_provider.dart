import 'package:flutter/material.dart';
import 'package:facecode/models/leaderboard_entry.dart';
import 'package:facecode/models/user_progress.dart';
import 'package:facecode/utils/constants.dart';
import 'dart:math';

enum LeaderboardType { daily, weekly, allTime }

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  LeaderboardType _currentType = LeaderboardType.daily;
  bool _isLoading = false;

  final Map<LeaderboardType, List<LeaderboardEntry>> _cache = {};

  List<LeaderboardEntry> get entries => _entries;
  LeaderboardType get currentType => _currentType;
  bool get isLoading => _isLoading;

  // Mock Names
  final List<String> _userNames = [
    'PixelMaster', 'CodeNinja', 'GlitchHunter', 'ByteWizard', 'NeonRider',
    'CyberPunk', 'DevGuru', 'NullPointer', 'StackOverflow', 'GitPush',
    'RepoReaper', 'BugBasher', 'SyntaxError', 'CompileTime', 'RuntimeKing',
    'AsyncAwait', 'FutureProof', 'StreamBuilder', 'WidgetCraft', 'StateFull'
  ];

  final List<String> _emojis = ['🤖', '👾', '👽', '👻', '🤡', '🤠', '🎃', '🦄', '🐲', '🌵'];

  Future<void> loadLeaderboard(LeaderboardType type, UserProgress userProgress, {String userName = "You", bool forceRefresh = false}) async {
    _currentType = type;
    
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _cache.containsKey(type)) {
      _entries = _cache[type]!;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final newEntries = _generateMockData(type, userProgress, userName);
    _cache[type] = newEntries;
    _entries = newEntries;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(UserProgress userProgress, {String userName = "You"}) async {
    await loadLeaderboard(_currentType, userProgress, userName: userName, forceRefresh: true);
  }

  List<LeaderboardEntry> _generateMockData(LeaderboardType type, UserProgress userProgress, String userName) {
    final random = Random();
    final List<LeaderboardEntry> generated = [];
    
    // Determine base score range based on type
    int maxScore = 0;
    int userScore = 0;
    
    switch (type) {
      case LeaderboardType.daily:
        maxScore = 2000;
        // User's daily score (mocked as a portion of their total for now needed)
        // Ideally we track daily XP separately, but for now we'll mock it 
        userScore = min(userProgress.currentXP, 500) + random.nextInt(200); 
        break;
      case LeaderboardType.weekly:
        maxScore = 15000;
        userScore = userProgress.level * 1000 + userProgress.currentXP; // Approx total XP
        break;
      case LeaderboardType.allTime:
        maxScore = 50000;
        userScore = userProgress.level * 2500 + userProgress.currentXP; 
        break;
    }

    // Ensure userScore is within bounds of "Top Players" sometimes, but not always 1st
    // Let's make the top player always have a bit more than the user to encourage play, unless user is very high level
    int topScore = max(maxScore, (userScore * 1.2).toInt());
    
    // Generate 50 bots
    for (int i = 0; i < 50; i++) {
      final name = _userNames[random.nextInt(_userNames.length)] + (random.nextInt(99)).toString();
      final avatar = _emojis[random.nextInt(_emojis.length)];
      
      // Decay score as rank drops to create curve
      final score = (topScore * (1.0 - (i * 0.015))).toInt() + random.nextInt(100);
      
      // Decay level/badges as rank drops
      final level = max(1, (topScore ~/ 1000) - (i ~/ 2));
      final badgeCount = max(0, 10 - (i ~/ 5));
      final badges = List.generate(badgeCount, (index) => 'badge_$index');

      generated.add(LeaderboardEntry(
        id: 'bot_$i',
        name: name,
        avatar: avatar,
        score: score,
        level: level,
        badges: badges,
        rank: 0, // Assigned later
        change: random.nextInt(3) - 1, // -1, 0, 1
      ));
    }

    // Add User
    generated.add(LeaderboardEntry(
      id: 'current_user',
      name: "$userName (You)",
      avatar: '👤', // Or user's actual avatar
      score: userScore,
      level: userProgress.level,
      badges: userProgress.badges,
      rank: 0,
      isUser: true,
      change: 1, // Simulate moving up
    ));

    // Sort by Score DESC
    generated.sort((a, b) => b.score.compareTo(a.score));

    // Assign Ranks and Re-map
    return generated.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      
      // Determine rank title based on score/rank for bots, or actual rank for user
      String title = 'Newbie';
      Color color = AppConstants.textMuted;
      
      if (entry.isUser) {
        final rank = userProgress.playerRank;
        title = rank.label;
        color = rank.color;
      } else {
        // Logic for bots: High rank = high title
        if (index < 3) {
          title = 'Legend';
          color = AppConstants.accentGold;
        } else if (index < 10) {
          title = 'Game Master';
          color = AppConstants.cardPink;
        } else if (index < 25) {
          title = 'Crowd Favorite';
          color = AppConstants.cardOrange;
        } else if (index < 40) {
          title = 'Party Starter';
          color = AppConstants.primaryColor;
        }
      }

      return LeaderboardEntry(
        id: entry.id,
        name: entry.name,
        avatar: entry.avatar,
        score: entry.score,
        level: entry.level,
        badges: entry.badges,
        rank: index + 1,
        isUser: entry.isUser,
        isDailyBest: (index == 0) || (entry.isUser && userProgress.activeDailyTitles.isNotEmpty),
        change: entry.change,
        rankTitle: title,
        rankColor: color,
      );
    }).toList();
  }
}
