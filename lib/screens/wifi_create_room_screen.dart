import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/app_dialogs.dart';
import 'package:facecode/screens/lobby_screen.dart';
import 'package:facecode/widgets/error_listener.dart';

/// Host a room over local Wi‑Fi
class WifiCreateRoomScreen extends StatefulWidget {
  const WifiCreateRoomScreen({super.key});

  @override
  State<WifiCreateRoomScreen> createState() => _WifiCreateRoomScreenState();
}

class _WifiCreateRoomScreenState extends State<WifiCreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isHosting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hostRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await AppDialogs.showError(context, title: 'Name Required', message: 'Please enter your name to host a room.');
      return;
    }

    setState(() => _isHosting = true);

    // Call provider to host over wifi
    await context.read<GameProvider>().hostWifiRoom(name);

    if (!mounted) return;
    setState(() => _isHosting = false);

    final room = context.read<GameProvider>().currentRoom;
    if (room == null) return;

    // Show success feedback
    AppDialogs.showSnack(context, 'Room hosted successfully!');

    Navigator.of(context).pushReplacement(
      AppRoute.fadeSlide(const LobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Host on Wi‑Fi')),
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
                ),
                const SizedBox(height: AppConstants.largePadding),
                ElevatedButton.icon(
                  onPressed: _isHosting ? null : _hostRoom,
                  icon: _isHosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_isHosting ? 'Hosting...' : 'Host Room (Wi‑Fi)'),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'This device will act as the host and advertise a room on the local Wi‑Fi network.',
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
