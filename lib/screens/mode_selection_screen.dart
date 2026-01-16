import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/create_room_screen.dart';
import 'package:facecode/screens/join_room_screen.dart';
import 'package:facecode/screens/wifi_create_room_screen.dart';
import 'package:facecode/screens/wifi_join_room_screen.dart';

/// Screen to select Offline (same device) or Local Wi-Fi multiplayer
class ModeSelectionScreen extends StatelessWidget {
  final bool isCreating;

  const ModeSelectionScreen({super.key, this.isCreating = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isCreating ? 'Create Room' : 'Join Room')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose Play Mode',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Offline option
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                child: ListTile(
                  leading: const Icon(Icons.phone_android, size: 36),
                  title: const Text('Offline (Same Device)'),
                  subtitle: const Text('Pass-and-play on one phone, no Wi‑Fi required'),
                  onTap: () {
                    if (isCreating) {
                      Navigator.of(context).pushReplacement(
                        AppRoute.fadeSlide(const CreateRoomScreen()),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        AppRoute.fadeSlide(const JoinRoomScreen()),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Wi-Fi option
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                child: ListTile(
                  leading: const Icon(Icons.wifi, size: 36),
                  title: const Text('Local Wi‑Fi'),
                  subtitle: const Text('Connect devices on the same network'),
                  onTap: () {
                    if (isCreating) {
                      Navigator.of(context).pushReplacement(
                        AppRoute.fadeSlide(const WifiCreateRoomScreen()),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        AppRoute.fadeSlide(const WifiJoinRoomScreen()),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Tip: If auto-discovery fails, use the room code provided by the host.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
