import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/models/game_event.dart';

/// Service for logging and querying game events for analytics
class EventLoggingService extends ChangeNotifier {
  static final EventLoggingService _instance = EventLoggingService._internal();
  factory EventLoggingService() => _instance;
  EventLoggingService._internal();

  static const String _storageKey = 'event_log';
  static const int _maxEvents = 1000; // Keep last 1000 events

  final List<GameEvent> _events = [];
  bool _initialized = false;

  /// Get all events
  List<GameEvent> get events => List.unmodifiable(_events);

  /// Get events count
  int get eventCount => _events.length;

  /// Initialize service and load persisted events
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _loadEvents();
    _initialized = true;
    debugPrint('✅ Event logging service initialized with ${_events.length} events');
  }

  /// Log a new event
  Future<void> logEvent(GameEvent event) async {
    _events.add(event);
    
    // Trim if exceeds max
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
    
    await _persistEvents();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('📊 Event logged: ${event.type.name} - ${event.metadata}');
    }
  }

  /// Query events by type
  List<GameEvent> getEventsByType(GameEventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// Query events by game ID
  List<GameEvent> getEventsByGame(String gameId) {
    return _events.where((e) => e.gameId == gameId).toList();
  }

  /// Query events in time range
  List<GameEvent> getEventsInRange(DateTime start, DateTime end) {
    return _events.where((e) {
      return e.timestamp.isAfter(start) && e.timestamp.isBefore(end);
    }).toList();
  }

  /// Get events from last N days
  List<GameEvent> getEventsFromLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Get event statistics
  Map<GameEventType, int> getEventStats() {
    final Map<GameEventType, int> stats = {};
    for (final event in _events) {
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }
    return stats;
  }

  /// Get total XP gained from events
  int getTotalXPGained() {
    return _events
        .where((e) => e.type == GameEventType.xpGained)
        .fold(0, (sum, e) => sum + (e.metadata['amount'] as int? ?? 0));
  }

  /// Get games played count
  int getGamesPlayed() {
    return _events.where((e) => e.type == GameEventType.gameStarted).length;
  }

  /// Get wins count
  int getWinsCount() {
    return _events.where((e) => e.type == GameEventType.gameWon).length;
  }

  /// Get losses count
  int getLossesCount() {
    return _events.where((e) => e.type == GameEventType.gameLost).length;
  }

  /// Get win rate
  double getWinRate() {
    final wins = getWinsCount();
    final losses = getLossesCount();
    final total = wins + losses;
    return total > 0 ? wins / total : 0.0;
  }

  /// Export events as JSON for analytics
  String exportEventsAsJson({DateTime? since}) {
    List<GameEvent> eventsToExport = _events;
    
    if (since != null) {
      eventsToExport = _events.where((e) => e.timestamp.isAfter(since)).toList();
    }
    
    final jsonList = eventsToExport.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Export events as CSV for analytics
  String exportEventsAsCsv({DateTime? since}) {
    List<GameEvent> eventsToExport = _events;
    
    if (since != null) {
      eventsToExport = _events.where((e) => e.timestamp.isAfter(since)).toList();
    }
    
    final buffer = StringBuffer();
    buffer.writeln('id,type,timestamp,game_id,metadata');
    
    for (final event in eventsToExport) {
      buffer.writeln(
        '${event.id},${event.type.name},${event.timestamp.toIso8601String()},'
        '${event.gameId ?? ""},${jsonEncode(event.metadata)}',
      );
    }
    
    return buffer.toString();
  }

  /// Clear all events
  Future<void> clearEvents() async {
    _events.clear();
    await _persistEvents();
    notifyListeners();
    debugPrint('🗑️ Event log cleared');
  }

  /// Clear events older than N days
  Future<void> clearOldEvents(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    _events.removeWhere((e) => e.timestamp.isBefore(cutoff));
    await _persistEvents();
    notifyListeners();
    debugPrint('🗑️ Cleared events older than $days days');
  }

  // Persistence methods
  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _events.clear();
        _events.addAll(jsonList.map((json) => GameEvent.fromJson(json)));
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  Future<void> _persistEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error persisting events: $e');
    }
  }
}
