import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/wyr_question.dart';
import 'package:facecode/services/wyr_service.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/widgets/game/game_outcome_actions.dart';
import 'package:facecode/widgets/ui_kit.dart';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key, this.questionId});

  final String? questionId;

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  final WyrService _service = WyrService();

  WyrQuestion? _currentQuestion;
  bool _isLoading = true;
  bool _hasVoted = false;
  String? _selectedOptionId; // 'A' or 'B'
  String? _aiChoice; // 'A' or 'B'
  bool _lightMode = false;
  String? _errorMessage;
  StreamSubscription<WyrQuestion>? _questionSub;

  // Tag filter for niche play
  String?
      _activeTagFilter; // when set, only questions from this tag will be loaded

  // Stats for animation
  double _percentA = 0.5;
  double _percentB = 0.5;

  // UI: categories and last chosen percent
  final List<Map<String, String>> _categories = [
    {'label': 'Funny', 'tag': 'funny'},
    {'label': 'Serious', 'tag': 'deep'},
    {'label': 'Moral', 'tag': 'life'},
    {'label': 'Weird', 'tag': 'superpower'},
  ];
  int? _lastChosenPercent;

  @override
  void initState() {
    super.initState();
    if (widget.questionId != null) {
      _loadQuestionById(widget.questionId!);
    } else {
      _loadNextQuestion();
    }
  }

  @override
  void dispose() {
    _questionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestionById(String id) async {
    setState(() {
      _isLoading = true;
      _hasVoted = false;
      _selectedOptionId = null;
      _aiChoice = null;
      _errorMessage = null;
    });

    final q = await _service.getQuestionById(id);
    if (!mounted) return;
    if (q == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'This question is no longer available.';
      });
      return;
    }
    await _bindQuestion(q);
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _hasVoted = false;
      _selectedOptionId = null;
      _aiChoice = null;
      _errorMessage = null;
    });

    final q = await _service.getRandomQuestion(
        tag: _activeTagFilter); // respects active niche/category filter

    if (mounted) {
      if (q != null) {
        await _bindQuestion(q);
      } else {
        // Retry or error
        setState(() {
          _isLoading = false;
          _errorMessage = _activeTagFilter != null
              ? 'No questions found for "$_activeTagFilter".'
              : 'No more questions currently.';
        });
      }
    }
  }

  Future<void> _bindQuestion(WyrQuestion question) async {
    _questionSub?.cancel();
    _questionSub = _service.watchQuestion(question.id).listen((updated) {
      if (!mounted) return;
      setState(() {
        _currentQuestion = updated;
        _percentA = updated.percentA / 100;
        _percentB = updated.percentB / 100;
      });
    });

    final voted = await _service.hasVoted(question.id);
    final choice = await _service.getVotedChoice(question.id);
    if (!mounted) return;
    setState(() {
      _currentQuestion = question;
      _isLoading = false;
      _hasVoted = voted;
      _selectedOptionId = choice;
      _percentA = question.percentA / 100;
      _percentB = question.percentB / 100;
    });
    _setAiChoice();
  }

  Future<void> _handleVote(bool isOptionA) async {
    if (_hasVoted || _currentQuestion == null) return;
    final alreadyVoted = await _service.hasVoted(_currentQuestion!.id);
    if (alreadyVoted) {
      if (!mounted) return;
      final choice = await _service.getVotedChoice(_currentQuestion!.id);
      setState(() {
        _hasVoted = true;
        _selectedOptionId = choice;
      });
      return;
    }

    setState(() {
      _hasVoted = true;
      _selectedOptionId = isOptionA ? 'A' : 'B';
    });

    GameFeedbackService.tap();

    try {
      final updatedQ = await _service.vote(_currentQuestion!.id, isOptionA);
      if (mounted && updatedQ != null) {
        setState(() {
          _currentQuestion = updatedQ;
          _percentA = updatedQ.percentA / 100;
          _percentB = updatedQ.percentB / 100;
          _lastChosenPercent =
              (isOptionA ? updatedQ.percentA : updatedQ.percentB).round();
        });
      }
    } catch (e) {
      final updated = _service.voteLocal(_currentQuestion!, isOptionA);
      await _service.recordVoteLocal(
          _currentQuestion!.id, isOptionA ? 'A' : 'B');
      await _service.queuePendingVote(_currentQuestion!.id, isOptionA);
      if (!mounted) return;
      setState(() {
        _currentQuestion = updated;
        _percentA = updated.percentA / 100;
        _percentB = updated.percentB / 100;
        _lastChosenPercent =
            (isOptionA ? updated.percentA : updated.percentB).round();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No internet — vote saved and will sync.")),
      );
    }

    _setAiChoice();

    if (!mounted) return;

    // Determine win (Consensus)
    final wonGame =
        (isOptionA && _percentA >= 0.5) || (!isOptionA && _percentB >= 0.5);

    context.read<ProgressProvider>().recordGameResult(
          gameId: 'game-would-rather',
          won: true,
          xpAward: 50,
          analytics: context.read<AnalyticsProvider>(),
        );

    if (wonGame) {
      GameFeedbackService.success();
    }
  }

  void _setAiChoice() {
    if (_currentQuestion == null) return;
    final aWeight = _currentQuestion!.percentA / 100;
    _aiChoice = (aWeight >= 0.5) ? 'A' : 'B';
  }

  void _showShareSheet() {
    if (_currentQuestion == null) return;
    final link = 'https://facecode.app/wyr/s/${_currentQuestion!.id}';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Share this question',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Share.share(link),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share link'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied.')));
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Copy link',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTrendingSheet() async {
    final chosenTag = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        final tags = ['funny', 'deep', 'life', 'food', 'movies', 'superpower'];
        String? selectedTag;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Trending',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: tags.map((tag) {
                        final selected = selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag.toUpperCase()),
                          selected: selected,
                          selectedColor:
                              AppConstants.primaryColor.withValues(alpha: 0.6),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold),
                          onSelected: (_) => setSheetState(
                              () => selectedTag = selected ? null : tag),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<WyrQuestion>>(
                        future: _service.getTrending(tag: selectedTag),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? [];
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (items.isEmpty) {
                            return const Center(
                                child: Text('No trending questions.',
                                    style: TextStyle(color: Colors.white70)));
                          }
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final q = items[index];
                              return ListTile(
                                title: Text('${q.optionA} / ${q.optionB}',
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text('${q.totalVotes} votes',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _loadQuestionById(q.id);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Apply / Clear controls
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, selectedTag);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor),
                            child: const Text('APPLY FILTER'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () =>
                              setSheetState(() => selectedTag = null),
                          child: const Text('CLEAR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Apply chosen tag filter (if user pressed APPLY)
    if (!mounted) return;
    if (chosenTag != null) {
      setState(() {
        _activeTagFilter = chosenTag;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Now showing only "$chosenTag" questions')));
      await _loadNextQuestion();
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Your Vote History',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _service.getVoteHistory(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (items.isEmpty) {
                        return const Center(
                            child: Text('No votes yet.',
                                style: TextStyle(color: Colors.white70)));
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          final choice = entry['choice']?.toString() ?? '-';
                          final ts = entry['ts']?.toString() ?? '';
                          return ListTile(
                            title: Text('Choice: $choice',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(ts,
                                style: const TextStyle(color: Colors.white70)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightMode ? Colors.white : AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButton(
                      color: _lightMode
                          ? AppConstants.backgroundColor
                          : Colors.white,
                      onPressed: () => Navigator.pop(context)),
                  Text(
                    "WOULD YOU RATHER",
                    style: TextStyle(
                      color: _lightMode
                          ? AppConstants.backgroundColor
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.trending_up,
                            color: _lightMode
                                ? AppConstants.backgroundColor
                                : Colors.white),
                        onPressed: _showTrendingSheet,
                      ),
                      IconButton(
                        icon: Icon(Icons.history,
                            color: _lightMode
                                ? AppConstants.backgroundColor
                                : Colors.white),
                        onPressed: _showHistorySheet,
                      ),
                      IconButton(
                        icon: Icon(
                            _lightMode ? Icons.dark_mode : Icons.light_mode,
                            color: _lightMode
                                ? AppConstants.backgroundColor
                                : Colors.white),
                        onPressed: () =>
                            setState(() => _lightMode = !_lightMode),
                      ),
                      IconButton(
                        icon: Icon(Icons.share,
                            color: _lightMode
                                ? AppConstants.backgroundColor
                                : Colors.white),
                        onPressed: _showShareSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentQuestion == null
                      ? _buildErrorView()
                      : _buildGameView(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasVoted)
                    Expanded(
                      child: GameOutcomeActions(
                        gameId: 'game-would-rather',
                        onReplay: _loadNextQuestion,
                        onTryAnother: () => Navigator.pop(context),
                      ),
                    ),
                  if (!_hasVoted)
                    TextButton(
                      onPressed: _loadNextQuestion,
                      child: const Text("SKIP QUESTION",
                          style: TextStyle(color: Colors.white54)),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Could not load questions.",
            style: TextStyle(
                color:
                    _lightMode ? AppConstants.backgroundColor : Colors.white),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _loadNextQuestion, child: const Text("Retry"))
        ],
      ),
    );
  }

  Widget _buildGameView() {
    final totalVotes = _currentQuestion?.totalVotes ?? 0;
    final textColor = _lightMode ? AppConstants.backgroundColor : Colors.white;
    final cardColor = _lightMode ? Colors.white : AppConstants.surfaceColor;
    final mutedColor = _lightMode ? Colors.black54 : AppConstants.textSecondary;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left or right to go to next question
        final velocity = details.primaryVelocity ?? 0.0;
        if (velocity.abs() > 300) {
          _loadNextQuestion();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Category chips
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                children: _categories.map((c) {
                  final selected = _activeTagFilter == c['tag'];
                  return ChoiceChip(
                    label: Text(c['label']!),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withAlpha(160),
                    onSelected: (v) {
                      setState(() {
                        _activeTagFilter = v ? c['tag'] : null;
                      });
                      _loadNextQuestion();
                    },
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _lightMode ? Colors.black12 : Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                      'Votes', totalVotes.toString(), textColor, mutedColor),
                  _buildStat('You', _hasVoted ? 'Voted' : 'Pending', textColor,
                      mutedColor),
                  _buildStat(
                      'AI',
                      _aiChoice == null ? '--' : 'Chose $_aiChoice',
                      textColor,
                      mutedColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if ((_currentQuestion?.tags.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _currentQuestion!.tags
                      .map((t) => Chip(
                            label: Text(t,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: _lightMode
                                ? Colors.grey.shade200
                                : Colors.white10,
                            side: BorderSide(
                                color: _lightMode
                                    ? Colors.black12
                                    : Colors.white12),
                          ))
                      .toList(),
                ),
              ),
            // Show last chosen percent message
            if (_hasVoted && _lastChosenPercent != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('You chose with $_lastChosenPercent% of players',
                    style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w700)),
              ),

// Most controversial today
          _buildMostControversial(),

            // Active tag filter pill
            if (_activeTagFilter != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text('Filter: $_activeTagFilter',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      backgroundColor: AppConstants.primaryColor.withAlpha(30),
                      onDeleted: () {
                        setState(() {
                          _activeTagFilter = null;
                        });
                        _loadNextQuestion();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildOptionCard(
                text: _currentQuestion!.optionA,
                isOptionA: true,
                percent: _percentA,
                color: const Color(0xFFE94057),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _lightMode ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "OR",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _lightMode
                        ? Colors.white
                        : AppConstants.backgroundColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildOptionCard(
                text: _currentQuestion!.optionB,
                isOptionA: false,
                percent: _percentB,
                color: const Color(0xFF4285F4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostControversial() {
    return FutureBuilder<List<WyrQuestion>>(
      future: _service.getMostControversial(tag: _activeTagFilter, limit: 3),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        if (items.isEmpty) return const SizedBox.shrink();
        final top = items.first;
        return GestureDetector(
          onTap: () => _loadQuestionById(top.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        'Most controversial today: ${top.optionA} / ${top.optionB}',
                        style: const TextStyle(color: Colors.white70))),
                Text('${top.totalVotes} votes',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String text,
    required bool isOptionA,
    required double percent,
    required Color color,
  }) {
    final isSelected = _selectedOptionId == (isOptionA ? 'A' : 'B');
    final isOtherSelected = _hasVoted && !isSelected;

    return PremiumTap(
      onTap: _hasVoted ? null : () => _handleVote(isOptionA),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isOtherSelected ? color.withValues(alpha: 0.25) : color),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hasVoted
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_hasVoted)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isSelected ? 0.0 : 0.25,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                            .withValues(alpha: isOtherSelected ? 0.6 : 1.0),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVoteDetails(percent, isSelected, color),
                    if (!isSelected) const SizedBox(height: 8),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Icon(Icons.check_circle,
                            color: Colors.white, size: 32),
                      ).animate().fadeIn(),
                  ],
                ),
              ),

            ],
          ),
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildVoteDetails(double percent, bool isSelected, Color color) {
    if (!_hasVoted) {
      return const Text('Tap to vote', style: TextStyle(color: Colors.white70));
    }
    return Column(
      children: [
        _buildPercentBar(percent, color, isSelected),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (percent * 100)),
          duration: const Duration(milliseconds: 900),
          builder: (context, value, child) {
              final isLast = _lastChosenPercent != null && _lastChosenPercent == value.toInt();
              return AnimatedScale(
                scale: isLast ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Text('${value.toInt()}%',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              );
            },
        ),
        const SizedBox(height: 6),
        const Text('of people chose this',
            style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildPercentBar(double value, Color color, bool isSelected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: width * value,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white70,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(
      String label, String value, Color textColor, Color mutedColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(color: mutedColor, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
