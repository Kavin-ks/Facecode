import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:facecode/providers/game_provider.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/lobby_screen.dart';
import 'package:facecode/widgets/error_listener.dart';
import 'package:facecode/utils/app_dialogs.dart';

/// Join a room over local Wi‑Fi
class WifiJoinRoomScreen extends StatefulWidget {
  const WifiJoinRoomScreen({super.key});

  @override
  State<WifiJoinRoomScreen> createState() => _WifiJoinRoomScreenState();
}

class _WifiJoinRoomScreenState extends State<WifiJoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _scanNetwork();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      await AppDialogs.showError(context, title: 'Code Required', message: 'Please enter a room code.');
      return;
    }

    setState(() => _isJoining = true);
    final ok = await context.read<GameProvider>().joinWifiRoom(code);
    if (!mounted) return;
    setState(() => _isJoining = false);

    if (ok) {
      AppDialogs.showSnack(context, 'Connected to room!');
      Navigator.of(context).pushReplacement(
        AppRoute.fadeSlide(const LobbyScreen()),
      );
    }
  }

  Future<void> _scanNetwork() async {
    // Trigger discovery; provider exposes a stream or list of discovered rooms
    await context.read<GameProvider>().discoverWifiRooms();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return ErrorListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Join on Wi‑Fi')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _scanNetwork,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Scan Network'),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                if (provider.connectionStatus == 'connecting')
                  const Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Scanning network...'),
                    ],
                  ),
                const SizedBox(height: AppConstants.defaultPadding),
                // Discovered rooms
                if (provider.discoveredRooms.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.discoveredRooms.length,
                      itemBuilder: (context, index) {
                        final r = provider.discoveredRooms[index];
                        return ListTile(
                          title: Text(r.name),
                          subtitle: Text('Host: ${r.host} • Code: ${r.code}'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final navCtx = context;
                              final ok = await provider.joinWifiRoom(r.code);
                              if (!navCtx.mounted) return;
                              if (ok) {
                                AppDialogs.showSnack(navCtx, 'Connected to ${r.name}!');
                                Navigator.of(navCtx).pushReplacement(
                                  AppRoute.fadeSlide(const LobbyScreen()),
                                );
                              }
                            },
                            child: const Text('Join'),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Room Code',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinWithCode,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isJoining ? 'Joining...' : 'Join'),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'If you cannot find a room automatically, ask the host for the room code and enter it here.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppConstants.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
