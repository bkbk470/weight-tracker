import 'dart:async';
import 'package:flutter/material.dart';

/// Unfocuses any active text input when navigating.
///
/// This helps avoid a Flutter Web assertion where pointer events target
/// a non-active input element when dialogs/bottom sheets appear while
/// another TextField is focused.
class UnfocusOnNavigateObserver extends NavigatorObserver {
  UnfocusOnNavigateObserver();
  
  void _unfocus() {
    // Safely unfocus without throwing if no focus
    // Use a microtask to ensure unfocus happens after current frame
    Future.microtask(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _unfocus();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _unfocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _unfocus();
  }
}
