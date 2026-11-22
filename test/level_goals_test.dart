import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_peep/data/level_goals.dart';
import 'package:pixel_peep/data/levels.dart';

void main() {
  test('counts loose fruit and fruit hidden in crates', () {
    const xml = '''
<properties><property name="time" value="45"/></properties>
<object name="Fruit" type="Fruit"/><object name="Fruit" type="Fruit"/>
<object name="Box" type="Box"><properties><property name="loot" value="Kiwi"/></properties></object>
''';
    final goals = LevelGoals.parse(xml);
    expect(goals.fruit, 3);
    expect(goals.targetSeconds, 45);
  });

  test('every level file exists and has fruit and a time goal', () {
    for (final level in levels) {
      final file = File('assets/tiles/${level.file}.tmx');
      expect(file.existsSync(), isTrue, reason: level.file);
      final goals = LevelGoals.parse(file.readAsStringSync());
      expect(goals.fruit, greaterThan(0), reason: level.file);
      expect(goals.targetSeconds, greaterThan(0), reason: level.file);
    }
  });
}
