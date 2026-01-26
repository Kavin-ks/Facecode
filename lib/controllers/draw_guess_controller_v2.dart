import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/models/draw_guess_models.dart';

class DrawGuessController extends ChangeNotifier {
  DrawGuessController({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  final List<Color> palette = [
    Colors.black,
    const Color(0xFFEF5350),
    const Color(0xFF42A5F5),
    const Color(0xFF66BB6A),
    const Color(0xFFFFCA28),
    const Color(0xFFAB47BC),
    const Color(0xFF8D6E63),
    const Color(0xFF00ACC1),
  ];
  final List<double> brushSizes = [4, 8, 12];

  Color selectedColor = Colors.black;
  double selectedBrush = 6;
  bool isEraser = false;

  DrawPhase phase = DrawPhase.home;
  Room? room;
  String? currentUserId;

  List<Stroke> strokes = [];
  Stroke? currentStroke;

  List<GuessMessage> messages = [];
  final Set<String> correctGuessers = {};
  final Map<String, int> guessTimes = {};

  int timeLeft = 0;
  int totalTime = 1;
  int countdown = 3;
  int wordChoiceSeconds = 5;
  List<String> wordOptions = [];
  String wordToDraw = '';
  final Set<int> revealedIndices = {};
  bool _firstHintRevealed = false;
  bool _secondHintRevealed = false;

  bool _wordsLoaded = false;
  final Map<WordCategory, Map<WordDifficulty, List<String>>> _wordBank = {};

  DateTime _lastStrokeBroadcast = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _strokeBroadcastThrottle = Duration(milliseconds: 60);

  Timer? _roundTimer;
  Timer? _aiTimer;
  Timer? _wordTimer;
  Timer? _countdownTimer;
  Timer? _aiDrawTimer;

  // Networking hook
  Function(Map<String, dynamic>)? onBroadcast;

  final List<String> publicRooms = ['ABCD', 'FJ9K', 'P4QZ'];

  final Map<WordCategory, Map<WordDifficulty, List<String>>> _defaultWordBank = {
    WordCategory.objects: {
      WordDifficulty.easy: ['cat', 'sun', 'cup', 'car', 'tree', 'ball', 'fish', 'hat', 'chair', 'clock'],
      WordDifficulty.medium: ['airplane', 'guitar', 'robot', 'camera', 'telescope', 'lamp', 'train'],
      WordDifficulty.hard: ['microscope', 'skyscraper', 'helicopter', 'lighthouse', 'constellation'],
    },
    WordCategory.animals: {
      WordDifficulty.easy: ['dog', 'cat', 'fish', 'bird', 'cow', 'duck'],
      WordDifficulty.medium: ['dolphin', 'kangaroo', 'penguin', 'turtle'],
      WordDifficulty.hard: ['hippopotamus', 'chameleon', 'axolotl', 'orangutan'],
    },
    WordCategory.movies: {
      WordDifficulty.easy: ['lion king', 'frozen', 'up'],
      WordDifficulty.medium: ['toy story', 'spider man', 'harry potter'],
      WordDifficulty.hard: ['interstellar', 'inception', 'jurassic park'],
    },
    WordCategory.food: {
      WordDifficulty.easy: ['pizza', 'apple', 'cake', 'bread'],
      WordDifficulty.medium: ['hamburger', 'spaghetti', 'sushi'],
      WordDifficulty.hard: ['croissant', 'risotto', 'tiramisu'],
    },
    WordCategory.actions: {
      WordDifficulty.easy: ['run', 'jump', 'sleep', 'dance'],
      WordDifficulty.medium: ['skateboard', 'climb', 'photograph'],
      WordDifficulty.hard: ['investigate', 'negotiate', 'improvise'],
    },
    WordCategory.random: {
      WordDifficulty.easy: ['sun', 'cat', 'pizza', 'run'],
      WordDifficulty.medium: ['guitar', 'spider man', 'skateboard'],
      WordDifficulty.hard: ['microscope', 'interstellar', 'improvise'],
    },
  };

  List<Player> get sortedPlayers {
    if (room == null) return [];
    final sorted = [...room!.players];
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  Player? get currentDrawer => room?.players.firstWhere((p) => p.isDrawer, orElse: () => room!.players.first);

  bool get isHost => room != null && room!.hostId == currentUserId;

  bool get isCurrentUserDrawer => currentUserId != null && currentDrawer?.id == currentUserId;

  bool get hasCurrentUserGuessed => currentUserId != null && correctGuessers.contains(currentUserId!);

  int get correctGuessCount => correctGuessers.length;

  String get currentRoundLabel {
    if (room == null) return '0/0';
    final total = room!.settings.rounds == 0 ? '∞' : room!.settings.rounds.toString();
    return '${room!.round}/$total';
  }

  void resetToHome() {
    _disposeTimers();
    room = null;
    phase = DrawPhase.home;
    notifyListeners();
  }

  void createRoom(String name, {String? avatar}) {
    if (name.trim().isEmpty) return;
    final player = Player(id: _id(), name: name.trim(), avatar: avatar);
    room = Room(
      code: _roomCode(),
      players: [player],
      round: 0,
      settings: GameSettings(),
      hostId: player.id,
    );
    currentUserId = player.id;
    phase = DrawPhase.lobby;
    notifyListeners();
  }

  void joinRoom(String code, String name, {String? avatar}) {
    if (name.trim().isEmpty) return;
    final player = Player(id: _id(), name: name.trim(), avatar: avatar);
    room = Room(
      code: code.isEmpty ? _roomCode() : code.toUpperCase(),
      players: [player],
      round: 0,
      settings: GameSettings(),
      hostId: player.id,
    );
    currentUserId = player.id;
    phase = DrawPhase.lobby;
    notifyListeners();
  }

  void setCurrentUser(String? id) {
    if (id == null) return;
    currentUserId = id;
    notifyListeners();
  }

  void addPlayer(String name, {String? avatar}) {
    if (room == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (room!.players.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) return;
    room!.players.add(Player(id: _id(), name: trimmed, avatar: avatar));
    notifyListeners();
  }

  void removePlayer(String id) {
    if (room == null) return;
    room!.players.removeWhere((p) => p.id == id);
    if (room!.players.isEmpty) {
      resetToHome();
      return;
    }
    if (!room!.players.any((p) => p.isDrawer)) {
      room!.players.first.isDrawer = true;
    }
    if (currentUserId == id) {
      currentUserId = room!.players.firstWhere((p) => !p.isAI, orElse: () => room!.players.first).id;
    }
    _ensureAiPlayers();
    notifyListeners();
  }

  void updateRounds(int rounds) {
    if (room == null) return;
    room!.settings.rounds = rounds;
    notifyListeners();
  }

  void updateDrawTime(int seconds) {
    if (room == null) return;
    room!.settings.drawTime = seconds;
    notifyListeners();
  }

  void updateDifficulty(WordDifficulty difficulty) {
    if (room == null) return;
    room!.settings.difficulty = difficulty;
    notifyListeners();
  }

  void updateCategory(WordCategory category) {
    if (room == null) return;
    room!.settings.category = category;
    notifyListeners();
  }

  void updateLanguage(String language) {
    if (room == null) return;
    room!.settings.language = language;
    notifyListeners();
  }

  void updateAiFallback(bool enabled) {
    if (room == null) return;
    room!.settings.aiFallback = enabled;
    if (enabled) {
      _ensureAiPlayers();
    } else {
      room!.players.removeWhere((p) => p.isAI);
      if (!room!.players.any((p) => p.isDrawer)) {
        room!.players.first.isDrawer = true;
      }
    }
    notifyListeners();
  }

  void updateAiLevel(int level) {
    if (room == null) return;
    room!.settings.aiLevel = level.clamp(1, 3);
    notifyListeners();
  }

  Future<void> loadWordBank() async {
    if (_wordsLoaded) return;
    _wordsLoaded = true;
    _wordBank.clear();
    _wordBank.addAll(_defaultWordBank);
    try {
      final raw = await rootBundle.loadString('assets/data/draw_guess_words.json');
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final Map<WordCategory, Map<WordDifficulty, List<String>>> parsed = {};
      for (final entry in json.entries) {
        final category = _parseCategory(entry.key);
        if (category == null) continue;
        final Map<String, dynamic> byDifficulty = entry.value as Map<String, dynamic>;
        final Map<WordDifficulty, List<String>> difficultyMap = {};
        for (final dEntry in byDifficulty.entries) {
          final difficulty = _parseDifficulty(dEntry.key);
          if (difficulty == null) continue;
          final List<dynamic> words = dEntry.value as List<dynamic>;
          difficultyMap[difficulty] = words.map((w) => w.toString()).toList();
        }
        if (difficultyMap.isNotEmpty) {
          parsed[category] = difficultyMap;
        }
      }
      if (parsed.isNotEmpty) {
        _wordBank
          ..clear()
          ..addAll(parsed);
      }
    } catch (_) {
      // Fallback to default word bank silently.
    }
    notifyListeners();
  }

  void startGame() {
    if (room == null) return;
    if (room!.players.length < 2 && room!.settings.aiFallback) {
      _ensureAiPlayers();
    }
    if (room!.players.length < 2) return;
    room!.round = 1;
    _assignDrawer(0);
    _startRoundCountdown();
  }

  void _startRoundCountdown() {
    _disposeTimers();
    countdown = 3;
    phase = DrawPhase.choosingWord;
    notifyListeners();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _startWordChoice();
      }
      notifyListeners();
    });
  }

  void _startWordChoice() {
    if (room == null) return;
    wordOptions = _pickWordOptions();
    wordChoiceSeconds = 5;
    notifyListeners();

    _wordTimer?.cancel();
    _wordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      wordChoiceSeconds--;
      if (wordChoiceSeconds <= 0) {
        timer.cancel();
        chooseWord(wordOptions[_rng.nextInt(wordOptions.length)]);
      }
      notifyListeners();
    });

