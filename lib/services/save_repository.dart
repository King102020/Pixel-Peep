import 'package:shared_preferences/shared_preferences.dart';

/// Result of a finished level run.
class LevelResult {
  const LevelResult({required this.stars, required this.seconds});
  final int stars;
  final double seconds;
}

/// Player progress storage. Behind an interface so it can move to the cloud
/// (or a fake in tests) without touching game code.
abstract class SaveRepository {
  int get unlockedLevels;
  int starsFor(int level);
  double? bestTimeFor(int level);
  Future<void> recordResult(int level, LevelResult result);
}

class InMemorySaveRepository implements SaveRepository {
  final Map<int, int> _stars = {};
  final Map<int, double> _times = {};

  @override
  int get unlockedLevels =>
      _stars.isEmpty ? 1 : _stars.keys.reduce((a, b) => a > b ? a : b) + 2;

  @override
  int starsFor(int level) => _stars[level] ?? 0;

  @override
  double? bestTimeFor(int level) => _times[level];

  @override
  Future<void> recordResult(int level, LevelResult result) async {
    if (result.stars > starsFor(level)) _stars[level] = result.stars;
    final best = _times[level];
    if (best == null || result.seconds < best) _times[level] = result.seconds;
  }
}

class SharedPrefsSaveRepository extends InMemorySaveRepository {
  SharedPrefsSaveRepository._(this._prefs);

  static const _starsKey = 'stars_';
  static const _timeKey = 'time_';
  final SharedPreferences _prefs;

  static Future<SaveRepository> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsSaveRepository._(prefs);
      for (final key in prefs.getKeys()) {
        final level = int.tryParse(key.split('_').last);
        if (level == null) continue;
        if (key.startsWith(_starsKey)) repo._stars[level] = prefs.getInt(key) ?? 0;
        if (key.startsWith(_timeKey)) repo._times[level] = prefs.getDouble(key) ?? 0;
      }
      return repo;
    } catch (_) {
      // Storage can be unavailable (private browsing); progress just won't persist.
      return InMemorySaveRepository();
    }
  }

  @override
  Future<void> recordResult(int level, LevelResult result) async {
    await super.recordResult(level, result);
    await _prefs.setInt('$_starsKey$level', starsFor(level));
    await _prefs.setDouble('$_timeKey$level', bestTimeFor(level)!);
  }
}
