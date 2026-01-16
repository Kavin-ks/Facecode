import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:facecode/models/discovered_room.dart';

/// Simple local network discovery and WebSocket host implementation.
///
/// NOTE: This is a lightweight implementation for local Wi‑Fi play. It uses
/// UDP broadcast to advertise/discover rooms on the local network and a
/// WebSocket server (dart:io) to accept game clients. All calls are wrapped
/// with try/catch to avoid app crashes when networking is unavailable.
class LocalNetworkService {
  static final LocalNetworkService _instance = LocalNetworkService._internal();
  factory LocalNetworkService() => _instance;
  LocalNetworkService._internal();

  RawDatagramSocket? _udpSocket;
  HttpServer? _wsServer;
  StreamController<WebSocket>? _serverSocketController;

  Stream<WebSocket>? get onClientConnected => _serverSocketController?.stream;
  int _wsPort = 0;

  final _random = Random();

  /// Broadcast port used for discovery
  static const int discoveryPort = 50000;

  /// Start hosting a room: start a WebSocket server and begin responding to
  /// discovery requests with the room info.
  Future<int?> startHosting({required String roomName, required String roomCode}) async {
    try {
      // Start WebSocket server on a random port in range
      _wsPort = 50000 + _random.nextInt(10000);
      _wsServer = await HttpServer.bind(InternetAddress.anyIPv4, _wsPort);
      // expose accepted sockets via a stream controller
      _serverSocketController = StreamController<WebSocket>.broadcast();

      // upgrade requests will be handled when clients connect
      _wsServer!.listen((HttpRequest req) async {
        if (WebSocketTransformer.isUpgradeRequest(req)) {
          try {
            final ws = await WebSocketTransformer.upgrade(req);
            _serverSocketController?.add(ws);
          } catch (_) {
            // ignore errors here
          }
        } else {
          req.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..close();
        }
      });

      // Start UDP socket for discovery responses
      _udpSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpSocket!.receive();
          if (dg == null) return;
          final msg = utf8.decode(dg.data);
          if (msg == 'FIND_FACECODE') {
            final response = jsonEncode({
              'name': roomName,
              'code': roomCode,
              'host': dg.address.address,
              'port': _wsPort,
            });
            _udpSocket!.send(utf8.encode(response), dg.address, dg.port);
          }
        }
      });

      return _wsPort;
    } catch (e) {
      // Return null on failure
      return null;
    }
  }

  /// Stop hosting and clean up
  Future<void> stopHosting() async {
    try {
      await _wsServer?.close(force: true);
      await _serverSocketController?.close();
      _serverSocketController = null;
      _wsServer = null;
      _wsPort = 0;
    } catch (_) {}
  }

  /// Discover rooms on the local network by broadcasting a discovery packet
  /// and listening for responses for a short timeout.
  Future<List<DiscoveredRoom>> discover({Duration timeout = const Duration(seconds: 2)}) async {
    final results = <DiscoveredRoom>[];
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      socket.send(utf8.encode('FIND_FACECODE'), InternetAddress('255.255.255.255'), discoveryPort);

      final completer = Completer<void>();
      final timer = Timer(timeout, () {
        completer.complete();
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg == null) return;
          try {
            final map = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
            final room = DiscoveredRoom(
              name: map['name'] ?? 'Unknown',
              code: map['code'] ?? '',
              host: map['host'] ?? dg.address.address,
              port: map['port'] ?? discoveryPort,
            );
            if (!results.any((r) => r.code == room.code && r.host == room.host)) {
              results.add(room);
            }
          } catch (_) {}
        }
      });

      await completer.future;
      timer.cancel();
      socket.close();
    } catch (e) {
      // ignore errors - simply return empty
    }

    return results;
  }

  /// Connect to a host WebSocket server and return the WebSocket instance
  Future<WebSocket?> connectToHost(String host, int port) async {
    try {
      final url = 'ws://$host:$port';
      final ws = await WebSocket.connect(url).timeout(const Duration(seconds: 4));
      return ws;
    } catch (_) {
      return null;
    }
  }
}
