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
      home: const GameScreen(),
    );
  }
}
