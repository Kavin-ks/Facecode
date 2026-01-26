import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/utils/theme.dart';
import 'package:facecode/services/sound_manager.dart';

class SettingsProvider with ChangeNotifier {
  // Theme
  AppThemeMode _themeMode = AppThemeMode.dark;
  Color? _accentColor; // If null, use default
  bool _reduceMotion = false;
  bool _hapticsEnabled = true;

  // Sound
  bool _uiSounds = true;
  bool _gameSounds = true;
  bool _celebrationSounds = true;
  bool _bgMusic = false;

  // Global AI fallback toggle (if true, multiplayer games will add AI players when needed)
  bool _aiFallback = true;
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.5;

  // Getters
  AppThemeMode get themeMode => _themeMode;
  Color? get accentColor => _accentColor;
  bool get reduceMotion => _reduceMotion;
  bool get hapticsEnabled => _hapticsEnabled;
  
  bool get uiSounds => _uiSounds;
  bool get gameSounds => _gameSounds;
  bool get celebrationSounds => _celebrationSounds;
  bool get bgMusic => _bgMusic;
  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  bool get aiFallback => _aiFallback;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = AppThemeMode.values[themeIndex];
    final accentValue = prefs.getInt('accent_color');
    if (accentValue != null) _accentColor = Color(accentValue);
    _reduceMotion = prefs.getBool('reduce_motion') ?? false;
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;

    // Sound
    _uiSounds = prefs.getBool('ui_sounds') ?? true;
    _gameSounds = prefs.getBool('game_sounds') ?? true;
    _celebrationSounds = prefs.getBool('celeb_sounds') ?? true;
    _bgMusic = prefs.getBool('bg_music') ?? false;
    _masterVolume = prefs.getDouble('master_vol') ?? 1.0;
    _sfxVolume = prefs.getDouble('sfx_vol') ?? 1.0;
    _musicVolume = prefs.getDouble('music_vol') ?? 0.5;

    // AI Fallback
    _aiFallback = prefs.getBool('ai_fallback') ?? true;

    // We don't load sound pack from preferences because it's in UserProgress (Shop)
    // SettingsProvider should be updated via notifyListeners from someone watching ProgressProvider.

    // Init Sound Manager
    await SoundManager().init();
    _pushSoundSettings();

    notifyListeners();
  }
  
  void setSoundPack(String? id) {
    SoundManager().setSoundPack(id);
    notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) await prefs.setInt(key, value);
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  // --- Theme Actions ---

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _saveSetting('theme_mode', mode.index);
    notifyListeners();
  }

  void setAccentColor(Color? color) {
    _accentColor = color;
    if (color != null) {
      try {
         // ignore: deprecated_member_use
         _saveSetting('accent_color', color.value); 
      } catch (_) {}
    } else {
      SharedPreferences.getInstance().then((p) => p.remove('accent_color'));
    }
    notifyListeners();
  }

  void toggleReduceMotion(bool val) {
    _reduceMotion = val;
    _saveSetting('reduce_motion', val);
    notifyListeners();
  }

  void toggleHaptics(bool val) {
    _hapticsEnabled = val;
    _saveSetting('haptics_enabled', val);
    _pushSoundSettings();
    notifyListeners();
  }

  // --- Sound Actions ---

  void setUiSounds(bool val) {
    _uiSounds = val;
    _saveSetting('ui_sounds', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setGameSounds(bool val) {
    _gameSounds = val;
    _saveSetting('game_sounds', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setCelebrationSounds(bool val) {
    _celebrationSounds = val;
    _saveSetting('celeb_sounds', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setBgMusic(bool val) {
    _bgMusic = val;
    _saveSetting('bg_music', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setMasterVolume(double val) {
    _masterVolume = val;
    _saveSetting('master_vol', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setSfxVolume(double val) {
    _sfxVolume = val;
    _saveSetting('sfx_vol', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setMusicVolume(double val) {
    _musicVolume = val;
    _saveSetting('music_vol', val);
    _pushSoundSettings();
    notifyListeners();
  }

  void setAiFallback(bool val) {
    _aiFallback = val;
    _saveSetting('ai_fallback', val);
    notifyListeners();
  }

  void _pushSoundSettings() {
    SoundManager().updateSettings(
      uiEnabled: _uiSounds,
      gameEnabled: _gameSounds,
      celebrationEnabled: _celebrationSounds,
      hapticsEnabled: _hapticsEnabled,
      musicEnabled: _bgMusic,
      masterVol: _masterVolume,
      sfxVol: _sfxVolume,
      musicVol: _musicVolume,
    );
  }
}
