import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/components/effects/confetti.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

const _dir = 'Items/Checkpoints';

/// Mid-level flag: touching it moves the player's respawn point here.
class Checkpoint extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  Checkpoint({super.position}) : super(size: Vector2.all(64));

  bool _reached = false;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(
      position: Vector2(18, 18),
      size: Vector2(12, 46),
      collisionType: CollisionType.passive,
    ));
    animation = SpriteAnimation.spriteList(
      [Sprite(game.images.fromCache('$_dir/Checkpoint/Checkpoint (No Flag).png'))],
      stepTime: 1,
    );
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !_reached) {
      _reached = true;
      other.respawnPoint = Vector2(position.x + 16, position.y + 32);
      AudioService.instance.playSfx(Sfx.checkpoint);
      animation = _anim('Checkpoint (Flag Out) (64x64).png', 26, loop: false);
      animationTicker?.onComplete =
          () => animation = _anim('Checkpoint (Flag Idle)(64x64).png', 10);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  SpriteAnimation _anim(String file, int amount, {bool loop = true}) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('$_dir/Checkpoint/$file'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: 0.05,
          textureSize: Vector2.all(64),
          loop: loop,
        ),
      );
}

/// Finish trophy: touching it completes the level.
class EndFlag extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  EndFlag({super.position}) : super(size: Vector2.all(64));

  bool _reached = false;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(
      position: Vector2(16, 16),
      size: Vector2(32, 48),
      collisionType: CollisionType.passive,
    ));
    animation = SpriteAnimation.spriteList(
      [Sprite(game.images.fromCache('$_dir/End/End (Idle).png'))],
      stepTime: 1,
    );
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !_reached && !other.isDead) {
      _reached = true;
      animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('$_dir/End/End (Pressed) (64x64).png'),
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.05,
          textureSize: Vector2.all(64),
          loop: false,
        ),
      );
      parent?.add(Confetti(position: position + Vector2(32, 24)));
      other.reachEnd();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
