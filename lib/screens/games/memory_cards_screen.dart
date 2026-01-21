import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/widgets/premium_ui.dart';

class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({super.key});

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

enum _MemoryStage { intro, playing }

class _LevelConfig {
  final int gridSize;
  final int timeLimitSec;
  final bool colorTraps;
  final List<String> emojiPool;

  const _LevelConfig({
    required this.gridSize,
    required this.timeLimitSec,
    required this.colorTraps,
    required this.emojiPool,
  });

  int get pairCount => (gridSize * gridSize) ~/ 2;

  String get label => '${gridSize}x$gridSize';
}

class _CardData {
  final String emoji;
  final Color faceColor;
  final bool isTrap;

  const _CardData({
    required this.emoji,
    required this.faceColor,
    required this.isTrap,
  });
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  static const _prefsUnlockedKey = 'memory_cards_unlocked_level';
  static const _prefsStarsKey = 'memory_cards_stars';

  final Random _rng = Random();
  _MemoryStage _stage = _MemoryStage.intro;

  final List<_LevelConfig> _levels = const [
    _LevelConfig(
      gridSize: 2,
      timeLimitSec: 30,
      colorTraps: false,
      emojiPool: ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'],
    ),
    _LevelConfig(
      gridSize: 4,
      timeLimitSec: 70,
      colorTraps: false,
      emojiPool: ['🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒', '🥝', '🥑', '🥕', '🌽', '🥔'],
    ),
    _LevelConfig(
      gridSize: 6,
      timeLimitSec: 140,
      colorTraps: true,
      emojiPool: ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '😋', '😝', '😜', '🤪', '🤔'],
    ),
    _LevelConfig(
      gridSize: 8,
      timeLimitSec: 210,
      colorTraps: true,
      emojiPool: ['🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '⬜', '⬛', '🟫', '🔺', '🔷', '🔶', '🔸', '🔹', '⭐', '🌙', '☀️', '🌟', '✨', '⚡️'],
    ),
  ];

  int _unlockedLevel = 0;
  Map<String, int> _starsByLevel = {};
  int _selectedLevel = 0;

  late List<_CardData> _cards;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;
  int _firstFlippedIndex = -1;
  bool _isProcessing = false;
  int _matchesFound = 0;
  int _moves = 0;
  int _timeLeft = 0;
  Timer? _timer;
  int _penaltySeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getInt(_prefsUnlockedKey) ?? 0;
    final starsJson = prefs.getStringList(_prefsStarsKey) ?? [];
    final Map<String, int> stars = {};
    for (final entry in starsJson) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        stars[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    if (!mounted) return;
    setState(() {
      _unlockedLevel = unlocked.clamp(0, _levels.length - 1);
      _selectedLevel = _unlockedLevel;
      _starsByLevel = stars;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsUnlockedKey, _unlockedLevel);
    final list = _starsByLevel.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_prefsStarsKey, list);
  }

