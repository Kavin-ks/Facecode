import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:facecode/services/game_feedback_service.dart';

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

  List<Stroke> strokes = [];
  Stroke? currentStroke;

  DrawStage stage = DrawStage.intro;
  final int totalRounds = 3;
  int roundIndex = 0;
  int score = 0;
  int timeLeft = 0;
  int hintsUsed = 0;
  int correctRounds = 0;
  bool hasPlayers = false;
  bool aiVerifying = false;

  final List<LocalPlayer> players = [];
  int drawerIndex = 0;
  int selectedGuesserIndex = 0;

  final List<String> aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna'];
  final List<GuessMessage> messages = [];

  final List<String> words = [
    'apple', 'bicycle', 'castle', 'rocket', 'tiger', 'pizza', 'guitar', 'rainbow', 'camera', 'dragon',
    'volcano', 'island', 'umbrella', 'chocolate', 'sunflower', 'elephant', 'snowman', 'airplane', 'cactus', 'piano',
    'lantern', 'butterfly', 'lighthouse', 'mountain', 'suitcase', 'spaceship', 'popcorn', 'football', 'telescope', 'dolphin',
  ];
  String wordToDraw = '';
  Set<int> revealedIndices = {};

  Timer? _timer;
  Timer? _aiTimer;

  void disposeTimers() {
    _timer?.cancel();
    _aiTimer?.cancel();
  }

  void setHasPlayers(bool value) {
    hasPlayers = value;
    notifyListeners();
  }

  void setSelectedGuesserIndex(int index) {
    selectedGuesserIndex = index;
    notifyListeners();
  }

  void setSelectedBrush(double value) {
    selectedBrush = value;
    notifyListeners();
  }

  void setSelectedColor(Color value) {
    selectedColor = value;
    notifyListeners();
  }

  void toggleEraser() {
    isEraser = !isEraser;
    notifyListeners();
  }

  void startGame() {
    GameFeedbackService.tap();
    score = 0;
    roundIndex = 0;
    correctRounds = 0;
    messages.clear();
    if (hasPlayers) {
      if (players.length < 2) {
        messages.add(const GuessMessage(name: 'System', text: 'Add at least 2 players to start.', isSystem: true));
        notifyListeners();
        return;
      }
      drawerIndex = 0;
      selectedGuesserIndex = players.length > 1 ? 1 : 0;
      for (final p in players) {
        p.score = 0;
      }
    }
    nextRound();
  }

  void nextRound() {
    disposeTimers();
    strokes = [];
    currentStroke = null;
    hintsUsed = 0;
    revealedIndices = {};
    wordToDraw = words[_rng.nextInt(words.length)].toUpperCase();
    timeLeft = 90;
    roundIndex++;
    if (hasPlayers && players.isNotEmpty) {
      messages.add(GuessMessage(name: 'System', text: 'Drawer: ${players[drawerIndex].name}', isSystem: true));
      selectedGuesserIndex = players.length > 1 ? (drawerIndex + 1) % players.length : 0;
    }
    messages.add(const GuessMessage(name: 'System', text: 'New round started!', isSystem: true));
    stage = DrawStage.playing;
    notifyListeners();
    startTimer();
    startAiGuessing();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0) {
        timer.cancel();
        endRound(success: false, reason: 'Time is up');
      } else {
        timeLeft--;
        if (timeLeft % 15 == 0) {
          revealHintLetter();
        }
        notifyListeners();
      }
    });
  }

  void startAiGuessing() {
    if (hasPlayers) return;
    _aiTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (stage != DrawStage.playing) return;
      final aiName = aiNames[_rng.nextInt(aiNames.length)];
      final guess = generateAiGuess();
      addGuess(aiName, guess);
      if (isCorrectGuess(guess)) {
        endRound(success: true, reason: '$aiName guessed correctly');
      }
    });
  }

  String generateAiGuess() {
    final base = wordToDraw.toLowerCase();
    final chance = _rng.nextDouble();
    if (chance > 0.75 && revealedIndices.length >= 2) {
      return base;
    }
    if (chance > 0.4) {
      final hint = buildHint().replaceAll(' ', '');
      return hint.replaceAll('_', base[_rng.nextInt(base.length)]).toLowerCase();
    }
    const decoys = ['car', 'house', 'tree', 'cat', 'dog', 'star', 'phone', 'book'];
    return decoys[_rng.nextInt(decoys.length)];
  }

  void addGuess(String name, String text, {bool correct = false}) {
    messages.add(GuessMessage(name: name, text: text, isCorrect: correct));
    notifyListeners();
  }

  void endRound({required bool success, required String reason}) {
    disposeTimers();
    if (success) {
      GameFeedbackService.success();
      correctRounds++;
      final roundScore = calculateRoundScore();
      score += roundScore;
      addGuess('System', '$reason • +$roundScore XP', correct: true);
    } else {
      GameFeedbackService.error();
      addGuess('System', reason, correct: false);
    }

    if (roundIndex >= totalRounds) {
      stage = DrawStage.finished;
      notifyListeners();
    } else {
      stage = DrawStage.roundEnd;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        if (hasPlayers && players.isNotEmpty) {
          drawerIndex = (drawerIndex + 1) % players.length;
        }
        nextRound();
      });
    }
  }

  int calculateRoundScore() {
    const base = 120;
    final timeBonus = timeLeft * 2;
    final hintPenalty = hintsUsed * 15;
    return max(30, base + timeBonus - hintPenalty);
  }

  void onPanStart(DragStartDetails details) {
    if (stage != DrawStage.playing) return;
    currentStroke = Stroke(
      points: [details.localPosition],
      color: selectedColor,
      width: selectedBrush,
      isEraser: isEraser,
    );
    strokes.add(currentStroke!);
    notifyListeners();
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (stage != DrawStage.playing || currentStroke == null) return;
    currentStroke!.points.add(details.localPosition);
    notifyListeners();
  }

  void onPanEnd(DragEndDetails details) {
    if (stage != DrawStage.playing || currentStroke == null) return;
    currentStroke!.points.add(null);
    currentStroke = null;
    notifyListeners();
  }

  void clearCanvas() {
    GameFeedbackService.tap();
    strokes.clear();
    notifyListeners();
  }

  void undoStroke() {
    if (strokes.isEmpty) return;
    GameFeedbackService.tap();
    strokes.removeLast();
    notifyListeners();
  }

  void revealHintLetter() {
    if (revealedIndices.length >= wordToDraw.length) return;
    final candidates = List<int>.generate(wordToDraw.length, (i) => i).where((i) => wordToDraw[i] != ' ').toList();
    candidates.removeWhere(revealedIndices.contains);
    if (candidates.isEmpty) return;
    revealedIndices.add(candidates[_rng.nextInt(candidates.length)]);
    hintsUsed++;
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

  bool isCorrectGuess(String guess) {
    final normalized = guess.trim().toUpperCase();
    return normalized == wordToDraw;
  }

  Future<bool> verifyWithAi(String guess) async {
    if (aiVerifying) return false;
    aiVerifying = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));
    final ok = isCorrectGuess(guess);
    aiVerifying = false;
    notifyListeners();
    return ok;
  }

  Future<void> submitGuess(String guess) async {
    final trimmed = guess.trim();
    if (trimmed.isEmpty) return;
    if (hasPlayers && players.isNotEmpty) {
      final drawer = players[drawerIndex];
      final guesser = players[selectedGuesserIndex];
      if (drawer.id == guesser.id) {
        addGuess('System', 'Drawer cannot guess.', correct: false);
        return;
      }
      addGuess(guesser.name, trimmed);
      if (isCorrectGuess(trimmed)) {
        final ok = await verifyWithAi(trimmed);
        if (!ok) return;
        final roundScore = calculateRoundScore();
        guesser.score += roundScore;
        addGuess('AI', 'Verified correct • ${guesser.name} +$roundScore', correct: true);
        endRound(success: true, reason: '${guesser.name} guessed correctly');
      } else {
        GameFeedbackService.error();
      }
      return;
    }
    addGuess('You', trimmed);
    if (isCorrectGuess(trimmed)) {
      final ok = await verifyWithAi(trimmed);
      if (!ok) return;
      endRound(success: true, reason: 'You guessed correctly');
    } else {
      GameFeedbackService.error();
    }
  }

  void addLocalPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = '${trimmed.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
    players.add(LocalPlayer(id: id, name: trimmed));
    notifyListeners();
  }

  void removePlayer(LocalPlayer p) {
    players.removeWhere((e) => e.id == p.id);
    if (drawerIndex >= players.length) drawerIndex = 0;
    if (selectedGuesserIndex >= players.length) selectedGuesserIndex = 0;
    notifyListeners();
  }

  void syncPlayersFromRoom(List<LocalPlayer> roomPlayers) {
    players
      ..clear()
      ..addAll(roomPlayers);
    drawerIndex = 0;
    selectedGuesserIndex = players.length > 1 ? 1 : 0;
    notifyListeners();
  }
}

enum DrawStage { intro, playing, roundEnd, finished }

class Stroke {
  final List<Offset?> points;
  final Color color;
  final double width;
  final bool isEraser;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isEraser,
  });
}

class GuessMessage {
  final String name;
  final String text;
  final bool isCorrect;
  final bool isSystem;

  const GuessMessage({
    required this.name,
    required this.text,
    this.isCorrect = false,
    this.isSystem = false,
  });
}

class LocalPlayer {
  final String id;
  final String name;
  int score;

  LocalPlayer({required this.id, required this.name}) : score = 0;
}
