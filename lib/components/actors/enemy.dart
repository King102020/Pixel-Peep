import 'dart:async';
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_peep/components/abilities/dash.dart';
import 'package:pixel_peep/components/abilities/ground_pound.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

enum EnemyState { move, hit }

/// How an enemy can be defeated.
enum Toughness {
  /// Stomp, dash or punch.
  soft,

  /// Only Masti Time's punch/slam or Final Call's dash.
  armored,
}

/// Base for every enemy: patrols a range, hurts the player on touch, and can
/// be stomped or attacked depending on [toughness].
abstract class Enemy extends SpriteAnimationGroupComponent<EnemyState>
    with HasGameReference<PixelPeep>, CollisionCallbacks {
  Enemy({
    super.position,
    super.size,
    this.offNeg = 3,
    this.offPos = 3,
    this.maxHp = 1,
    this.toughness = Toughness.soft,
  });

  final double offNeg;
  final double offPos;
  final int maxHp;
  final Toughness toughness;

  late int hp = maxHp;
  late final double minX = position.x - offNeg * 16;
  late final double maxX = position.x + offPos * 16;
  double direction = -1;
  bool isDefeated = false;
  double _hurtCooldown = 0;

  String get folder;
  int get moveFrames;
  String get moveName => 'Run';
  double get speed;

  /// Hitbox inset inside the sprite.
  Rect2 get hitboxRect;

  @override
  FutureOr<void> onLoad() {
    debugMode = PixelPeep.showHitboxes;
    add(RectangleHitbox(position: hitboxRect.position, size: hitboxRect.size));
    animations = {
      EnemyState.move: _anim(moveName, moveFrames),
      EnemyState.hit: _anim('Hit', 5, loop: false),
    };
    current = EnemyState.move;
    return super.onLoad();
  }

  SpriteAnimation _anim(String state, int frames, {bool loop = true}) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/$folder/$state (32x32).png'),
        SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: 0.07,
          textureSize: Vector2.all(32),
          loop: loop,
        ),
      );

  @override
  void update(double dt) {
    if (_hurtCooldown > 0) _hurtCooldown -= dt;
    if (!isDefeated) move(dt);
    super.update(dt);
  }

  /// Default: walk back and forth between [minX] and [maxX].
  void move(double dt) {
    position.x += direction * speed * dt;
    if (position.x <= minX) {
      position.x = minX;
      direction = 1;
    } else if (position.x >= maxX) {
      position.x = maxX;
      direction = -1;
    }
    _face(direction);
  }

  void _face(double dir) {
    // Sprites face left by default.
    if (dir > 0 && scale.x > 0 || dir < 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isDefeated && !other.isDead) _touch(other);
    super.onCollision(intersectionPoints, other);
  }

  void _touch(Player player) {
    if (_hurtCooldown > 0) return;
    final stomping = player.velocity.y > 0 &&
        player.position.y + Player.hitbox.offsetY + Player.hitbox.height <
            absoluteCenter.y + 2;
    final ability = player.ability;
    final attacking = player.isAttacking;
    final canBeAttacked = toughness == Toughness.soft ||
        (attacking && (ability is GroundPound || ability is Dash));

    if (attacking && canBeAttacked) {
      hurt(ability is GroundPound ? 2 : 1);
      if (ability is GroundPound && ability.isSlamming) player.bounce();
    } else if (stomping) {
      player.bounce();
      game.shake(intensity: 2.5, duration: 0.15);
      if (toughness == Toughness.soft) hurt(1);
      AudioService.instance.playSfx(Sfx.jump);
    } else {
      player.takeHit(from: this);
    }
  }

  void hurt(int damage) {
    _hurtCooldown = 0.3;
    hp -= damage;
    game.freeze(0.06);
    current = EnemyState.hit;
    animationTicker?.onComplete = () {
      if (hp <= 0) {
        defeat();
      } else {
        current = EnemyState.move;
      }
    };
    if (hp <= 0) isDefeated = true;
  }

  void defeat() {
    AudioService.instance.playSfx(Sfx.enemyDefeat);
    game.shake(intensity: 2);
    onDefeated();
    removeFromParent();
  }

  void onDefeated() {}

  double distanceToPlayer() => game.player.center.distanceTo(center);
}

/// Simple rectangle used to describe hitboxes.
class Rect2 {
  const Rect2(this.x, this.y, this.w, this.h);
  final double x, y, w, h;
  Vector2 get position => Vector2(x, y);
  Vector2 get size => Vector2(w, h);
}

