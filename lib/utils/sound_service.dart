import 'package:flutter/services.dart';
import 'package:facecode/services/sound_manager.dart';

/// Wrapper to bridge legacy calls to new SoundManager
class SoundService {
  static Future<void> tap() async {
    try {
      await HapticFeedback.lightImpact();
      // SoundManager().playUiSound(SoundManager.sfxUiTap); // Redundant if buttons handle it
    } catch (_) {}
  }

  static Future<void> correct() async {
    try {
      await HapticFeedback.mediumImpact();
      SoundManager().playGameSound(SoundManager.sfxCorrect);
    } catch (_) {}
  }

  static Future<void> wrong() async {
    try {
      await HapticFeedback.heavyImpact();
      SoundManager().playGameSound(SoundManager.sfxGameFail);
    } catch (_) {}
  }

  static Future<void> roundStart() async {
    try {
      await HapticFeedback.selectionClick();
      SoundManager().playGameSound(SoundManager.sfxGameStart);
    } catch (_) {}
  }

  static Future<void> roundEnd() async {
    try {
      await HapticFeedback.mediumImpact();
      // Neutral sound or handled by specific result logic
    } catch (_) {}
  }
}
