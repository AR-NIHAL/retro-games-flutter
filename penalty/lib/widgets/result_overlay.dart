import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/game_state.dart';
import '../painters/celebration_painter.dart';

class ResultOverlay extends StatelessWidget {
  final ShotResult? lastResult;
  final double idleValue;
  final Size gameSize;

  const ResultOverlay({
    super.key,
    required this.lastResult,
    required this.idleValue,
    required this.gameSize,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    String subtext;
    String emoji;
    TextColorScheme scheme;

    switch (lastResult) {
      case ShotResult.goal:
        text = 'Kemira vovo';
        subtext = 'GOAL!';
        emoji = '\u26BD';
        scheme = TextColorScheme.goal;
      case ShotResult.saved:
        text = 'suiii!!';
        subtext = 'PERFECT SAVE!';
        emoji = '\uD83E\uDDE4';
        scheme = TextColorScheme.saved;
      case ShotResult.missed:
        text = 'MISSED!';
        subtext = 'TRY AGAIN';
        emoji = '\u274C';
        scheme = TextColorScheme.missed;
      default:
        return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            CustomPaint(
              size: gameSize,
              painter: CelebrationPainter(
                time: idleValue,
                scheme: scheme,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  _mainText(text, scheme),
                  const SizedBox(height: 12),
                  _subText(subtext),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainText(String text, TextColorScheme scheme) {
    final gradientColors = switch (scheme) {
      TextColorScheme.goal || TextColorScheme.saved => const [
          Color(0xFFFFFACD),
          Color(0xFFFFD700),
          Color(0xFFFF8C00),
          Color(0xFFFFD700),
          Color(0xFFFFFACD),
        ],
      TextColorScheme.missed => const [
          Color(0xFFFFB3B3),
          Color(0xFFDC143C),
          Color(0xFF8B0000),
          Color(0xFFDC143C),
          Color(0xFFFFB3B3),
        ],
    };

    final depthColor = switch (scheme) {
      TextColorScheme.goal || TextColorScheme.saved => const Color(0xFF3A2510),
      TextColorScheme.missed => const Color(0xFF2A0000),
    };

    final glowColor = switch (scheme) {
      TextColorScheme.goal || TextColorScheme.saved =>
        const Color(0xFFFFD700).withValues(alpha: 0.4),
      TextColorScheme.missed =>
        const Color(0xFFDC143C).withValues(alpha: 0.4),
    };

    final style = GoogleFonts.oswald(
      fontSize: scheme == TextColorScheme.missed ? 38 : 44,
      fontWeight: FontWeight.w900,
      letterSpacing: 2,
      height: 1.1,
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    ).createShader(Rect.fromLTWH(0, 0, tp.width, tp.height));

    const shadowSteps = 5;

    return Transform.rotate(
      angle: -0.06,
      child: Text(text, style: style.copyWith(
        foreground: Paint()..shader = shader,
        shadows: [
          for (int i = shadowSteps; i >= 1; i--)
            Shadow(
              offset: Offset(i * 1.2, i * 1.2),
              blurRadius: i == shadowSteps ? 4 : 1.0,
              color: Color.lerp(
                Colors.transparent, depthColor, i / shadowSteps)!,
            ),
          Shadow(
            offset: Offset.zero,
            blurRadius: 20,
            color: glowColor,
          ),
        ],
      )),
    );
  }

  Widget _subText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.92),
        letterSpacing: 3,
        shadows: const [
          Shadow(offset: Offset.zero, blurRadius: 8, color: Colors.black54),
        ],
      ),
    );
  }
}
