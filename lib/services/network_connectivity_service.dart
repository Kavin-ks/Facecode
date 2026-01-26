import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity service that monitors network status and provides retry logic
class NetworkConnectivityService extends ChangeNotifier {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _hasEverBeenOnline = false;
  DateTime? _lastOnlineTime;
  final List<VoidCallback> _reconnectionCallbacks = [];

  /// Current online status
  bool get isOnline => _isOnline;

  /// Has the app ever had network connection
  bool get hasEverBeenOnline => _hasEverBeenOnline;

  /// Time when app was last online
  DateTime? get lastOnlineTime => _lastOnlineTime;

  /// Stream of connectivity changes
  Stream<bool> get onlineStatusStream => _connectivity.onConnectivityChanged.map(
    (results) => _isConnected(results),
  );

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
      onError: (error) {
        debugPrint('Connectivity error: $error');
      },
    );

    debugPrint('✅ Network connectivity monitoring initialized');
  }

  /// Update connectivity status
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(results);

    if (_isOnline) {
      _lastOnlineTime = DateTime.now();
      if (!_hasEverBeenOnline) {
        _hasEverBeenOnline = true;
      }
    }

    // If we just came back online
    if (!wasOnline && _isOnline) {
      debugPrint('🌐 Network reconnected');
      _executeReconnectionCallbacks();
    } else if (wasOnline && !_isOnline) {
      debugPrint('📡 Network disconnected');
    }

    notifyListeners();
  }

  /// Check if connected based on connectivity results
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }

  /// Register callback to run when network reconnects
  void onReconnect(VoidCallback callback) {
    _reconnectionCallbacks.add(callback);
  }

  /// Remove reconnection callback
  void removeReconnectCallback(VoidCallback callback) {
    _reconnectionCallbacks.remove(callback);
  }

  /// Execute all registered reconnection callbacks
  void _executeReconnectionCallbacks() {
    for (final callback in _reconnectionCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in reconnection callback: $e');
      }
    }
  }

  /// Retry logic with exponential backoff
  Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      
      try {
        // Check if online before attempting
        if (!_isOnline) {
          throw NetworkException('No network connection');
        }

        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) {
          debugPrint('❌ Operation failed after $maxAttempts attempts');
          rethrow;
        }

        debugPrint('⚠️ Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
  }

  /// Check connectivity and throw if offline
  void requireOnline() {
    if (!_isOnline) {
      throw NetworkException('This feature requires an internet connection');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _reconnectionCallbacks.clear();
    super.dispose();
  }
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
