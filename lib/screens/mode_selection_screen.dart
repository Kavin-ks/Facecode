import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/create_room_screen.dart';
import 'package:facecode/screens/join_room_screen.dart';
import 'package:facecode/screens/wifi_create_room_screen.dart';
import 'package:facecode/screens/wifi_join_room_screen.dart';

/// Premium screen to select Offline (same device) or Local Wi-Fi multiplayer
class ModeSelectionScreen extends StatelessWidget {
  final bool isCreating;

  const ModeSelectionScreen({super.key, this.isCreating = true});

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),

                const SizedBox(height: 40),
                
                // Title
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppConstants.neonGradient,
                    ).createShader(bounds),
                    child: Text(
                      isCreating ? 'Create Room' : 'Join Room',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),
                
                Center(
                  child: Text(
                    'Choose how you want to play',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Offline option
                _buildModeCard(
                  context: context,
                  icon: Icons.phone_android,
                  title: 'Offline Mode',
                  subtitle: 'Pass-and-play on one device',
                  description: 'No Wi-Fi required • Great for parties',
                  gradient: AppConstants.premiumGradient,
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                  delay: 300,
                ),

                const SizedBox(height: 16),

                // Wi-Fi option
                _buildModeCard(
                  context: context,
                  icon: Icons.wifi,
                  title: 'Local Wi-Fi',
                  subtitle: 'Connect multiple devices',
                  description: 'Same network required • Each player needs a phone',
                  gradient: AppConstants.neonGradient,
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                  delay: 400,
                ),

                const Spacer(),

                // Tip
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.goldAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: AppConstants.goldAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Tip: If auto-discovery fails, use the room code provided by the host.',
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const SizedBox(height: AppConstants.largePadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor.withAlpha(150),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient.first.withAlpha(50),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: gradient.first,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }
}
