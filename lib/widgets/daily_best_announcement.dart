import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';
import 'package:facecode/widgets/ui_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class DailyBestAnnouncement extends StatefulWidget {
  final List<String> titles;
  final VoidCallback onDismiss;

  const DailyBestAnnouncement({
    super.key,
    required this.titles,
    required this.onDismiss,
  });

  static void show(BuildContext context, List<String> titles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DailyBestAnnouncement(
        titles: titles,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<DailyBestAnnouncement> createState() => _DailyBestAnnouncementState();
}

class _DailyBestAnnouncementState extends State<DailyBestAnnouncement> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleLabels = widget.titles.map((t) => t == 'overall' ? 'OVERALL CHAMPION' : t.toUpperCase().replaceAll('_', ' ')).toList();

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppConstants.accentGold, Colors.white, AppConstants.primaryColor],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🏆",
                    style: TextStyle(fontSize: 80),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    "CONGRATULATIONS!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    "You were the best player yesterday!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppConstants.accentGold.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.accentGold.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "NEW TITLES EARNED",
                          style: TextStyle(
                            color: AppConstants.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...titleLabels.map((label) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "✨ $label ✨",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ).animate().scale(delay: 800.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    "Badge active for the next 24 hours",
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                  ).animate().fadeIn(delay: 1.2.seconds),
                  
                  const SizedBox(height: 60),
                  
                  AddictivePrimaryButton(
                    label: "HELL YEAH!",
                    onPressed: widget.onDismiss,
                  ).animate().fadeIn(delay: 1.5.seconds).scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
