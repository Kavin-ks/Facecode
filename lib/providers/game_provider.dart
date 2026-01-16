import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:facecode/models/game_room.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/models/game_error.dart';
import 'package:facecode/models/game_prompt.dart';
import 'package:facecode/utils/prompt_generator.dart';
import 'package:facecode/utils/room_code_generator.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/sound_service.dart';
import 'package:facecode/network/local_network_service.dart';
import 'package:facecode/network/socket_manager.dart';
import 'package:facecode/models/discovered_room.dart';
import 'package:facecode/services/stats_service.dart';
import 'package:uuid/uuid.dart';

/// Game state management provider
class GameProvider extends ChangeNotifier {
  GameRoom? _currentRoom;
  Player? _currentPlayer;
  Timer? _gameTimer;
  String? _lastCorrectAnswer;
  final Uuid _uuid = const Uuid();

  GameError? _uiError;
  bool _isBusy = false;

  DateTime? _roundEndsAt;
  Duration? _pausedRemaining;

  bool _lastRoundWasCorrect = false;
  bool _lastRoundEndedByTime = false;

  final Map<String, DateTime> _lastGuessAt = {};
  final Map<String, String> _lastGuessText = {};

  final DateTime Function() _now;

  // Networking
  final List<DiscoveredRoom> _discoveredRooms = [];
  String _connectionStatus = 'disconnected'; // 'disconnected'|'connecting'|'connected'|'hosting'

  // Network helpers
  final LocalNetworkService _localNetwork = LocalNetworkService();
  SocketManager? _socketManager;
  String? _connectedHost;
  int? _connectedPort;
  int _reconnectAttempts = 0; // for simple backoff

  GameProvider({DateTime Function()? now}) : _now = now ?? DateTime.now;

  List<DiscoveredRoom> get discoveredRooms => List.unmodifiable(_discoveredRooms);
  String get connectionStatus => _connectionStatus;

  GameRoom? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  String? get lastCorrectAnswer => _lastCorrectAnswer;
  GameError? get uiError => _uiError;
  bool get isBusy => _isBusy;
  bool get lastRoundWasCorrect => _lastRoundWasCorrect;
  bool get lastRoundEndedByTime => _lastRoundEndedByTime;

