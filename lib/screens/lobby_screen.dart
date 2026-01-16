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

/// Lobby screen where players wait before game starts
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied!'),
        duration: Duration(seconds: 2),
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
          appBar: AppBar(
            title: const Text('Lobby'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _leaveRoom,
            ),
            actions: [
              if (gameProvider.connectionStatus != 'disconnected')
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Row(
                    children: [
                      if (gameProvider.connectionStatus == 'connecting')
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        gameProvider.connectionStatus == 'hosting' ? Icons.wifi : Icons.wifi, // same icon for now
                        color: AppConstants.secondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gameProvider.connectionStatus,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Room Code Display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        children: [
                          Text(
                            'Room Code',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.roomCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: AppConstants.primaryColor,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyRoomCode(room.roomCode),
                                color: AppConstants.primaryColor,
                              ),
                            ],
                          ),
                          Text(
                            'Share this code with friends',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().scale(),

                  const SizedBox(height: AppConstants.largePadding),

                  // Players List
                  Text(
                    'Players (${room.players.length}/${AppConstants.maxPlayers})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Player Cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: room.players.length,
                      itemBuilder: (context, index) {
                        final player = room.players[index];
                        final isActive =
                            gameProvider.currentPlayer?.id == player.id;
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: AppConstants.smallPadding,
                          ),
                          child: ListTile(
                            onTap: () => gameProvider.setActivePlayer(player.id),
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primaryColor,
                              child: Text(
                                player.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(player.name),
                            subtitle: Text(
                              isActive
                                  ? 'Active player (tap others to switch)'
                                  : 'Tap to switch active player',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                if (player.isHost)
                                  const Chip(
                                    label: Text('Host'),
                                    backgroundColor: AppConstants.secondaryColor,
                                  ),
                                if (room.isEmojiPlayer(player.id))
                                  Chip(
                                    label: const Text('Emoji'),
                                    backgroundColor:
                                        AppConstants.primaryColor.withAlpha(64),
                                  ),
                                if (isActive)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppConstants.secondaryColor,
                                  ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 * index))
                            .slideX(begin: -0.2, end: 0);
                      },
                    ),
                  ),

                  // Add Player Section (for local multiplayer)
                  if (room.players.length < AppConstants.maxPlayers) ...[
                    const Divider(),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      'Add Another Player',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerNameController,
                            decoration: const InputDecoration(
                              hintText: 'Player name',
                              prefixIcon: Icon(Icons.person_add),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => _addPlayer(),
                          ),
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addPlayer,
                          color: AppConstants.primaryColor,
                          iconSize: 40,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppConstants.largePadding),

                  // Start Game Button (host only)
                  if (gameProvider.isHost)
                    ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Game'),
                    ).animate().fadeIn(delay: 500.ms).scale()
                  else
                    Card(
                      color: AppConstants.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: AppConstants.defaultPadding),
                            Text(
                              'Waiting for host to start...',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .fadeIn()
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.02, 1.02),
                          duration: 900.ms,
                          curve: Curves.easeInOut,
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
}
