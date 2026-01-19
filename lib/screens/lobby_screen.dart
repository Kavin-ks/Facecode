import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:facecode/models/game_room.dart';
import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/screens/game_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Premium lobby screen where players wait before game starts
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _playerNameController = TextEditingController();

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  /// Add a new player (for local multiplayer)
  void _addPlayer() {
    final name = _playerNameController.text.trim();
    final gameProvider = context.read<GameProvider>();
    gameProvider.addPlayer(name);
    _playerNameController.clear();
  }

  /// Start the game
  void _startGame() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.startGame();
    final room = gameProvider.currentRoom;
    if (room == null || room.state != GameState.playing) return;
    Navigator.of(context).pushReplacement(
      AppRoute.fadeSlide(const GameScreen()),
    );
  }

  /// Copy room code to clipboard
  void _copyRoomCode(String roomCode) {
    Clipboard.setData(ClipboardData(text: roomCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Room code copied!'),
          ],
        ),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Leave room and go back
  void _leaveRoom() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.leaveRoom();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final room = gameProvider.currentRoom;
          if (room == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0D12),
                    Color(0xFF1A1A2E),
                    Color(0xFF0D0D12),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    _buildAppBar(gameProvider),
                    
                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Room Code Card
                            _buildRoomCodeCard(room.roomCode),
                            
                            const SizedBox(height: AppConstants.xlPadding),
                            
                            // Players Section
                            _buildPlayersSection(room, gameProvider),
                            
                            // Add Player Section
                            if (room.players.length < AppConstants.maxPlayers) ...[
                              const SizedBox(height: AppConstants.largePadding),
                              _buildAddPlayerSection(),
                            ],
                            
                            const SizedBox(height: AppConstants.xlPadding),
                            
                            // Start/Wait Section
                            if (gameProvider.isHost)
                              _buildStartButton()
                            else
                              _buildWaitingCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _leaveRoom,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Game Lobby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Connection status
          if (gameProvider.connectionStatus != 'disconnected')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstants.successColor.withAlpha(50),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppConstants.successColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.successColor.withAlpha(150),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gameProvider.connectionStatus,
                    style: TextStyle(
                      color: AppConstants.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildRoomCodeCard(String roomCode) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withAlpha(30),
            AppConstants.secondaryColor.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppConstants.primaryColor.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'ROOM CODE',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyRoomCode(roomCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withAlpha(40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: Text(
                      roomCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to copy • Share with friends',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPlayersSection(GameRoom room, GameProvider gameProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: AppConstants.goldAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'PLAYERS',
              style: TextStyle(
                color: AppConstants.goldAccent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${room.players.length}/${AppConstants.maxPlayers}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...room.players.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final isActive = gameProvider.currentPlayer?.id == player.id;
          
          return _buildPlayerCard(
            player: player,
            isActive: isActive,
            isHost: player.isHost,
            isEmojiPlayer: room.isEmojiPlayer(player.id),
            index: index,
            onTap: () => gameProvider.setActivePlayer(player.id),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerCard({
    required dynamic player,
    required bool isActive,
    required bool isHost,
    required bool isEmojiPlayer,
    required int index,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive 
              ? AppConstants.primaryColor.withAlpha(20) 
              : AppConstants.surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? AppConstants.primaryColor.withAlpha(100) 
                : AppConstants.borderColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: AppConstants.premiumGradient)
                    : null,
                color: isActive ? null : AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive 
                      ? Colors.transparent 
                      : AppConstants.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  player.name[0].toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : AppConstants.textMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Active player' : 'Tap to switch',
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Badges
            Row(
              children: [
                if (isHost)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.goldAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '👑 Host',
                      style: TextStyle(
                        color: AppConstants.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isHost && isEmojiPlayer) const SizedBox(width: 8),
                if (isEmojiPlayer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.neonPink.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '😎 Emoji',
                      style: TextStyle(
                        color: AppConstants.neonPink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    color: AppConstants.successColor,
                    size: 24,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildAddPlayerSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: AppConstants.neonBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Add Another Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: TextField(
                    controller: _playerNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Player name',
                      hintStyle: TextStyle(color: AppConstants.textMuted),
                      prefixIcon: Icon(Icons.person, color: AppConstants.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addPlayer,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppConstants.neonGradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.neonBlue.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: AppConstants.premiumGradient),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withAlpha(100),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'START GAME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms)
        .scale(begin: const Offset(0.9, 0.9))
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white24);
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Waiting for host to start...',
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}
