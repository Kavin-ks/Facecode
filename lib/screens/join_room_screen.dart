import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/screens/lobby_screen.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Screen for joining a room by code.
///
/// Note: In Version 1 (local multiplayer), the room must exist on this device
/// (created earlier in the same session).
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    final ok = context.read<GameProvider>().joinRoom(code, name);
    if (!ok) return;

    Navigator.of(context).pushReplacement(
      AppRoute.fadeSlide(const LobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Join Room')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Room Code',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: '6 characters',
                    prefixIcon: Icon(Icons.key),
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _joinRoom(),
                ),
                const SizedBox(height: AppConstants.largePadding),
                ElevatedButton.icon(
                  onPressed: _joinRoom,
                  icon: const Icon(Icons.login),
                  label: const Text('Join'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
