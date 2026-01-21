import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/truth_dare_models.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/providers/truth_dare_provider.dart';
import 'package:facecode/widgets/spinner_wheel.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/services/game_feedback_service.dart';

class TruthDareScreen extends StatefulWidget {
  const TruthDareScreen({super.key});

  @override
  State<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen> {
  final GlobalKey<SpinnerWheelState> _wheelKey = GlobalKey<SpinnerWheelState>();
  final TextEditingController _nameController = TextEditingController();
  late ConfettiController _confettiController;
  bool _useAiFill = true;
  int _targetTurns = 10; // 0 = endless
  int _turnCount = 0;
  final List<String> _aiNames = ['Nova', 'Pixel', 'Echo', 'Blitz', 'Luna', 'Orion', 'Vega'];
  
  bool _showQuestion = false;
  String _history = "";
  // Whether the user has started the spinning session (explicit start)
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TruthDareProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(provider),
            Expanded(
              child: _buildMainContent(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(TruthDareProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (provider.mode != null) {
                provider.resetGame();
                setState(() { _started = false; });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Text(
            "TRUTH OR DARE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          if (provider.mode == TruthDareMode.withQuestions)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () => _showSettings(provider),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainContent(TruthDareProvider provider) {
    if (provider.mode == null) {
      return _buildModeSelection(provider);
    }

    // If there are less than 2 players, we stay in setup.
    if (provider.players.length < 2) {
      return _buildPlayerSetup(provider);
    }

    // Allow adding arbitrary number of players before explicitly starting the session.
    if (!_started) {
      return _buildPlayerSetup(provider);
    }

    return _buildGameView(provider);
  }

  // --- PHASE 1: MODE SELECTION ---
  Widget _buildModeSelection(TruthDareProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "CHOOSE MODE",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 40),
          _buildModeCard(
            title: "With Questions",
            subtitle: "Play with real questions & dares",
            icon: Icons.question_answer_rounded,
            color: AppConstants.cardPurple,
            onTap: () => provider.setMode(TruthDareMode.withQuestions),
          ),
          const SizedBox(height: 20),
          _buildModeCard(
            title: "Spinner Only",
            subtitle: "Just spin & choose player",
            icon: Icons.refresh_rounded,
            color: AppConstants.cardBlue,
            onTap: () => provider.setMode(TruthDareMode.withoutQuestions),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
    );
  }

  // --- PHASE 2: PLAYER SETUP ---
  Widget _buildPlayerSetup(TruthDareProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text("ADD PLAYERS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (v) => _addPlayer(provider),
                      decoration: InputDecoration(
                        hintText: "Enter name",
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppConstants.surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _addPlayer(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSessionSettings(provider),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: provider.players.length,
            itemBuilder: (context, index) {
              final player = provider.players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  child: Text(player.name[0]),
                ),
                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () => provider.removePlayer(player.id),
                ),
              ).animate().fadeIn().slideX();
            },
          ),
        ),
        if (provider.players.length >= 2)
           Padding(
             padding: const EdgeInsets.all(24.0),
             child: SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   if (provider.players.length < 2) {
                     if (_useAiFill && provider.players.isNotEmpty) {
                       _ensureAiPlayers(provider);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Add at least 2 players to start.')),
                       );
                       return;
                     }
                   }
                   setState(() {
                     _turnCount = 0;
                     _started = true;
                   });
                 }, // Explicitly enter spinner view
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppConstants.successColor,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: const Text("START SPINNING", style: TextStyle(fontWeight: FontWeight.bold)),
               ),
             ),
           ),
      ],
    );
  }

  void _addPlayer(TruthDareProvider provider) {
    if (_nameController.text.isNotEmpty) {
      final added = provider.addPlayer(_nameController.text);
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate name. Pick a unique name.')),
        );
        return;
      }
      _nameController.clear();
      HapticFeedback.lightImpact();
    }
  }

  // --- PHASE 3: GAME VIEW ---
  Widget _buildGameView(TruthDareProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
          child: Row(
            children: [
              _buildChip('Turn ${_turnCount + 1}', AppConstants.secondaryColor),
              const SizedBox(width: 8),
              _buildChip('${provider.players.length} players', AppConstants.primaryColor),
              const Spacer(),
              if (_targetTurns > 0)
                Text('$_turnCount/$_targetTurns', style: const TextStyle(color: AppConstants.textSecondary)),
            ],
          ),
        ),
        if (_targetTurns > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
            child: LinearProgressIndicator(
              value: (_turnCount / _targetTurns).clamp(0, 1),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
        const SizedBox(height: 8),
        // Turnover Status
        if (provider.currentPlayer != null)
           Padding(
             padding: const EdgeInsets.only(top: 20),
             child: Text(
               "It's ${provider.currentPlayer!.name.toUpperCase()}'s turn!",
               style: const TextStyle(color: AppConstants.accentGold, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
             ).animate().fadeIn().scale().shimmer(),
           ),
        
        const Spacer(),
        
        // Spinner Wheel
        Center(
          child: SpinnerWheel(
            key: _wheelKey,
            names: provider.players.map((p) => p.name).toList(),
            onResult: (index) {
              HapticFeedback.heavyImpact();
              provider.setCurrentPlayer(index);
              _turnCount += 1;
              setState(() {
                _history = "${provider.players[index].name}'s turn\n$_history";
                if (provider.mode == TruthDareMode.withQuestions) {
                  _showQuestionSelection(provider);
                }
              });
              if (_targetTurns > 0 && _turnCount >= _targetTurns) {
                _showSessionComplete(provider);
              }
            },
          ),
        ),
        
        const Spacer(),
        
        // Footer Buttons
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
               if (!_showQuestion)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        GameFeedbackService.tap();
                        _wheelKey.currentState?.spin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text("SPIN WHEEL", style: TextStyle(color: AppConstants.backgroundColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () { setState(() { _started = false; }); },
                      child: const Text("EDIT PLAYERS", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
               
               const SizedBox(height: 20),
               
               GestureDetector(
                 onTap: () => _showHistory(),
                 child: Text(
                   "VIEW HISTORY",
                   style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1),
                 ),
               ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQuestionSelection(TruthDareProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              "${provider.currentPlayer?.name}, Choose your fate:",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    title: "TRUTH",
                    color: AppConstants.cardBlue,
                    onTap: () async {
                      Navigator.pop(context);
                      await provider.fetchQuestion(TdType.truth);
                      _showQuestionOverlay(provider);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildChoiceButton(
                    title: "DARE",
                    color: AppConstants.cardPink,
                    onTap: () async {
                      Navigator.pop(context);
                      await provider.fetchQuestion(TdType.dare);
                      _showQuestionOverlay(provider);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton({required String title, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
    );
  }

  void _showQuestionOverlay(TruthDareProvider provider) {
    setState(() => _showQuestion = true);
    final isTruth = provider.currentQuestion?.type == TdType.truth;
    final themeColor = isTruth ? AppConstants.cardBlue : AppConstants.cardPink;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: 450, // Big card
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor,
                themeColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with Player Name
              Column(
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.black.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(50),
                     ),
                     child: Text(
                       provider.currentPlayer?.name.toUpperCase() ?? "PLAYER",
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Icon(
                     isTruth ? Icons.psychology : Icons.local_fire_department,
                     size: 48,
                     color: Colors.white.withValues(alpha: 0.8),
                   ),
                ],
              ),
              
              // The Question
              Expanded(
                child: Center(
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          provider.currentQuestion?.text ?? "No questions found for this filter. Try changing settings.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                            fontFamily: 'Roboto', // Or app default
                          ),
                        ).animate().fadeIn().scale(),
                ),
              ),

              // Difficulty Badge
              if (!provider.isLoading && provider.currentQuestion != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${provider.currentQuestion!.difficulty.name.toUpperCase()}  |  ${provider.currentQuestion!.category.name.toUpperCase()}",
                    style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5),
                  ),
                ),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.completeTurn();
                    context.read<ProgressProvider>().recordGameResult(
                      gameId: 'truth_dare',
                      won: false,
                      xpAward: 10,
                    );
                    GameFeedbackService.success();
                    _confettiController.play();
                    setState(() => _showQuestion = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("NEXT PLAYER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }

  void _showSettings(TruthDareProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("GAME SETTINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              SwitchListTile(
                title: const Text("Safe Mode (10-15)", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Filter out spicy content", style: TextStyle(color: Colors.white38, fontSize: 12)),
                value: provider.safeMode,
                onChanged: (v) {
                  provider.setSafeMode(v);
                  if (v) provider.setAgeGroup(TdAgeGroup.kids);
                  setModalState(() {});
                },
              ),
              
              const SizedBox(height: 10),
              const Text("Age Group", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TdAgeGroup.values.map((group) {
                  final isSelected = provider.selectedAgeGroup == group;
                  return ChoiceChip(
                    label: Text(group.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (s) {
                      provider.setAgeGroup(group);
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              const Text("Category", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  {'label': 'CLEAN', 'value': TdCategory.friends},
                  {'label': 'SPICY', 'value': TdCategory.spicy},
                  {'label': 'COUPLES', 'value': TdCategory.couples},
                  {'label': 'TRENDING', 'value': TdCategory.trending},
                  {'label': 'MOST ASKED', 'value': TdCategory.mostAsked},
                ].map((entry) {
                  final cat = entry['value'] as TdCategory;
                  final label = entry['label'] as String;
                  final isSelected = provider.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (s) {
                      provider.setCategory(cat);
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text("Difficulty", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TdDifficulty.values.map((diff) {
                  final isSelected = provider.selectedDifficulty == diff;
                  return ChoiceChip(
                    label: Text(diff.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (s) {
                      provider.setDifficulty(diff);
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text("Turn History", style: TextStyle(color: Colors.white)),
        content: Text(_history.isEmpty ? "No turns yet." : _history, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))
        ],
      ),
    );
  }

  Widget _buildSessionSettings(TruthDareProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Turns', style: TextStyle(color: AppConstants.textSecondary)),
              const SizedBox(width: 12),
              ...[5, 10, 15, 0].map((turns) {
                final label = turns == 0 ? '∞' : turns.toString();
                final selected = _targetTurns == turns;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _targetTurns = turns),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
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

  void _ensureAiPlayers(TruthDareProvider provider) {
    if (!_useAiFill) return;
    final existingNames = provider.players.map((p) => p.name.toLowerCase()).toSet();
    while (provider.players.length < 2) {
      final name = _aiNames.firstWhere((n) => !existingNames.contains(n.toLowerCase()), orElse: () => 'AI-${provider.players.length + 1}');
      existingNames.add(name.toLowerCase());
      provider.addPlayerObject(Player(id: 'ai_${DateTime.now().microsecondsSinceEpoch}', name: name));
    }
  }

  void _showSessionComplete(TruthDareProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Session Complete', style: TextStyle(color: Colors.white)),
        content: Text('$_turnCount turns played.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _targetTurns = 0;
              });
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.resetGame();
              setState(() {
                _started = false;
                _turnCount = 0;
              });
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
