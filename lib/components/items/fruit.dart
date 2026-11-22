import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

class Fruit extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  Fruit({required this.fruit, super.position}) : super(size: Vector2.all(32));

  final String fruit;
  bool _collected = false;

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    add(RectangleHitbox(
      position: Vector2(10, 10),
      size: Vector2(12, 12),
      collisionType: CollisionType.passive,
    ));
    animation = _anim('Items/Fruits/$fruit.png', 17);
    return super.onLoad();
  }

  SpriteAnimation _anim(String path, int amount, {bool loop = true}) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache(path),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: 0.05,
          textureSize: Vector2.all(32),
          loop: loop,
        ),
      );

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !_collected) collect();
    super.onCollisionStart(intersectionPoints, other);
  }

  void collect() {
    _collected = true;
    game.session.fruits.value++;
    AudioService.instance.playSfx(Sfx.collectFruit);
    animation = _anim('Items/Fruits/Collected.png', 6, loop: false);
    animationTicker?.onComplete = removeFromParent;
  }
}
