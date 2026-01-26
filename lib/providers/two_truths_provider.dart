import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/models/two_truths_models.dart';

class TwoTruthsProvider extends ChangeNotifier {
  List<Player> _players = [];
  TwoTruthsPhase _phase = TwoTruthsPhase.intro;
  int _currentRoundIndex = 0;
  int _totalRounds = 0;
  
  // Callback for networking
  Function(Map<String, dynamic>)? onBroadcast;

  TwoTruthsRound? _currentRound;
  int _lastCorrectGuesses = 0;
  bool _storytellerWon = false;
  List<Player> get players => _players;
  TwoTruthsPhase get phase => _phase;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => _totalRounds;
  TwoTruthsRound? get currentRound => _currentRound;
  int get lastCorrectGuesses => _lastCorrectGuesses;
  bool get storytellerWon => _storytellerWon;
  
  Player? get currentStoryteller {
    if (_players.isEmpty || _currentRound == null) return null;
    return _players.firstWhere((p) => p.id == _currentRound!.storytellerId, orElse: () => _players[0]);
  }

  void startSetup() {
    _phase = TwoTruthsPhase.setup;
    notifyListeners();
  }

  void addPlayer(Player player) {
    _players.add(player);
    notifyListeners();
  }

  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
    if (_players.length < 2 && _phase != TwoTruthsPhase.setup) {
       resetGame();
    }
    notifyListeners();
  }

  // When setting up a party game, if AI fallback is enabled we will
  // add simple AI players until a playable minimum is reached.
  void setupGame(List<Player> players, {int totalRounds = 0, bool aiFallback = true}) {
    _players = [...players];
    _totalRounds = totalRounds;
    _currentRoundIndex = 0;

    // Ensure minimum players (Two Truths requires at least 3)
    const minPlayers = 3;
    if (aiFallback && _players.length < minPlayers) {
      final needed = minPlayers - _players.length;
      for (var i = 0; i < needed; i++) {
        final id = 'ai_${DateTime.now().microsecondsSinceEpoch}_$i';
        final name = 'AI ${_randomName()}';
        _players.add(Player(id: id, name: name, isHost: false));
      }
    }

    _startNewRound();
  }

  String _randomName() {
    const names = ['Sam', 'Alex', 'Charlie', 'Taylor', 'Jordan', 'Riley', 'Casey', 'Jamie', 'Morgan'];
    return names[Random().nextInt(names.length)];
  }

  void _startNewRound() {
    if (_totalRounds > 0 && _currentRoundIndex >= _totalRounds) {
      _phase = TwoTruthsPhase.scoreboard;
      notifyListeners();
      return;
    }

    final storyteller = _players[_currentRoundIndex % _players.length];
    _currentRound = TwoTruthsRound(
      storytellerId: storyteller.id,
      statements: [],
    );
    _phase = TwoTruthsPhase.input;

    notifyListeners();
  }

  void submitStatements(List<String> truths, String lie) {
    if (_currentRound == null) return;

    final List<Statement> all = [
      ...truths.map((t) => Statement(text: t, isLie: false)),
      Statement(text: lie, isLie: true),
    ];
    
    all.shuffle(Random());

    _currentRound = TwoTruthsRound(
      storytellerId: _currentRound!.storytellerId,
      statements: all,
    );
    _phase = TwoTruthsPhase.voting;
    
    // Networking
    onBroadcast?.call({
      'type': 'two_truths_statements',
      'statements': all.map((s) => {'text': s.text, 'isLie': s.isLie}).toList(),
    });

    notifyListeners();
  }

  void submitVote(String voterId, int statementIndex) {
    if (_currentRound == null || _phase != TwoTruthsPhase.voting) return;
    if (_currentRound!.votes.containsKey(voterId)) return;
    
    _currentRound!.votes[voterId] = statementIndex;
    
    // Networking
    onBroadcast?.call({
      'type': 'two_truths_vote',
      'voterId': voterId,
      'index': statementIndex,
    });

    notifyListeners();

    // Check if everyone except the storyteller has voted
    final votersCount = _players.length - 1;
    if (_currentRound!.votes.length >= votersCount) {
      revealResults();
    }
  }

  void revealResults() {
    _phase = TwoTruthsPhase.reveal;

    // Ensure AI voters have voted if needed (simple believable behavior)
    for (final p in _players) {
      if (p.id.startsWith('ai_') && !_currentRound!.votes.containsKey(p.id)) {
        // AI has a bias: 70% chance to guess wrong (to make storyteller possibly win sometimes)
        final rnd = Random().nextDouble();
        final correctIndex = _currentRound!.statements.indexWhere((s) => s.isLie);
        final pick = rnd < 0.6 ? correctIndex : Random().nextInt(_currentRound!.statements.length);
        _currentRound!.votes[p.id] = pick;
      }
    }

    // Calculate scores
    final correctIndex = _currentRound!.statements.indexWhere((s) => s.isLie);
    int correctGuesses = 0;

    for (var entry in _currentRound!.votes.entries) {
      final voterId = entry.key;
      final voteIndex = entry.value;

      if (voteIndex == correctIndex) {
        correctGuesses++;
        _updatePlayerScore(voterId, 1);
      }
    }

    final votersCount = _players.length - 1;
    final wrongGuesses = votersCount - correctGuesses;
    _storytellerWon = wrongGuesses > correctGuesses;
    if (_storytellerWon) {
      _updatePlayerScore(_currentRound!.storytellerId, 2);
    }

    _lastCorrectGuesses = correctGuesses;

    notifyListeners();
  }

  void _updatePlayerScore(String playerId, int increment) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(score: _players[index].score + increment);
    }
  }

  void nextRound() {
    _currentRoundIndex++;
    _startNewRound();
  }

  void resetGame() {
    for (var i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(score: 0);
    }
    _currentRoundIndex = 0;
    _phase = TwoTruthsPhase.intro;
    notifyListeners();
  }

  void restartGame() {
    for (var i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(score: 0);
    }
    _currentRoundIndex = 0;
    _phase = TwoTruthsPhase.setup;
    notifyListeners();
  }
}
