import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'views/main_shell/main_shell_view.dart';

void main() {
  runApp(const MainApplication());
}

class MainApplication extends StatelessWidget {
  const MainApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr. Rex',
      theme: AppTheme.light,
      home: const MainShellView(),
    );
  }
}
