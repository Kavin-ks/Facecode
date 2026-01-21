import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/widgets/premium_ui.dart';

class DrawGuessScreen extends StatefulWidget {
  const DrawGuessScreen({super.key});

  @override
  State<DrawGuessScreen> createState() => _DrawGuessScreenState();
}

enum _DrawStage { intro, playing, roundEnd, finished }

class _Stroke {
  final List<Offset?> points;
  final Color color;
  final double width;
  final bool isEraser;

  _Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isEraser,
  });
}

class _GuessMessage {
  final String name;
  final String text;
  final bool isCorrect;
  final bool isSystem;

  const _GuessMessage({
    required this.name,
    required this.text,
    this.isCorrect = false,
    this.isSystem = false,
  });
}

class _DrawGuessScreenState extends State<DrawGuessScreen> {
  final Random _rng = Random();
  final TextEditingController _guessController = TextEditingController();
  final ScrollController _chatController = ScrollController();

  final List<Color> _palette = [
    Colors.black,
    const Color(0xFFEF5350),
    const Color(0xFF42A5F5),
    const Color(0xFF66BB6A),
    const Color(0xFFFFCA28),
    const Color(0xFFAB47BC),
    const Color(0xFF8D6E63),
    const Color(0xFF00ACC1),
  ];
  final List<double> _brushSizes = [4, 8, 12];

  Color _selectedColor = Colors.black;
  double _selectedBrush = 6;
  bool _isEraser = false;

  List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;

  _DrawStage _stage = _DrawStage.intro;
  final int _totalRounds = 3;
  int _roundIndex = 0;
  int _score = 0;
  int _timeLeft = 0;
  Timer? _timer;
  Timer? _aiTimer;
  int _hintsUsed = 0;
  int _correctRounds = 0;
  bool _hasPlayers = false;

  final List<String> _aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna'];
  final List<_GuessMessage> _messages = [];

  final List<String> _words = [
    'apple', 'bicycle', 'castle', 'rocket', 'tiger', 'pizza', 'guitar', 'rainbow', 'camera', 'dragon',
    'volcano', 'island', 'umbrella', 'chocolate', 'sunflower', 'elephant', 'snowman', 'airplane', 'cactus', 'piano',
    'lantern', 'butterfly', 'lighthouse', 'mountain', 'suitcase', 'spaceship', 'popcorn', 'football', 'telescope', 'dolphin',
  ];
  String _wordToDraw = '';
  Set<int> _revealedIndices = {};

