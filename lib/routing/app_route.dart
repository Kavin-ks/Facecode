import 'package:flutter/material.dart';

/// Centralized screen transitions.
/// Centralized screen transitions.
class AppRoute {
  static PageRoute<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        // Entrance: Fade In + Slide Up slightly (Vertical motion requirement)
        final enterFade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final enterSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        // Exit: Fade Out (keep it simple, no movement on exit to avoid messiness)
        final exitFade = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn);

        return FadeTransition(
          opacity: exitFade.drive(Tween(begin: 1.0, end: 0.0)), // Inverse for exit
          child: SlideTransition(
            position: enterSlide,
            child: FadeTransition(
              opacity: enterFade,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
