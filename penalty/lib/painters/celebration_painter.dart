import 'dart:math';
import 'package:flutter/material.dart';

enum TextColorScheme { goal, saved, missed }

extension on TextColorScheme {
  Color get effectColor {
    switch (this) {
      case TextColorScheme.goal:
      case TextColorScheme.saved:
        return const Color(0xFFFFD700);
      case TextColorScheme.missed:
        return const Color(0xFFDC143C);
    }
  }
}

class CelebrationPainter extends CustomPainter {
  final double time;
  final TextColorScheme scheme;

  CelebrationPainter({
    required this.time,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final baseColor = scheme.effectColor;

    _drawRays(canvas, size, center, baseColor);
    _drawParticles(canvas, center, baseColor);
    _drawStars(canvas, center, baseColor);
  }

  void _drawRays(Canvas canvas, Size size, Offset center, Color color) {
    final rayCount = 12;
    final maxLen = size.width * 0.65;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * 2 * pi);

    for (int i = 0; i < rayCount; i++) {
      canvas.save();
      canvas.rotate(i * 2 * pi / rayCount);

      final gradient = RadialGradient(
        colors: [
          color.withValues(alpha: 0.07),
          color.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: maxLen));

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-12, -maxLen)
        ..lineTo(12, -maxLen)
        ..close();

      canvas.drawPath(path, Paint()..shader = gradient);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawParticles(Canvas canvas, Offset center, Color color) {
    final paint = Paint();
    for (int i = 0; i < 25; i++) {
      final seed = i * 1.7;
      final angle = (seed + time * 0.5) % (2 * pi);
      final dist = (center.dx * 0.3 +
              sin(i * 3.0 + time * 2) * center.dx * 0.15)
          .abs()
          .clamp(20, center.dx * 0.55);
      final px = center.dx + cos(angle) * dist;
      final py = center.dy + sin(angle) * dist;
      final pSize = 1.5 + sin(i * 2.5 + time * 3) * 1.0 + 1.0;
      final alpha = (0.25 + sin(i * 4.0 + time) * 0.2).clamp(0.0, 0.6);

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), pSize, paint);
    }
  }

  void _drawStars(Canvas canvas, Offset center, Color color) {
    for (int i = 0; i < 6; i++) {
      final seed = i * 2.1;
      final angle = (seed + time * 0.3) % (2 * pi);
      final dist = center.dx * 0.25 + sin(i * 5.0 + time * 1.5) * center.dx * 0.1;
      final sx = center.dx + cos(angle) * dist;
      final sy = center.dy + sin(angle) * dist;
      final starSize = 6.0 + sin(i * 3.0 + time * 2) * 3.0;
      final alpha = (0.3 + sin(i * 2.0 + time * 1.5) * 0.2).clamp(0.0, 0.6);

      _drawFourPointStar(canvas, Offset(sx, sy), starSize.abs(),
          color.withValues(alpha: alpha));
    }
  }

  void _drawFourPointStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    final outer = size;
    final inner = size * 0.25;

    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? outer : inner;
      final a = i * pi / 4 - pi / 2;
      final x = center.dx + cos(a) * r;
      final y = center.dy + sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.scheme != scheme;
  }
}
