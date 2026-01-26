/// Base game state model for all mini-games
/// Provides standardized game phases and common state properties
library;

enum GamePhase {
  idle,       // Game not started
  ready,      // Waiting to start
  countdown,  // Pre-game countdown (3, 2, 1...)
  playing,    // Active gameplay
  paused,     // Temporarily paused
  result,     // Showing round/game results
  completed,  // Game finished
}

/// Standardized game state that all games can use
class BaseGameState {
  final GamePhase phase;
  final int score;
  final int round;
  final int totalRounds;
  final Duration? timeLimit;
  final Duration? timeElapsed;
  final bool won;
  final Map<String, dynamic> customData;

  const BaseGameState({
    this.phase = GamePhase.idle,
    this.score = 0,
    this.round = 0,
    this.totalRounds = 1,
    this.timeLimit,
    this.timeElapsed,
    this.won = false,
    this.customData = const {},
  });

  /// Computed properties
  bool get isPlaying => phase == GamePhase.playing;
  bool get isPaused => phase == GamePhase.paused;
  bool get isFinished => phase == GamePhase.completed;
  bool get hasTimeLimit => timeLimit != null;
  
  double get progress => totalRounds > 0 ? round / totalRounds : 0;
  
  Duration? get timeRemaining {
    if (timeLimit == null || timeElapsed == null) return null;
    final remaining = timeLimit! - timeElapsed!;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Create a copy with updated fields
  BaseGameState copyWith({
    GamePhase? phase,
    int? score,
    int? round,
    int? totalRounds,
    Duration? timeLimit,
    Duration? timeElapsed,
    bool? won,
    Map<String, dynamic>? customData,
  }) {
    return BaseGameState(
      phase: phase ?? this.phase,
      score: score ?? this.score,
      round: round ?? this.round,
      totalRounds: totalRounds ?? this.totalRounds,
      timeLimit: timeLimit ?? this.timeLimit,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      won: won ?? this.won,
      customData: customData ?? this.customData,
    );
  }

  @override
  String toString() {
    return 'BaseGameState(phase: $phase, score: $score, round: $round/$totalRounds)';
  }
}
