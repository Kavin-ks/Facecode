import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/providers/analytics_provider.dart';

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
  static const _prefsUnlockedThemes = 'memory_cards_unlocked_themes';
  static const _prefsDailyKey = 'memory_cards_daily_done';

  final Random _rng = Random();
  _MemoryStage _stage = _MemoryStage.intro;

  // Expanded levels to provide longer progression (up to 9x9 for hardcore)
  final List<_LevelConfig> _levels = const [
    _LevelConfig(gridSize: 2, timeLimitSec: 30, colorTraps: false, emojiPool: ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼']),
    _LevelConfig(gridSize: 4, timeLimitSec: 70, colorTraps: false, emojiPool: ['🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒', '🥝', '🥑', '🥕', '🌽', '🥔']),
    _LevelConfig(gridSize: 6, timeLimitSec: 140, colorTraps: true, emojiPool: ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '😋', '😝', '😜', '🤪', '🤔']),
    _LevelConfig(gridSize: 8, timeLimitSec: 210, colorTraps: true, emojiPool: ['🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '⬜', '⬛', '🟫', '🔺', '🔷', '🔶', '🔸', '🔹', '⭐', '🌙', '☀️', '🌟', '✨', '⚡️']),
    _LevelConfig(gridSize: 6, timeLimitSec: 120, colorTraps: true, emojiPool: ['◼︎', '◻︎', '◆', '◇', '▲', '△', '●', '○', '◯', '⬟', '⬢', '⬣']),
    _LevelConfig(gridSize: 8, timeLimitSec: 180, colorTraps: true, emojiPool: ['🔶', '🔷', '🔺', '🔹', '🔸', '🔻', '🔵', '🔴', '⚪', '⚫', '🔺', '🔷']),
    _LevelConfig(gridSize: 9, timeLimitSec: 240, colorTraps: true, emojiPool: ['🧠', '🧩', '🪄', '🎯', '🎲', '🔮', '🪄', '🎯', '🧭', '🪄']),
  ];

  int _unlockedLevel = 0;
  Map<String, int> _starsByLevel = {};
  int _selectedLevel = 0;

  // Themes and daily challenge management
  final List<String> _availableThemes = ['emoji', 'shapes', 'icons'];
  String _selectedTheme = 'emoji';
  Set<String> _unlockedThemes = {'emoji'};
  bool _isDailyMode = false;
  bool _dailyCompletedToday = false;

  late List<_CardData> _cards;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;
  int _firstFlippedIndex = -1;
  bool _isProcessing = false;
  int _matchesFound = 0;
  int _moves = 0;
  int _timeLeft = 0;
  Timer? _timer;
  Timer? _distractorTimer;
  int _penaltySeconds = 0;
  int? _distractorIndex;
  int _mistakes = 0;

  // For perfect-run replay & share
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _distractorTimer?.cancel();
    // If they leave while playing, it's a drop-off
    if (_stage == _MemoryStage.playing) {
      try {
        context.read<AnalyticsProvider>().trackGameEnd(completed: false);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getInt(_prefsUnlockedKey) ?? 0;
    final starsJson = prefs.getStringList(_prefsStarsKey) ?? [];
    final unlockedThemesList = prefs.getStringList(_prefsUnlockedThemes) ?? ['emoji'];
    final dailyDone = prefs.getString(_prefsDailyKey);

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
      _unlockedThemes = unlockedThemesList.toSet();
      _dailyCompletedToday = dailyDone == DateTime.now().toIso8601String().split('T').first;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsUnlockedKey, _unlockedLevel);
    final list = _starsByLevel.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_prefsStarsKey, list);
    await prefs.setStringList(_prefsUnlockedThemes, _unlockedThemes.toList());
  }

  void _startLevel(int levelIndex, {bool daily = false}) {
    final level = _levels[levelIndex];
    GameFeedbackService.tap();
    _timer?.cancel();
    _distractorTimer?.cancel();
    _cards = _buildDeck(level);
    _isFlipped = List.generate(_cards.length, (_) => false);
    _isMatched = List.generate(_cards.length, (_) => false);
    _firstFlippedIndex = -1;
    _isProcessing = false;
    _matchesFound = 0;
    _moves = 0;
    _penaltySeconds = 0;
    _timeLeft = level.timeLimitSec;
    _mistakes = 0;
    _isDailyMode = daily;
    setState(() {
      _stage = _MemoryStage.playing;
      _selectedLevel = levelIndex;
    });
    // Start distractor pulses on higher difficulty
    if (level.gridSize >= 6) {
      _distractorTimer = Timer.periodic(Duration(seconds: max(1, level.gridSize ~/ 2)), (_) {
        if (!mounted) return;
        final candidates = List<int>.generate(_cards.length, (i) => i).where((i) => !_isMatched[i] && !_isFlipped[i]).toList();
        if (candidates.isEmpty) return;
        setState(() => _distractorIndex = candidates[_rng.nextInt(candidates.length)]);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => _distractorIndex = null);
        });
      });
    }
    _startTimer();
  }

  Future<void> _startDailyChallenge() async {
    if (_dailyCompletedToday) return;
    final pick = min(_unlockedLevel, _levels.length - 1);
    _startLevel(pick, daily: true);
    _dailyCompletedToday = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDailyKey, DateTime.now().toIso8601String().split('T').first);
    setState(() {});
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
          onReplay: () {
            Navigator.of(context).pop();
          },
          customMessage: 'Time\'s up! Try again.',
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
        // small celebration: subtle glow already handled by widget
        if (_matchesFound == _levels[_selectedLevel].pairCount) {
          _onLevelComplete();
        }
      } else {
        // incorrect: vibration + lock and count mistake
        GameFeedbackService.error();
        _mistakes++;
        if (_levels[_selectedLevel].colorTraps && (firstCard.isTrap || secondCard.isTrap)) {
          _penaltySeconds += 2;
          _timeLeft = max(0, _timeLeft - 2);
        }
        // briefly keep them visible then flip back
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

  Future<void> _onLevelComplete() async {
    _timer?.cancel();
    _distractorTimer?.cancel();
    final level = _levels[_selectedLevel];

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

    // Perfect memory bonus
    final perfect = _mistakes == 0 && _moves == _levels[_selectedLevel].pairCount;
    final perfBonus = perfect ? 100 : 0;
    final xpAward = max(20, min(400, score ~/ 1 + perfBonus));
    // award XP via ProgressProvider if available
    try {
      // guard in case provider missing
      final provider = Provider.of(context, listen: false);
      provider.read ?? {};
    } catch (_) {}

    final message = perfect
        ? 'Perfect Memory! +$perfBonus XP • Completed ${_levels[_selectedLevel].label} • $stars ★'
        : 'Completed ${_levels[_selectedLevel].label} • $stars ★';

    // Unlock themes based on performance
    final unlockedNow = <String>[];
    try {
      // shapes: 2-star on 4x4 (label contains '4x4')
      if (level.label == '4x4' && stars >= 2 && !_unlockedThemes.contains('shapes')) {
        _unlockedThemes.add('shapes');
        unlockedNow.add('shapes');
      }
      // icons: 3-star on 8x8 OR perfect on any level
      if ((level.label == '8x8' && stars == 3) || perfect) {
        if (!_unlockedThemes.contains('icons')) {
          _unlockedThemes.add('icons');
          unlockedNow.add('icons');
        }
      }
    } catch (_) {}

    // Save progress including themes
    _saveProgress();

    // Daily completion reward: if playing as daily, mark completion and give bonus
    if (_isDailyMode) {
      try {
        if (!mounted) return;
        await context.read<ProgressProvider>().completeDailyChallenge();
      } catch (_) {}
    }

    // If perfect run, play a quick replay and offer share before navigating
    if (perfect) {
      await _playPerfectReplayAndOfferShare(score, message);
    }

    // Try to record progression
    try {
      if (mounted) {
        context.read<ProgressProvider>().recordGameResult(
          gameId: 'game-memory-cards', 
          won: true, 
          xpAward: xpAward,
          analytics: context.read<AnalyticsProvider>(),
        );
      }
    } catch (_) {
      // ignore if provider not available
    }

    if (unlockedNow.isNotEmpty && mounted) {
      final names = unlockedNow.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlocked theme(s): $names')));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: GameCatalog.allGames.firstWhere((g) => g.id == 'memory_cards', orElse: () => GameCatalog.allGames[0]),
          score: score,
          isWin: true,
          onReplay: () {
            Navigator.of(context).pop();
          },
          customMessage: message,
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

  // Demo helper: unlock a theme (can be removed later)
  void _unlockNextThemeForDemo() {
    final locked = _availableThemes.where((t) => !_unlockedThemes.contains(t)).toList();
    if (locked.isEmpty) return;
    setState(() => _unlockedThemes.add(locked.first));
    _saveProgress();
  }

  Future<void> _playPerfectReplayAndOfferShare(int score, String message) async {
    if (!mounted) return;
    // reveal all cards
    setState(() {
      for (int i = 0; i < _isFlipped.length; i++) {
        _isFlipped[i] = true;
      }
    });
    await Future.delayed(const Duration(milliseconds: 700));

    // slight board flourish
    for (int i = 0; i < _cards.length; i++) {
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 30));
    }

    // capture screenshot and offer share
    try {
      final imageFile = await _captureBoardImage();
      if (imageFile != null) {        if (!mounted) return;        final share = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Perfect Memory!'),
            content: const Text('Share your perfect run?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Share')),
            ],
          ),
        );
            if (share == true) {
          if (!mounted) return;
          await Share.shareXFiles([XFile(imageFile.path)], text: 'I got a Perfect Memory on FaceCode!');
        }
      }
    } catch (e) {
      // ignore share errors
    }

    // hide all before continuing
    setState(() {
      for (int i = 0; i < _isFlipped.length; i++) {
        _isFlipped[i] = false;
      }
    });
  }

  Future<File?> _captureBoardImage() async {
    try {
      final boundary = _boardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return null;
      final tmp = Directory.systemTemp.createTemp();
      final dir = await tmp;
      final file = File('${dir.path}/perfect_memory_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  List<_CardData> _buildDeck(_LevelConfig level) {
    // Theme-aware pools
    List<String> pool;
    switch (_selectedTheme) {
      case 'shapes':
        pool = ['◼︎', '◻︎', '◆', '◇', '▲', '△', '●', '○', '◯', '⬟', '⬢', '⬣', '⬤', '⬥', '⬧'];
        break;
      case 'icons':
        pool = ['🧠', '🧩', '🪄', '🎯', '🎲', '🔮', '🎛️', '🧪', '⚙️', '🪝', '🧭'];
        break;
      case 'emoji':
      default:
        pool = [...level.emojiPool];
        break;
    }

    pool.shuffle();
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
      // make some entries very similar at higher levels to increase difficulty
      final baseColor = colors[_rng.nextInt(colors.length)];
      final color = _selectedLevel >= 3
          ? Color.lerp(baseColor, Colors.white, _rng.nextDouble() * 0.14)!
          : baseColor;
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
                const SizedBox(height: 12),
                const Text('Card Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableThemes.map((t) {
                    final unlocked = _unlockedThemes.contains(t);
                    final selected = _selectedTheme == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: selected,
                      selectedColor: AppConstants.primaryColor.withAlpha(60),
                      disabledColor: Colors.white10,
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                      onSelected: unlocked ? (_) => setState(() => _selectedTheme = t) : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _dailyCompletedToday ? null : () => _startDailyChallenge(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGold),
                      child: Text(_dailyCompletedToday ? 'Daily Done' : 'Daily Challenge'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => _unlockNextThemeForDemo(),
                      child: const Text('Unlock theme (demo)', style: TextStyle(color: Colors.white70)),
                    )
                  ],
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
          child: RepaintBoundary(
            key: _boardKey,
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
                final isDistractor = _distractorIndex == index;
                return Transform.scale(
                  scale: scale,
                  child: _MemoryCardWidget(
                    data: _cards[index],
                    isFlipped: _isFlipped[index],
                    isMatched: _isMatched[index],
                    gridSize: level.gridSize,
                    isDistractor: isDistractor,
                    onTap: () => _onCardTap(index),
                  ),
                );
              },
            ),
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
        if (_isDailyMode) _buildChip('Daily', AppConstants.accentGold),
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
  final bool isDistractor;
  final VoidCallback onTap;

  const _MemoryCardWidget({
    required this.data,
    required this.isFlipped,
    required this.isMatched,
    required this.gridSize,
    this.isDistractor = false,
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
          // subtle pulse for distractor
          final pulse = isDistractor ? (1 + (sin(DateTime.now().millisecondsSinceEpoch / 200) * 0.02)) : 1.0;
          return Transform.scale(
            scale: pulse,
            child: Transform(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context, double radius, double emojiSize) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: data.faceColor.withAlpha(80),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: data.faceColor.withAlpha(160)),
        boxShadow: isMatched
            ? [BoxShadow(color: data.faceColor.withValues(alpha: 40), blurRadius: 12, spreadRadius: 2)]
            : null,
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
            data.isTrap ? AppConstants.errorColor.withValues(alpha: 0.30) : AppConstants.primaryColor.withValues(alpha: 0.20),
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
