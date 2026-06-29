import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int totalRounds;
  final VoidCallback onRestart;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.totalRounds,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = score / totalRounds;
    final (message, subtitle) = switch (ratio) {
      1.0 => ('PERFECT!', 'You scored all $totalRounds!'),
      >= 0.8 => ('Excellent!', '$score out of $totalRounds'),
      >= 0.6 => ('Good Job!', '$score out of $totalRounds'),
      >= 0.4 => ('Not Bad', '$score out of $totalRounds'),
      _ => ('Keep Practicing', '$score out of $totalRounds'),
    };

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A1628).withValues(alpha: 0.95),
              const Color(0xFF1B3D2A).withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u26BD', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                "Penalty Palooza",
                style: GoogleFonts.oswald(
                  color: Colors.amberAccent.withValues(alpha: 0.6),
                  fontSize: 14,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('PLAY AGAIN',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFF2E7D32).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
