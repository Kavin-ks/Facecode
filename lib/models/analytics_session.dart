import 'package:facecode/models/game_session.dart';

/// Model for an app-wide user session
class AnalyticsSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<GameSession> gameSessions;
  final String? exitRoute;

  const AnalyticsSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.gameSessions = const [],
    this.exitRoute,
  });

  int get totalDurationMs {
    if (endTime == null) return DateTime.now().difference(startTime).inMilliseconds;
    return endTime!.difference(startTime).inMilliseconds;
  }

  AnalyticsSession copyWith({
    DateTime? endTime,
    List<GameSession>? gameSessions,
    String? exitRoute,
  }) {
    return AnalyticsSession(
      sessionId: sessionId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      gameSessions: gameSessions ?? this.gameSessions,
      exitRoute: exitRoute ?? this.exitRoute,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'gameSessions': gameSessions.map((s) => s.toJson()).toList(),
    'exitRoute': exitRoute,
  };

  factory AnalyticsSession.fromJson(Map<String, dynamic> json) => AnalyticsSession(
    sessionId: json['sessionId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    gameSessions: (json['gameSessions'] as List?)
        ?.map((s) => GameSession.fromJson(s))
        .toList() ?? const [],
    exitRoute: json['exitRoute'],
  );
}
