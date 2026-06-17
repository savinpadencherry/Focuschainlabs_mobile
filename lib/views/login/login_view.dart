import 'package:flutter/material.dart';

import '../main_shell/main_shell_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.graphic_eq_rounded, color: colors.onPrimary),
              ),
              const Spacer(),
              Text(
                'Welcome to\nMr. Rex',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                      letterSpacing: -1.6,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Client context in seconds. CRM updates without forms. Follow-ups that never slip.',
                style: TextStyle(
                  color: Color(0xFF68716E),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.lock_outline_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your organisation’s data stays isolated and access-controlled.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement<void, void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainShellView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Use work email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