  void _startLevel(int levelIndex) {
    final level = _levels[levelIndex];
    GameFeedbackService.tap();
    _timer?.cancel();
    _cards = _buildDeck(level);
    _isFlipped = List.generate(_cards.length, (_) => false);
    _isMatched = List.generate(_cards.length, (_) => false);
    _firstFlippedIndex = -1;
    _isProcessing = false;
    _matchesFound = 0;
    _moves = 0;
    _penaltySeconds = 0;
    _timeLeft = level.timeLimitSec;
    setState(() {
      _stage = _MemoryStage.playing;
      _selectedLevel = levelIndex;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        timer.cancel();
        _onTimeExpired();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  void _onTimeExpired() {
    GameFeedbackService.error();
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: GameCatalog.allGames.firstWhere((g) => g.id == 'memory_cards', orElse: () => GameCatalog.allGames[0]),
          score: _calculateScore(),
          isWin: false,
          customMessage: 'Time\'s up! Try again.',
          onReplay: () => Navigator.of(context).pushReplacementNamed('/memory-cards'),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    if (_stage != _MemoryStage.playing) return;
    if (_isProcessing || _isFlipped[index] || _isMatched[index]) return;

    GameFeedbackService.tap();
    setState(() {
      _isFlipped[index] = true;
    });

    if (_firstFlippedIndex == -1) {
      _firstFlippedIndex = index;
    } else {
      _isProcessing = true;
      _moves++;
      final firstCard = _cards[_firstFlippedIndex];
      final secondCard = _cards[index];

      if (firstCard.emoji == secondCard.emoji) {
        GameFeedbackService.success();
        setState(() {
          _isMatched[index] = true;
          _isMatched[_firstFlippedIndex] = true;
          _firstFlippedIndex = -1;
          _isProcessing = false;
          _matchesFound++;
        });
        if (_matchesFound == _levels[_selectedLevel].pairCount) {
          _onLevelComplete();
        }
      } else {
        GameFeedbackService.error();
        if (_levels[_selectedLevel].colorTraps && (firstCard.isTrap || secondCard.isTrap)) {
          _penaltySeconds += 2;
          _timeLeft = max(0, _timeLeft - 2);
        }
        Timer(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _isFlipped[index] = false;
            _isFlipped[_firstFlippedIndex] = false;
            _firstFlippedIndex = -1;
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _onLevelComplete() {
    _timer?.cancel();
    final stars = _calculateStars();
    final levelKey = _levels[_selectedLevel].label;
    final existing = _starsByLevel[levelKey] ?? 0;
    if (stars > existing) {
      _starsByLevel[levelKey] = stars;
    }

    if (_selectedLevel == _unlockedLevel && _unlockedLevel < _levels.length - 1) {
      _unlockedLevel++;
    }
    _saveProgress();

    final score = _calculateScore();
    final message = 'Completed ${_levels[_selectedLevel].label} • $stars ★';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: GameCatalog.allGames.firstWhere((g) => g.id == 'memory_cards', orElse: () => GameCatalog.allGames[0]),
          score: score,
          isWin: true,
          customMessage: message,
          onReplay: () => Navigator.of(context).pushReplacementNamed('/memory-cards'),
        ),
      ),
    );
  }

  int _calculateStars() {
    final level = _levels[_selectedLevel];
    final optimalMoves = level.pairCount;
    if (_moves <= (optimalMoves * 1.2) && _timeLeft >= (level.timeLimitSec * 0.4)) return 3;
    if (_moves <= (optimalMoves * 1.6)) return 2;
    return 1;
  }

  int _calculateScore() {
    final level = _levels[_selectedLevel];
    final base = level.pairCount * 50;
    final timeBonus = max(0, _timeLeft * 5);
    final movePenalty = max(0, (_moves - level.pairCount)) * 10;
    final trapPenalty = _penaltySeconds * 5;
    return max(0, base + timeBonus - movePenalty - trapPenalty);
  }

  List<_CardData> _buildDeck(_LevelConfig level) {
    final pool = [...level.emojiPool]..shuffle();
    final chosen = pool.take(level.pairCount).toList();
    final colors = [
      const Color(0xFF00BCD4),
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
      const Color(0xFFFF4081),
      const Color(0xFF00C853),
      const Color(0xFFFFD740),
      const Color(0xFF5C6BC0),
    ];
    final List<_CardData> cards = [];
    for (final emoji in chosen) {
      final color = colors[_rng.nextInt(colors.length)];
      final isTrap = level.colorTraps && _rng.nextDouble() < 0.35;
      cards.add(_CardData(emoji: emoji, faceColor: color, isTrap: isTrap));
      cards.add(_CardData(emoji: emoji, faceColor: color, isTrap: isTrap));
    }
    cards.shuffle();
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return GameBaseScreen(
      title: 'Memory Cards',
      score: _matchesFound * 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _stage == _MemoryStage.intro ? _buildIntro() : _buildGame(),
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
                const Text('Flip cards, match pairs, and clear the board before time runs out.', style: TextStyle(color: AppConstants.textSecondary)),
                const SizedBox(height: 8),
                const Text('Fewer moves = more stars. Color traps add penalties!', style: TextStyle(color: AppConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Levels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _levels.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final level = entry.value;
                    final locked = idx > _unlockedLevel;
                    final stars = _starsByLevel[level.label] ?? 0;
                    return GestureDetector(
                      onTap: locked ? null : () => _startLevel(idx),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: locked ? Colors.white.withAlpha(8) : AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: locked ? Colors.white24 : AppConstants.primaryColor.withAlpha(60)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(level.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                if (locked) const Icon(Icons.lock, color: Colors.white54, size: 16),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${level.timeLimitSec}s', style: const TextStyle(color: AppConstants.textSecondary)),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(3, (i) {
                                return Icon(
                                  i < stars ? Icons.star : Icons.star_border,
                                  color: AppConstants.accentGold,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    final level = _levels[_selectedLevel];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusRow(level),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _timeLeft / max(1, level.timeLimitSec),
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(10),
          valueColor: AlwaysStoppedAnimation<Color>(
            _timeLeft < 10 ? AppConstants.errorColor : AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: level.gridSize,
              crossAxisSpacing: level.gridSize >= 6 ? 4 : 6,
              mainAxisSpacing: level.gridSize >= 6 ? 4 : 6,
              childAspectRatio: 1,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final scale = level.gridSize >= 8
                  ? 0.86
                  : level.gridSize >= 6
                      ? 0.9
                      : 0.96;
              return Transform.scale(
                scale: scale,
                child: _MemoryCardWidget(
                  data: _cards[index],
                  isFlipped: _isFlipped[index],
                  isMatched: _isMatched[index],
                  gridSize: level.gridSize,
                  onTap: () => _onCardTap(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(_LevelConfig level) {
    return Row(
      children: [
        _buildChip('Level ${level.label}', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip('Moves $_moves', AppConstants.primaryColor),
        const SizedBox(width: 8),
        _buildChip('Matches $_matchesFound/${level.pairCount}', AppConstants.successColor),
        const Spacer(),
        _buildChip('${_timeLeft}s', AppConstants.warningColor),
      ],
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

class _MemoryCardWidget extends StatelessWidget {
  final _CardData data;
  final bool isFlipped;
  final bool isMatched;
  final int gridSize;
  final VoidCallback onTap;

  const _MemoryCardWidget({
    required this.data,
    required this.isFlipped,
    required this.isMatched,
    required this.gridSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showFront = isFlipped || isMatched;
    final radius = gridSize >= 6 ? 10.0 : 12.0;
    final emojiSize = gridSize >= 8 ? 16.0 : gridSize >= 6 ? 18.0 : 22.0;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: showFront ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) {
          final angle = value * pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: value < 0.5
                ? _buildBack(context, radius)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildFront(context, radius, emojiSize),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context, double radius, double emojiSize) {
    return Container(
      decoration: BoxDecoration(
        color: data.faceColor.withAlpha(80),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: data.faceColor.withAlpha(160)),
      ),
      child: Center(
        child: Text(data.emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }

  Widget _buildBack(BuildContext context, double radius) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.surfaceColor,
            data.isTrap ? AppConstants.errorColor.withAlpha(30) : AppConstants.primaryColor.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white24),
      ),
      child: const Center(
        child: Icon(Icons.question_mark, color: Colors.white54),
      ),
    );
  }
}
