import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/hazards/hazard.dart';
import 'package:pixel_peep/pixel_peep.dart';

/// Spinning saw that moves back and forth along one axis.
class Saw extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, Hazard {
  Saw({
    super.position,
    this.isVertical = false,
    this.offNeg = 0,
    this.offPos = 0,
  }) : super(size: Vector2.all(32));

  final bool isVertical;
  /// Travel distance in tiles before and after the start position.
  final double offNeg;
  final double offPos;

  static const double _speed = 50;
  static const double _tile = 16;
  double _direction = 1;
  late final double _min;
  late final double _max;

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    add(CircleHitbox(collisionType: CollisionType.passive));
    final start = isVertical ? position.y : position.x;
    _min = start - offNeg * _tile;
    _max = start + offPos * _tile;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Saw/On (38x38).png'),
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.03,
        textureSize: Vector2.all(38),
      ),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_max > _min) {
      if (isVertical) {
        position.y += _direction * _speed * dt;
        if (position.y >= _max || position.y <= _min) {
          position.y = position.y.clamp(_min, _max);
          _direction *= -1;
        }
      } else {
        position.x += _direction * _speed * dt;
        if (position.x >= _max || position.x <= _min) {
          position.x = position.x.clamp(_min, _max);
          _direction *= -1;
        }
      }
    }
    super.update(dt);
  }
}
