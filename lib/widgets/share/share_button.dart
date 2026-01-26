import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/models/share_content.dart';
import 'package:facecode/services/share_service.dart';

/// Button for sharing content
/// Can be prominent (large) or subtle (icon only)
class ShareButton extends StatelessWidget {
  final ShareContent content;
  final bool prominent;
  final VoidCallback? onShareComplete;
  final IconData? customIcon;
  final String? customLabel;

  const ShareButton({
    super.key,
    required this.content,
    this.prominent = false,
    this.onShareComplete,
    this.customIcon,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (prominent) {
      return _buildProminentButton(context);
    } else {
      return _buildSubtleButton(context);
    }
  }

  Widget _buildProminentButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleShare(context),
      icon: Icon(customIcon ?? Icons.share, size: 20),
      label: Text(customLabel ?? 'Share'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSubtleButton(BuildContext context) {
    return IconButton(
      onPressed: () => _handleShare(context),
      icon: Icon(customIcon ?? Icons.share),
      color: AppConstants.textSecondary,
      tooltip: 'Share',
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await ShareService().shareAchievement(content);
      
      if (onShareComplete != null) {
        onShareComplete!();
      }
      
      // Optional: Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Shared successfully!'),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}

/// Conditional share button that only shows for share-worthy moments
class ConditionalShareButton extends StatelessWidget {
  final ShareContent? content;
  final bool isShareWorthy;
  final bool prominent;

  const ConditionalShareButton({
    super.key,
    required this.content,
    required this.isShareWorthy,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isShareWorthy || content == null) {
      return const SizedBox.shrink();
    }

    return ShareButton(
      content: content!,
      prominent: prominent,
    );
  }
}
