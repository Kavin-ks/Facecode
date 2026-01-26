import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/models/base_game_state.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/services/event_logging_service.dart';
import 'package:facecode/models/game_event.dart';

/// Base game controller mixin providing common game logic
/// Use this with your StatefulWidget state to get:
/// - Standardized lifecycle (start, pause, resume, end)
/// - Timer management
/// - Score tracking
/// - Analytics integration
/// - State transitions
mixin BaseGameController<T extends StatefulWidget> on State<T> {
  // Internal state
  GamePhase _phase = GamePhase.idle;
  Timer? _gameTimer;
  Timer? _countdownTimer;
  int _score = 0;
  int _round = 0;

  // Getters for current state
  GamePhase get phase => _phase;
  int get score => _score;
  int get round => _round;
  bool get isPlaying => _phase == GamePhase.playing;
  bool get isFinished => _phase == GamePhase.completed;

  // Must override - game identification
  String get gameId;

  // Optional overrides - game configuration
  int get totalRounds => 1;
  Duration? get roundTimeLimit => null;
  int get countdownSeconds => 3;

  // Optional overrides - game hooks
  void onGameStart() {}
  void onGameEnd(bool won, int finalScore) {}
  void onRoundStart() {}
  void onRoundEnd(bool won) {}
  void onCountdownTick(int remaining) {}
  void onTimerTick(Duration remaining) {}

  // Optional override - score calculation
  int calculateRoundScore() => 100;

  /// Start the game with optional countdown
  Future<void> startGame({bool skipCountdown = false}) async {
    if (skipCountdown) {
      _transitionToPlaying();
    } else {
      await _runCountdown();
      _transitionToPlaying();
    }

    _trackGameStart();
  }

  /// Run countdown before game starts
  Future<void> _runCountdown() async {
    setState(() => _phase = GamePhase.countdown);
    GameFeedbackService.tap();

    for (int i = countdownSeconds; i > 0; i--) {
      onCountdownTick(i);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Transition to playing phase
  void _transitionToPlaying() {
    setState(() {
      _phase = GamePhase.playing;
      _round = 1;
    });

    onGameStart();
    onRoundStart();
    
    // Log game started event
    EventLoggingService().logEvent(
      GameEvent.gameStarted(gameId),
    );

    // Start timer if time limit exists
    if (roundTimeLimit != null) {
      startRoundTimer(roundTimeLimit!);
    }
  }

  /// Start a timer for the current round
  void startRoundTimer(Duration duration) {
    _gameTimer?.cancel();
    
    _gameTimer = Timer(duration, () {
      if (mounted && _phase == GamePhase.playing) {
        endRound(won: false, timedOut: true);
      }
    });

    // Optional: Call onTimerTick periodically for UI updates
    // You can add a periodic timer here if needed
  }

  /// End the current round
  void endRound({required bool won, bool timedOut = false}) {
    _gameTimer?.cancel();

    setState(() {
      if (won) {
        _score += calculateRoundScore();
        GameFeedbackService.success();
      } else {
        GameFeedbackService.error();
      }
      _phase = GamePhase.result;
    });

    onRoundEnd(won);

    // Check if game is complete
    if (_round >= totalRounds || (!won && !timedOut)) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          endGame(won: won && _round >= totalRounds);
        }
      });
    }
  }

  /// Start next round
  void nextRound() {
    if (_round >= totalRounds) {
      endGame(won: true);
      return;
    }

    setState(() {
      _round++;
      _phase = GamePhase.playing;
    });

    onRoundStart();

    if (roundTimeLimit != null) {
      startRoundTimer(roundTimeLimit!);
    }
  }

  /// Pause the game
  void pauseGame() {
    _gameTimer?.cancel();
    setState(() => _phase = GamePhase.paused);
  }

  /// Resume the game
  void resumeGame() {
    setState(() => _phase = GamePhase.playing);
    
    if (roundTimeLimit != null) {
      startRoundTimer(roundTimeLimit!);
    }
  }

  /// End the game
  void endGame({required bool won}) {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _phase = GamePhase.completed;
    });

    onGameEnd(won, _score);
    _trackGameEnd(won, _score);
    _recordProgress(won, _score);
    
    // Log game ended event
    EventLoggingService().logEvent(
      GameEvent.gameEnded(
        gameId: gameId,
        won: won,
        score: _score,
      ),
    );
  }

  /// Reset game to initial state
  void resetGame() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _phase = GamePhase.idle;
      _score = 0;
      _round = 0;
    });
  }

  // Analytics tracking
  void _trackGameStart() {
    try {
      context.read<AnalyticsProvider>().trackGameStart(gameId);
    } catch (_) {
      // Analytics not available
    }
  }

  void _trackGameEnd(bool won, int score) {
    try {
      context.read<AnalyticsProvider>().trackGameEnd(completed: won);
    } catch (_) {
      // Analytics not available
    }
  }

  // Progress recording
  void _recordProgress(bool won, int score) {
    try {
      context.read<ProgressProvider>().recordGameResult(
        gameId: gameId,
        won: won,
        xpAward: score,
        analytics: context.read<AnalyticsProvider>(),
      );
    } catch (_) {
      // Progress provider not available
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
