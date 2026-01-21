import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/routing/app_route.dart';
import 'package:facecode/screens/create_room_screen.dart';
import 'package:facecode/screens/join_room_screen.dart';
import 'package:facecode/screens/wifi_create_room_screen.dart';
import 'package:facecode/screens/wifi_join_room_screen.dart';

/// Modern mode selection screen - Play Store game hub style
class ModeSelectionScreen extends StatelessWidget {
  final bool isCreating;

  const ModeSelectionScreen({super.key, this.isCreating = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.borderColor,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: -0.2, end: 0),

              const SizedBox(height: 32),
              
              // Title
              Center(
                child: Text(
                  isCreating ? 'Create Room' : 'Join Room',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),
              
              Center(
                child: Text(
                  'Choose how you want to play',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Offline option
              _buildModeCard(
                context: context,
                icon: Icons.phone_android_rounded,
                title: 'Offline Mode',
                subtitle: 'Pass-and-play on one device',
                description: 'No Wi-Fi required • Great for parties',
                color: AppConstants.cardPurple,
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

              const SizedBox(height: 14),

              // Wi-Fi option
              _buildModeCard(
                context: context,
                icon: Icons.wifi_rounded,
                title: 'Local Wi-Fi',
                subtitle: 'Connect multiple devices',
                description: 'Same network required • Each player needs a phone',
                color: AppConstants.cardBlue,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
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
                          Icons.lightbulb_outline_rounded,
                          color: AppConstants.accentGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: If auto-discovery fails, use the room code provided by the host.',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const SizedBox(height: 24),
              ],
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
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }
}
