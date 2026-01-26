import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

enum SoundCategory { ui, game, ambient }

enum HapticType { none, light, medium, heavy, selection }
enum SoundPriority { low, normal, high, critical }

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  // Multiple players for overlapping game sounds
  final List<AudioPlayer> _sfxPlayers = List.generate(5, (_) => AudioPlayer());
  int _currentSfxIndex = 0;
  
  // Dedicated UI player (usually short clicks dont need much overlap, but let's have 2)
  final List<AudioPlayer> _uiPlayers = List.generate(2, (_) => AudioPlayer());
  int _currentUiIndex = 0;

  // Settings
  bool _isUiSoundEnabled = true;
  bool _isGameSoundEnabled = true;
  bool _isCelebrationSoundEnabled = true;
  bool _isMusicEnabled = false;
  bool _isHapticsEnabled = true;
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.5;
  String? _currentSoundPackId;

  // Cache of available assets from manifest
  final Set<String> _availableAssets = {};
  final Map<String, String> _resolvedPaths = {};

  // Debounce/Throttle Map
  final Map<String, int> _lastPlayedTimes = {};
  int _lastHighPriorityTime = 0;
  
  // Assets definition (Extensions removed for auto-detection)
  static const String sfxUiTap = 'audio/ui_tap';
  static const String sfxUiSelect = 'audio/ui_select';
  static const String sfxUiSwitch = 'audio/ui_switch';
  static const String sfxUiSuccess = 'audio/ui_success_chime';
  static const String sfxUiError = 'audio/ui_error_thud';
  static const String sfxUiWhoosh = 'audio/ui_whoosh';
  
  static const String sfxGameStart = 'audio/game_start';
  static const String sfxGameWin = 'audio/game_win';
  static const String sfxGameFail = 'audio/game_fail';
  static const String sfxTimerTick = 'audio/timer_tick';
  static const String sfxTurnChange = 'audio/turn_change';
  static const String sfxCorrect = 'audio/correct'; 
  static const String sfxGameOver = 'audio/game_fail'; // Alias
  static const String sfxPop = 'audio/pop';
  static const String sfxCardFlip = 'audio/card_flip';
  
  static const String sfxXpGain = 'audio/xp_gain_sparkle';
  static const String sfxLevelUp = 'audio/level_up_celeb';
  static const String sfxBadgeUnlock = 'audio/badge_unlock_chime';

  static const String sfxPlayerJoin = 'audio/player_join_pop';
  static const String sfxPlayerLeave = 'audio/player_leave_fade';
  static const String sfxChatMessage = 'audio/chat_tick';

  static const String musicAmbient = 'audio/ambient_loop';

  Future<void> init() async {
    // Load asset manifest to detect available formats
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);
      _availableAssets.addAll(manifestMap.keys);
    } catch (_) {
      debugPrint("Warning: Could not load AssetManifest.");
    }

    // Configure audio context
    await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
    
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Preload critical interaction sounds
    await _preload([sfxUiTap, sfxUiSwitch, sfxUiSuccess, sfxGameStart, sfxCorrect]);
  }

  Future<void> _preload(List<String> keys) async {
    for (final key in keys) {
      final path = _resolvePath(key);
      if (path != null) {
        // Just standard cache warming handled by AudioPlayers
        // Or play silent to warm up if needed, but modern engines handle this okay.
        // We will just resolve them now to populate cache map.
      }
    }
  }

  /// returns path with extension if found, else null
  String? _resolvePath(String baseKey) {
    // 1. Try Sound Pack Path if active
    if (_currentSoundPackId != null) {
       final packKey = baseKey.replaceFirst('audio/', 'audio/$_currentSoundPackId/');
       final packPath = _doResolve(packKey);
       if (packPath != null) return packPath;
    }

    // 2. Default Path
    return _doResolve(baseKey);
  }

  String? _doResolve(String key) {
    if (_resolvedPaths.containsKey(key)) return _resolvedPaths[key];

    final extensions = ['.mp3', '.wav', '.ogg'];
    for (final ext in extensions) {
      final candidate = '$key$ext';
      if (_availableAssets.contains(candidate)) {
        _resolvedPaths[key] = candidate;
        return candidate;
      }
      if (_availableAssets.contains('assets/$candidate')) {
         _resolvedPaths[key] = 'assets/$candidate';
         return 'assets/$candidate';
      }
    }
    return null;
  }

  void setSoundPack(String? id) {
    if (_currentSoundPackId == id) return;
    _currentSoundPackId = id;
    _resolvedPaths.clear(); // Force re-resolution
    
    // Preload critical sounds with new pack
    if (id != null) {
      _preload([sfxUiTap, sfxUiSwitch, sfxUiSuccess, sfxGameStart, sfxCorrect]);
    }
  }

  void updateSettings({
    required bool uiEnabled,
    required bool gameEnabled,
    required bool musicEnabled,
    required bool celebrationEnabled,
    required bool hapticsEnabled,
    required double masterVol,
    required double sfxVol,
    required double musicVol,
  }) {
    _isUiSoundEnabled = uiEnabled;
    _isGameSoundEnabled = gameEnabled;
    _isMusicEnabled = musicEnabled;
    _isCelebrationSoundEnabled = celebrationEnabled;
    _isHapticsEnabled = hapticsEnabled;
    _masterVolume = masterVol;
    _sfxVolume = sfxVol;
    _musicVolume = musicVol;

    _updatePlayerVolumes();
    
    if (_isMusicEnabled) {
      if (_musicPlayer.state != PlayerState.playing) {
        playMusic(musicAmbient);
      }
    } else {
      stopMusic();
    }
  }

  void _updatePlayerVolumes() {
    final effectiveSfxVol = _sfxVolume * _masterVolume;
    final effectiveMusicVol = _musicVolume * _masterVolume;

    _musicPlayer.setVolume(effectiveMusicVol);
    for (var p in _sfxPlayers) {
      p.setVolume(effectiveSfxVol);
    }
    for (var p in _uiPlayers) {
      p.setVolume(effectiveSfxVol);
    }
  }

  /// Plays a UI sound (click, tap, toggle)
  Future<void> playUiSound(String baseKey, {int throttleMs = 50, HapticType haptic = HapticType.none, SoundPriority priority = SoundPriority.normal}) async {
    if (haptic != HapticType.none) _triggerHaptic(haptic);

    if (!_isUiSoundEnabled) return;
    
    // Priority Gating (Ducking)
    if (_shouldSuppress(priority)) return;

    if (_shouldSkip(baseKey, throttleMs)) return;

    final path = _resolvePath(baseKey);
    if (path == null) return;

    try {
      final player = _uiPlayers[_currentUiIndex];
      await player.stop(); 
      await player.setVolume(_sfxVolume * _masterVolume);
      await player.play(AssetSource(path.replaceFirst('assets/', '')), mode: PlayerMode.lowLatency);
      _currentUiIndex = (_currentUiIndex + 1) % _uiPlayers.length;
      
      _updatePriority(priority);
    } catch (_) {}
  }

  /// Plays a Gameplay sound (win, fail, tick)
  Future<void> playGameSound(String baseKey, {double volumeScale = 1.0, int throttleMs = 0, HapticType haptic = HapticType.none, SoundPriority priority = SoundPriority.normal}) async {
    if (haptic != HapticType.none) _triggerHaptic(haptic);

    if (!_isGameSoundEnabled) return;
    
    if (!_isCelebrationSoundEnabled && (baseKey == sfxLevelUp || baseKey == sfxBadgeUnlock)) {
      return;
    }

    // Priority Gating (Ducking)
    if (_shouldSuppress(priority)) return;

    if (throttleMs > 0 && _shouldSkip(baseKey, throttleMs)) return;

    final path = _resolvePath(baseKey);
    if (path == null) return;

    try {
      final player = _sfxPlayers[_currentSfxIndex];
      await player.setVolume(_sfxVolume * _masterVolume * volumeScale);
      await player.play(AssetSource(path.replaceFirst('assets/', '')), mode: PlayerMode.lowLatency);
      _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPlayers.length;
      
      _updatePriority(priority);
    } catch (e) {
      debugPrint("Game SFX Error: $e");
    }
  }
  
  void triggerHaptic(HapticType type) => _triggerHaptic(type);

  Future<void> _triggerHaptic(HapticType type) async {
    if (!_isHapticsEnabled) return;
    try {
      switch (type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticType.none:
          break;
      }
    } catch (e) {
      // Gracefully disable haptics on errors/unsupported devices
      debugPrint('Haptic feedback failed or unsupported: $e');
    }
  }

  /// Helper to check throttling
  bool _shouldSkip(String key, int throttleMs) {
    if (throttleMs <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedTimes[key] ?? 0;
    
    if (now - last < throttleMs) {
      return true; // Skip
    }
    
    _lastPlayedTimes[key] = now;
    return false;
  }
  
  bool _shouldSuppress(SoundPriority priority) {
    if (priority == SoundPriority.critical || priority == SoundPriority.high) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    // Suppress low sounds if a high/critical sound played recently (e.g. within 500ms)
    // "Ducking" logic: clean up chaos.
    if (now - _lastHighPriorityTime < 500) {
      return true; 
    }
    return false;
  }
  
  void _updatePriority(SoundPriority priority) {
    if (priority == SoundPriority.high || priority == SoundPriority.critical) {
      _lastHighPriorityTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<void> playMusic(String baseKey) async {
    if (!_isMusicEnabled) return;
    if (_musicPlayer.state == PlayerState.playing) return;

    final path = _resolvePath(baseKey);
    if (path == null) return;

    try {
      // Fade In Effect for Premium Feel
      await _musicPlayer.setVolume(0); 
      await _musicPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
      
      // Animate volume to target over 800ms
      final target = _musicVolume * _masterVolume;
      const steps = 10;
      const stepDuration = Duration(milliseconds: 80);
      final stepVol = target / steps;
      
      for (int i = 1; i <= steps; i++) {
        if (!_isMusicEnabled) break; // formatting safeguard
        await Future.delayed(stepDuration);
        await _musicPlayer.setVolume(stepVol * i);
      }
      
    } catch (e) {
      debugPrint("Music Error: $e");
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }
}
