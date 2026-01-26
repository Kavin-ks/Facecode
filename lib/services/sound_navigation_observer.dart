import 'package:flutter/material.dart';
import 'package:facecode/services/sound_manager.dart';

/// plays a subtle whoosh sound on navigation push/pop
class SoundNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _playNavSound(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // When popping, we are going back to 'previousRoute'. 
    // Usually valid to play sound if we are popping a page.
    _playNavSound(route);
  }

  void _playNavSound(Route<dynamic> route) {
    // Only play for PageRoutes (screens), avoid dialogs/bottomsheets if purely strictly 'navigation'
    // But often dialogs also sound good with a whoosh? User said "navigating between pages".
    // Let's restrict to PageRoute to be subtle.
    if (route is PageRoute) {
       SoundManager().playUiSound(SoundManager.sfxUiWhoosh, throttleMs: 300);
    }
  }
}
