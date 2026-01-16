import 'dart:math';

/// Generate a random room code
class RoomCodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _random = Random();

  /// Generate a 6-character room code
  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }
}
