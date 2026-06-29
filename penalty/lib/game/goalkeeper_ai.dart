import 'dart:math';

double _gauss(Random rng) {
  return sqrt(-2 * log(rng.nextDouble())) * cos(2 * pi * rng.nextDouble());
}

class GoalkeeperAI {
  final _random = Random();

  double decideWithTarget(double ballTarget) {
    final rand = _random.nextDouble();
    if (rand < 0.7) {
      final noise = _gauss(_random) * 15;
      return (ballTarget + noise).clamp(0.0, 100.0);
    } else if (rand < 0.85) {
      return (100.0 - ballTarget + _gauss(_random) * 15).clamp(0.0, 100.0);
    } else {
      return (50.0 + _gauss(_random) * 8).clamp(0.0, 100.0);
    }
  }
}
