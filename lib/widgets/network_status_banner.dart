import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facecode/services/network_connectivity_service.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Banner widget that shows network status at the top of the screen
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkConnectivityService>(
      builder: (context, networkService, child) {
        // Only show banner when offline
        if (networkService.isOnline) {
          return const SizedBox.shrink();
        }

        final timeSinceOnline = networkService.lastOnlineTime != null
            ? DateTime.now().difference(networkService.lastOnlineTime!)
            : null;

        return Material(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.warningColor,
                  AppConstants.warningColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.white,
                    size: 20,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 600.ms)
                      .then()
                      .fadeOut(duration: 600.ms),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timeSinceOnline != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Last online ${_formatDuration(timeSinceOnline)} ago',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ).animate().slideY(begin: -1, duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inDays}d';
    }
  }
}

/// Inline network status indicator for use within widgets
class NetworkStatusIndicator extends StatelessWidget {
  final bool showWhenOnline;

  const NetworkStatusIndicator({
    super.key,
    this.showWhenOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkConnectivityService>(
      builder: (context, networkService, child) {
        if (networkService.isOnline && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: networkService.isOnline
                ? AppConstants.successColor.withValues(alpha: 0.2)
                : AppConstants.errorColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: networkService.isOnline
                  ? AppConstants.successColor
                  : AppConstants.errorColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                networkService.isOnline ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: networkService.isOnline
                    ? AppConstants.successColor
                    : AppConstants.errorColor,
              ),
              const SizedBox(width: 6),
              Text(
                networkService.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: networkService.isOnline
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
