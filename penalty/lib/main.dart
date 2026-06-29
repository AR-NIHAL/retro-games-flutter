import 'package:flutter/material.dart';
import 'game/game_screen.dart';

void main() {
  runApp(const PenaltyApp());
}

class PenaltyApp extends StatelessWidget {
  const PenaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penalty Shootout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _GameWrapper(),
    );
  }
}

class _GameWrapper extends StatelessWidget {
  const _GameWrapper();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        Widget game = const GameScreen();
        if (isWide) {
          game = Center(
            child: SizedBox(
              width: 500,
              height: constraints.maxHeight,
              child: game,
            ),
          );
        }
        return ColoredBox(color: const Color(0xFF0A1628), child: game);
      },
    );
  }
}
