import 'dart:math';

class AiHelper {
  static final _rng = Random();

  static const List<String> _names = [
    'Sam', 'Alex', 'Charlie', 'Taylor', 'Jordan', 'Riley', 'Casey', 'Jamie', 'Morgan', 'Drew',
    'Avery', 'Parker', 'Rowan', 'Quinn', 'Reese', 'Blake', 'Elliot', 'Sky', 'Noa', 'Finn'
  ];

  static const List<String> _avatars = ['😀', '😎', '🦊', '🐶', '🐱', '🐼', '🤖', '🐸', '🦄', '🐙'];

  /// Returns a short human-like name prefixed with ai_ id-safe string
  static String generateName() {
    return _names[_rng.nextInt(_names.length)];
  }

  static String generateAvatar() {
    return _avatars[_rng.nextInt(_avatars.length)];
  }

  /// Simple skill tier mapping used by AIs for chances
  static double accuracyForTier(int tier) {
    switch (tier) {
      case 1:
        return 0.6; // casual
      case 2:
        return 0.75; // balanced
      case 3:
      default:
        return 0.85; // sharp
    }
  }

  static int reactionMsForTier(int tier, {int base = 900}) {
    // returns a reaction time sample in ms
    final jitter = _rng.nextInt(base ~/ 2);
    return base + jitter - (tier * 50);
  }
}
