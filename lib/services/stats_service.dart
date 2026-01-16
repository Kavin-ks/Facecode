import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking user game statistics
class StatsService {
  static const String _gamesPrefix = 'stats_games_';
  static const String _winsPrefix = 'stats_wins_';

  /// Get total games played for a user
  static Future<int> getGamesPlayed(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_gamesPrefix$uid') ?? 0;
  }

  /// Get total wins for a user
  static Future<int> getWins(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_winsPrefix$uid') ?? 0;
  }

  /// Increment games played count
  static Future<void> incrementGames(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getGamesPlayed(uid);
    await prefs.setInt('$_gamesPrefix$uid', current + 1);
  }

  /// Increment wins count
  static Future<void> incrementWins(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getWins(uid);
    await prefs.setInt('$_winsPrefix$uid', current + 1);
  }

  /// Reset stats for a user
  static Future<void> resetStats(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_gamesPrefix$uid');
    await prefs.remove('$_winsPrefix$uid');
  }
}
