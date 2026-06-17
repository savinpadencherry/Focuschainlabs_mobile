import 'package:flutter/material.dart';

import 'views/main_shell/main_shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MrRexApp());
}

class MrRexApp extends StatelessWidget {
  const MrRexApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF0F766E);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr. Rex',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE5ECE9)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: const MainShellView(),
    );
  }
}
