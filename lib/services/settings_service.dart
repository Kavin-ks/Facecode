import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for app settings.
class SettingsService {
  // Notification keys
  static const String _kNotifEnabled = 'notif_enabled';
  static const String _kNotifSound = 'notif_sound';
  static const String _kNotifVibrate = 'notif_vibrate';

  // Privacy keys
  static const String _kPrivacyPublicProfile = 'privacy_public_profile';
  static const String _kPrivacyShowOnline = 'privacy_show_online';

  // Defaults
  static const bool _dTrue = true;

  // ───────────────────────── Notifications ─────────────────────────
  static Future<bool> getNotificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotifEnabled) ?? _dTrue;
  }

  static Future<void> setNotificationsEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifEnabled, v);
  }

  static Future<bool> getNotificationSound() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotifSound) ?? _dTrue;
  }

  static Future<void> setNotificationSound(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifSound, v);
  }

  static Future<bool> getNotificationVibrate() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotifVibrate) ?? _dTrue;
  }

  static Future<void> setNotificationVibrate(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifVibrate, v);
  }

  // ────────────────────────── Privacy ──────────────────────────
  static Future<bool> getPublicProfile() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPrivacyPublicProfile) ?? _dTrue;
  }

  static Future<void> setPublicProfile(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPrivacyPublicProfile, v);
  }

  static Future<bool> getShowOnline() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPrivacyShowOnline) ?? _dTrue;
  }

  static Future<void> setShowOnline(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPrivacyShowOnline, v);
  }

  // Convenience: load all at once
  static Future<Map<String, bool>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    return {
      _kNotifEnabled: p.getBool(_kNotifEnabled) ?? _dTrue,
      _kNotifSound: p.getBool(_kNotifSound) ?? _dTrue,
      _kNotifVibrate: p.getBool(_kNotifVibrate) ?? _dTrue,
      _kPrivacyPublicProfile: p.getBool(_kPrivacyPublicProfile) ?? _dTrue,
      _kPrivacyShowOnline: p.getBool(_kPrivacyShowOnline) ?? _dTrue,
    };
  }
}
