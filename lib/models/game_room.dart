import 'player.dart';
import 'game_prompt.dart';

/// Game states
enum GameState {
  lobby,
  playing,
  results,
}

/// Represents a game room
class GameRoom {
  final String roomCode;
  final List<Player> players;
  GameState state;
  int currentEmojiPlayerIndex;
  GamePrompt? currentPrompt;
  List<String> emojiMessages;
  int roundTimeRemaining;

  GameRoom({
    required this.roomCode,
    this.players = const [],
    this.state = GameState.lobby,
    this.currentEmojiPlayerIndex = 0,
    this.currentPrompt,
    this.emojiMessages = const [],
    this.roundTimeRemaining = 60,
  });

  /// Get the current emoji player
  Player? get currentEmojiPlayer {
    if (players.isEmpty) return null;
    return players[currentEmojiPlayerIndex % players.length];
  }

  /// Check if a specific player is the emoji player
  bool isEmojiPlayer(String playerId) {
    return currentEmojiPlayer?.id == playerId;
  }

  /// Create a copy with updated fields
  GameRoom copyWith({
    String? roomCode,
    List<Player>? players,
    GameState? state,
    int? currentEmojiPlayerIndex,
    GamePrompt? currentPrompt,
    List<String>? emojiMessages,
    int? roundTimeRemaining,
  }) {
    return GameRoom(
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      state: state ?? this.state,
      currentEmojiPlayerIndex:
          currentEmojiPlayerIndex ?? this.currentEmojiPlayerIndex,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      emojiMessages: emojiMessages ?? this.emojiMessages,
      roundTimeRemaining: roundTimeRemaining ?? this.roundTimeRemaining,
    );
  }
}
