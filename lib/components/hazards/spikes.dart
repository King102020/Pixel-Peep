import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/hazards/hazard.dart';
import 'package:pixel_peep/pixel_peep.dart';

class Spikes extends SpriteComponent with HasGameReference<PixelPeep>, Hazard {
  Spikes({super.position}) : super(size: Vector2.all(16));

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Traps/Spikes/Idle.png'));
    add(RectangleHitbox(
      position: Vector2(1, 8),
      size: Vector2(14, 8),
      collisionType: CollisionType.passive,
    ));
    return super.onLoad();
  }
}