class Slime extends Enemy {
  Slime({super.position}) : super(size: Vector2.all(32));

  @override
  String get folder => 'Slime';
  @override
  int get moveFrames => 6;
  @override
  double get speed => 35;
  @override
  Rect2 get hitboxRect => const Rect2(5, 16, 22, 14);
}

class Bat extends Enemy {
  Bat({super.position}) : super(size: Vector2.all(32), offNeg: 4, offPos: 4);

  late final double _baseY = position.y;
  double _time = 0;

  @override
  String get folder => 'Bat';
  @override
  String get moveName => 'Fly';
  @override
  int get moveFrames => 6;
  @override
  double get speed => 45;
  @override
  Rect2 get hitboxRect => const Rect2(9, 8, 14, 14);

  @override
  void move(double dt) {
    _time += dt;
    // Swoops toward the player when close, otherwise patrols.
    if (distanceToPlayer() < 110) {
      final dir = (game.player.center.x - center.x).sign;
      position.x = (position.x + dir * speed * 1.4 * dt).clamp(minX, maxX);
      _face(dir);
    } else {
      super.move(dt);
    }
    position.y = _baseY + math.sin(_time * 3) * 10;
  }
}

class Golem extends Enemy {
  Golem({super.position, Vector2? size, super.maxHp = 2})
      : super(size: size ?? Vector2.all(32), toughness: Toughness.armored);

  @override
  String get folder => 'Rock Golem';
  @override
  String get moveName => 'Walk';
  @override
  int get moveFrames => 8;
  @override
  double get speed => 25;
  @override
  Rect2 get hitboxRect => Rect2(4 * size.x / 32, 8 * size.y / 32,
      24 * size.x / 32, 24 * size.y / 32);
}

/// Final boss: a giant golem that charges at the player. Stomps hurt it
/// while it's dizzy after a charge, so every hero can win.
class BossGolem extends Golem {
  BossGolem({super.position})
      : super(size: Vector2.all(48), maxHp: 6);

  /// Called when the boss falls; the level then reveals the exit.
  void Function()? onBossDefeated;

  static const double windupTime = 0.7;
  static const double dizzyTime = 1.8;
  static const double chargeSpeed = 170;

  double _chargeTimer = 2;
  double _windup = 0;
  double _dizzy = 0;
  bool _charging = false;
  // Charges across the whole room, stopping short of the walls.
  double get _arenaMin => 2 * 16;
  double get _arenaMax => game.level.mapSize.x - 2 * 16 - width;

  bool get isDizzy => _dizzy > 0;

  @override
  void move(double dt) {
    if (_dizzy > 0) {
      _dizzy -= dt;
      opacity = (_dizzy * 8).floor().isEven ? 0.6 : 1;
      return;
    }
    opacity = 1;
    if (_charging) {
      position.x += direction * chargeSpeed * dt;
      if (position.x <= _arenaMin || position.x >= _arenaMax) {
        position.x = position.x.clamp(_arenaMin, _arenaMax);
        _charging = false;
        _dizzy = dizzyTime;
        _chargeTimer = 2.2;
        game.shake(intensity: 5);
      }
      return;
    }
    if (_windup > 0) {
      // The tell: shudder in place and flash red-white, then charge.
      _windup -= dt;
      _wobble = (_windup * 40).floor().isEven ? 1 : -1;
      position.x += _wobble;
      opacity = (_windup * 12).floor().isEven ? 0.5 : 1;
      if (_windup <= 0) {
        opacity = 1;
        _charging = true;
      }
      return;
    }
    _chargeTimer -= dt;
    direction = (game.player.center.x - center.x).sign;
    _face(direction);
    if (_chargeTimer <= 0) _windup = windupTime;
  }

  double _wobble = 0;

  @override
  void _touch(Player player) {
    if (_hurtCooldown > 0) return;
    final stomping = player.velocity.y > 0 &&
        player.position.y + Player.hitbox.offsetY + Player.hitbox.height <
            absoluteCenter.y;
    if (isDizzy && stomping) {
      // The dizzy stomp is the big hit, for every hero.
      player.bounce();
      game.shake(intensity: 4);
      hurt(2);
      return;
    }
    if (isDizzy && player.isAttacking) {
      // Dash and punch only chip him, and only while he's dizzy.
      hurt(1);
      return;
    }
    if (stomping) {
      // Bounces off his rocky head while he's alert.
      player.bounce();
      return;
    }
    player.takeHit(from: this);
  }

  @override
  void onDefeated() => onBossDefeated?.call();
}