  @override
  void dispose() {
    _timer?.cancel();
    _aiTimer?.cancel();
    _guessController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _startGame() {
    GameFeedbackService.tap();
    _score = 0;
    _roundIndex = 0;
    _correctRounds = 0;
    _messages.clear();
    _nextRound();
  }

  void _nextRound() {
    _timer?.cancel();
    _aiTimer?.cancel();
    _strokes = [];
    _currentStroke = null;
    _hintsUsed = 0;
    _revealedIndices = {};
    _wordToDraw = _words[_rng.nextInt(_words.length)].toUpperCase();
    _timeLeft = 90;
    _roundIndex++;
    _messages.add(const _GuessMessage(name: 'System', text: 'New round started!', isSystem: true));
    setState(() {
      _stage = _DrawStage.playing;
    });
    _startTimer();
    _startAiGuessing();
    _scrollChatToBottom();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        timer.cancel();
        _endRound(success: false, reason: 'Time is up');
      } else {
        setState(() {
          _timeLeft--;
          if (_timeLeft % 15 == 0) {
            _revealHintLetter();
          }
        });
      }
    });
  }

  void _startAiGuessing() {
    if (_hasPlayers) return; // player guesses instead of AI
    _aiTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _stage != _DrawStage.playing) return;
      final aiName = _aiNames[_rng.nextInt(_aiNames.length)];
      final guess = _generateAiGuess();
      _addGuess(aiName, guess);
      if (_isCorrectGuess(guess)) {
        _endRound(success: true, reason: '$aiName guessed correctly');
      }
    });
  }

  String _generateAiGuess() {
    final base = _wordToDraw.toLowerCase();
    final chance = _rng.nextDouble();
    if (chance > 0.75 && _revealedIndices.length >= 2) {
      return base;
    }
    if (chance > 0.4) {
      final hint = _buildHint().replaceAll(' ', '');
      return hint.replaceAll('_', base[_rng.nextInt(base.length)]).toLowerCase();
    }
    const decoys = ['car', 'house', 'tree', 'cat', 'dog', 'star', 'phone', 'book'];
    return decoys[_rng.nextInt(decoys.length)];
  }

  void _addGuess(String name, String text, {bool correct = false}) {
    _messages.add(_GuessMessage(name: name, text: text, isCorrect: correct));
    _scrollChatToBottom();
    setState(() {});
  }

  void _scrollChatToBottom() {
    if (!_chatController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatController.hasClients) return;
      _chatController.animateTo(
        _chatController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _endRound({required bool success, required String reason}) {
    _timer?.cancel();
    _aiTimer?.cancel();
    if (success) {
      GameFeedbackService.success();
      _correctRounds++;
      final roundScore = _calculateRoundScore();
      _score += roundScore;
      _addGuess('System', '$reason • +$roundScore XP', correct: true);
    } else {
      GameFeedbackService.error();
      _addGuess('System', reason, correct: false);
    }

    if (_roundIndex >= _totalRounds) {
      _finishGame();
    } else {
      setState(() {
        _stage = _DrawStage.roundEnd;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _nextRound();
      });
    }
  }

  int _calculateRoundScore() {
    const base = 120;
    final timeBonus = _timeLeft * 2;
    final hintPenalty = _hintsUsed * 15;
    return max(30, base + timeBonus - hintPenalty);
  }

  void _finishGame() {
    setState(() {
      _stage = _DrawStage.finished;
    });
    final gameInfo = GameCatalog.allGames.firstWhere((g) => g.id == 'draw_guess', orElse: () => GameCatalog.allGames[0]);
    final win = _correctRounds >= 2;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: gameInfo,
          score: _score,
          isWin: win,
          customMessage: 'Rounds won $_correctRounds/$_totalRounds',
          onReplay: () => Navigator.of(context).pushReplacementNamed('/draw-guess'),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_stage != _DrawStage.playing) return;
    setState(() {
      _currentStroke = _Stroke(
        points: [details.localPosition],
        color: _selectedColor,
        width: _selectedBrush,
        isEraser: _isEraser,
      );
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_stage != _DrawStage.playing || _currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_stage != _DrawStage.playing || _currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(null);
      _currentStroke = null;
    });
  }

  void _clearCanvas() {
    GameFeedbackService.tap();
    setState(() {
      _strokes.clear();
    });
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    GameFeedbackService.tap();
    setState(() {
      _strokes.removeLast();
    });
  }

  void _revealHintLetter() {
    if (_revealedIndices.length >= _wordToDraw.length) return;
    final candidates = List<int>.generate(_wordToDraw.length, (i) => i).where((i) => _wordToDraw[i] != ' ').toList();
    candidates.removeWhere(_revealedIndices.contains);
    if (candidates.isEmpty) return;
    _revealedIndices.add(candidates[_rng.nextInt(candidates.length)]);
    _hintsUsed++;
  }

  String _buildHint() {
    return _wordToDraw.split('').asMap().entries.map((entry) {
      final idx = entry.key;
      final ch = entry.value;
      if (ch == ' ') return ' ';
      return _revealedIndices.contains(idx) ? ch : '_';
    }).join(' ');
  }

  bool _isCorrectGuess(String guess) {
    final normalized = guess.trim().toUpperCase();
    return normalized == _wordToDraw;
  }

  void _submitGuess() {
    final guess = _guessController.text.trim();
    if (guess.isEmpty) return;
    _guessController.clear();
    _addGuess('You', guess);
    if (_isCorrectGuess(guess)) {
      _endRound(success: true, reason: 'You guessed correctly');
    } else {
      GameFeedbackService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBaseScreen(
      title: 'Draw & Guess',
      score: _score,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _stage == _DrawStage.intro ? _buildIntro() : _buildGame(),
      ),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to play', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Draw the word while others guess in chat. Use hints carefully.', style: TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 8),
                const Text('3 rounds • Timer-based scoring • AI guesses in solo mode.', style: TextStyle(color: AppConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Solo (AI guesses)'),
                      selected: !_hasPlayers,
                      selectedColor: AppConstants.secondaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: !_hasPlayers ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _hasPlayers = false),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Local Players'),
                      selected: _hasPlayers,
                      selectedColor: AppConstants.primaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: _hasPlayers ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _hasPlayers = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _timeLeft / 90,
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(10),
          valueColor: AlwaysStoppedAnimation<Color>(
            _timeLeft < 15 ? AppConstants.errorColor : AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildHintCard(),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildCanvas()),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildChatPanel()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTools(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildChip('Round $_roundIndex/$_totalRounds', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip('Score $_score', AppConstants.successColor),
        const SizedBox(width: 8),
        _buildChip(_hasPlayers ? 'Players' : 'AI', AppConstants.primaryColor),
        const Spacer(),
        _buildChip('${_timeLeft}s', AppConstants.warningColor),
      ],
    );
  }

  Widget _buildHintCard() {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'WORD: ${_buildHint()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _revealHintLetter,
            child: const Text('Reveal Hint', style: TextStyle(color: AppConstants.accentGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _DrawingPainter(_strokes),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Guesses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _chatController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final color = msg.isSystem
                    ? AppConstants.textSecondary
                    : msg.isCorrect
                        ? AppConstants.successColor
                        : Colors.white;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${msg.name}: ${msg.text}', style: TextStyle(color: color, fontSize: 12)),
                );
              },
            ),
          ),
          if (_hasPlayers) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      hintText: 'Enter guess...',
                      hintStyle: const TextStyle(color: AppConstants.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitGuess,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTools() {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text('Brush', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              ..._brushSizes.map((size) {
                final selected = _selectedBrush == size;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${size.toInt()}'),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withAlpha(60),
                    backgroundColor: Colors.white.withAlpha(10),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _selectedBrush = size),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                onPressed: _undoStroke,
                icon: const Icon(Icons.undo, color: Colors.white),
              ),
              IconButton(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.delete, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isEraser = !_isEraser),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _isEraser ? AppConstants.errorColor : Colors.white.withAlpha(10),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.auto_fix_off, color: Colors.white, size: 18),
                  ),
                ),
                ..._palette.map((c) {
                  final selected = _selectedColor == c && !_isEraser;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEraser = false;
                        _selectedColor = c;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..color = Colors.white);

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.transparent : stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
