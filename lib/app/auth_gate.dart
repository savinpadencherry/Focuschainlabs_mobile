import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/view/login_view.dart';
import '../features/auth/view/splash_view.dart';
import '../features/shell/view/app_shell.dart';

/// Routes between splash, login and the authenticated shell based on
/// [AuthState]. Kicks off session restore after a brief branded splash.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Let the splash breathe, then restore any cached session.
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) context.read<AuthBloc>().add(const AuthStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final Widget child = switch (state.status) {
          AuthStatus.authenticated => const AppShell(),
          AuthStatus.unauthenticated => const LoginView(),
          _ => const SplashView(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          child: KeyedSubtree(
            key: ValueKey<AuthStatus>(state.status),
            child: child,
          ),
        );
      },
    );
  }
}
