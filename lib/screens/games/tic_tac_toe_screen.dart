import 'dart:async';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  final List<String> _board = List.filled(9, '');
  bool _isXTurn = true; // X is Player, O is AI
  bool _gameOver = false;
  bool _isThinking = false;
  String _status = "Your Turn";
  List<int>? _winningLine;
  int _playerScore = 0;
  int _aiScore = 0;
  int _draws = 0;

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

  void _onTap(int index) {
    if (_board[index].isNotEmpty || _gameOver || !_isXTurn || _isThinking) return;

    GameFeedbackService.tap();
    setState(() {
      _board[index] = 'X';
      _isXTurn = false;
      _status = "AI Thinking...";
    });

    if (_checkWin('X')) {
      _endGame(true);
    } else if (_isBoardFull()) {
      _endGame(null); // Draw
    } else {
      // AI Move
      _isThinking = true;
      Timer(const Duration(milliseconds: 450), _aiMove);
    }
  }

  void _aiMove() {
    if (_gameOver || !mounted) return;
    final move = _findBestMove();
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

    if (_checkWin('O')) {
      _endGame(false);
    } else if (_isBoardFull()) {
      _endGame(null);
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

  void _endGame(bool? playerWon) {
    setState(() {
      _gameOver = true;
      if (playerWon == true) {
        _status = "You Won!";
        _playerScore++;
        GameFeedbackService.success();
      } else if (playerWon == false) {
        _status = "AI Won!";
        _aiScore++;
        GameFeedbackService.error();
      } else {
        _status = "Draw!";
        _draws++;
        GameFeedbackService.tap();
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
         MaterialPageRoute(
           builder: (_) => GameResultScreen(
             gameInfo: GameCatalog.allGames.firstWhere((g) => g.id == 'tic_tac_toe', orElse: () => GameCatalog.allGames[0]), 
             score: playerWon == true ? 100 : (playerWon == null ? 20 : 0), 
             isWin: playerWon == true, 
             customMessage: _status,
             onReplay: () => Navigator.of(context).pushReplacementNamed('/tic-tac-toe'),
           )
         )
       );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBaseScreen(
      title: 'Tic Tac Toe',
      child: Column(
        children: [
          _buildScoreHeader(),
          const SizedBox(height: 16),
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
          _buildScoreChip("You", _playerScore, AppConstants.primaryColor),
          _buildScoreChip("Draws", _draws, AppConstants.textSecondary),
          _buildScoreChip("AI", _aiScore, AppConstants.errorColor),
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
