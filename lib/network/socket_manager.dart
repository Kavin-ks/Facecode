import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:facecode/network/local_network_service.dart';

/// Manages WebSocket connections for the host and client roles.
class SocketManager {
  final LocalNetworkService _network = LocalNetworkService();

  WebSocket? _clientSocket; // when this device is a client
  final List<WebSocket> _hostSockets = []; // when this device is a host

  StreamSubscription<WebSocket>? _hostConnSub;

  /// Listen for new client sockets when hosting
  void startHostListener(void Function(WebSocket) onClientConnected) {
    _hostConnSub?.cancel();
    _hostConnSub = _network.onClientConnected?.listen((ws) {
      try {
        _hostSockets.add(ws);
        ws.done.then((_) => _hostSockets.remove(ws));
        onClientConnected(ws);
      } catch (_) {}
    });
  }

  /// Stop listening for host connections
  Future<void> stopHostListener() async {
    await _hostConnSub?.cancel();
    _hostConnSub = null;
    // close all sockets
    for (final s in List.of(_hostSockets)) {
      try {
        s.close();
      } catch (_) {}
    }
    _hostSockets.clear();
  }

  /// Connect as a client to a host
  Future<bool> connectTo(String host, int port, void Function(dynamic) onMessage, {void Function()? onDone, void Function(Object?)? onError}) async {
    try {
      final ws = await _network.connectToHost(host, port);
      if (ws == null) return false;
      _clientSocket = ws;
      ws.listen((data) {
        try {
          final msg = jsonDecode(data);
          onMessage(msg);
        } catch (_) {}
      }, onDone: () {
        _clientSocket = null;
        if (onDone != null) onDone();
      }, onError: (err) {
        _clientSocket = null;
        if (onError != null) onError(err);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Send a message as client
  void sendToHost(Map<String, dynamic> msg) {
    try {
      _clientSocket?.add(jsonEncode(msg));
    } catch (_) {}
  }

  /// Broadcast to all connected clients (host)
  void broadcast(Map<String, dynamic> msg) {
    final payload = jsonEncode(msg);
    for (final s in List.of(_hostSockets)) {
      try {
        s.add(payload);
      } catch (_) {}
    }
  }

  Future<void> closeClient() async {
    try {
      await _clientSocket?.close();
      _clientSocket = null;
    } catch (_) {}
  }
}
