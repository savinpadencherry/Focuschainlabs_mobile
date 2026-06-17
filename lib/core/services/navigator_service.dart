import 'package:flutter/material.dart';

/// Global navigation so blocs/services can route without a [BuildContext].
class NavigatorService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T>(Widget page) {
    return navigatorKey.currentState!.push<T>(AppPageRoute<T>(page));
  }

  Future<T?> pushReplacement<T, R>(Widget page) {
    return navigatorKey.currentState!.pushReplacement<T, R>(AppPageRoute<T>(page));
  }

  void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }
}

/// Shared page transition: a soft fade with a subtle upward slide. Gives the
/// whole app a consistent, polished motion language.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 360),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
