import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_state.dart';
import 'goalkeeper_ai.dart';
import 'game_painter.dart';
import '../widgets/score_bar.dart';
import '../widgets/result_overlay.dart';
import '../widgets/game_over_screen.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _gauss(Random rng) {
  return sqrt(-2 * log(rng.nextDouble())) * cos(2 * pi * rng.nextDouble());
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballCtrl;
  late AnimationController _keeperCtrl;
  late AnimationController _idleCtrl;
  late AnimationController _shakeCtrl;
  final _audioPlayer = AudioPlayer();
  bool _audioUnlocked = false;

  final _ai = GoalkeeperAI();
  final _random = Random();

  GamePhase _phase = GamePhase.ready;
  int _round = 1;
  int _score = 0;

  double _keeperDivePosition = 50;
  double _shotPower = 0.5;
  ShotResult? _lastResult;

  Offset? _ballStart;
  Offset? _ballEnd;

  Offset? _panStart;
  DateTime? _panStartTime;
  List<Offset> _panPath = [];

  Size _gameSize = Size.zero;
  ui.Image? _footballImage;
  ui.Image? _goalkeeperImage;

  Offset get _shakeOffset {
    if (!_shakeCtrl.isAnimating) return Offset.zero;
    final v = _shakeCtrl.value;
    final decay = 1.0 - v;
    final wave = sin(v * pi * 10);
    final intensity = 10.0 * decay;
    return Offset(wave * intensity, (cos(v * pi * 7) - 0.5) * intensity * 0.6);
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.audioCache = AudioCache(prefix: '');
    _ballCtrl = AnimationController(vsync: this);
    _keeperCtrl = AnimationController(vsync: this);
    _idleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _idleCtrl.repeat();
    _idleCtrl.addListener(_onTick);
    _ballCtrl.addListener(_onTick);
    _keeperCtrl.addListener(_onTick);
    _shakeCtrl.addListener(_onTick);
    _loadImages();
  }

  Future<void> _loadImages() async {
    final football = await rootBundle.load('asset/a.png');
    final footballCodec = await ui.instantiateImageCodec(
        football.buffer.asUint8List(football.offsetInBytes, football.lengthInBytes));
    final footballFrame = await footballCodec.getNextFrame();

    final keeper = await rootBundle.load('asset/g.png');
    final keeperCodec = await ui.instantiateImageCodec(
        keeper.buffer.asUint8List(keeper.offsetInBytes, keeper.lengthInBytes));
    final keeperFrame = await keeperCodec.getNextFrame();

    if (mounted) {
      setState(() {
        _footballImage = footballFrame.image;
        _goalkeeperImage = keeperFrame.image;
      });
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ballCtrl.dispose();
    _keeperCtrl.dispose();
    _idleCtrl.dispose();
    _shakeCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---- GESTURE HANDLING ----

  void _onPanStart(DragStartDetails details) {
    if (_phase != GamePhase.ready) return;
    _panStart = details.localPosition;
    _panStartTime = DateTime.now();
    _panPath = [details.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_phase != GamePhase.ready) return;
    _panPath.add(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_phase != GamePhase.ready ||
        _panStart == null ||
        _panStartTime == null) {
      return;
    }

    _panPath.add(details.localPosition);

    final delta = details.localPosition - _panStart!;
    final dt = DateTime.now().difference(_panStartTime!).inMilliseconds;

    if (delta.dy > -20) return;
    if (delta.distance < 30) return;

    final dx = details.localPosition.dx - _panStart!.dx;
    final maxDx = _gameSize.width * 0.35;
    final normDx = (dx / maxDx).clamp(-1.0, 1.0);
    final aimPosition = 50 + normDx * 45;

    final cleanliness = _computeCleanliness();

    final speed = delta.distance / max(dt, 1);
    final power = (speed / 3).clamp(0.3, 1.0);

    _executeShot(aimPosition, power, cleanliness);
    _unlockAudio();
  }

  void _onPanCancel() {
    _panStart = null;
    _panStartTime = null;
  }

  // ---- SWIPE ANALYSIS ----

  double _pointLineDistance(Offset p, Offset a, Offset b) {
    final abx = b.dx - a.dx;
    final aby = b.dy - a.dy;
    final apx = p.dx - a.dx;
    final apy = p.dy - a.dy;
    final dot = apx * abx + apy * aby;
    final len2 = abx * abx + aby * aby;
    if (len2 < 1) return (p - a).distance;
    final t = (dot / len2).clamp(0.0, 1.0);
    final projx = a.dx + abx * t;
    final projy = a.dy + aby * t;
    return sqrt(pow(p.dx - projx, 2) + pow(p.dy - projy, 2));
  }

  double _computeCleanliness() {
    if (_panPath.length < 3) return 1.0;
    final start = _panPath.first;
    final end = _panPath.last;
    final totalDist = (end - start).distance;
    if (totalDist < 20) return 1.0;

    double sumDev = 0;
    int count = 0;
    for (int i = 1; i < _panPath.length - 1; i++) {
      sumDev += _pointLineDistance(_panPath[i], start, end);
      count++;
    }

    if (count == 0) return 1.0;
    final avgDev = sumDev / count;
    final maxDev = totalDist * 0.12;
    return 1.0 - (avgDev / maxDev).clamp(0.0, 1.0);
  }

  // ---- SHOT EXECUTION ----

  void _executeShot(double aimPosition, double power, double cleanliness) {
    final gl = _gameSize.width * 0.10;
    final gr = _gameSize.width * 0.90;
    final goalPixelWidth = gr - gl;

    final stdDev =
        8.0 + (1.0 - cleanliness) * 10.0 + (power - 0.65).abs() * 6.0;
    final error = _gauss(_random) * stdDev;
    final ballPosition = (aimPosition + error).clamp(-10.0, 110.0);

    final ballEndX = gl + (ballPosition / 100) * goalPixelWidth;
    final ballEndY = _gameSize.height * 0.43 - 5;

    final isMiss = ballPosition < 0 || ballPosition > 100;
    final baseCenterPx = (gl + gr) / 2;

    setState(() {
      _phase = GamePhase.shooting;
      _shotPower = power;
      _ballStart = Offset(_gameSize.width / 2, _gameSize.height * 0.88);
      _ballEnd = Offset(ballEndX, ballEndY);
    });

    final ballDur = _lerp(900, 500, power).round();
    final keeperDur = _lerp(550, 250, power).round();

    // Ball starts moving immediately
    _ballCtrl.duration = Duration(milliseconds: ballDur);
    _ballCtrl.forward();

    // Keeper reacts after 150-250ms delay (Approach C: Reaction Time & Speed)
    final reactionDelay =
        keeperReactionMinMs + _random.nextInt(keeperReactionMaxMs - keeperReactionMinMs + 1);

    Future.delayed(Duration(milliseconds: reactionDelay), () {
      if (!mounted) return;
      _keeperDivePosition = _ai.decideWithTarget(ballPosition);
      _keeperCtrl.duration = Duration(milliseconds: keeperDur);
      _keeperCtrl.forward();
    });

    // Evaluate result when ball arrives
    Future.delayed(Duration(milliseconds: ballDur), () {
      if (!mounted) return;

      ShotResult result;
      if (isMiss) {
        result = ShotResult.missed;
      } else {
        final keeperTargetPx = gl + (_keeperDivePosition / 100) * goalPixelWidth;

        // Actual keeper position at ball arrival (accounts for reaction delay)
        final keeperProgress = _keeperCtrl.isAnimating ? _keeperCtrl.value : 0.0;
        final overshoot = (keeperTargetPx - baseCenterPx) * 1.5;
        final keeperVisualCenterX = baseCenterPx + overshoot * keeperProgress;

        final keeperReachPx = (keeperReach / 100) * goalPixelWidth;
        final forwardReach = keeperReachPx * 1.25 + 25.0;

        final ballOffset = ballEndX - keeperVisualCenterX;
        final isInReach = _keeperDivePosition == 50
            ? ballOffset.abs() <= keeperReachPx * 0.6
            : _keeperDivePosition > 50
                ? ballOffset >= -keeperReachPx * 0.3 && ballOffset <= forwardReach
                : ballOffset <= keeperReachPx * 0.3 && ballOffset >= -forwardReach;

        if (isInReach) {
          result = _random.nextDouble() < 0.04
              ? ShotResult.goal
              : ShotResult.saved;
        } else {
          result = ShotResult.goal;
        }
      }

      setState(() {
        _lastResult = result;
        _phase = GamePhase.result;
        if (result == ShotResult.goal) _score++;
      });

      _triggerShake();
      _playResultSound(result);
      try {
        switch (result) {
          case ShotResult.goal:
            HapticFeedback.heavyImpact();
          case ShotResult.saved:
            HapticFeedback.mediumImpact();
          case ShotResult.missed:
            HapticFeedback.heavyImpact();
        }
      } catch (_) {}

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (_round >= totalRounds) {
          setState(() => _phase = GamePhase.gameOver);
        } else {
          _resetForNextRound();
        }
      });
    });
  }

  void _resetForNextRound() {
    _ballCtrl.reset();
    _keeperCtrl.reset();
    setState(() {
      _round++;
      _phase = GamePhase.ready;
      _ballStart = null;
      _ballEnd = null;
      _lastResult = null;
    });
  }

  void _restartGame() {
    _ballCtrl.reset();
    _keeperCtrl.reset();
    setState(() {
      _phase = GamePhase.ready;
      _round = 1;
      _score = 0;
      _ballStart = null;
      _ballEnd = null;
      _lastResult = null;
    });
  }

  void _triggerShake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  Future<void> _unlockAudio() async {
    if (_audioUnlocked) return;
    _audioUnlocked = true;
    try {
      await _audioPlayer.setSource(AssetSource('asset/s.mp3'));
      await _audioPlayer.setVolume(0);
      await _audioPlayer.resume();
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1);
    } catch (_) {}
  }

  Future<void> _playResultSound(ShotResult result) async {
    final asset = switch (result) {
      ShotResult.goal => 'asset/m.mp3',
      ShotResult.saved => 'asset/s.mp3',
      ShotResult.missed => 'asset/x.mp3',
    };
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    await _audioPlayer.play(AssetSource(asset));
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                children: [
                  Transform(
                    transform: Matrix4.translationValues(
                        _shakeOffset.dx, _shakeOffset.dy, 0),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: _gameSize,
                          painter: GamePainter(
                            ballProgress: _ballCtrl.isAnimating
                                ? _ballCtrl.value
                                : (_phase == GamePhase.result && _lastResult != null
                                    ? 1.0
                                    : 0),
                            keeperProgress: _keeperCtrl.isAnimating
                                ? _keeperCtrl.value
                                : (_phase == GamePhase.result && _lastResult != null
                                    ? 1.0
                                    : 0),
                            idleValue: _idleCtrl.value,
                            shotPower: _shotPower,
                            ballStart: _ballStart,
                            ballEnd: _ballEnd,
                            keeperTargetX: _keeperCtrl.isAnimating ||
                                    (_phase == GamePhase.result && _lastResult != null)
                                ? (_gameSize.width * 0.10 +
                                    (_keeperDivePosition / 100) *
                                        (_gameSize.width * 0.80))
                                : null,
                            keeperReachPx: (keeperReach / 100) *
                                (_gameSize.width * 0.80),
                            phase: _phase,
                            footballImage: _footballImage,
                            goalkeeperImage: _goalkeeperImage,
                          ),
                        ),
                        ScoreBar(
                          score: _score,
                          round: _round,
                          totalRounds: totalRounds,
                          phase: _phase,
                        ),
                      ],
                    ),
                  ),
                  if (_phase == GamePhase.result)
                    ResultOverlay(
                      lastResult: _lastResult,
                      idleValue: _idleCtrl.value,
                      gameSize: _gameSize,
                    ),
                  if (_phase == GamePhase.gameOver)
                    GameOverScreen(
                      score: _score,
                      totalRounds: totalRounds,
                      onRestart: _restartGame,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }}
