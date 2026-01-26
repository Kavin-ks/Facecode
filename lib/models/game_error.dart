/// Error types that can be surfaced to the UI.
///
/// Even though FaceCode is local multiplayer (V1), some types represent future
/// networked versions; they are included so UI can handle them consistently.
enum GameErrorType {
  validation,
  roomNotFound,
  timeExpired,
  network,
  disconnect,
  invalidEmoji,
  unknown,
}

/// UI-friendly error object shown as a dialog.
class GameError {
  final GameErrorType type;
  final String title;
  final String message;
  final String actionLabel;
  final String? illustrationAsset; 

  const GameError({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel = 'OK',
    this.illustrationAsset,
  });
}
