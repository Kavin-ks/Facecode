import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:facecode/models/analytics_session.dart';
import 'package:facecode/models/game_session.dart';
import 'package:facecode/models/engagement_stats.dart';
import 'package:facecode/models/retention_score.dart';

class AnalyticsProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _storageKey = 'analytics_sessions';
  final List<AnalyticsSession> _sessions = [];
  AnalyticsSession? _currentSession;
  DateTime? _gameStartTime;
  String? _currentGameId;

  AnalyticsProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadSessions();
    _startNewSession();
  }

  AnalyticsSession? get currentSession => _currentSession;
  List<AnalyticsSession> get sessions => List.unmodifiable(_sessions);

  double get averageSessionLengthMinutes {
    if (_sessions.isEmpty) return 0;
    final totalMs = _sessions.fold<int>(0, (sum, s) => sum + s.totalDurationMs);
    final avgMs = totalMs / _sessions.length;
    return avgMs / (1000 * 60);
  }

  /// Aggregates engagement statistics across all sessions
  Map<String, GameEngagementStats> get gameEngagementStats {
    final Map<String, GameEngagementStats> statsMap = {};

    for (final session in _sessions) {
      final Set<String> gamesInSession = {};
      
      for (final gSession in session.gameSessions) {
        gamesInSession.add(gSession.gameId);
        
        final current = statsMap[gSession.gameId] ?? GameEngagementStats(gameId: gSession.gameId);
        
        statsMap[gSession.gameId] = current.copyWith(
          playCount: current.playCount + 1,
          totalDurationMs: current.totalDurationMs + gSession.durationMs,
          completions: current.completions + (gSession.completed ? 1 : 0),
          abandons: current.abandons + (gSession.completed ? 0 : 1),
        );
      }

      for (final gameId in gamesInSession) {
        final current = statsMap[gameId]!;
        statsMap[gameId] = current.copyWith(
          sessionsWithGame: current.sessionsWithGame + 1,
        );
      }
    }

    return statsMap;
  }

  /// Calculates a comprehensive retention score
  RetentionScore calculateRetentionScore({
    required int streak,
    required int totalGamesPlayed,
  }) {
    final now = DateTime.now();
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    
    final Set<String> uniqueDaysInRange = {};
    final Set<String> allUniqueDays = {};

    for (final session in _sessions) {
      final dateString = "${session.startTime.year}-${session.startTime.month}-${session.startTime.day}";
      allUniqueDays.add(dateString);
      
      if (session.startTime.isAfter(fourteenDaysAgo)) {
        uniqueDaysInRange.add(dateString);
      }
    }

    // 1. Streak Factor (30% weight, max 30 days)
    final streakRatio = (streak / 30).clamp(0.0, 1.0);
    final streakWeight = streakRatio * 30.0;

    // 2. Frequency Factor (40% weight, unique days in last 14)
    final frequencyRatio = (uniqueDaysInRange.length / 14).clamp(0.0, 1.0);
    final frequencyWeight = frequencyRatio * 40.0;

    // 3. Volume Factor (30% weight, max 500 games)
    final volumeRatio = (totalGamesPlayed / 500).clamp(0.0, 1.0);
    final volumeWeight = volumeRatio * 30.0;

    return RetentionScore(
      totalScore: streakWeight + frequencyWeight + volumeWeight,
      streakWeight: streakWeight,
      frequencyWeight: frequencyWeight,
      volumeWeight: volumeWeight,
      streak: streak,
      uniqueDaysInLast14: uniqueDaysInRange.length,
      totalGamesPlayed: totalGamesPlayed,
      totalUniqueDaysActive: allUniqueDays.length,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _endCurrentSession();
    } else if (state == AppLifecycleState.resumed) {
      _startNewSession();
    }
  }

  void _startNewSession() {
    if (_currentSession != null) return;
    
    _currentSession = AnalyticsSession(
      sessionId: const Uuid().v4(),
      startTime: DateTime.now(),
    );
    notifyListeners();
  }

  void _endCurrentSession() async {
    if (_currentSession == null) return;

    final endedSession = _currentSession!.copyWith(endTime: DateTime.now());
    _sessions.add(endedSession);
    _currentSession = null;
    
    await _saveSessions();
    notifyListeners();
  }

  /// Track when a game starts
  void trackGameStart(String gameId) {
    _currentGameId = gameId;
    _gameStartTime = DateTime.now();
  }

  /// Track when a game ends (completed or dropped)
  void trackGameEnd({required bool completed}) {
    if (_currentGameId == null || _gameStartTime == null || _currentSession == null) return;

    final durationMs = DateTime.now().difference(_gameStartTime!).inMilliseconds;
    
    final gameSession = GameSession(
      gameId: _currentGameId!,
      startTime: _gameStartTime!,
      durationMs: durationMs,
      completed: completed,
    );

    final updatedGameSessions = [..._currentSession!.gameSessions, gameSession];
    _currentSession = _currentSession!.copyWith(gameSessions: updatedGameSessions);
    
    _currentGameId = null;
    _gameStartTime = null;
    
    _saveSessions(); // Save partially in case of crash
    notifyListeners();
  }

  /// Track exit route for drop-off analysis
  void trackExitRoute(String route) {
    if (_currentSession == null) return;
    _currentSession = _currentSession!.copyWith(exitRoute: route);
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _sessions.clear();
        _sessions.addAll(decoded.map((s) => AnalyticsSession.fromJson(s)));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading analytics: $e');
      }
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endCurrentSession();
    super.dispose();
  }
}
