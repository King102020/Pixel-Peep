import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_peep/components/actors/enemy.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/hazards/saw.dart';
import 'package:pixel_peep/components/hazards/spikes.dart';
import 'package:pixel_peep/components/hazards/traps.dart';
import 'package:pixel_peep/components/items/checkpoint.dart';
import 'package:pixel_peep/components/items/fruit.dart';
import 'package:pixel_peep/pixel_peep.dart';

/// Loads a Tiled map and turns its object layers into game components.
class Level extends World with HasGameReference<PixelPeep> {
  Level({required this.levelName, required this.player});

  final String levelName;
  final Player player;
  late TiledComponent map;
  final List<CollisionBlock> collisionBlocks = [];

  Vector2 get mapSize => Vector2(map.width, map.height);

  @override
  FutureOr<void> onLoad() async {
    map = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(map);

    final props = map.tileMap.map.properties;
    final fruitCount = _spawnObjects();
    _addCollisions();
    game.session.reset(
      fruitCount: fruitCount,
      target: double.tryParse(props.getValue<String>('time') ?? '') ?? 60,
    );
    await _addBackground(props.getValue<String>('bg') ?? 'Gray');
    return super.onLoad();
  }

  Future<void> _addBackground(String color) async {
    final parallax = await game.loadParallaxComponent(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, -25),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );
    game.cam.backdrop.add(parallax);
  }

  /// Returns the number of fruits so the session can track completion.
  int _spawnObjects() {
    var fruits = 0;
    EndFlag? end;
    BossGolem? boss;
    final layer = map.tileMap.getLayer<ObjectGroup>('spawnPoints');
    if (layer == null) return 0;
    for (final obj in layer.objects) {
      final pos = Vector2(obj.x, obj.y);
      switch (obj.class_) {
        case 'Player':
          player
            ..position = pos
            ..respawnPoint = pos.clone();
          add(player);
        case 'Fruit':
          fruits++;
          add(Fruit(
            fruit: obj.properties.getValue<String>('fruit') ?? 'Apple',
            position: pos,
          ));
        case 'Checkpoint':
          add(Checkpoint(position: pos));
        case 'End':
          end = EndFlag(position: pos);
        case 'Spikes':
          add(Spikes(position: pos));
        case 'Saw':
          add(Saw(
            position: pos,
            isVertical: _bool(obj, 'isVertical'),
            offNeg: _num(obj, 'offNeg'),
            offPos: _num(obj, 'offPos'),
          ));
        case 'Trampoline':
          add(Trampoline(position: pos));
        case 'Fan':
          add(Fan(position: pos));
        case 'Fire':
          add(Fire(position: pos, phase: _num(obj, 'phase')));
        case 'FallingPlatform':
          final platform = FallingPlatform(position: pos);
          collisionBlocks.add(platform);
          add(platform);
        case 'Box':
          final loot = obj.properties.getValue<String>('loot');
          if (loot != null) fruits++;
          final box = Box(position: pos, loot: loot);
          collisionBlocks.add(box);
          add(box);
        case 'Slime':
          add(Slime(position: pos));
        case 'Bat':
          add(Bat(position: pos));
        case 'Golem':
          add(Golem(position: pos));
        case 'Boss':
          boss = BossGolem(position: pos);
          add(boss);
      }
    }
    // On boss levels the exit only appears once the boss is beaten.
    if (end != null) {
      final exit = end;
      if (boss != null) {
        boss.onBossDefeated = () => add(exit);
      } else {
        add(exit);
      }
    }
    return fruits;
  }

  void _addCollisions() {
    final layer = map.tileMap.getLayer<ObjectGroup>('Collisions');
    if (layer == null) return;
    for (final c in layer.objects) {
      final block = CollisionBlock(
        position: Vector2(c.x, c.y),
        size: Vector2(c.width, c.height),
        isPlatform: c.class_ == 'Platform',
      );
      collisionBlocks.add(block);
      add(block);
    }
    player.collisionBlocks = collisionBlocks;
  }

  static bool _bool(TiledObject o, String key) =>
      '${o.properties.getValue<Object>(key)}' == 'true';

  static double _num(TiledObject o, String key) =>
      double.tryParse('${o.properties.getValue<Object>(key) ?? 0}') ?? 0;
}