  /// In local multiplayer (same device), the "active" player is whichever
  /// player is currently holding the phone.
  void setActivePlayer(String playerId) {
    try {
      if (_currentRoom == null) return;
      final match = _currentRoom!.players.where((p) => p.id == playerId);
      if (match.isEmpty) return;

      _currentPlayer = match.first;
      notifyListeners();
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Something went wrong while switching players. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  void clearError() {
    _uiError = null;
    notifyListeners();
  }

  void _setError(GameError error) {
    // Avoid re-firing the same dialog repeatedly.
    if (_uiError?.message == error.message && _uiError?.type == error.type) {
      return;
    }
    _uiError = error;
    notifyListeners();
  }

  /// Check if current player is the emoji player
  bool get isEmojiPlayer {
    if (_currentRoom == null || _currentPlayer == null) return false;
    return _currentRoom!.isEmojiPlayer(_currentPlayer!.id);
  }

  /// Check if current player is the host
  bool get isHost {
    return _currentPlayer?.isHost ?? false;
  }

  /// Create a new room
  void createRoom(String playerName) {
    try {
      final name = playerName.trim();
      if (name.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Oops!',
          message: 'Please enter your name to create a room.',
          actionLabel: 'OK',
        ));
        return;
      }

      final roomCode = RoomCodeGenerator.generate();
      final player = Player(
        id: _uuid.v4(),
        name: name,
        isHost: true,
      );

      _currentPlayer = player;
      _currentRoom = GameRoom(
        roomCode: roomCode,
        players: [player],
        state: GameState.lobby,
      );
      notifyListeners();
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not create the room. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  /// Join an existing room
  bool joinRoom(String roomCode, String playerName) {
    try {
      final code = roomCode.trim().toUpperCase();
      final name = playerName.trim();

      if (name.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Oops!',
          message: 'Please enter your name to join.',
          actionLabel: 'OK',
        ));
        return false;
      }

      if (code.isEmpty || code.length < 6) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Invalid Code',
          message: 'Please enter a valid 6-character room code.',
          actionLabel: 'OK',
        ));
        return false;
      }

      // V1: local multiplayer only (room must exist on this device).
      if (_currentRoom == null || _currentRoom!.roomCode != code) {
        _setError(const GameError(
          type: GameErrorType.roomNotFound,
          title: 'Room Not Found',
          message: 'That room code isn’t active on this device yet.\n\nCreate a room first, then join it.',
          actionLabel: 'Go back',
        ));
        return false;
      }

      final player = Player(
        id: _uuid.v4(),
        name: name,
        isHost: false,
      );

      _currentPlayer = player;
      _currentRoom = _currentRoom!.copyWith(
        players: [..._currentRoom!.players, player],
      );
      notifyListeners();
      return true;
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not join the room. Please try again.',
        actionLabel: 'Retry',
      ));
      return false;
    }
  }

  /// Host a room over local Wi‑Fi (starts server + advertises)
  Future<void> hostWifiRoom(String playerName) async {
    try {
      createRoom(playerName);
      final room = _currentRoom;
      if (room == null) return;

      final port = await _localNetwork.startHosting(roomName: room.players.first.name, roomCode: room.roomCode);
      if (port == null) {
        _setError(const GameError(
          type: GameErrorType.network,
          title: 'Network Error',
          message: 'Could not bind to the local network. Make sure Wi‑Fi is enabled and try again.',
          actionLabel: 'OK',
        ));
        return;
      }

      _socketManager = SocketManager();
      final Map<WebSocket, String> socketPlayerMap = {};

      _socketManager!.startHostListener((ws) {
        // Attach per-client message handler
        ws.listen((data) {
          try {
            final msg = jsonDecode(data);
            final type = msg['type'];
            if (type == 'join') {
              final pid = msg['id'] ?? _uuid.v4();
              final pname = msg['name'] ?? 'Guest';

              // Room capacity check
              if (_currentRoom!.players.length >= AppConstants.maxPlayers) {
                try {
                  ws.add(jsonEncode({'type': 'room_full', 'message': 'Room is full'}));
                  ws.close();
                } catch (_) {}
                return;
              }

              socketPlayerMap[ws] = pid;
              _addRemotePlayer(pid, pname);
              // Notify clients
              _socketManager!.broadcast({
                'type': 'player_joined',
                'id': pid,
                'name': pname,
              });

              // Also send the full room info to the new client
              try {
                final players = _currentRoom!.players.map((p) => {'id': p.id, 'name': p.name, 'isHost': p.isHost}).toList();
                ws.add(jsonEncode({'type': 'room_info', 'code': _currentRoom!.roomCode, 'players': players}));
              } catch (_) {}
            } else if (type == 'emoji') {
              final emoji = msg['emoji'] ?? '';
              if (emoji.isNotEmpty) {
                _currentRoom = _currentRoom!.copyWith(emojiMessages: [..._currentRoom!.emojiMessages, emoji]);
                notifyListeners();
                // broadcast to everyone (including origin)
                _socketManager!.broadcast({'type': 'emoji', 'emoji': emoji});
              }
            } else if (type == 'start') {
              // Clients shouldn't send start; ignore
            }
          } catch (_) {}
        });

        // When a client disconnects, remove the player and inform remaining clients
        ws.done.then((_) {
          try {
            final pid = socketPlayerMap[ws];
            if (pid != null && _currentRoom != null) {
              final remaining = _currentRoom!.players.where((p) => p.id != pid).toList();
              _currentRoom = _currentRoom!.copyWith(players: remaining);
              _socketManager!.broadcast({'type': 'player_left', 'id': pid});
              notifyListeners();
            }
          } catch (_) {}
        });
      });

      _connectionStatus = 'hosting';
      notifyListeners();
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Unable to host a Wi‑Fi room. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  void _addRemotePlayer(String id, String name) {
    try {
      if (_currentRoom == null) return;
      if (_currentRoom!.players.length >= AppConstants.maxPlayers) {
        // Room is full – inform client via socket when needed (not implemented yet)
        return;
      }
      final p = Player(id: id, name: name, isHost: false);
      _currentRoom = _currentRoom!.copyWith(players: [..._currentRoom!.players, p]);
      notifyListeners();
    } catch (_) {}
  }

  /// Discover rooms on the local Wi‑Fi
  Future<void> discoverWifiRooms() async {
    try {
      _discoveredRooms.clear();
      final found = await _localNetwork.discover();
      _discoveredRooms.addAll(found);
      if (_discoveredRooms.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.network,
          title: 'No Rooms Found',
          message: 'No local Wi‑Fi rooms were found on this network. Ensure all devices are on the same Wi‑Fi and try again.',
          actionLabel: 'OK',
        ));
      }
      notifyListeners();
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.network,
        title: 'Network Error',
        message: 'Failed to scan the network. Check your Wi‑Fi connection and try again.',
        actionLabel: 'OK',
      ));
    }
  }

  /// Join a Wi‑Fi room by code. Returns true if joined successfully.
  Future<bool> joinWifiRoom(String code) async {
    try {
      final match = _discoveredRooms.where((r) => r.code.toUpperCase() == code.toUpperCase());
      if (match.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.roomNotFound,
          title: 'Room Not Found',
          message: 'Could not find a room with that code on the local network.',
          actionLabel: 'OK',
        ));
        return false;
      }

      final r = match.first;
      _connectionStatus = 'connecting';
      notifyListeners();

      _socketManager = SocketManager();
      final connected = await _socketManager!.connectTo(r.host, r.port, (msg) {
        try {
          final type = msg['type'];
          if (type == 'room_info') {
            // Host provided room info – build local room state
            final roomCode = msg['code'] ?? r.code;
            final players = (msg['players'] as List<dynamic>? ?? []).map((p) => Player(id: p['id'], name: p['name'], isHost: p['isHost'] ?? false)).toList();
            _currentRoom = GameRoom(roomCode: roomCode, players: players, state: GameState.lobby);
            // Set current player to the one we just created locally
            final localPlayer = Player(id: _uuid.v4(), name: 'You', isHost: false);
            _currentPlayer = localPlayer;
            notifyListeners();
          } else if (type == 'player_joined') {
            // Host informs of a new player
            final pid = msg['id'];
            final pname = msg['name'];
            final p = Player(id: pid, name: pname, isHost: false);
            if (_currentRoom != null) {
              _currentRoom = _currentRoom!.copyWith(players: [..._currentRoom!.players, p]);
              notifyListeners();
            }
          } else if (type == 'room_full') {
            _setError(const GameError(
              type: GameErrorType.validation,
              title: 'Room Full',
              message: 'That room is full. Try another room or ask the host to free up space.',
              actionLabel: 'OK',
            ));
            _socketManager?.closeClient();
            _connectionStatus = 'disconnected';
            notifyListeners();
          } else if (type == 'emoji') {
            final emoji = msg['emoji'] ?? '';
            if (_currentRoom != null && emoji.isNotEmpty) {
              _currentRoom = _currentRoom!.copyWith(emojiMessages: [..._currentRoom!.emojiMessages, emoji]);
              notifyListeners();
            }
          } else if (type == 'start') {
            // Host started the round: set prompt and start timer locally
            final promptMap = msg['prompt'] as Map<String, dynamic>?;
            final duration = msg['duration'] as int? ?? AppConstants.roundDuration;
            final prompt = promptMap != null ? GamePrompt.fromJson(promptMap) : null;
            _currentRoom = _currentRoom!.copyWith(state: GameState.playing, currentPrompt: prompt, roundTimeRemaining: duration, emojiMessages: []);
            _roundEndsAt = _now().add(Duration(seconds: duration));
            _pausedRemaining = null;
            _startTimer();
          } else if (type == 'round_end') {
            final wasCorrect = msg['wasCorrect'] as bool? ?? false;
            final endedByTime = msg['endedByTime'] as bool? ?? false;
            final answer = msg['answer'] as String?;
            final scores = (msg['scores'] as List<dynamic>?) ?? [];
            // Update local scores and switch to results
            if (_currentRoom != null) {
              final updated = _currentRoom!.players.map((p) {
                final s = scores.firstWhere((sc) => sc['id'] == p.id, orElse: () => null);
                if (s != null) {
                  return p.copyWith(score: s['score'] ?? p.score);
                }
                return p;
              }).toList();
              _currentRoom = _currentRoom!.copyWith(players: updated, state: GameState.results);
              _lastCorrectAnswer = answer;
              _lastRoundWasCorrect = wasCorrect;
              _lastRoundEndedByTime = endedByTime;
              _gameTimer?.cancel();
              notifyListeners();
            }
          } else if (type == 'player_left') {
            final pid = msg['id'];
            if (_currentRoom != null) {
              final remaining = _currentRoom!.players.where((p) => p.id != pid).toList();
              _currentRoom = _currentRoom!.copyWith(players: remaining);
              _setError(const GameError(
                type: GameErrorType.network,
                title: 'Player Disconnected',
                message: 'A player left the room.',
                actionLabel: 'OK',
              ));
              notifyListeners();
            }
          } else if (type == 'next_round') {
            final promptMap = msg['prompt'] as Map<String, dynamic>?;
            final duration = msg['duration'] as int? ?? AppConstants.roundDuration;
            final prompt = promptMap != null ? GamePrompt.fromJson(promptMap) : null;
            _currentRoom = _currentRoom!.copyWith(state: GameState.playing, currentPrompt: prompt, roundTimeRemaining: duration, emojiMessages: []);
            _roundEndsAt = _now().add(Duration(seconds: duration));
            _pausedRemaining = null;
            _startTimer();
          }
        } catch (_) {}
      }, onDone: () {
        // Connection closed by host - attempt reconnect
        _connectionStatus = 'disconnected';
        _setError(const GameError(
          type: GameErrorType.network,
          title: 'Disconnected',
          message: 'Lost connection to host. Reconnecting…',
          actionLabel: 'OK',
        ));
        notifyListeners();
        _tryReconnect();
      }, onError: (err) {
        _connectionStatus = 'disconnected';
        _setError(GameError(
          type: GameErrorType.network,
          title: 'Connection Error',
          message: 'Network error: ${err?.toString()} — attempting to reconnect.',
          actionLabel: 'OK',
        ));
        notifyListeners();
      });

      if (!connected) {
        _connectionStatus = 'disconnected';
        _setError(const GameError(
          type: GameErrorType.network,
          title: 'Connection Failed',
          message: 'Could not connect to the host. Check Wi‑Fi and try again.',
          actionLabel: 'OK',
        ));
        notifyListeners();
        return false;
      }



      if (!connected) {
        _connectionStatus = 'disconnected';
        _setError(const GameError(
          type: GameErrorType.network,
          title: 'Connection Failed',
          message: 'Could not connect to the host. Check Wi‑Fi and try again.',
          actionLabel: 'OK',
        ));
        notifyListeners();
        return false;
      }

      // Send join request (with a temporary name – let user update later)
      const name = 'Player';
      final id = _uuid.v4();
      _socketManager!.sendToHost({'type': 'join', 'id': id, 'name': name});

      _connectionStatus = 'connected';
      SoundService.tap();
      notifyListeners();
      return true;
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.network,
        title: 'Connection Error',
        message: 'An error occurred while joining the room. Please try again.',
        actionLabel: 'OK',
      ));
      _connectionStatus = 'disconnected';
      notifyListeners();
      return false;
    }
  }

  Future<void> _tryReconnect() async {
    if (_connectedHost == null || _connectedPort == null) return;
    if (_reconnectAttempts >= 3) {
      _connectionStatus = 'disconnected';
      _setError(const GameError(
        type: GameErrorType.disconnect,
        title: 'Host Disconnected',
        message: 'Could not reconnect to the host. Please try joining again.',
        actionLabel: 'OK',
      ));
      notifyListeners();
      return;
    }

    _reconnectAttempts += 1;
    final wait = Duration(seconds: 1 << _reconnectAttempts);
    await Future.delayed(wait);

    try {
      _connectionStatus = 'connecting';
      notifyListeners();
      _socketManager = SocketManager();
      final ok = await _socketManager!.connectTo(_connectedHost!, _connectedPort!, (msg) {
        try {
          final type = msg['type'];
          if (type == 'emoji') {
            final emoji = msg['emoji'] ?? '';
            if (_currentRoom != null && emoji.isNotEmpty) {
              _currentRoom = _currentRoom!.copyWith(emojiMessages: [..._currentRoom!.emojiMessages, emoji]);
              notifyListeners();
            }
          } else if (type == 'start') {
            final promptMap = msg['prompt'] as Map<String, dynamic>?;
            final duration = msg['duration'] as int? ?? AppConstants.roundDuration;
            final prompt = promptMap != null ? GamePrompt.fromJson(promptMap) : null;
            _currentRoom = _currentRoom!.copyWith(state: GameState.playing, currentPrompt: prompt, roundTimeRemaining: duration, emojiMessages: []);
            _roundEndsAt = _now().add(Duration(seconds: duration));
            _pausedRemaining = null;
            _startTimer();
          }
        } catch (_) {}
      }, onDone: () {
        _connectionStatus = 'disconnected';
        notifyListeners();
        _tryReconnect();
      }, onError: (_) {
        _connectionStatus = 'disconnected';
        notifyListeners();
        _tryReconnect();
      });

      if (ok) {
        _connectionStatus = 'connected';
        _reconnectAttempts = 0;
        notifyListeners();
      } else {
        _tryReconnect();
      }
    } catch (_) {
      _tryReconnect();
    }
  }

  /// Add a player to the current room (for local multiplayer)
  void addPlayer(String playerName) {
    try {
      if (_currentRoom == null) return;

      final name = playerName.trim();
      if (name.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Oops!',
          message: 'Please enter a player name.',
          actionLabel: 'OK',
        ));
        return;
      }

      if (_currentRoom!.players.length >= AppConstants.maxPlayers) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Room Full',
          message: 'You’ve reached the maximum number of players for this device.',
          actionLabel: 'OK',
        ));
        return;
      }

      final player = Player(
        id: _uuid.v4(),
        name: name,
        isHost: false,
      );

      _currentRoom = _currentRoom!.copyWith(
        players: [..._currentRoom!.players, player],
      );
      notifyListeners();

      // If hosting on Wi‑Fi, inform clients of the new player
      try {
        if (_connectionStatus == 'hosting' && _socketManager != null) {
          _socketManager!.broadcast({'type': 'player_joined', 'id': player.id, 'name': player.name});
        }
      } catch (_) {}
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not add player. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  /// Start the game
  void startGame() {
    try {
      if (_currentRoom == null) return;
      if (_currentRoom!.players.length < AppConstants.minPlayers) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Not Enough Players',
          message: 'Add at least ${AppConstants.minPlayers} players to start.',
          actionLabel: 'OK',
        ));
        return;
      }

      _isBusy = true;
      notifyListeners();

      final prompt = PromptGenerator.getRandomPrompt();
      _lastGuessAt.clear();
      _lastGuessText.clear();
      _lastCorrectAnswer = null;
      _lastRoundWasCorrect = false;
      _lastRoundEndedByTime = false;

      _currentRoom = _currentRoom!.copyWith(
        state: GameState.playing,
        currentPrompt: prompt,
        roundTimeRemaining: AppConstants.roundDuration,
        emojiMessages: [],
      );

      _roundEndsAt = _now().add(const Duration(seconds: AppConstants.roundDuration));
      _pausedRemaining = null;
      _startTimer();
      SoundService.roundStart();

      // Networking: if hosting, broadcast start with prompt
      try {
        if (_connectionStatus == 'hosting' && _socketManager != null) {
          _socketManager!.broadcast({'type': 'start', 'prompt': _currentRoom!.currentPrompt?.toJson(), 'duration': AppConstants.roundDuration});
        }
      } catch (_) {}
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not start the game. Please try again.',
        actionLabel: 'Retry',
      ));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Start the round timer
  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentRoom == null || _currentRoom!.state != GameState.playing) {
        timer.cancel();
        return;
      }

      final endsAt = _roundEndsAt;
      if (endsAt == null) {
        // Fallback: keep ticking down existing value.
        final newTime = _currentRoom!.roundTimeRemaining - 1;
        if (newTime <= 0) {
          timer.cancel();
          _endRound(false, endedByTime: true);
        } else {
          _currentRoom = _currentRoom!.copyWith(roundTimeRemaining: newTime);
          notifyListeners();
        }
        return;
      }

      final remaining = endsAt.difference(_now());
      final secondsLeft = remaining.inSeconds.clamp(0, AppConstants.roundDuration);
      if (secondsLeft <= 0) {
        timer.cancel();
        _currentRoom = _currentRoom!.copyWith(roundTimeRemaining: 0);
        notifyListeners();
        _endRound(false, endedByTime: true);
        return;
      }

      if (secondsLeft != _currentRoom!.roundTimeRemaining) {
        _currentRoom = _currentRoom!.copyWith(roundTimeRemaining: secondsLeft);
        notifyListeners();
      }
    });
  }

  /// Pause timer safely (e.g., app in background).
  void onAppPaused() {
    try {
      if (_currentRoom == null || _currentRoom!.state != GameState.playing) return;
      if (_roundEndsAt == null) return;

      final remaining = _roundEndsAt!.difference(_now());
      _pausedRemaining = remaining.isNegative ? Duration.zero : remaining;
      _gameTimer?.cancel();
    } catch (_) {
      // Don't crash on lifecycle events.
    }
  }

  /// Resume timer safely after a pause.
  void onAppResumed() {
    try {
      if (_currentRoom == null || _currentRoom!.state != GameState.playing) return;
      final remaining = _pausedRemaining;
      if (remaining == null) return;

      _roundEndsAt = _now().add(remaining);
      _pausedRemaining = null;
      _startTimer();
      notifyListeners();
    } catch (_) {
      // Don't crash on lifecycle events.
    }
  }

  /// Send an emoji message (only for emoji player)
  void sendEmoji(String emoji) {
    try {
      if (_currentRoom == null) return;
      if (_currentRoom!.state != GameState.playing) return;
      if (!isEmojiPlayer) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Oops!',
          message: "Oops! You can’t send text. Emojis only 😄",
          actionLabel: 'OK',
        ));
        return;
      }

      final value = emoji.trim();
      final hasEmoji = RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      ).hasMatch(value);

      if (value.isEmpty || !hasEmoji) {
        _setError(const GameError(
          type: GameErrorType.invalidEmoji,
          title: 'Invalid Emoji',
          message: 'Please pick an emoji from the emoji keyboard.',
          actionLabel: 'OK',
        ));
        return;
      }

      _currentRoom = _currentRoom!.copyWith(
        emojiMessages: [..._currentRoom!.emojiMessages, value],
      );
      notifyListeners();
      SoundService.tap();

      // Networking: propagate emoji messages to remote players
      try {
        if (_connectionStatus == 'hosting' && _socketManager != null) {
          _socketManager!.broadcast({'type': 'emoji', 'emoji': value});
        } else if (_connectionStatus == 'connected' && _socketManager != null) {
          _socketManager!.sendToHost({'type': 'emoji', 'emoji': value, 'playerId': _currentPlayer?.id});
        }
      } catch (_) {}
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not send that emoji. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  /// Submit a guess (for non-emoji players)
  bool submitGuess(String guess, String playerId) {
    try {
      if (_currentRoom == null || _currentRoom!.currentPrompt == null) {
        return false;
      }

      if (_currentRoom!.state != GameState.playing) return false;

      // Emoji player is not allowed to submit a text guess.
      if (_currentRoom!.isEmojiPlayer(playerId)) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Emojis Only',
          message: "Oops! You can’t send text. Emojis only 😄",
          actionLabel: 'OK',
        ));
        return false;
      }

      final raw = guess.trim();
      if (raw.isEmpty) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Empty Guess',
          message: 'Type a guess before submitting.',
          actionLabel: 'OK',
        ));
        return false;
      }

      final normalized = raw.toLowerCase();
      if (_lastGuessText[playerId] == normalized) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Same Guess',
          message: 'You already tried that one. Try something different!',
          actionLabel: 'OK',
        ));
        return false;
      }

      final lastAt = _lastGuessAt[playerId];
      if (lastAt != null) {
        final diff = _now().difference(lastAt);
        if (diff < AppConstants.guessCooldown) {
          _setError(GameError(
            type: GameErrorType.validation,
            title: 'Slow Down',
            message: 'One guess at a time! Wait ${AppConstants.guessCooldown.inSeconds}s and try again.',
            actionLabel: 'OK',
          ));
          return false;
        }
      }

      _lastGuessAt[playerId] = _now();
      _lastGuessText[playerId] = normalized;

      // Check if guess is correct (case-insensitive)
      final correctAnswer = _currentRoom!.currentPrompt!.text.toLowerCase();
      if (normalized == correctAnswer) {
        final updatedPlayers = _currentRoom!.players.map((player) {
          if (player.id == playerId) {
            return player.copyWith(
              score: player.score + AppConstants.pointsPerCorrectGuess,
            );
          }
          return player;
        }).toList();

        _currentRoom = _currentRoom!.copyWith(players: updatedPlayers);
        SoundService.correct();
        _endRound(true, endedByTime: false);
        return true;
      }

      SoundService.wrong();
      return false;
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not submit that guess. Please try again.',
        actionLabel: 'Retry',
      ));
      return false;
    }
  }

  /// End the current round
  void _endRound(bool wasCorrect, {required bool endedByTime}) async {
    try {
      _gameTimer?.cancel();
      if (_currentRoom == null) return;

      _lastCorrectAnswer = _currentRoom!.currentPrompt?.text;
      _lastRoundWasCorrect = wasCorrect;
      _lastRoundEndedByTime = endedByTime;

      _currentRoom = _currentRoom!.copyWith(state: GameState.results);
      notifyListeners();

      // Track stats: increment games for all players
      try {
        for (final player in _currentRoom!.players) {
          await StatsService.incrementGames(player.id);
        }
        // If correct guess, increment wins for the player who guessed correctly
        if (wasCorrect) {
          final winner = _currentRoom!.players.firstWhere(
            (p) => p.score == _currentRoom!.players.map((pl) => pl.score).reduce((a, b) => a > b ? a : b),
            orElse: () => _currentRoom!.players.first,
          );
          await StatsService.incrementWins(winner.id);
        }
      } catch (_) {
        // Don't fail the round if stats tracking fails
      }

      // Networking: notify clients of round end (host only)
      try {
        if (_connectionStatus == 'hosting' && _socketManager != null) {
          final scores = _currentRoom!.players.map((p) => {'id': p.id, 'score': p.score}).toList();
          _socketManager!.broadcast({'type': 'round_end', 'wasCorrect': wasCorrect, 'endedByTime': endedByTime, 'answer': _lastCorrectAnswer, 'scores': scores});
        }
      } catch (_) {}

      if (endedByTime) {
        SoundService.roundEnd();
        _setError(const GameError(
          type: GameErrorType.timeExpired,
          title: "Time’s Up!",
          message: 'The round ended because the timer ran out.',
          actionLabel: 'See Results',
        ));
      }
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Something went wrong ending the round.',
        actionLabel: 'OK',
      ));
    }
  }

  /// Start the next round
  void nextRound() {
    try {
      if (_currentRoom == null) return;
      if (_currentRoom!.players.length < AppConstants.minPlayers) {
        _setError(const GameError(
          type: GameErrorType.validation,
          title: 'Not Enough Players',
          message: 'Add at least ${AppConstants.minPlayers} players to continue.',
          actionLabel: 'OK',
        ));
        return;
      }

      _isBusy = true;
      notifyListeners();

      final nextIndex = (_currentRoom!.currentEmojiPlayerIndex + 1) %
          _currentRoom!.players.length;

      final prompt = PromptGenerator.getRandomPrompt();
      _lastGuessAt.clear();
      _lastGuessText.clear();
      _lastCorrectAnswer = null;
      _lastRoundWasCorrect = false;
      _lastRoundEndedByTime = false;

      _currentRoom = _currentRoom!.copyWith(
        state: GameState.playing,
        currentEmojiPlayerIndex: nextIndex,
        currentPrompt: prompt,
        roundTimeRemaining: AppConstants.roundDuration,
        emojiMessages: [],
      );

      _roundEndsAt = _now().add(const Duration(seconds: AppConstants.roundDuration));
      _pausedRemaining = null;
      _startTimer();
      SoundService.roundStart();

      // Networking: host broadcasts next round info
      try {
        if (_connectionStatus == 'hosting' && _socketManager != null) {
          _socketManager!.broadcast({'type': 'next_round', 'prompt': prompt.toJson(), 'duration': AppConstants.roundDuration});
        }
      } catch (_) {}
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not start the next round. Please try again.',
        actionLabel: 'Retry',
      ));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Return to lobby
  void returnToLobby() {
    try {
      _gameTimer?.cancel();
      if (_currentRoom == null) return;

      _currentRoom = _currentRoom!.copyWith(
        state: GameState.lobby,
        currentPrompt: null,
        emojiMessages: [],
        roundTimeRemaining: AppConstants.roundDuration,
      );
      _lastCorrectAnswer = null;
      _lastRoundWasCorrect = false;
      _lastRoundEndedByTime = false;
      _roundEndsAt = null;
      _pausedRemaining = null;
      _lastGuessAt.clear();
      _lastGuessText.clear();
      notifyListeners();
    } catch (_) {
      _setError(const GameError(
        type: GameErrorType.unknown,
        title: 'Oops!',
        message: 'Could not return to lobby. Please try again.',
        actionLabel: 'Retry',
      ));
    }
  }

  /// Leave the current room
  void leaveRoom() {
    _gameTimer?.cancel();

    // Cleanup network resources
    try {
      if (_connectionStatus == 'hosting') {
        _localNetwork.stopHosting();
        _socketManager?.stopHostListener();
      }
      if (_connectionStatus == 'connected') {
        _socketManager?.closeClient();
      }
    } catch (_) {}

    _connectionStatus = 'disconnected';

    _currentRoom = null;
    _currentPlayer = null;
    _lastCorrectAnswer = null;
    _lastRoundWasCorrect = false;
    _lastRoundEndedByTime = false;
    _roundEndsAt = null;
    _pausedRemaining = null;
    _lastGuessAt.clear();
    _lastGuessText.clear();
    _uiError = null;
    notifyListeners();
  }

  /// Clear all emoji messages
  void clearEmojiMessages() {
    if (_currentRoom == null) return;
    _currentRoom = _currentRoom!.copyWith(emojiMessages: []);
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}
