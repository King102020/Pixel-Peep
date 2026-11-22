import 'package:flutter/foundation.dart';

/// Live state of the level being played. Overlays listen to these notifiers.
class GameSession {
  final fruits = ValueNotifier<int>(0);
  final totalFruits = ValueNotifier<int>(0);
  final elapsed = ValueNotifier<double>(0);
  final deaths = ValueNotifier<int>(0);
  final hp = ValueNotifier<int>(3);
  final maxHp = ValueNotifier<int>(3);

  /// 0 = ability ready, 1 = just used.
  final abilityCooldown = ValueNotifier<double>(0);

  /// False until the player first moves; the clock waits for it.
  bool started = false;

  /// Target time in seconds for the time star; read from the level file.
  double targetTime = 60;

  void reset({required int fruitCount, required double target}) {
    fruits.value = 0;
    totalFruits.value = fruitCount;
    elapsed.value = 0;
    deaths.value = 0;
    started = false;
    targetTime = target;
  }

  /// 1 star for finishing, +1 for all fruit, +1 for beating the target time.
  int get stars =>
      1 +
      (fruits.value >= totalFruits.value ? 1 : 0) +
      (elapsed.value <= targetTime ? 1 : 0);
}
