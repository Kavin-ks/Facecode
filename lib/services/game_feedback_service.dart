import 'package:facecode/services/sound_manager.dart';

/// Centralized haptic + sound feedback for games.
/// Now delegates to SoundManager for unified control.
class GameFeedbackService {
  static Future<void> tap() async {
    // SoundManager taps usually happen in onTap. This is for explicit logic taps.
    // If SoundManager is already handling UI taps via buttons, this might be redundant,
    // but useful for game interactions that feel like taps.
    SoundManager().playUiSound(SoundManager.sfxUiTap, haptic: HapticType.selection, priority: SoundPriority.low);
  }

  static Future<void> success() async {
    SoundManager().triggerHaptic(HapticType.medium);
    SoundManager().playUiSound(SoundManager.sfxUiSuccess, priority: SoundPriority.high); 
  }

  static Future<void> error() async {
    SoundManager().triggerHaptic(HapticType.heavy);
    SoundManager().playUiSound(SoundManager.sfxUiError, priority: SoundPriority.high);
  }

  static Future<void> tick() async {
    SoundManager().triggerHaptic(HapticType.light);
    SoundManager().playGameSound(SoundManager.sfxTimerTick, volumeScale: 0.5, priority: SoundPriority.low);
  }

  static Future<void> coinGain() async {
    SoundManager().triggerHaptic(HapticType.selection);
    // Use Xp Gain sound for now as it's sparkly
    SoundManager().playGameSound(SoundManager.sfxXpGain, volumeScale: 0.8);
  }

  static Future<void> streakMilestone() async {
    SoundManager().triggerHaptic(HapticType.medium);
    SoundManager().playGameSound(SoundManager.sfxBadgeUnlock, volumeScale: 0.7);
  }

  static Future<void> turnStart() async {
    SoundManager().triggerHaptic(HapticType.medium);
    SoundManager().playGameSound(SoundManager.sfxTurnChange, priority: SoundPriority.high);
  }
}
