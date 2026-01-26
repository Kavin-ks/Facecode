import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for standardized game data persistence
/// Provides consistent save/load patterns for all games
class GamePersistenceHelper {
  /// Save best score for a game
  static Future<void> saveBestScore(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${gameId}_best_score', score);
  }

  /// Load best score for a game
  static Future<int> loadBestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameId}_best_score') ?? 0;
  }

  /// Save game history (list of scores/times)
  static Future<void> saveHistory(String gameId, List<int> values) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = values.map((v) => v.toString()).toList();
    await prefs.setStringList('${gameId}_history', stringList);
  }

  /// Load game history
  static Future<List<int>> loadHistory(String gameId, {int maxItems = 100}) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList('${gameId}_history') ?? [];
    final values = stringList
        .map((s) => int.tryParse(s) ?? 0)
        .where((v) => v > 0)
        .toList();
    
    // Limit to maxItems
    if (values.length > maxItems) {
      return values.sublist(values.length - maxItems);
    }
    return values;
  }

  /// Save daily progress for a game
  static Future<void> saveDailyProgress(String gameId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final key = '${gameId}_daily_$today';
    
    // Save as JSON-like string (simple implementation)
    final entries = data.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(key, entries);
  }

  /// Load daily progress for a game
  static Future<Map<String, dynamic>> loadDailyProgress(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final key = '${gameId}_daily_$today';
    
    final data = prefs.getString(key);
    if (data == null || data.isEmpty) return {};
    
    // Parse simple key:value format
    final Map<String, dynamic> result = {};
    for (final entry in data.split(',')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0]] = int.tryParse(parts[1]) ?? parts[1];
      }
    }
    return result;
  }

  /// Clear all data for a game
  static Future<void> clearGameData(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(gameId));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Save a single game stat
  static Future<void> saveStat(String gameId, String statName, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${gameId}_$statName', value);
  }

  /// Load a single game stat
  static Future<int> loadStat(String gameId, String statName, {int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameId}_$statName') ?? defaultValue;
  }

  /// Increment a stat (useful for counters)
  static Future<int> incrementStat(String gameId, String statName, {int by = 1}) async {
    final current = await loadStat(gameId, statName);
    final newValue = current + by;
    await saveStat(gameId, statName, newValue);
    return newValue;
  }
}
