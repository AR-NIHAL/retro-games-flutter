import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/game_state.dart';
import 'glass_pod.dart';

class ScoreBar extends StatelessWidget {
  final int score;
  final int round;
  final int totalRounds;
  final GamePhase phase;

  const ScoreBar({
    super.key,
    required this.score,
    required this.round,
    required this.totalRounds,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final roundProgress =
        (phase == GamePhase.ready ? round - 1 : round) / totalRounds;

    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scorePod(),
          const Spacer(),
          _branding(),
          const Spacer(),
          _roundPod(roundProgress),
        ],
      ),
    );
  }

  Widget _scorePod() {
    return GlassPod(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\uD83C\uDFC6', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer,
                      size: 10, color: Colors.amberAccent),
                  const SizedBox(width: 3),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                '$score / $totalRounds',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _branding() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.amberAccent.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Text(
        "Penalty Palooza",
        style: GoogleFonts.oswald(
          color: Colors.amberAccent.withValues(alpha: 0.9),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          shadows: [
            Shadow(
                color: Colors.amberAccent.withValues(alpha: 0.35),
                blurRadius: 12),
            const Shadow(color: Colors.black54, blurRadius: 6),
          ],
        ),
      ),
    );
  }

  Widget _roundPod(double progress) {
    return GlassPod(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUND',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$round',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
