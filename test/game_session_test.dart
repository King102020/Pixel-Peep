import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/game/game_session.dart';

void main() {
  group('GameSession.stars', () {
    late GameSession session;
    setUp(() => session = GameSession()..reset(fruitCount: 5, target: 30));

    test('one star for just finishing', () {
      session
        ..fruits.value = 2
        ..elapsed.value = 45;
      expect(session.stars, 1);
    });

    test('three stars for all fruit under target time', () {
      session
        ..fruits.value = 5
        ..elapsed.value = 20;
      expect(session.stars, 3);
    });
  });

  test('every hero has a distinct strength', () {
    final stats = {for (final h in HeroId.values) h: h.stats};
    final fastest = stats.entries.reduce(
        (a, b) => a.value.moveSpeed > b.value.moveSpeed ? a : b);
    final highest = stats.entries.reduce(
        (a, b) => a.value.jumpForce > b.value.jumpForce ? a : b);
    final toughest =
        stats.entries.reduce((a, b) => a.value.maxHp > b.value.maxHp ? a : b);
    expect(fastest.key, HeroId.finalCall);
    expect(highest.key, HeroId.bubbleTrouper);
    expect(toughest.key, HeroId.mastiTime);
  });
}
