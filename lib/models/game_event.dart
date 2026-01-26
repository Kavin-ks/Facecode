/// Event types for analytics tracking
enum GameEventType {
  // Game lifecycle
  gameStarted,
  gameEnded,
  gameAbandoned,
  
  // Game outcomes
  gameWon,
  gameLost,
  roundCompleted,
  
  // Progression
  xpGained,
  levelUp,
  badgeUnlocked,
  achievementEarned,
  
  // Social
  multiplayerJoined,
  multiplayerCreated,
  emojiSent,
  
  // Monetization (future)
  shopVisited,
  itemPurchased,
  
  // Engagement
  dailyStreakContinued,
  dailyStreakBroken,
  tutorialCompleted,
}

/// Game event model for analytics
class GameEvent {
  final String id;
  final GameEventType type;
  final DateTime timestamp;
  final String? gameId;
  final Map<String, dynamic> metadata;

  const GameEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.gameId,
    this.metadata = const {},
  });

  /// Create event from specific action
  factory GameEvent.gameStarted(String gameId, {Map<String, dynamic>? extra}) {
    return GameEvent(
      id: _generateId(),
      type: GameEventType.gameStarted,
      timestamp: DateTime.now(),
      gameId: gameId,
      metadata: extra ?? {},
    );
  }

  factory GameEvent.gameEnded({
    required String gameId,
    required bool won,
    required int score,
    int? duration,
    Map<String, dynamic>? extra,
  }) {
    return GameEvent(
      id: _generateId(),
      type: won ? GameEventType.gameWon : GameEventType.gameLost,
      timestamp: DateTime.now(),
      gameId: gameId,
      metadata: {
        'won': won,
        'score': score,
        if (duration != null) 'duration_ms': duration,
        ...?extra,
      },
    );
  }

  factory GameEvent.xpGained({
    required int amount,
    required String source,
    Map<String, dynamic>? extra,
  }) {
    return GameEvent(
      id: _generateId(),
      type: GameEventType.xpGained,
      timestamp: DateTime.now(),
      metadata: {
        'amount': amount,
        'source': source,
        ...?extra,
      },
    );
  }

  factory GameEvent.levelUp({
    required int newLevel,
    required int totalXP,
  }) {
    return GameEvent(
      id: _generateId(),
      type: GameEventType.levelUp,
      timestamp: DateTime.now(),
      metadata: {
        'level': newLevel,
        'total_xp': totalXP,
      },
    );
  }

  factory GameEvent.badgeUnlocked({
    required String badgeId,
    required String badgeName,
  }) {
    return GameEvent(
      id: _generateId(),
      type: GameEventType.badgeUnlocked,
      timestamp: DateTime.now(),
      metadata: {
        'badge_id': badgeId,
        'badge_name': badgeName,
      },
    );
  }

  factory GameEvent.roundCompleted({
    required String gameId,
    required int round,
    required bool won,
    int? score,
  }) {
    return GameEvent(
      id: _generateId(),
      type: GameEventType.roundCompleted,
      timestamp: DateTime.now(),
      gameId: gameId,
      metadata: {
        'round': round,
        'won': won,
        if (score != null) 'score': score,
      },
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      if (gameId != null) 'game_id': gameId,
      'metadata': metadata,
    };
  }

  /// Deserialize from JSON
  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'] as String,
      type: GameEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GameEventType.gameStarted,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      gameId: json['game_id'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  @override
  String toString() {
    return 'GameEvent(type: ${type.name}, gameId: $gameId, metadata: $metadata)';
  }
}
