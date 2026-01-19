import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages user preferences: favorites and recently played games
class UserPreferencesProvider with ChangeNotifier {
  final Set<String> _favoriteGameIds = {};
  final List<String> _recentlyPlayedIds = [];
  
  static const String _favoritesKey = 'favorite_games';
  static const String _recentlyPlayedKey = 'recently_played_games';
  static const int _maxRecentGames = 10;

  UserPreferencesProvider() {
    _loadPreferences();
  }

  Set<String> get favoriteGameIds => _favoriteGameIds;
  List<String> get recentlyPlayedIds => _recentlyPlayedIds;

  bool isFavorite(String gameId) => _favoriteGameIds.contains(gameId);

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load favorites
    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson != null) {
      final favoritesList = List<String>.from(jsonDecode(favoritesJson));
      _favoriteGameIds.addAll(favoritesList);
    }

    // Load recently played
    final recentJson = prefs.getString(_recentlyPlayedKey);
    if (recentJson != null) {
      final recentList = List<String>.from(jsonDecode(recentJson));
      _recentlyPlayedIds.addAll(recentList);
    }

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favoriteGameIds.toList()));
    await prefs.setString(_recentlyPlayedKey, jsonEncode(_recentlyPlayedIds));
  }

  Future<void> toggleFavorite(String gameId) async {
    if (_favoriteGameIds.contains(gameId)) {
      _favoriteGameIds.remove(gameId);
    } else {
      _favoriteGameIds.add(gameId);
    }
    await _savePreferences();
    notifyListeners();
  }

  Future<void> addToRecentlyPlayed(String gameId) async {
    // Remove if already exists
    _recentlyPlayedIds.remove(gameId);
    
    // Add to front
    _recentlyPlayedIds.insert(0, gameId);
    
    // Keep only max recent games
    if (_recentlyPlayedIds.length > _maxRecentGames) {
      _recentlyPlayedIds.removeRange(_maxRecentGames, _recentlyPlayedIds.length);
    }

    await _savePreferences();
    notifyListeners();
  }

  void clearRecentlyPlayed() {
    _recentlyPlayedIds.clear();
    _savePreferences();
    notifyListeners();
  }
}
