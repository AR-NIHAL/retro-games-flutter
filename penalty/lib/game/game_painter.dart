import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'game_state.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

class GamePainter extends CustomPainter {
  final double ballProgress;
  final double keeperProgress;
  final double idleValue;
  final double shotPower;
  final Offset? ballStart;
  final Offset? ballEnd;
  final double? keeperTargetX;
  final double keeperReachPx;
  final GamePhase phase;
  final double? keeperDiveProgress;
  final ui.Image? footballImage;
  final ui.Image? goalkeeperImage;

  GamePainter({
    this.ballProgress = 0,
    this.keeperProgress = 0,
    this.idleValue = 0,
    this.shotPower = 0.5,
    this.ballStart,
    this.ballEnd,
    this.keeperTargetX,
    this.keeperReachPx = 0,
    this.phase = GamePhase.ready,
    this.keeperDiveProgress,
    this.footballImage,
    this.goalkeeperImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawPitch(canvas, size);
    _drawGoal(canvas, size);
    _drawKeeperReach(canvas, size);
    _drawKeeper(canvas, size);
    _drawBallTrail(canvas, size);
    _drawBall(canvas, size);
    _drawTouchHint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;

  // ---- GEOMETRY HELPERS ----
  double get _goalLeft => 0.10;
  double get _goalRight => 0.90;
  double get _goalTop => 0.09;
  double get _goalBottom => 0.43;

  double goalLeft(Size s) => s.width * _goalLeft;
  double goalRight(Size s) => s.width * _goalRight;
  double goalTop(Size s) => s.height * _goalTop;
  double goalBottom(Size s) => s.height * _goalBottom;
  double goalWidth(Size s) => goalRight(s) - goalLeft(s);
  double goalHeight(Size s) => goalBottom(s) - goalTop(s);

  // ---- SKY ----
  void _drawSky(Canvas canvas, Size size) {
    final skyHeight = size.height * 0.48;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF0A1628),
          Color(0xFF162238),
          Color(0xFF1B3D2A),
          Color(0xFF1B5E20),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, skyHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, skyHeight), paint);
  }

  // ---- PITCH ----
  void _drawPitch(Canvas canvas, Size size) {
    final grassTop = size.height * 0.43;
    final grassHeight = size.height - grassTop;

    // Base grass with depth gradient (darker at horizon, brighter near viewer)
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF1B5E20),
          Color(0xFF2E7D32),
          Color(0xFF3A8C3A),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, grassTop, size.width, grassHeight));
    canvas.drawRect(
        Rect.fromLTWH(0, grassTop, size.width, grassHeight), grassPaint);

    // Perspective stripes (horizontal bands that shrink toward horizon)
    const stripeCount = 40;
    for (int i = 0; i < stripeCount; i++) {
      final t0 = i / stripeCount;
      final t1 = (i + 1) / stripeCount;

      // Quadratic perspective: far stripes thin, near stripes thick
      final y0 = grassTop + grassHeight * (t0 * t0);
      final y1 = grassTop + grassHeight * (t1 * t1);

      if (i.isEven) {
        final alpha = (0.08 + t0 * 0.08).clamp(0.0, 0.18);
        canvas.drawRect(
          Rect.fromLTWH(0, y0, size.width, y1 - y0),
          Paint()..color = const Color(0xFF338A38).withValues(alpha: alpha),
        );
      }
    }

    // Penalty area
    final gl = goalLeft(size);
    final gr = goalRight(size);
    final gb = goalBottom(size);
    final paLeft = gl - (gr - gl) * 0.2;
    final paRight = gr + (gr - gl) * 0.2;
    final paBottom = gb + (gb - grassTop) * 0.6;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTRB(paLeft, grassTop, paRight, paBottom), linePaint);
  }

  // ---- GOAL ----
  void _drawGoal(Canvas canvas, Size size) {
    final gl = goalLeft(size);
    final gr = goalRight(size);
    final gt = goalTop(size);
    final gb = goalBottom(size);

    // Net shadow
    canvas.drawRect(
      Rect.fromLTRB(gl + 3, gt + 3, gr - 3, gb - 3),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Net lines
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;
    for (double y = gt; y <= gb; y += 12) {
      canvas.drawLine(Offset(gl, y), Offset(gr, y), netPaint);
    }
    for (double x = gl; x <= gr; x += 12) {
      canvas.drawLine(Offset(x, gt), Offset(x, gb), netPaint);
    }

    // Post glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(gl, gt), Offset(gl, gb), glowPaint);
    canvas.drawLine(Offset(gr, gt), Offset(gr, gb), glowPaint);
    canvas.drawLine(Offset(gl, gt), Offset(gr, gt), glowPaint);

    // Posts
    final postPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(gl, gt), Offset(gl, gb), postPaint);
    canvas.drawLine(Offset(gr, gt), Offset(gr, gb), postPaint);
    canvas.drawLine(Offset(gl, gt), Offset(gr, gt), postPaint);

    // Goal line
    canvas.drawLine(
      Offset(gl, gb),
      Offset(gr, gb),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2.5,
    );
  }

  // ---- KEEPER REACH ZONE ----
  void _drawKeeperReach(Canvas canvas, Size size) {
    if (keeperTargetX == null ||
        keeperReachPx <= 0 ||
        (phase != GamePhase.shooting && phase != GamePhase.result)) {
      return;
    }

    final prog = keeperDiveProgress ?? keeperProgress;
    final currentX = _lerp(
      (goalLeft(size) + goalRight(size)) / 2,
      keeperTargetX!,
      prog,
    );

    final baseX = (goalLeft(size) + goalRight(size)) / 2;
    final diveDir = keeperTargetX! < baseX ? -1.0 : 1.0;
    final forwardReach = keeperReachPx * 1.25;
    final backReach = keeperReachPx * 0.625;
    final reachLeft = currentX + min(0.0, diveDir * backReach);
    final reachRight = currentX + max(0.0, diveDir * forwardReach);
    final gt = goalTop(size);
    final gb = goalBottom(size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(reachLeft, gt, reachRight, gb),
        Radius.circular(keeperReachPx * 0.15),
      ),
      Paint()
        ..color = Colors.yellow.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(reachLeft, (gt + gb) / 2),
      Offset(reachRight, (gt + gb) / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1,
    );
  }

  // ---- GOALKEEPER ----
  void _drawKeeper(Canvas canvas, Size size) {
    final baseX = (goalLeft(size) + goalRight(size)) / 2;
    final baseY = goalBottom(size);

    double diveOffset = 0;
    double diveDirection = 0;
    if (keeperTargetX != null && phase != GamePhase.ready) {
      final overshoot = (keeperTargetX! - baseX) * 1.5;
      diveOffset = overshoot * keeperProgress;
      diveDirection = keeperTargetX! < baseX ? -1.0 : 1.0;
    }

    final kx = baseX + diveOffset;
    final ky = baseY;

    canvas.save();
    canvas.translate(kx, ky);

    double sway = 0;
    if (phase == GamePhase.ready) {
      sway = sin(idleValue * 2 * pi) * 3;
    }

    double tilt = diveDirection * 20 * keeperProgress;

    if (goalkeeperImage != null) {
      final kHeight = size.height * 0.26;
      final aspect = goalkeeperImage!.width / goalkeeperImage!.height;
      final imgW = kHeight * aspect;
      final imgH = kHeight;

      canvas.save();
      canvas.translate(sway, 0);
      canvas.rotate(tilt * pi / 180);

      final src = Rect.fromLTWH(
        0, 0,
        goalkeeperImage!.width.toDouble(),
        goalkeeperImage!.height.toDouble(),
      );
      final dst = Rect.fromLTRB(-imgW / 2, -imgH, imgW / 2, 0);
      canvas.drawImageRect(
        goalkeeperImage!, src, dst,
        Paint()..filterQuality = FilterQuality.high,
      );

      canvas.restore();
    } else {
      // Fallback: simple colored rectangle when image is not loaded
      final kHeight = size.height * 0.26;
      final kWidth = kHeight * 0.5;
      canvas.save();
      canvas.rotate(tilt * pi / 180);
      canvas.translate(sway, 0);
      canvas.drawRect(
        Rect.fromLTRB(-kWidth / 2, -kHeight, kWidth / 2, 0),
        Paint()..color = const Color(0xFFFDD835),
      );
      canvas.drawCircle(
        Offset(0, -kHeight - kHeight * 0.1),
        kHeight * 0.15,
        Paint()..color = const Color(0xFFD2A679),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  // ---- BALL TRAIL ----
  void _drawBallTrail(Canvas canvas, Size size) {
    if (phase != GamePhase.shooting ||
        ballStart == null ||
        ballEnd == null) {
      return;
    }

    final startX = ballStart!.dx;
    final startY = ballStart!.dy;
    final endX = ballEnd!.dx;
    final endY = ballEnd!.dy;
    final arcHeightF = _lerp(size.height * 0.22, size.height * 0.08, shotPower);

    for (int i = 1; i <= 3; i++) {
      final t = (ballProgress - i * 0.05).clamp(0.0, 1.0);
      final tx = _lerp(startX, endX, t);
      final ty = _lerp(startY, endY, t) - sin(pi * t) * arcHeightF;
      final alpha = (1.0 - i * 0.28).clamp(0.0, 0.5);

      canvas.drawCircle(
        Offset(tx, ty),
        min(size.width, size.height) * 0.018 * (1.0 - i * 0.2),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  // ---- BALL ----
  void _drawBall(Canvas canvas, Size size) {
    final startX = size.width / 2;
    final startY = size.height * 0.88;
    final radius = min(size.width, size.height) * 0.085;

    double x = startX;
    double y = startY;

    if (phase == GamePhase.ready) {
      y += sin(idleValue * 2 * pi) * 4;
    }

    if (phase == GamePhase.shooting &&
        ballStart != null &&
        ballEnd != null) {
      final t = ballProgress;
      final arcHeight =
          _lerp(size.height * 0.22, size.height * 0.08, shotPower);

      x = _lerp(ballStart!.dx, ballEnd!.dx, t);
      y = _lerp(ballStart!.dy, ballEnd!.dy, t) -
          sin(pi * t) * arcHeight;
    }

    if (phase == GamePhase.result && ballEnd != null) {
      x = ballEnd!.dx;
      y = ballEnd!.dy;
    }

    // Shadow — grows as ball rises (height illusion)
    final shadowScale = phase == GamePhase.shooting
        ? 1.0 + (1.0 - (y / ballStart!.dy).clamp(0.0, 1.0)) * 0.5
        : 1.0;
    canvas.drawCircle(
      Offset(x + 3 * shadowScale, y + 3 * shadowScale),
      radius * shadowScale * 0.7,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Ball image
    if (footballImage != null) {
      final iw = footballImage!.width.toDouble();
      final ih = footballImage!.height.toDouble();
      final srcSize = min(iw, ih);
      final src = Rect.fromLTWH((iw - srcSize) / 2, (ih - srcSize) / 2,
          srcSize, srcSize);
      final dst = Rect.fromCenter(
          center: Offset(x, y), width: radius * 2, height: radius * 2);
      canvas.drawImageRect(footballImage!, src, dst,
          Paint()..filterQuality = FilterQuality.high);
    } else {
      canvas.drawCircle(
          Offset(x, y), radius, Paint()..color = Colors.white);
    }
  }

  // ---- HINT TEXT ----
  void _drawTouchHint(Canvas canvas, Size size) {
    if (phase != GamePhase.ready) return;

    const hint = '\u2B06 SWIPE UP TO SHOOT';

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    );

    final builder = TextPainter(
      text: TextSpan(text: hint, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background pill
    const padding = 16.0;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.78),
        width: builder.width + padding * 2,
        height: builder.height + padding,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    builder.paint(
      canvas,
      Offset(
        (size.width - builder.width) / 2,
        size.height * 0.78 - builder.height / 2,
      ),
    );
  }
}
