/// Represents a player in the game
class Player {
  final String id;
  final String name;
  int score;
  bool isHost;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
  });

  /// Create a copy of the player with updated fields
  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isHost,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
    );
  }
}
