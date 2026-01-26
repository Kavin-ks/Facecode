/// Model for a specific game instance within a session
class GameSession {
  final String gameId;
  final DateTime startTime;
  final int durationMs;
  final bool completed;

  const GameSession({
    required this.gameId,
    required this.startTime,
    this.durationMs = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'startTime': startTime.toIso8601String(),
    'durationMs': durationMs,
    'completed': completed,
  };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
    gameId: json['gameId'],
    startTime: DateTime.parse(json['startTime']),
    durationMs: json['durationMs'] ?? 0,
    completed: json['completed'] ?? false,
  );
}
