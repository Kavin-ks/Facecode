import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/widgets/game/game_outcome_actions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/providers/two_truths_provider.dart';
import 'package:facecode/models/two_truths_models.dart';
import 'package:facecode/models/player.dart';
import 'package:uuid/uuid.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';
import 'package:facecode/services/sound_manager.dart';
import 'package:facecode/providers/analytics_provider.dart';
import 'package:facecode/widgets/ui_kit.dart';

class TwoTruthsScreen extends StatefulWidget {
  const TwoTruthsScreen({super.key});

  @override
  State<TwoTruthsScreen> createState() => _TwoTruthsScreenState();
}

class _TwoTruthsScreenState extends State<TwoTruthsScreen> {
  late ConfettiController _confettiController;
  final Random _rng = Random();
  final TextEditingController _playerNameController = TextEditingController();
  final List<TextEditingController> _statementControllers = List.generate(3, (_) => TextEditingController());
  bool _useAiFill = true;
  int _totalRounds = 5; // 0 = endless
  int _lastRoundNumber = -1;
  TwoTruthsPhase? _lastPhase;
  final Set<String> _aiVotedThisRound = {};
  bool _aiStorytellerSubmitted = false;
  bool _lieRevealPlayed = false; // ensure reveal effects play only once per round
  bool _lieFlash = false; // transient UI flash when the lie is revealed
  final List<String> _aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna', 'Orion', 'Vega'];
  final List<String> _avatarOptions = ['😀', '😎', '🤖', '🦊', '🐶', '🐱', '🐼', '🐸', '🦄', '🐙'];
  String _selectedAvatar = '😀';

