import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_peep/services/save_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('only level 1 is unlocked on a fresh save', () {
    expect(InMemorySaveRepository().unlockedLevels, 1);
  });

  test('finishing a level unlocks the next and keeps the best result', () async {
    final repo = InMemorySaveRepository();
    await repo.recordResult(0, const LevelResult(stars: 2, seconds: 40));
    await repo.recordResult(0, const LevelResult(stars: 1, seconds: 30));
    expect(repo.unlockedLevels, 2);
    expect(repo.starsFor(0), 2);
    expect(repo.bestTimeFor(0), 30);
  });

  test('progress survives a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await SharedPrefsSaveRepository.load();
    await first.recordResult(2, const LevelResult(stars: 3, seconds: 12.5));

    final reloaded = await SharedPrefsSaveRepository.load();
    expect(reloaded.starsFor(2), 3);
    expect(reloaded.bestTimeFor(2), 12.5);
    expect(reloaded.unlockedLevels, 4);
  });
}
