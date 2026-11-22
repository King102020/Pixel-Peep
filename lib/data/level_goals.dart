import 'package:flutter/services.dart';

/// What a level asks for, read from its Tiled file so the hero picker can show
/// the targets before the player drops in.
class LevelGoals {
  const LevelGoals({required this.fruit, required this.targetSeconds});
  final int fruit;
  final double targetSeconds;

  static final Map<String, LevelGoals> _cache = {};

  static Future<LevelGoals> load(String file) async {
    final cached = _cache[file];
    if (cached != null) return cached;
    final xml = await rootBundle.loadString('assets/tiles/$file.tmx');
    final goals = parse(xml);
    _cache[file] = goals;
    return goals;
  }

  /// Counts loose fruit plus fruit hidden in crates, and reads the time goal.
  static LevelGoals parse(String xml) {
    final fruit = RegExp(r'type="Fruit"').allMatches(xml).length +
        RegExp(r'name="loot"').allMatches(xml).length;
    final time = RegExp(r'name="time" value="([\d.]+)"').firstMatch(xml);
    return LevelGoals(
      fruit: fruit,
      targetSeconds: double.tryParse(time?.group(1) ?? '') ?? 60,
    );
  }
}
