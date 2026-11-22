import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/hazards/hazard.dart';
import 'package:pixel_peep/components/items/fruit.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

SpriteAnimation _sheet(PixelPeep game, String path, int frames, Vector2 frame,
        {double step = 0.05, bool loop = true}) =>
    SpriteAnimation.fromFrameData(
      game.images.fromCache(path),
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: step,
        textureSize: frame,
        loop: loop,
      ),
    );

/// Launches the player high into the air.
class Trampoline extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  Trampoline({super.position}) : super(size: Vector2.all(28));

  static const double launchSpeed = 560;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(
      position: Vector2(4, 16),
      size: Vector2(20, 12),
      collisionType: CollisionType.passive,
    ));
    animation = SpriteAnimation.spriteList(
      [Sprite(game.images.fromCache('Traps/Trampoline/Idle.png'))],
      stepTime: 1,
    );
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && other.velocity.y >= 0) {
      other.launch(launchSpeed);
      AudioService.instance.playSfx(Sfx.doubleJump);
      animation = _sheet(game, 'Traps/Trampoline/Jump (28x28).png', 8, Vector2.all(28),
          loop: false);
      animationTicker?.onComplete = () => animation = SpriteAnimation.spriteList(
            [Sprite(game.images.fromCache('Traps/Trampoline/Idle.png'))],
            stepTime: 1,
          );
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

/// Blows the player upward while they're in its air column.
class Fan extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  Fan({super.position}) : super(size: Vector2(24, 8));

  static const double columnHeight = 112;
  static const double lift = 1500;

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    add(RectangleHitbox(
      position: Vector2(0, -columnHeight),
      size: Vector2(24, columnHeight),
      collisionType: CollisionType.passive,
    ));
    animation = _sheet(game, 'Traps/Fan/On (24x8).png', 4, Vector2(24, 8), step: 0.03);
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) other.windLift = lift;
    super.onCollision(intersectionPoints, other);
  }
}

/// Fire that cycles on and off; only hurts while burning.
class Fire extends SpriteAnimationComponent
    with HasGameReference<PixelPeep>, Hazard {
  Fire({super.position, this.phase = 0}) : super(size: Vector2(16, 32));

  static const double onTime = 1.6;
  static const double offTime = 1.4;
  final double phase;
  late double _t = phase;
  bool _on = false;

  @override
  bool get isActive => _on;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(
      position: Vector2(2, 14),
      size: Vector2(12, 18),
      collisionType: CollisionType.passive,
    ));
    _setOn(false);
    return super.onLoad();
  }

  void _setOn(bool on) {
    _on = on;
    animation = on
        ? _sheet(game, 'Traps/Fire/On (16x32).png', 3, Vector2(16, 32))
        : SpriteAnimation.spriteList(
            [Sprite(game.images.fromCache('Traps/Fire/Off.png'))],
            stepTime: 1,
          );
  }

  @override
  void update(double dt) {
    _t += dt;
    final cycle = _t % (onTime + offTime);
    final shouldBeOn = cycle < onTime;
    if (shouldBeOn != _on) _setOn(shouldBeOn);
    super.update(dt);
  }
}

/// One-way platform that shakes, then drops shortly after being stood on.
class FallingPlatform extends CollisionBlock with HasGameReference<PixelPeep> {
  FallingPlatform({required Vector2 position})
      : _home = position.clone(),
        super(position: position, size: Vector2(32, 10), isPlatform: true);

  final Vector2 _home;
  double _shakeLeft = -1;
  double _fallSpeed = 0;
  double _respawnLeft = 0;
  late final SpriteAnimationComponent _sprite;

  @override
  FutureOr<void> onLoad() {
    _sprite = SpriteAnimationComponent(
      animation: _sheet(game, 'Traps/Falling Platforms/On (32x10).png', 4,
          Vector2(32, 10)),
      size: size,
    );
    add(_sprite);
    return super.onLoad();
  }

  bool get _playerOnTop {
    final p = game.player;
    final feet = p.position.y + Player.hitbox.offsetY + Player.hitbox.height;
    final left = p.center.x - Player.hitbox.width / 2;
    return p.isOnGround &&
        (feet - y).abs() < 1.5 &&
        left < x + width &&
        left + Player.hitbox.width > x;
  }

  @override
  void update(double dt) {
    if (_respawnLeft > 0) {
      _respawnLeft -= dt;
      if (_respawnLeft <= 0) {
        position.setFrom(_home);
        _sprite.opacity = 1;
        _fallSpeed = 0;
        _shakeLeft = -1;
      }
    } else if (_fallSpeed > 0) {
      _fallSpeed += 600 * dt;
      position.y += _fallSpeed * dt;
      if (position.y > _home.y + 400) {
        _sprite.opacity = 0;
        position.y = -1000; // out of the way until it respawns
        _respawnLeft = 3;
      }
    } else if (_shakeLeft > 0) {
      _shakeLeft -= dt;
      _sprite.position.x = (_shakeLeft * 60).floor().isEven ? 1 : -1;
      if (_shakeLeft <= 0) {
        _sprite.position.x = 0;
        _fallSpeed = 30;
      }
    } else if (_playerOnTop) {
      _shakeLeft = 0.45;
    }
    super.update(dt);
  }
}

/// Crate that Final Call's dash or Masti Time's punch can smash open.
/// Usually hides fruit on a hero-specific secret route.
class Box extends CollisionBlock with HasGameReference<PixelPeep> {
  Box({required Vector2 position, this.loot})
      : super(position: position, size: Vector2(28, 24));

  final String? loot;
  bool _broken = false;
  late final SpriteAnimationComponent _sprite;

  @override
  FutureOr<void> onLoad() {
    _sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(
        [Sprite(game.images.fromCache('Items/Boxes/Box2/Idle.png'))],
        stepTime: 1,
      ),
      size: size,
    );
    add(_sprite);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_broken && game.player.isAttacking && _playerTouching()) smash();
    super.update(dt);
  }

  bool _playerTouching() {
    final p = game.player;
    const reach = 6.0;
    final left = p.center.x - Player.hitbox.width / 2 - reach;
    final top = p.position.y + Player.hitbox.offsetY - reach;
    return left < x + width &&
        left + Player.hitbox.width + reach * 2 > x &&
        top < y + height &&
        top + Player.hitbox.height + reach * 2 > y;
  }

  void smash() {
    _broken = true;
    game.level.collisionBlocks.remove(this);
    game.shake(intensity: 2);
    AudioService.instance.playSfx(Sfx.enemyDefeat);
    if (loot != null) {
      parent?.add(Fruit(fruit: loot!, position: position + Vector2(-2, -6)));
    }
    _sprite.animation = _sheet(game, 'Items/Boxes/Box2/Break.png', 4, Vector2(28, 24),
        loop: false);
    _sprite.animationTicker?.onComplete = removeFromParent;
  }
}