  final List<String> _aiTruths = [
    'I can solve a Rubik\'s cube in under a minute.',
    'I have visited three different countries before.',
    'I once baked a cake from scratch.',
    'I learned to ride a bicycle in one day.',
    'I can name all the planets in order.',
    'I have watched the sunrise at the beach.',
    'I once built a small robot from a kit.',
    'I can play a simple song on the piano.',
  ];
  final List<String> _aiLies = [
    'I have climbed Mount Everest twice.',
    'I keep a pet tiger at home.',
    'I won a world championship in chess.',
    'I can fly a helicopter solo.',
    'I ate 100 slices of pizza in one sitting.',
    'I invented a new planet last week.',
    'I can speak 20 languages fluently.',
    'I once ran a marathon backwards.',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _playerNameController.dispose();
    for (var controller in _statementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TwoTruthsProvider>();
    _syncRoundTracking(provider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(provider),
                Expanded(
                  child: _buildPhaseView(provider),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TwoTruthsProvider provider) {
    String title = "Two Truths & One Lie";
    String subtitle = "";

    if (provider.phase == TwoTruthsPhase.intro) {
      subtitle = "Party game for everyone";
    } else if (provider.phase == TwoTruthsPhase.setup) {
      subtitle = "Add Players to Start";
    } else if (provider.phase == TwoTruthsPhase.input) {
      subtitle = "Storyteller: ${provider.currentStoryteller?.name}";
    } else if (provider.phase == TwoTruthsPhase.voting) {
      subtitle = "Find the LIE!";
    } else if (provider.phase == TwoTruthsPhase.reveal) {
      subtitle = "The Truth is revealed!";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                   provider.resetGame();
                   Navigator.pop(context);
                },
              ),
              if (provider.phase != TwoTruthsPhase.intro && provider.phase != TwoTruthsPhase.setup && provider.phase != TwoTruthsPhase.scoreboard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    "Round ${provider.currentRoundNumber}/${provider.totalRounds == 0 ? '∞' : provider.totalRounds}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFF6D00), Color(0xFF7C4DFF)],
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: AppConstants.secondaryColor, fontSize: 16),
            ).animate().fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildPhaseView(TwoTruthsProvider provider) {
    switch (provider.phase) {
      case TwoTruthsPhase.intro:
        return _buildIntroView(provider);
      case TwoTruthsPhase.setup:
        return _buildSetupView(provider);
      case TwoTruthsPhase.input:
        return _buildInputView(provider);
      case TwoTruthsPhase.voting:
        return _buildVotingView(provider);
      case TwoTruthsPhase.reveal:
        return _buildRevealView(provider);
      case TwoTruthsPhase.scoreboard:
        return _buildScoreboardView(provider);
    }
  }

  Widget _buildIntroView(TwoTruthsProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.casino_rounded, color: AppConstants.accentGold, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Two Truths & One Lie",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Vote on the lie and rack up points.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showHowToPlayModal(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "START GAME",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  void _showHowToPlayModal(TwoTruthsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "How to play",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildRulesContent(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.startSetup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("START GAME", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SETUP PHASE ---
  Widget _buildSetupView(TwoTruthsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playerNameController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _addPlayer(provider),
                  decoration: InputDecoration(
                    hintText: "Player Name",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addPlayer(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _avatarOptions.map((avatar) {
              final isSelected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppConstants.primaryColor : Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                  ),
                  child: Text(avatar, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildSetupControls(provider),
          const SizedBox(height: 12),
          _buildRulesCard(),
          const SizedBox(height: 12),
          if (provider.players.isEmpty)
            Center(
              child: Text(
                _useAiFill
                    ? "Add at least 1 player (AI will fill the rest)"
                    : "Add at least 2 players to start",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.players.length,
              itemBuilder: (context, index) {
                final player = provider.players[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF7C4DFF), const Color(0xFF00E5FF), index % 3 / 2)!,
                        Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFD54F), index % 3 / 2)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                      child: Text(
                        player.avatar ?? player.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    title: Text(player.name, style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                      onPressed: () => provider.removePlayer(player.id),
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: 0.1);
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (provider.players.isNotEmpty)
                  ? () {
                      if (provider.players.length < 2 && !_useAiFill) {
                        setState(() => _useAiFill = true);
                      }
                      final players = _buildStartingPlayers(provider);
                      if (players.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add at least 2 players to start.')),
                        );
                        return;
                      }
                      provider.setupGame(players, totalRounds: _totalRounds);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                disabledBackgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "START GAME",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF311B92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How to play",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRulesContent(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildRulesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "One player is the storyteller each round.",
          style: TextStyle(color: Colors.white70, height: 1.3),
        ),
        SizedBox(height: 6),
        Text("Write two truths and one lie.", style: TextStyle(color: Colors.white70, height: 1.3)),
        SizedBox(height: 6),
        Text("Everyone votes on the lie.", style: TextStyle(color: Colors.white70, height: 1.3)),
        SizedBox(height: 6),
        Text("Correct guess: +1 point.", style: TextStyle(color: Colors.white70, height: 1.3)),
        SizedBox(height: 6),
        Text("Storyteller: +2 if majority guess wrong.", style: TextStyle(color: Colors.white70, height: 1.3)),
      ],
    );
  }

  void _addPlayer(TwoTruthsProvider provider) {
    final name = _playerNameController.text.trim();
    if (name.isNotEmpty) {
      final exists = provider.players.any((p) => p.name.toLowerCase() == name.toLowerCase());
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate name. Pick a unique name.')),
        );
        return;
      }
      GameFeedbackService.tap();
      provider.addPlayer(Player(
        id: const Uuid().v4(),
        name: name,
        avatar: _selectedAvatar,
      ));
      _playerNameController.clear();
    }
  }

  // --- INPUT PHASE ---
  Widget _buildInputView(TwoTruthsProvider provider) {
    final storyteller = provider.currentStoryteller;
    final isAiStoryteller = storyteller != null && _isAiPlayer(storyteller);
    if (isAiStoryteller && !_aiStorytellerSubmitted) {
      _scheduleAiStatements(provider);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
             "Pass the phone to ${provider.currentStoryteller?.name}",
             textAlign: TextAlign.center,
             style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
          ).animate().shake(),
          const SizedBox(height: 24),
          if (isAiStoryteller)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                'AI is crafting statements...',
                style: TextStyle(color: AppConstants.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          if (isAiStoryteller)
            const SizedBox(height: 16),
          _buildStatementField(label: "Truth #1", controller: _statementControllers[0], enabled: !isAiStoryteller),
          const SizedBox(height: 16),
          _buildStatementField(label: "Truth #2", controller: _statementControllers[1], enabled: !isAiStoryteller),
          const SizedBox(height: 16),
          _buildStatementField(label: "Lie", controller: _statementControllers[2], enabled: !isAiStoryteller, isLie: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: isAiStoryteller ? null : () {
              GameFeedbackService.tap();
              final entries = _statementControllers.map((c) => c.text.trim()).toList();
              if (entries.any((e) => e.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter something!")),
                );
                return;
              }
              final lower = entries.map((e) => e.toLowerCase()).toList();
              if (lower.toSet().length != lower.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Make them different!")),
                );
                return;
              }

              provider.submitStatements([entries[0], entries[1]], entries[2]);
              for (var c in _statementControllers) {
                c.clear();
              }
              GameFeedbackService.success();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text("LOCK IT IN", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    bool isLie = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isLie ? Colors.redAccent : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isLie ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            enabled: enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppConstants.surfaceLight,
              hintText: "Type here...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSetupControls(TwoTruthsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00B0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Game Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Number of rounds', style: TextStyle(color: AppConstants.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [3, 5, 7, 10, 0].map((r) {
                    final selected = _totalRounds == r;
                    return ChoiceChip(
                      label: Text(r == 0 ? '∞' : r.toString()),
                      selected: selected,
                      selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _totalRounds = r),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI fallback', style: TextStyle(color: AppConstants.textSecondary)),
              Switch(
                value: _useAiFill,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (val) => setState(() => _useAiFill = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Player> _buildStartingPlayers(TwoTruthsProvider provider) {
    final players = [...provider.players];
    if (!_useAiFill) return players;
    final existingNames = players.map((p) => p.name.toLowerCase()).toSet();
    while (players.length < 2) {
      final name = _aiNames.firstWhere((n) => !existingNames.contains(n.toLowerCase()), orElse: () => 'AI-${players.length + 1}');
      existingNames.add(name.toLowerCase());
      players.add(Player(id: 'ai_${const Uuid().v4()}', name: name, avatar: '🤖'));
    }
    return players;
  }

  void _syncRoundTracking(TwoTruthsProvider provider) {
    if (_lastRoundNumber != provider.currentRoundNumber || _lastPhase != provider.phase) {
      _aiVotedThisRound.clear();
      _aiStorytellerSubmitted = false;
      _lieRevealPlayed = false;
      _lieFlash = false;
      _lastRoundNumber = provider.currentRoundNumber;
      _lastPhase = provider.phase;
    }
  }

  bool _isAiPlayer(Player player) => player.id.startsWith('ai_');

  void _scheduleAiStatements(TwoTruthsProvider provider) {
    _aiStorytellerSubmitted = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || provider.phase != TwoTruthsPhase.input) return;
      final truth1 = _aiTruths[_rng.nextInt(_aiTruths.length)];
      final truth2 = _aiTruths[_rng.nextInt(_aiTruths.length)];
      final lie = _aiLies[_rng.nextInt(_aiLies.length)];
      final truths = truth1 == truth2 ? [truth1, _aiTruths[_rng.nextInt(_aiTruths.length)]] : [truth1, truth2];
      provider.submitStatements(truths, lie);
    });
  }

  void _maybeAutoVote(TwoTruthsProvider provider, Player voter) {
    if (!_isAiPlayer(voter)) return;
    if (_aiVotedThisRound.contains(voter.id)) return;
    _aiVotedThisRound.add(voter.id);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || provider.phase != TwoTruthsPhase.voting) return;
      final index = _rng.nextInt(3);
      provider.submitVote(voter.id, index);
    });
  }

  // --- VOTING PHASE ---
  Widget _buildVotingView(TwoTruthsProvider provider) {
    final targetVoters = provider.players.where((p) => p.id != provider.currentStoryteller?.id).toList();
    final remainingVoters = targetVoters.where((p) => !provider.currentRound!.votes.containsKey(p.id)).toList();

    if (remainingVoters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Tallying votes...", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    final currentVoter = remainingVoters.first;
    _maybeAutoVote(provider, currentVoter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
               Text(
                 "PASS THE PHONE TO",
                 style: TextStyle(color: AppConstants.accentGold.withValues(alpha: 0.8), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold),
               ).animate().fadeIn().then().shimmer(),
               const SizedBox(height: 8),
               CircleAvatar(
                 radius: 30,
                 backgroundColor: AppConstants.secondaryColor,
                 child: Text(currentVoter.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
               ).animate().scale(delay: 200.ms),
               const SizedBox(height: 12),
               Text(
                "${currentVoter.name}'s Vote",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Find the lie among these statements",
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            itemBuilder: (context, index) {
              final statement = provider.currentRound!.statements[index];
              final isSelected = provider.currentRound!.votes.containsKey(currentVoter.id) && provider.currentRound!.votes[currentVoter.id] == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PremiumTap(
                  onTap: provider.currentRound!.votes.containsKey(currentVoter.id)
                      ? null
                      : () {
                          GameFeedbackService.tap();
                          provider.submitVote(currentVoter.id, index);
                        },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      statement.text,
                      style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02)).slideY(begin: 0.1, delay: (index * 100).ms).fadeIn(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Waiting for others... ${provider.currentRound!.votes.length}/${targetVoters.length}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(targetVoters.length, (i) {
                  final hasVoted = provider.currentRound!.votes.containsKey(targetVoters[i].id);
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasVoted ? AppConstants.successColor : Colors.white24,
                    ),
                  );
                }),
              ),
            ],
          ),
        )
      ],
    );
  }

