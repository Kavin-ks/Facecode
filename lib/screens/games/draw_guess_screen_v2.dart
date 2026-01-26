import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/controllers/draw_guess_controller_v2.dart';
import 'package:facecode/models/draw_guess_models.dart';
import 'package:facecode/providers/progress_provider.dart';
import 'package:facecode/providers/analytics_provider.dart';

class DrawGuessScreen extends StatefulWidget {
  const DrawGuessScreen({super.key});

  @override
  State<DrawGuessScreen> createState() => _DrawGuessScreenState();
}

class _DrawGuessScreenState extends State<DrawGuessScreen> {
  final TextEditingController _guessController = TextEditingController();
  final TextEditingController _playerController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final ScrollController _chatController = ScrollController();
  late final DrawGuessController _controller;
  late final ConfettiController _confettiController;

  final List<String> _avatars = ['😀', '😎', '🤖', '🐶', '🐱', '🦊', '🐼', '🐸', '🦄', '🐙'];
  String _selectedAvatar = '😀';
  bool _statsRecorded = false;

  @override
  void initState() {
    super.initState();
    _controller = DrawGuessController();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _controller.addListener(_scrollChatToBottom);
    _controller.addListener(_checkGameEnd);
    _controller.loadWordBank();
  }

  @override
  void dispose() {
    _guessController.dispose();
    _playerController.dispose();
    _roomController.dispose();
    _chatController.dispose();
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
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

  void _checkGameEnd() {
    if (_controller.phase == DrawPhase.scoreboard && !_statsRecorded) {
      _statsRecorded = true;
      
      final room = _controller.room;
      if (room == null || !mounted) return;
      
      final currentUserId = _controller.currentUserId;
      if (currentUserId == null) return;
      
      final me = room.players.firstWhere((p) => p.id == currentUserId, orElse: () => Player(id: '', name: ''));
      if (me.id != currentUserId) return;

      final sorted = _controller.sortedPlayers;
      final isWinner = sorted.isNotEmpty && sorted.first.id == me.id;
      final xp = isWinner ? 100 : (me.score > 0 ? 50 : 25);

      context.read<ProgressProvider>().recordGameResult(
        gameId: 'game-draw-guess',
        won: isWinner,
        xpAward: xp,
        analytics: context.read<AnalyticsProvider>(),
        drawingsCreated: 1, // Award 1 drawing stat per game
      );
    } 
    
    if (_controller.phase == DrawPhase.home) {
      _statsRecorded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DrawGuessController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: Stack(
              children: [
                SafeArea(
                  child: AnimatedSwitcher(
                    duration: 250.ms,
                    child: _buildPhase(controller),
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
        },
      ),
    );
  }

  Widget _buildPhase(DrawGuessController controller) {
    switch (controller.phase) {
      case DrawPhase.home:
        return _buildHome(controller);
      case DrawPhase.lobby:
        return _buildLobby(controller);
      case DrawPhase.choosingWord:
        return _buildChoosingWord(controller);
      case DrawPhase.drawing:
        return _buildDrawing(controller);
      case DrawPhase.reveal:
        return _buildReveal(controller);
      case DrawPhase.scoreboard:
        return _buildScoreboard(controller);
    }
  }

  Widget _buildHome(DrawGuessController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Draw & Guess',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time drawing and guessing, drawize-style.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            'Active rooms: ${controller.publicRooms.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          _buildNameInput(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.createRoom(_playerController.text, avatar: _selectedAvatar),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CREATE ROOM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => controller.joinRoom(_roomController.text, _playerController.text, avatar: _selectedAvatar),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('JOIN ROOM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _roomController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter room code',
              hintStyle: const TextStyle(color: AppConstants.textSecondary),
              filled: true,
              fillColor: AppConstants.surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          if (controller.publicRooms.isNotEmpty) ...[
            const Text('Public Rooms', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...controller.publicRooms.map((room) => _buildPublicRoomTile(room)),
          ],
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _playerController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: const TextStyle(color: AppConstants.textSecondary),
            filled: true,
            fillColor: AppConstants.surfaceColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _avatars.map((avatar) {
            final selected = _selectedAvatar == avatar;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = avatar),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppConstants.primaryColor : Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? Colors.white : Colors.white12),
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPublicRoomTile(String roomCode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.group, color: Colors.white70),
          const SizedBox(width: 8),
          Text(roomCode, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLobby(DrawGuessController controller) {
    final room = controller.room;
    if (room == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: controller.resetToHome,
              ),
              Column(
                children: [
                  const Text('ROOM CODE', style: TextStyle(color: AppConstants.textSecondary, letterSpacing: 1.5, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(room.code, style: const TextStyle(color: AppConstants.primaryColor, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          _buildLobbySettings(controller),
          const SizedBox(height: 16),
          _buildLobbyPlayers(controller),
          const SizedBox(height: 16),
          if (controller.isHost)
            ElevatedButton(
              onPressed: controller.startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('START GAME', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildLobbySettings(DrawGuessController controller) {
    final settings = controller.room!.settings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 5, 10, 0].map((r) {
              final selected = settings.rounds == r;
              return ChoiceChip(
                label: Text(r == 0 ? '∞' : r.toString()),
                selected: selected,
                selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                onSelected: (_) => controller.updateRounds(r),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [60, 80, 100].map((t) {
              final selected = settings.drawTime == t;
              return ChoiceChip(
                label: Text('${t}s'),
                selected: selected,
                selectedColor: AppConstants.secondaryColor.withValues(alpha: 0.6),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                onSelected: (_) => controller.updateDrawTime(t),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: WordDifficulty.values.map((d) {
              final selected = settings.difficulty == d;
              return ChoiceChip(
                label: Text(d.name.toUpperCase()),
                selected: selected,
                selectedColor: AppConstants.accentGold.withValues(alpha: 0.6),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                onSelected: (_) => controller.updateDifficulty(d),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WordCategory.values.map((c) {
              final selected = settings.category == c;
              return ChoiceChip(
                label: Text(c.name.toUpperCase()),
                selected: selected,
                selectedColor: AppConstants.primaryColor.withValues(alpha: 0.5),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                onSelected: (_) => controller.updateCategory(c),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['EN', 'ES'].map((lang) {
              final selected = settings.language == lang;
              return ChoiceChip(
                label: Text(lang),
                selected: selected,
                selectedColor: AppConstants.secondaryColor.withValues(alpha: 0.5),
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                onSelected: (_) => controller.updateLanguage(lang),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI fallback', style: TextStyle(color: AppConstants.textSecondary)),
              Switch(
                value: settings.aiFallback,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (val) => controller.updateAiFallback(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (settings.aiFallback)
            Wrap(
              spacing: 8,
              children: [1, 2, 3].map((level) {
                final selected = settings.aiLevel == level;
                final label = level == 1 ? 'CASUAL' : level == 2 ? 'BALANCED' : 'SHARP';
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  selectedColor: AppConstants.accentGold.withValues(alpha: 0.5),
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                  onSelected: (_) => controller.updateAiLevel(level),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLobbyPlayers(DrawGuessController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Players', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add player',
                    hintStyle: const TextStyle(color: AppConstants.textSecondary),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  controller.addPlayer(_playerController.text, avatar: _selectedAvatar);
                  _playerController.clear();
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.room!.players.map((p) {
              return Chip(
                label: Text('${p.avatar ?? '🙂'} ${p.name}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.white10,
                deleteIcon: controller.isHost && !p.isAI ? const Icon(Icons.close) : null,
                onDeleted: controller.isHost && !p.isAI ? () => controller.removePlayer(p.id) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (controller.room!.players.isNotEmpty)
            DropdownButton<String>(
              value: controller.currentUserId,
              dropdownColor: AppConstants.surfaceColor,
              iconEnabledColor: Colors.white,
              isExpanded: true,
              items: controller.room!.players.where((p) => !p.isAI).map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text('You are: ${p.name}', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (id) => controller.setCurrentUser(id),
            ),
        ],
      ),
    );
  }

  Widget _buildChoosingWord(DrawGuessController controller) {
    final isDrawer = controller.isCurrentUserDrawer;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGameTopBar(controller),
          const SizedBox(height: 16),
          if (controller.countdown > 0)
            Center(
              child: Text(
                controller.countdown.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              ).animate().scale(duration: 400.ms),
            ),
          if (controller.countdown <= 0) ...[
            Text(
              isDrawer ? 'Choose a word' : 'Waiting for drawer to choose...',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Difficulty: ${controller.room?.settings.difficulty.name.toUpperCase()}',
              style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Category: ${controller.room?.settings.category.name.toUpperCase()} • ${controller.room?.settings.language}',
              style: const TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Time left: ${controller.wordChoiceSeconds}s',
              style: const TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isDrawer)
              Column(
                children: controller.wordOptions.map((w) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => controller.chooseWord(w),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawing(DrawGuessController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGameTopBar(controller),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: controller.timeLeft / controller.totalTime,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              controller.timeLeft < 15 ? AppConstants.errorColor : AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildHintBar(controller),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                if (wide) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: _buildCanvas(controller)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildChat(controller)),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: _buildCanvas(controller)),
                    const SizedBox(height: 12),
                    SizedBox(height: 260, child: _buildChat(controller)),
                  ],
                );
              },
            ),
          ),
          if (controller.isCurrentUserDrawer) ...[
            const SizedBox(height: 12),
            _buildTools(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildReveal(DrawGuessController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGameTopBar(controller),
          const SizedBox(height: 16),
          Text('The word was', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(controller.wordToDraw, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _buildRevealSummary(controller),
          const Spacer(),
          ElevatedButton(
            onPressed: controller.nextRound,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('NEXT ROUND', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(DrawGuessController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
    final sorted = controller.sortedPlayers;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Final Scoreboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final p = sorted[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: index == 0 ? AppConstants.primaryColor : AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text(p.avatar ?? '🙂', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Text('${p.score} pts', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: controller.resetToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTopBar(DrawGuessController controller) {
    final drawer = controller.currentDrawer;
    return Row(
      children: [
        _buildChip('Round ${controller.currentRoundLabel}', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip('Timer ${controller.timeLeft}s', AppConstants.warningColor),
        const SizedBox(width: 8),
        _buildChip('Drawer: ${drawer?.avatar ?? '🙂'} ${drawer?.name ?? '—'}', AppConstants.accentGold),
      ],
    );
  }

  Widget _buildHintBar(DrawGuessController controller) {
    final isDrawer = controller.isCurrentUserDrawer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isDrawer ? 'WORD: ${controller.wordToDraw}' : 'WORD: ${controller.buildHint()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isDrawer)
            Text('Hints', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildCanvas(DrawGuessController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onPanStart: controller.isCurrentUserDrawer ? controller.onPanStart : null,
          onPanUpdate: controller.isCurrentUserDrawer ? controller.onPanUpdate : null,
          onPanEnd: controller.isCurrentUserDrawer ? controller.onPanEnd : null,
          child: CustomPaint(
            painter: _DrawingPainter(controller.strokes),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildChat(DrawGuessController controller) {
    final guessDisabled = controller.isCurrentUserDrawer || controller.hasCurrentUserGuessed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Guesses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: controller.room?.players
                    .map((p) {
                      final isDrawer = p.isDrawer;
                      return Chip(
                        label: Text('${p.avatar ?? '🙂'} ${p.name} • ${p.score}', style: const TextStyle(color: Colors.white)),
                        backgroundColor: isDrawer ? AppConstants.accentGold.withValues(alpha: 0.35) : Colors.white10,
                        side: isDrawer ? const BorderSide(color: AppConstants.accentGold) : BorderSide.none,
                      );
                    })
                    .toList() ??
                [],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _chatController,
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[index];
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _guessController,
                  style: const TextStyle(color: Colors.white),
                  enabled: !guessDisabled,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    hintText: guessDisabled ? 'Guess locked' : 'Type your guess...',
                    hintStyle: const TextStyle(color: AppConstants.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: guessDisabled
                    ? null
                    : () {
                        final text = _guessController.text;
                        _guessController.clear();
                        controller.submitGuess(controller.currentUserId, text);
                      },
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          if (guessDisabled && !controller.isCurrentUserDrawer) ...[
            const SizedBox(height: 8),
            const Text('Waiting for others...', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildTools(DrawGuessController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Brush', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              ...controller.brushSizes.map((size) {
                final selected = controller.selectedBrush == size;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${size.toInt()}'),
                    selected: selected,
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.6),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => controller.setSelectedBrush(size),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                onPressed: controller.toggleEraser,
                icon: Icon(controller.isEraser ? Icons.auto_fix_high : Icons.brush, color: Colors.white),
              ),
              IconButton(
                onPressed: controller.undoStroke,
                icon: const Icon(Icons.undo, color: Colors.white70),
              ),
              IconButton(
                onPressed: controller.clearCanvas,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.palette.map((c) {
                final selected = c == controller.selectedColor && !controller.isEraser;
                return GestureDetector(
                  onTap: () {
                    if (controller.isEraser) controller.toggleEraser();
                    controller.setSelectedColor(c);
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealSummary(DrawGuessController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Round Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Correct guesses: ${controller.correctGuessCount}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: controller.room!.players.map((p) {
              final correct = controller.correctGuessers.contains(p.id);
              return Chip(
                label: Text('${p.name} ${correct ? '✓' : '✗'}', style: const TextStyle(color: Colors.white)),
                backgroundColor: correct ? AppConstants.successColor : Colors.white10,
              );
            }).toList(),
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

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;

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
        ..strokeWidth = stroke.thickness
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