    if (currentDrawer?.isAI == true) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (phase == DrawPhase.choosingWord) {
          chooseWord(wordOptions[_rng.nextInt(wordOptions.length)]);
        }
      });
    }
  }

  void chooseWord(String word) {
    if (phase != DrawPhase.choosingWord) return;
    _wordTimer?.cancel();
    wordToDraw = word.toUpperCase();
    revealedIndices.clear();
    _firstHintRevealed = false;
    _secondHintRevealed = false;
    correctGuessers.clear();
    guessTimes.clear();
    messages.clear();
    strokes.clear();
    currentStroke = null;
    totalTime = room?.settings.drawTime ?? 80;
    timeLeft = totalTime;
    phase = DrawPhase.drawing;
    notifyListeners();

    _startRoundTimer();
    _startAiGuessing();
    if (currentDrawer?.isAI == true) {
      _startAiDrawing();
    }
  }

  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeLeft--;
      onBroadcast?.call({'type': 'timer:update', 'timeLeft': timeLeft});
      if (!_firstHintRevealed && timeLeft <= (totalTime * 0.5).floor()) {
        _revealHintLetter();
        _firstHintRevealed = true;
      }
      if (!_secondHintRevealed && timeLeft <= (totalTime * 0.25).floor()) {
        _revealHintLetter();
        _secondHintRevealed = true;
      }
      if (timeLeft <= 0) {
        timer.cancel();
        _endRound();
      }
      notifyListeners();
    });
  }

  void _startAiGuessing() {
    if (room == null || !room!.settings.aiFallback) return;
    _aiTimer?.cancel();
    final level = room!.settings.aiLevel;
    final interval = Duration(milliseconds: level == 1 ? 3000 : level == 2 ? 2200 : 1700);
    _aiTimer = Timer.periodic(interval, (_) {
      if (phase != DrawPhase.drawing) return;
      final aiGuessers = room!.players.where((p) => p.isAI && !p.isDrawer && !correctGuessers.contains(p.id));
      for (final ai in aiGuessers) {
        final guess = _generateAiGuess();
        submitGuess(ai.id, guess);
      }
    });
  }

  void _startAiDrawing() {
    _aiDrawTimer?.cancel();
    final level = room?.settings.aiLevel ?? 2;
    final interval = Duration(milliseconds: level == 1 ? 650 : level == 2 ? 480 : 360);
    _aiDrawTimer = Timer.periodic(interval, (_) {
      if (phase != DrawPhase.drawing) return;
      final start = Offset(_rng.nextDouble() * 300, _rng.nextDouble() * 220);
      final end = Offset(start.dx + _rng.nextDouble() * 40, start.dy + _rng.nextDouble() * 40);
      strokes.add(Stroke(
        points: [start, end, null],
        color: palette[_rng.nextInt(palette.length)],
        thickness: brushSizes[_rng.nextInt(brushSizes.length)],
        isEraser: false,
      ));
      notifyListeners();
    });
  }

  void submitGuess(String? playerId, String text) {
    if (playerId == null || phase != DrawPhase.drawing) return;
    final player = room?.players.firstWhere((p) => p.id == playerId, orElse: () => room!.players.first);
    if (player == null) return;
    if (player.isDrawer) return;
    if (correctGuessers.contains(playerId)) return;
    final guess = text.trim();
    if (guess.isEmpty) return;

    messages.add(GuessMessage(name: player.name, text: guess));
    onBroadcast?.call({'type': 'guess:submit', 'playerId': playerId, 'guess': guess});

    if (_isCorrectGuess(guess)) {
      correctGuessers.add(playerId);
      guessTimes[playerId] = timeLeft;
      final score = _calculateGuessScore(timeLeft);
      player.score += score;
      messages.add(GuessMessage(name: 'System', text: '${player.name} guessed correctly • +$score', isCorrect: true, isSystem: true));
      onBroadcast?.call({'type': 'guess:correct', 'playerId': playerId, 'score': score});
      if (_allGuessersCorrect()) {
        _endRound();
      }
    }

    notifyListeners();
  }

  void _endRound() {
    _disposeTimers();
    _scoreDrawer();
    phase = DrawPhase.reveal;
    onBroadcast?.call({'type': 'round:end', 'word': wordToDraw});
    notifyListeners();
  }

  void nextRound() {
    if (room == null) return;
    if (room!.settings.rounds != 0 && room!.round >= room!.settings.rounds) {
      phase = DrawPhase.scoreboard;
      notifyListeners();
      return;
    }
    room!.round += 1;
    _rotateDrawer();
    _startRoundCountdown();
  }

  void _rotateDrawer() {
    if (room == null) return;
    final index = room!.players.indexWhere((p) => p.isDrawer);
    if (index != -1) room!.players[index].isDrawer = false;
    final nextIndex = (index + 1) % room!.players.length;
    room!.players[nextIndex].isDrawer = true;
  }

  void _assignDrawer(int index) {
    for (final p in room!.players) {
      p.isDrawer = false;
    }
    room!.players[index].isDrawer = true;
  }

  void _scoreDrawer() {
    if (room == null) return;
    final drawer = currentDrawer;
    if (drawer == null) return;
    final correct = correctGuessers.length;
    int score = max(5, correct * 20);
    if (correct == room!.players.where((p) => !p.isDrawer).length && timeLeft > 0) {
      score += 40;
    }
    drawer.score += score;
  }

  void onPanStart(DragStartDetails details) {
    if (phase != DrawPhase.drawing || !isCurrentUserDrawer) return;
    currentStroke = Stroke(
      points: [details.localPosition],
      color: selectedColor,
      thickness: selectedBrush,
      isEraser: isEraser,
    );
    strokes.add(currentStroke!);
    _broadcastStroke(currentStroke!);
    notifyListeners();
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (phase != DrawPhase.drawing || currentStroke == null || !isCurrentUserDrawer) return;
    currentStroke!.points.add(details.localPosition);
    final now = DateTime.now();
    if (now.difference(_lastStrokeBroadcast) >= _strokeBroadcastThrottle) {
      _lastStrokeBroadcast = now;
      _broadcastStrokePoint(details.localPosition);
    }
    notifyListeners();
  }

  void onPanEnd(DragEndDetails details) {
    if (phase != DrawPhase.drawing || currentStroke == null || !isCurrentUserDrawer) return;
    currentStroke!.points.add(null);
    currentStroke = null;
    _broadcastStrokeEnd();
    notifyListeners();
  }

  void clearCanvas() {
    if (!isCurrentUserDrawer) return;
    strokes.clear();
    notifyListeners();
  }

  void undoStroke() {
    if (!isCurrentUserDrawer) return;
    if (strokes.isEmpty) return;
    strokes.removeLast();
    notifyListeners();
  }

  void setSelectedBrush(double size) {
    selectedBrush = size;
    notifyListeners();
  }

  void setSelectedColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  void toggleEraser() {
    isEraser = !isEraser;
    notifyListeners();
  }

  String buildHint() {
    return wordToDraw.split('').asMap().entries.map((entry) {
      final idx = entry.key;
      final ch = entry.value;
      if (ch == ' ') return ' ';
      return revealedIndices.contains(idx) ? ch : '_';
    }).join(' ');
  }

  List<String> _pickWordOptions() {
    final difficulty = room?.settings.difficulty ?? WordDifficulty.mixed;
    final category = room?.settings.category ?? WordCategory.random;
    final bank = _wordBank.isEmpty ? _defaultWordBank : _wordBank;
    List<String> pool = [];

    List<String> collect(WordCategory cat, WordDifficulty diff) {
      return bank[cat]?[diff] ?? [];
    }

    if (category == WordCategory.random || difficulty == WordDifficulty.mixed) {
      for (final cat in WordCategory.values) {
        if (cat == WordCategory.random) continue;
        pool.addAll(collect(cat, WordDifficulty.easy));
        pool.addAll(collect(cat, WordDifficulty.medium));
        pool.addAll(collect(cat, WordDifficulty.hard));
      }
    } else {
      pool = collect(category, difficulty);
    }

    if (pool.isEmpty) {
      pool = _defaultWordBank[WordCategory.objects]?[WordDifficulty.easy] ?? [];
    }
    pool.shuffle(_rng);
    return pool.take(3).map((w) => w.toUpperCase()).toList();
  }

  bool _isCorrectGuess(String guess) {
    return guess.trim().toUpperCase() == wordToDraw;
  }

  int _calculateGuessScore(int time) {
    final speed = time / totalTime;
    return max(20, (50 + speed * 100).round());
  }

  bool _allGuessersCorrect() {
    if (room == null) return false;
    final guessers = room!.players.where((p) => !p.isDrawer);
    return correctGuessers.length >= guessers.length;
  }

  void _revealHintLetter() {
    final candidates = List<int>.generate(wordToDraw.length, (i) => i).where((i) => wordToDraw[i] != ' ').toList();
    candidates.removeWhere(revealedIndices.contains);
    if (candidates.isEmpty) return;
    revealedIndices.add(candidates[_rng.nextInt(candidates.length)]);
  }

  void _broadcastStroke(Stroke stroke) {
    onBroadcast?.call({
      'type': 'stroke:add',
      'points': stroke.points.map((p) => p == null ? null : {'x': p.dx, 'y': p.dy}).toList(),
      'color': stroke.color.toARGB32(),
      'thickness': stroke.thickness,
      'isEraser': stroke.isEraser,
    });
  }

  void _broadcastStrokePoint(Offset point) {
    onBroadcast?.call({
      'type': 'stroke:point',
      'point': {'x': point.dx, 'y': point.dy},
    });
  }

  void _broadcastStrokeEnd() {
    onBroadcast?.call({'type': 'stroke:end'});
  }

  void _ensureAiPlayers() {
    if (room == null) return;
    if (!room!.settings.aiFallback) return;
    while (room!.players.length < 2) {
      room!.players.add(Player(id: _id(), name: _aiName(), isAI: true, avatar: '🤖'));
    }
  }

  String _aiName() {
    const names = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna', 'Orion'];
    return names[_rng.nextInt(names.length)];
  }

  String _generateAiGuess() {
    final base = wordToDraw.toLowerCase();
    final chance = _rng.nextDouble();
    final level = room?.settings.aiLevel ?? 2;
    final correctThreshold = level == 1 ? 0.9 : level == 2 ? 0.75 : 0.6;
    if (chance > correctThreshold && revealedIndices.length >= (level == 1 ? 3 : 2)) {
      return base;
    }
    if (chance > (level == 1 ? 0.65 : 0.4)) {
      final hint = buildHint().replaceAll(' ', '');
      if (hint.contains('_')) {
        final letters = hint.split('');
        final idx = letters.indexOf('_');
        if (idx != -1) letters[idx] = base[idx];
        return letters.join();
      }
    }
    const decoys = ['car', 'house', 'tree', 'cat', 'dog', 'star', 'phone', 'book'];
    return decoys[_rng.nextInt(decoys.length)];
  }

  WordCategory? _parseCategory(String raw) {
    for (final c in WordCategory.values) {
      if (c.name.toLowerCase() == raw.toLowerCase()) return c;
    }
    return null;
  }

  WordDifficulty? _parseDifficulty(String raw) {
    for (final d in WordDifficulty.values) {
      if (d.name.toLowerCase() == raw.toLowerCase()) return d;
    }
    return null;
  }

  String _roomCode() {
    const letters = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => letters[_rng.nextInt(letters.length)]).join();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void _disposeTimers() {
    _roundTimer?.cancel();
    _aiTimer?.cancel();
    _wordTimer?.cancel();
    _countdownTimer?.cancel();
    _aiDrawTimer?.cancel();
  }
}