  // --- REVEAL PHASE ---
  Widget _buildRevealView(TwoTruthsProvider provider) {
    final correctIndex = provider.currentRound!.statements.indexWhere((s) => s.isLie);
    final votersCount = provider.players.length - 1;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
      if (!_lieRevealPlayed) {
        setState(() => _lieFlash = true);
        SoundManager().playGameSound(SoundManager.sfxPop);
        GameFeedbackService.success();
        _lieRevealPlayed = true;
        Future.delayed(const Duration(milliseconds: 420), () {
          if (!mounted) return;
          setState(() => _lieFlash = false);
        });
      }
    });

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("RESULTS", style: TextStyle(color: AppConstants.accentGold, letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 14)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 3,
            itemBuilder: (context, index) {
              final statement = provider.currentRound!.statements[index];
              final isCorrectLie = index == correctIndex;
              final votersForThis = provider.currentRound!.votes.entries
                  .where((e) => e.value == index)
                  .map((e) => provider.players.firstWhere((p) => p.id == e.key))
                  .toList();

              final card = Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCorrectLie
                        ? (_lieFlash ? Colors.greenAccent.withValues(alpha: 0.28) : Colors.green.withValues(alpha: 0.15))
                        : AppConstants.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrectLie ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white10,
                      width: isCorrectLie ? 2 : 1
                    ),
                  ),
                  child: AnimatedScale(
                    scale: (isCorrectLie && _lieFlash) ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Column(
                      children: [
                        if (isCorrectLie)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text("THE LIE!", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        Text(
                          statement.text,
                          style: TextStyle(
                            color: isCorrectLie ? Colors.white : Colors.white54,
                            fontSize: 17,
                            fontWeight: isCorrectLie ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (votersForThis.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: votersForThis.map((player) {
                              final isCorrect = isCorrectLie;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(isCorrect ? Icons.check_circle : Icons.cancel, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              );

              return card;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                provider.storytellerWon ? "Storyteller fooled the group!" : "The group spotted the lie!",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "ROUND SUMMARY",
                style: TextStyle(color: AppConstants.accentGold, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Correct guesses: ${provider.lastCorrectGuesses}/$votersCount",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.storytellerWon ? "Storyteller bonus: +2" : "Storyteller bonus: +0",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildMiniScoreboard(provider),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _confettiController.stop();
                context.read<ProgressProvider>().recordGameResult(
                  gameId: 'game-two-truths',
                  won: true,
                  xpAward: 50,
                  analytics: context.read<AnalyticsProvider>(),
                );
                provider.nextRound();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("NEXT ROUND", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // --- SCOREBOARD PHASE ---
  Widget _buildScoreboardView(TwoTruthsProvider provider) {
    final sortedPlayers = [...provider.players]..sort((a, b) => b.score.compareTo(a.score));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
    });

    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.emoji_events, color: AppConstants.accentGold, size: 64).animate().scale().then().shake(),
        const SizedBox(height: 12),
        const Text(
          "Final Standings",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final isWinner = index == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isWinner ? AppConstants.primaryColor : AppConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isWinner ? [BoxShadow(color: AppConstants.primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))] : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black26,
                      child: Text(
                        player.avatar ?? player.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "#${index + 1}",
                      style: TextStyle(
                        color: isWinner ? Colors.white : AppConstants.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${player.score} pts",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ).animate().slideX(begin: 1, delay: (index * 150).ms).fadeIn();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameOutcomeActions(
            gameId: 'game-two-truths',
            onReplay: () {
              provider.restartGame();
            },
            onTryAnother: () {
              provider.resetGame();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniScoreboard(TwoTruthsProvider provider) {
    final sortedPlayers = [...provider.players]..sort((a, b) => b.score.compareTo(a.score));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: sortedPlayers.map((player) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white12,
                  child: Text(
                    player.avatar ?? player.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(player.name, style: const TextStyle(color: Colors.white70)),
                ),
                Text("${player.score}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
