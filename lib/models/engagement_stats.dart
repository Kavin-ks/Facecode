/// Aggregated statistics for a specific game
class GameEngagementStats {
  final String gameId;
  final int playCount;
  final int totalDurationMs;
  final int completions;
  final int abandons;
  final int sessionsWithGame;

  GameEngagementStats({
    required this.gameId,
    this.playCount = 0,
    this.totalDurationMs = 0,
    this.completions = 0,
    this.abandons = 0,
    this.sessionsWithGame = 0,
  });

  double get averageDurationMs => playCount > 0 ? totalDurationMs / playCount : 0;
  double get abandonRate => playCount > 0 ? (abandons / playCount) * 100 : 0;
  double get replayRate => sessionsWithGame > 0 ? playCount / sessionsWithGame : 0;

  GameEngagementStats copyWith({
    int? playCount,
    int? totalDurationMs,
    int? completions,
    int? abandons,
    int? sessionsWithGame,
  }) {
    return GameEngagementStats(
      gameId: gameId,
      playCount: playCount ?? this.playCount,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      completions: completions ?? this.completions,
      abandons: abandons ?? this.abandons,
      sessionsWithGame: sessionsWithGame ?? this.sessionsWithGame,
    );
  }
}
