import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/utils/motion.dart';
import 'package:facecode/services/sound_manager.dart';

class PremiumSnackBar extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;
  final Color? colorOverride;

  const PremiumSnackBar({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.onDismiss,
    this.colorOverride,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color? colorOverride,
    Duration duration = const Duration(seconds: 4),
  }) {
    SoundManager().playUiSound(SoundManager.sfxUiTap);

    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _PremiumSnackBarOverlay(
        entry: overlayEntry,
        title: title,
        message: message,
        icon: icon,
        colorOverride: colorOverride,
        duration: duration,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); 
  }
}

class _PremiumSnackBarOverlay extends StatefulWidget {
  final OverlayEntry entry;
  final String title;
  final String message;
  final IconData icon;
  final Color? colorOverride;
  final Duration duration;

  const _PremiumSnackBarOverlay({
    required this.entry,
    required this.title,
    required this.message,
    required this.icon,
    this.colorOverride,
    required this.duration,
  });

  @override
  State<_PremiumSnackBarOverlay> createState() => _PremiumSnackBarOverlayState();
}

class _PremiumSnackBarOverlayState extends State<_PremiumSnackBarOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationMedium,
    );
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (_isExiting) return;
    _isExiting = true;
    try {
      await _controller.reverse();
    } catch(e) {
      // ignore
    }
    if (mounted) {
      widget.entry.remove();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     return Positioned(
       top: MediaQuery.of(context).padding.top + 16,
       left: 16,
       right: 16,
       child: Material(
         color: Colors.transparent,
         child: Dismissible(
           key: UniqueKey(),
           direction: DismissDirection.up,
           onDismissed: (_) {
              widget.entry.remove();
           },
           child: _buildContent(),
         ),
       ),
     );
  }
  
  Widget _buildContent() {
    final color = widget.colorOverride ?? AppConstants.primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.9), // Glassy backdrop
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(controller: _controller)
    .fadeIn(duration: 300.ms)
    .slideY(begin: -1, end: 0, curve: Curves.easeOutBack);
  }
}
