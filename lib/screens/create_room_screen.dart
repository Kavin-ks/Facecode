import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/screens/lobby_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Screen for creating a room.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createRoom() {
    final name = _nameController.text.trim();
    context.read<GameProvider>().createRoom(name);

    final room = context.read<GameProvider>().currentRoom;
    if (room == null) return;

    Navigator.of(context).pushReplacement(
      AppRoute.fadeSlide(const LobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Room')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Host Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createRoom(),
                ),
                const SizedBox(height: AppConstants.largePadding),
                ElevatedButton.icon(
                  onPressed: _createRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Local multiplayer (pass-and-play)\nAdd players in the lobby.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppConstants.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
