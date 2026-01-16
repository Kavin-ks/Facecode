/// Emoji categories used by FaceCode.
///
/// Kept intentionally small + curated for fast gameplay.
class EmojiCatalog {
  static const String faces = 'Faces';
  static const String objects = 'Objects';
  static const String places = 'Places';

  static const List<String> categories = [faces, objects, places];

  static const Map<String, List<String>> emojisByCategory = {
    faces: [
      '😀', '😃', '😄', '😁', '😆', '🤣', '😂', '🙂', '😉', '😊', '😍', '🤩',
      '😘', '😜', '🤔', '😮', '😱', '😭', '😡', '😎', '🤯', '🥳', '🤫', '🤐',
      '👀', '🧠', '💤', '💯', '❤️', '💔',
    ],
    objects: [
      '📱', '💻', '🎧', '🎤', '🎬', '📷', '🔑', '💡', '🧨', '🧲', '💣', '🎁',
      '🎈', '🎉', '🧩', '🎲', '🕹️', '🎮', '🚗', '✈️', '🚀', '⚽', '🏀', '🎾',
      '🍕', '🍔', '🍟', '🍿', '🎂', '☕',
    ],
    places: [
      '🏠', '🏙️', '🏝️', '🏜️', '⛰️', '🌋', '🏰', '🏟️', '🎡', '🎢', '🏖️',
      '🗽', '🗼', '🗿', '🌉', '🌃', '🌌', '🌅', '🌧️', '⛈️', '❄️', '🌈',
      '🛣️', '🛤️', '🚦', '🚧',
    ],
  };

  static List<String> getEmojis(String category) {
    return emojisByCategory[category] ?? const [];
  }
}
