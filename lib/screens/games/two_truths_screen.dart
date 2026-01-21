import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/providers/two_truths_provider.dart';
import 'package:facecode/models/two_truths_models.dart';
import 'package:facecode/models/player.dart';
import 'package:uuid/uuid.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';

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
  int _lieIndex = 0; // 0, 1, or 2
  bool _useAiFill = true;
  int _roundsPerPlayer = 1;
  int _lastRoundNumber = -1;
  TwoTruthsPhase? _lastPhase;
  final Set<String> _aiVotedThisRound = {};
  bool _aiStorytellerSubmitted = false;
  final List<String> _aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna', 'Orion', 'Vega'];

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

    if (provider.phase == TwoTruthsPhase.setup) {
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
              if (provider.phase != TwoTruthsPhase.setup && provider.phase != TwoTruthsPhase.scoreboard)
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
                    "Round ${provider.currentRoundNumber}/${provider.totalRounds}",
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
          if (provider.phase == TwoTruthsPhase.input || provider.phase == TwoTruthsPhase.voting)
             Padding(
               padding: const EdgeInsets.only(top: 16),
               child: Column(
                 children: [
                    LinearProgressIndicator(
                      value: provider.secondsRemaining / (provider.phase == TwoTruthsPhase.input ? 60 : 30),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.secondsRemaining < 10 ? Colors.redAccent : AppConstants.primaryColor
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${provider.secondsRemaining}s remaining",
                      style: TextStyle(
                        color: provider.secondsRemaining < 10 ? Colors.redAccent : AppConstants.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                 ],
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildPhaseView(TwoTruthsProvider provider) {
    switch (provider.phase) {
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
                      child: Text(player.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
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
              onPressed: (provider.players.length >= 2 || (_useAiFill && provider.players.isNotEmpty))
                  ? () {
                      final players = _buildStartingPlayers(provider);
                      if (players.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add at least 2 players to start.')),
                        );
                        return;
                      }
                      provider.setupGame(players, roundsPerPlayer: _roundsPerPlayer);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                disabledBackgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "START ROUND",
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
        children: const [
          Text(
            "How to play",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("• One player is the storyteller each round.", style: TextStyle(color: Colors.white70, height: 1.3)),
          Text("• Storyteller writes 2 truths and 1 lie.", style: TextStyle(color: Colors.white70, height: 1.3)),
          Text("• Everyone else guesses the lie.", style: TextStyle(color: Colors.white70, height: 1.3)),
          Text("• Correct guess: +1 point. Storyteller: +1 if majority guess wrong.", style: TextStyle(color: Colors.white70, height: 1.3)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
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
          ...List.generate(3, (index) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _lieIndex = index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            _lieIndex == index ? Icons.error_outline : Icons.check_circle_outline,
                            size: 16,
                            color: _lieIndex == index ? Colors.redAccent : Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lieIndex == index ? "THIS IS MY LIE" : "THIS IS A TRUTH",
                            style: TextStyle(
                              color: _lieIndex == index ? Colors.redAccent : Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextField(
                    controller: _statementControllers[index],
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    enabled: !isAiStoryteller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppConstants.surfaceLight,
                      hintText: "Wait for it... something clever...",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _lieIndex == index ? Colors.redAccent.withValues(alpha: 0.3) : Colors.transparent)
                      ),
                    ),
                  ),
                ],
              ),
            )
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: isAiStoryteller ? null : () {
              bool valid = true;
              for (var c in _statementControllers) {
                if (c.text.trim().split(' ').length < 5) {
                  valid = false;
                  break;
                }
              }
              
              if (!valid) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Make it harder! Use at least 5 words per statement."))
                  );
                  return;
              }

              List<String> truths = [];
              String lie = "";
              for (int i = 0; i < 3; i++) {
                if (i == _lieIndex) {
                  lie = _statementControllers[i].text;
                } else {
                  truths.add(_statementControllers[i].text);
                }
              }
              provider.submitStatements(truths, lie);
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
          const Text('Match Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Rounds per player', style: TextStyle(color: AppConstants.textSecondary)),
              const SizedBox(width: 12),
              ...[1, 2, 3].map((r) {
                final selected = _roundsPerPlayer == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(r.toString()),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _roundsPerPlayer = r),
                  ),
                );
              }),
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
      players.add(Player(id: 'ai_${const Uuid().v4()}', name: name));
    }
    return players;
  }

  void _syncRoundTracking(TwoTruthsProvider provider) {
    if (_lastRoundNumber != provider.currentRoundNumber || _lastPhase != provider.phase) {
      _aiVotedThisRound.clear();
      _aiStorytellerSubmitted = false;
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

    if (remainingVoters.isEmpty) return const Center(child: CircularProgressIndicator());

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
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => provider.submitVote(currentVoter.id, index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                ).animate().slideY(begin: 0.1, delay: (index * 100).ms).fadeIn(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: List.generate(targetVoters.length, (i) {
               final hasVoted = provider.currentRound!.votes.containsKey(targetVoters[i].id);
               return Container(
                 width: 10,
                 height: 10,
                 margin: const EdgeInsets.symmetric(horizontal: 4),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: hasVoted ? AppConstants.successColor : Colors.white24
                 ),
               );
             }),
          ),
        )
      ],
    );
  }

  // --- REVEAL PHASE ---
  Widget _buildRevealView(TwoTruthsProvider provider) {
    final correctIndex = provider.currentRound!.statements.indexWhere((s) => s.isLie);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
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
                  .map((e) => provider.players.firstWhere((p) => p.id == e.key).name)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCorrectLie ? Colors.green.withValues(alpha: 0.1) : AppConstants.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrectLie ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white10,
                      width: isCorrectLie ? 2 : 1
                    ),
                  ),
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
                          decoration: !isCorrectLie ? TextDecoration.lineThrough : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (votersForThis.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: votersForThis.map((name) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrectLie ? Colors.green : Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          )).toList(),
                        )
                      ],
                    ],
                  ),
                ).animate().scale(delay: (index * 300).ms, duration: 500.ms).fadeIn(),
              );
            },
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
                  gameId: 'two_truths',
                  won: false,
                  xpAward: 15,
                );
                provider.nextRound();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // --- SCOREBOARD PHASE ---
  Widget _buildScoreboardView(TwoTruthsProvider provider) {
    final sortedPlayers = [...provider.players]..sort((a, b) => b.score.compareTo(a.score));

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
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => provider.resetGame(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                   provider.resetGame();
                   Navigator.pop(context);
                },
                child: const Text("EXIT TO HUB", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
