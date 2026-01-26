import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/screens/games/common/game_base_screen.dart';
import 'package:facecode/screens/games/common/game_result_screen.dart';
import 'package:facecode/utils/game_catalog.dart';
import 'package:facecode/widgets/premium_ui.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/screens/wifi_create_room_screen.dart';
import 'package:facecode/screens/wifi_join_room_screen.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/controllers/draw_guess_controller.dart';

class DrawGuessScreen extends StatefulWidget {
  const DrawGuessScreen({super.key});

  @override
  State<DrawGuessScreen> createState() => _DrawGuessScreenState();
}

class _DrawGuessScreenState extends State<DrawGuessScreen> {
  final TextEditingController _guessController = TextEditingController();
  final TextEditingController _playerController = TextEditingController();
  final ScrollController _chatController = ScrollController();
  late final DrawGuessController _controller;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = DrawGuessController();
    _controller.addListener(_scrollChatToBottom);
    _controller.addListener(_handleFinish);
  }

  @override
  void dispose() {
    _controller.disposeTimers();
    _controller.removeListener(_scrollChatToBottom);
    _controller.removeListener(_handleFinish);
    _controller.dispose();
    _guessController.dispose();
    _playerController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _handleFinish() {
    if (!mounted) return;
    if (_controller.stage != DrawStage.finished) return;
    if (_didNavigate) return;
    _didNavigate = true;
    final gameInfo = GameCatalog.allGames.firstWhere(
      (g) => g.id == 'draw_guess',
      orElse: () => GameCatalog.allGames[0],
    );
    final win = _controller.correctRounds >= 2;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameInfo: gameInfo,
          score: _controller.score,
          isWin: win,
          onReplay: () {
            Navigator.of(context).pop();
          },
          customMessage: 'Rounds won ${_controller.correctRounds}/${_controller.totalRounds}',
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DrawGuessController>(
        builder: (context, controller, _) {
          return GameBaseScreen(
            title: 'Draw & Guess',
            score: controller.score,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: controller.stage == DrawStage.intro ? _buildIntro(context, controller) : _buildGame(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntro(BuildContext context, DrawGuessController controller) {
    final provider = context.watch<GameProvider>();
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
                      selected: !controller.hasPlayers,
                      selectedColor: AppConstants.secondaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: !controller.hasPlayers ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => controller.setHasPlayers(false),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Local Players'),
                      selected: controller.hasPlayers,
                      selectedColor: AppConstants.primaryColor.withAlpha(70),
                      backgroundColor: Colors.white.withAlpha(10),
                      labelStyle: TextStyle(color: controller.hasPlayers ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                      onSelected: (_) => controller.setHasPlayers(true),
                    ),
                  ],
                ),
                if (controller.hasPlayers) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add player name',
                            hintStyle: const TextStyle(color: AppConstants.textSecondary),
                            filled: true,
                            fillColor: Colors.white.withAlpha(10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          controller.addLocalPlayer(_playerController.text);
                          _playerController.clear();
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.players
                        .map((p) => Chip(
                              label: Text(p.name, style: const TextStyle(color: Colors.white)),
                              backgroundColor: Colors.white.withAlpha(10),
                              deleteIconColor: Colors.white70,
                              onDeleted: () => controller.removePlayer(p),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.currentRoom == null
                              ? null
                              : () {
                                  final mapped = provider.currentRoom!.players
                                      .map((p) => LocalPlayer(id: p.id, name: p.name))
                                      .toList();
                                  controller.syncPlayersFromRoom(mapped);
                                },
                          icon: const Icon(Icons.wifi),
                          label: const Text('Use Wi‑Fi room players'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(AppRoute.fadeSlide(const WifiCreateRoomScreen())),
                          child: const Text('Host on Wi‑Fi', style: TextStyle(color: AppConstants.secondaryColor)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(AppRoute.fadeSlide(const WifiJoinRoomScreen())),
                          child: const Text('Join on Wi‑Fi', style: TextStyle(color: AppConstants.secondaryColor)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.startGame,
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

  Widget _buildGame(DrawGuessController controller) {
    return Column(
      children: [
        _buildTopBar(controller),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: controller.timeLeft / 90,
          minHeight: 6,
          backgroundColor: Colors.white.withAlpha(10),
          valueColor: AlwaysStoppedAnimation<Color>(
            controller.timeLeft < 15 ? AppConstants.errorColor : AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildHintCard(controller),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildCanvas(controller)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildChatPanel(controller)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTools(controller),
      ],
    );
  }

  Widget _buildTopBar(DrawGuessController controller) {
    return Row(
      children: [
        _buildChip('Round ${controller.roundIndex}/${controller.totalRounds}', AppConstants.secondaryColor),
        const SizedBox(width: 8),
        _buildChip('Score ${controller.score}', AppConstants.successColor),
        const SizedBox(width: 8),
        _buildChip(controller.hasPlayers ? 'Players' : 'AI', AppConstants.primaryColor),
        if (controller.hasPlayers && controller.players.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildChip('Drawer: ${controller.players[controller.drawerIndex].name}', AppConstants.accentGold),
        ],
        const Spacer(),
        _buildChip('${controller.timeLeft}s', AppConstants.warningColor),
      ],
    );
  }

  Widget _buildHintCard(DrawGuessController controller) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'WORD: ${controller.buildHint()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: controller.revealHintLetter,
            child: const Text('Reveal Hint', style: TextStyle(color: AppConstants.accentGold)),
          ),
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
          onPanStart: controller.onPanStart,
          onPanUpdate: controller.onPanUpdate,
          onPanEnd: controller.onPanEnd,
          child: CustomPaint(
            painter: _DrawingPainter(controller.strokes),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(DrawGuessController controller) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Guesses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (controller.hasPlayers && controller.players.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: controller.players
                  .map((p) => Chip(
                        label: Text('${p.name} • ${p.score}', style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.white.withAlpha(10),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
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
          if (controller.hasPlayers) ...[
            const SizedBox(height: 8),
            if (controller.players.isNotEmpty) ...[
              DropdownButton<int>(
                value: controller.selectedGuesserIndex,
                isExpanded: true,
                dropdownColor: AppConstants.surfaceColor,
                iconEnabledColor: Colors.white,
                items: List.generate(controller.players.length, (i) {
                  final p = controller.players[i];
                  final isDrawer = i == controller.drawerIndex;
                  return DropdownMenuItem(
                    value: i,
                    child: Text(
                      isDrawer ? '${p.name} (Drawer)' : p.name,
                      style: TextStyle(color: isDrawer ? AppConstants.textMuted : Colors.white),
                    ),
                  );
                }),
                onChanged: (v) => controller.setSelectedGuesserIndex(v ?? 0),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      hintText: controller.aiVerifying ? 'AI verifying...' : 'Enter guess...',
                      hintStyle: const TextStyle(color: AppConstants.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controller.aiVerifying
                      ? null
                      : () async {
                          final text = _guessController.text;
                          _guessController.clear();
                          await controller.submitGuess(text);
                        },
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

  Widget _buildTools(DrawGuessController controller) {
    return GlassCard(
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
                    selectedColor: AppConstants.primaryColor.withAlpha(60),
                    backgroundColor: Colors.white.withAlpha(10),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700),
                    onSelected: (_) => controller.setSelectedBrush(size),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                onPressed: controller.undoStroke,
                icon: const Icon(Icons.undo, color: Colors.white),
              ),
              IconButton(
                onPressed: controller.clearCanvas,
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
                  onTap: controller.toggleEraser,
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: controller.isEraser ? AppConstants.errorColor : Colors.white.withAlpha(10),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.auto_fix_off, color: Colors.white, size: 18),
                  ),
                ),
                ...controller.palette.map((c) {
                  final selected = controller.selectedColor == c && !controller.isEraser;
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
