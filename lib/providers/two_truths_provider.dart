import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/models/two_truths_models.dart';

class TwoTruthsProvider extends ChangeNotifier {
  List<Player> _players = [];
  TwoTruthsPhase _phase = TwoTruthsPhase.setup;
  int _currentRoundIndex = 0;
  int _totalRounds = 0;
  
  // Callback for networking
  Function(Map<String, dynamic>)? onBroadcast;

  // Timer related
  Timer? _timer;
  int _secondsRemaining = 0;
  static const int inputTimeLimit = 60;
  static const int votingTimeLimit = 30;

  int get secondsRemaining => _secondsRemaining;
  
  TwoTruthsRound? _currentRound;
  List<Player> get players => _players;
  TwoTruthsPhase get phase => _phase;
  int get currentRoundNumber => _currentRoundIndex + 1;
  int get totalRounds => _totalRounds;
  TwoTruthsRound? get currentRound => _currentRound;
  
  Player? get currentStoryteller {
    if (_players.isEmpty || _currentRound == null) return null;
    return _players.firstWhere((p) => p.id == _currentRound!.storytellerId, orElse: () => _players[0]);
  }

  void _startTimer(int seconds, VoidCallback onExpired) {
    _timer?.cancel();
    _secondsRemaining = seconds;
    notifyListeners();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        onExpired();
      }
    });
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

  void setupGame(List<Player> players, {int roundsPerPlayer = 1}) {
    _players = players;
    _totalRounds = players.length * roundsPerPlayer;
    _currentRoundIndex = 0;
    _startNewRound();
  }

  void _startNewRound() {
    _timer?.cancel();
    if (_currentRoundIndex >= _totalRounds) {
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
    
    _startTimer(inputTimeLimit, () {
      // If they didn't input, auto-generate or skip?
      // For now, let's just force next round if host/local.
      // In a real app, you might kick.
      nextRound(); 
    });
    
    notifyListeners();
  }

  void submitStatements(List<String> truths, String lie) {
    if (_currentRound == null) return;
    _timer?.cancel();

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

    _startTimer(votingTimeLimit, () {
      revealResults();
    });
    
    notifyListeners();
  }

  void submitVote(String voterId, int statementIndex) {
    if (_currentRound == null || _phase != TwoTruthsPhase.voting) return;
    
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
    _timer?.cancel();
    _phase = TwoTruthsPhase.reveal;
    
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

    // Storyteller gets 1 point if majority failed (or at least one failed? 
    // User said: "+1 point to storyteller if majority fails")
    final majorityCount = (_players.length - 1) / 2;
    if (correctGuesses < majorityCount) {
      _updatePlayerScore(_currentRound!.storytellerId, 1);
    }

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
    _timer?.cancel();
    _secondsRemaining = 0;
    for (var i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(score: 0);
    }
    _currentRoundIndex = 0;
    _phase = TwoTruthsPhase.setup;
    notifyListeners();
  }
}
