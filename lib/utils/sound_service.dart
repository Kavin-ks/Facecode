import 'package:flutter/services.dart';

/// Simple sound effects using platform system sounds.
///
/// This avoids shipping audio assets for Version 1.
class SoundService {
  static Future<void> tap() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Ignore platform limitations.
    }
  }

  static Future<void> correct() async {
    try {
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Ignore platform limitations.
    }
  }

  static Future<void> wrong() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore platform limitations.
    }
  }

  static Future<void> roundStart() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Ignore platform limitations.
    }
  }

  static Future<void> roundEnd() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore platform limitations.
    }
  }
}
