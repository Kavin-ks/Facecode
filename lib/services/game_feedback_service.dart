import 'package:flutter/services.dart';

/// Centralized haptic + sound feedback for games.
class GameFeedbackService {
  static Future<void> tap() async {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static Future<void> error() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> tick() async {
    HapticFeedback.lightImpact();
  }
}
