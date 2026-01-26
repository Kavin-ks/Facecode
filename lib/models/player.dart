/// Represents a player in the game
class Player {
  final String id;
  final String name;
  int score;
  bool isHost;
  String? avatar;
  bool isAI;
  bool isAFK;
  int afkStrikes;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
    this.avatar,
    this.isAI = false,
    this.isAFK = false,
    this.afkStrikes = 0,
  });

  /// Create a copy of the player with updated fields
  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isHost,
    String? avatar,
    bool? isAI,
    bool? isAFK,
    int? afkStrikes,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
      avatar: avatar ?? this.avatar,
      isAI: isAI ?? this.isAI,
      isAFK: isAFK ?? this.isAFK,
      afkStrikes: afkStrikes ?? this.afkStrikes,
    );
  }
}
