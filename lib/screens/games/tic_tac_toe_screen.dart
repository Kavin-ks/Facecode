import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> with TickerProviderStateMixin {
  final List<String> _board = List.filled(9, '');
  bool _isXTurn = true; // X is Player, O is AI or Player 2
  bool _gameOver = false;
  bool _isThinking = false;
  String _status = "Your Turn";
  List<int>? _winningLine;
  int _playerScore = 0;
  int _aiScore = 0;
  int _draws = 0;

  // Modes & progression
  bool _isPvP = false;
  String _aiDifficulty = 'Hard'; // Easy, Medium, Hard
  bool _bestOf3 = false;
  int _playerSets = 0;
  int _aiSets = 0;

  int _currentStreak = 0;
  int _bestStreak = 0;
  static const String _prefsDailyWins = 'tic_daily_wins';
  int _dailyWins = 0;

  // Animation controllers
  late final AnimationController _winLineController;
  final Random _rng = Random();

  static const List<List<int>> _winLines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  @override
  void initState() {
    super.initState();
    _winLineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadDailyWins();
    SoundManager().init();
  }

  @override
  void dispose() {
    _winLineController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyWins() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyWins = prefs.getInt(_prefsDailyWins) ?? 0;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveDailyWins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsDailyWins, _dailyWins);
  }

  void _onTap(int index) {
    if (_board[index].isNotEmpty || _gameOver || _isThinking) return;

    GameFeedbackService.tap();
    SoundManager().playUiSound(SoundManager.sfxUiTap);

    // PvP handling: if PvP allow both players to tap
    if (_isPvP) {
      setState(() {
        _board[index] = _isXTurn ? 'X' : 'O';
        _isXTurn = !_isXTurn;
        _status = _isXTurn ? "Player X's Turn" : "Player O's Turn";
      });
      SoundManager().playGameSound(SoundManager.sfxTurnChange);

      if (_checkWin(_board[index])) {
        _endRound(_board[index] == 'X');
      } else if (_isBoardFull()) {
        _endRound(null);
      }
      return;
    }

    // PvAI
    if (!_isXTurn) return; // wait for player turn

    setState(() {
      _board[index] = 'X';
      _isXTurn = false;
      _status = "AI Thinking...";
    });

    if (_checkWin('X')) {
      _endRound(true);
    } else if (_isBoardFull()) {
      _endRound(null); // Draw
    } else {
      // AI Move
      _isThinking = true;
      Timer(const Duration(milliseconds: 450), _aiMove);
    }
  }

  void _aiMove() {
    if (_gameOver || !mounted) return;
    int move;
    switch (_aiDifficulty) {
      case 'Easy':
        move = _randomMove();
        break;
      case 'Medium':
        move = _mediumMove();
        break;
      default:
        move = _findBestMove(); // hard (minimax)
    }

    if (move == -1) {
      _isThinking = false;
      return;
    }

    setState(() {
      _board[move] = 'O';
      _isXTurn = true;
      _status = "Your Turn";
      _isThinking = false;
    });

    SoundManager().playGameSound(SoundManager.sfxTurnChange);

    if (_checkWin('O')) {
      _endRound(false);
    } else if (_isBoardFull()) {
      _endRound(null);
    }
  }

  bool _checkWin(String player) {
    for (final line in _winLines) {
      if (_board[line[0]] == player && _board[line[1]] == player && _board[line[2]] == player) {
        _winningLine = line;
        return true;
      }
    }
    return false;
  }

  bool _checkWinFor(List<String> board, String player) {
    for (final line in _winLines) {
      if (board[line[0]] == player && board[line[1]] == player && board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  bool _isBoardFull() {
    return !_board.contains('');
  }

  void _endRound(bool? playerWon) {
    setState(() {
      _gameOver = true;
      if (playerWon == true) {
        _status = _isPvP ? "Player X won" : "You Won!";
        _playerScore++;
        _currentStreak++;
        _bestStreak = max(_bestStreak, _currentStreak);
        GameFeedbackService.success();
        SoundManager().playGameSound(SoundManager.sfxGameWin);
        // award daily win
        _dailyWins++;
        _saveDailyWins();
      } else if (playerWon == false) {
        _status = _isPvP ? "Player O won" : "AI Won!";
        _aiScore++;
        _currentStreak = 0;
        GameFeedbackService.error();
        SoundManager().playGameSound(SoundManager.sfxGameFail);
      } else {
        _status = "Draw!";
        _draws++;
        _currentStreak = 0;
        GameFeedbackService.tap();
      }
    });

    // handle best-of-3 set counting
    if (_bestOf3) {
      if (playerWon == true) _playerSets++;
      if (playerWon == false) _aiSets++;

      if (_playerSets >= 2 || _aiSets >= 2) {
        // series winner
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          final win = _playerSets > _aiSets;
          final gameInfo = GameCatalog.allGames.firstWhere((g) => g.id == 'tic_tac_toe', orElse: () => GameCatalog.allGames[0]);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameResultScreen(
                gameInfo: gameInfo,
                score: win ? 200 : 0,
                isWin: win,
                onReplay: () {
                  Navigator.of(context).pop();
                },
                customMessage: win ? 'Series won!' : 'Great effort! Keep practicing.',
              ),
            ),
          );
        });
        return;
      }
    }

    // show winning animation line briefly
    if (_winningLine != null) {
      _winLineController.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // After a brief pause start next round or prompt result
      if (!_bestOf3) {
        _resetBoard();
      } else {
        // continue next game in set
        _resetBoard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBaseScreen(
      title: 'Tic Tac Toe',
      child: Column(
        children: [
          _buildScoreHeader(),
          const SizedBox(height: 12),
          _buildModeControls(),
          const SizedBox(height: 12),
          _buildStatusPill(),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildBoard(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBottomControls(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text("You", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                _playerScore.toString(),
                style: TextStyle(color: AppConstants.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_bestOf3) ...[
                const SizedBox(height: 6),
                Text('Sets: $_playerSets', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ],
          ),
          _buildScoreChip("Draws", _draws, AppConstants.textSecondary),
          Column(
            children: [
              Text("AI", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                _aiScore.toString(),
                style: TextStyle(color: AppConstants.errorColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_bestOf3) ...[
                const SizedBox(height: 6),
                Text('Sets: $_aiSets', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Switch.adaptive(
              value: _isPvP,
              onChanged: (v) {
                setState(() {
                  _isPvP = v;
                  _resetBoard();
                  _status = _isPvP ? 'Player X starts' : 'Your Turn';
                });
                SoundManager().playUiSound(SoundManager.sfxUiTap);
              },
            ),
            const SizedBox(width: 8),
            Text(_isPvP ? 'PvP' : 'PvAI', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            if (!_isPvP)
              Row(
                children: [
                  const Text('Diff:', style: TextStyle(color: Colors.white54)),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _aiDifficulty,
                    dropdownColor: AppConstants.surfaceColor,
                    items: ['Easy', 'Medium', 'Hard'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _aiDifficulty = v);
                      SoundManager().playUiSound(SoundManager.sfxUiTap);
                    },
                  ),
                ],
              ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Text('Best of 3', style: TextStyle(color: Colors.white54)),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: _bestOf3,
                  onChanged: (v) {
                    setState(() {
                      _bestOf3 = v;
                      _playerSets = 0;
                      _aiSets = 0;
                    });
                    SoundManager().playUiSound(SoundManager.sfxUiTap);
                  },
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppConstants.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppConstants.warningColor, size: 14),
                  const SizedBox(width: 6),
                  Text('Wins: $_dailyWins', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppConstants.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: AppConstants.primaryColor, size: 14),
                  const SizedBox(width: 6),
                  Text('Streak: $_currentStreak', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final value = _board[index];
          final isWinning = _winningLine?.contains(index) ?? false;

          return GestureDetector(
            onTap: () => _onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isWinning ? Colors.white10 : AppConstants.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isWinning ? Colors.white54 : Colors.white10,
                  width: isWinning ? 2 : 1,
                ),
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: value.isEmpty ? 1.0 : 1.1,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value == 'X' ? AppConstants.primaryColor : AppConstants.errorColor,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetBoard,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("NEW ROUND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetScores,
            icon: const Icon(Icons.restart_alt, color: Colors.white),
            label: const Text("RESET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  void _resetScores() {
    setState(() {
      _playerScore = 0;
      _aiScore = 0;
      _draws = 0;
    });
    _resetBoard();
  }

  void _resetBoard() {
    setState(() {
      for (int i = 0; i < _board.length; i++) {
        _board[i] = '';
      }
      _isXTurn = true;
      _gameOver = false;
      _isThinking = false;
      _status = "Your Turn";
      _winningLine = null;
    });
  }

  int _findBestMove() {
    int bestScore = -1000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = 'O';
        final score = _minimax(_board, 0, false);
        _board[i] = '';

        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _randomMove() {
    final empties = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        empties.add(i);
      }
    }
    if (empties.isEmpty) return -1;
    return empties[_rng.nextInt(empties.length)];
  }

  int _mediumMove() {
    // 1) Win if possible
    for (int i=0;i<9;i++){
      if (_board[i].isEmpty){
        _board[i]='O';
        if (_checkWin('O')){ _board[i]=''; return i; }
        _board[i]='';
      }
    }
    // 2) Block player win
    for (int i=0;i<9;i++){
      if (_board[i].isEmpty){
        _board[i]='X';
        if (_checkWin('X')){ _board[i]=''; return i; }
        _board[i]='';
      }
    }
    // 3) take center
    if (_board[4].isEmpty) return 4;
    // 4) take opposite corner
    final corners = [0,2,6,8];
    for (final c in corners) {
      final opp = 8 - c;
      if (_board[c]=='X' && _board[opp].isEmpty) return opp;
    }
    // 5) take any corner
    final availableCorners = corners.where((c) => _board[c].isEmpty).toList();
    if (availableCorners.isNotEmpty) return availableCorners[_rng.nextInt(availableCorners.length)];
    // 6) fallback random
    return _randomMove();
  }

  int _minimax(List<String> board, int depth, bool isMax) {
    if (_checkWinFor(board, 'O')) return 10 - depth;
    if (_checkWinFor(board, 'X')) return depth - 10;
    if (!board.contains('')) return 0;

    if (isMax) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'O';
          best = best > _minimax(board, depth + 1, false) ? best : _minimax(board, depth + 1, false);
          board[i] = '';
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'X';
          best = best < _minimax(board, depth + 1, true) ? best : _minimax(board, depth + 1, true);
          board[i] = '';
        }
      }
      return best;
    }
  }
}
