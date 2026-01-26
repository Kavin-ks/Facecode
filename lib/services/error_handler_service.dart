import 'package:flutter/foundation.dart';

/// Global error handler service that captures and logs errors
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final List<ErrorLogEntry> _errorLog = [];
  final int _maxLogSize = 50;

  /// Get recent errors for debugging
  List<ErrorLogEntry> get recentErrors => List.unmodifiable(_errorLog);

  /// Initialize global error handlers
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _instance._logError(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework',
        library: details.library,
      );
    };

    // Catch async errors outside Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._logError(
        error: error,
        stackTrace: stack,
        context: 'Async',
      );
      return true; // Prevent app from crashing
    };

    debugPrint('✅ Global error handling initialized');
  }

  /// Log an error with context
  void _logError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? library,
  }) {
    final entry = ErrorLogEntry(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context,
      library: library,
    );

    _errorLog.insert(0, entry);
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeLast();
    }

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('🔴 ERROR [${entry.context}]: ${entry.error}');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }

    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  }

  /// Manually report an error
  void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    _logError(
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'Manual Report',
    );
  }

  /// Clear error log
  void clearLog() {
    _errorLog.clear();
  }
}

/// Error log entry
class ErrorLogEntry {
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String? context;
  final String? library;

  ErrorLogEntry({
    required this.error,
    this.stackTrace,
    required this.timestamp,
    this.context,
    this.library,
  });

  String get errorMessage => error.toString();

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
