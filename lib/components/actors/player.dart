import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pixel_peep/components/abilities/ability.dart';
import 'package:pixel_peep/components/abilities/dash.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/effects/dust.dart';
import 'package:pixel_peep/components/effects/one_shot_effect.dart';
import 'package:pixel_peep/components/hazards/hazard.dart';
import 'package:pixel_peep/components/utils.dart';
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

enum PlayerState { idle, running, jumping, falling, doubleJump, wallSlide, hit }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<PixelPeep>, KeyboardHandler, CollisionCallbacks {
  Player({super.position, this.hero = HeroId.blueNinja});

  final HeroId hero;
  late final Ability ability = Ability.forHero(hero, this);

  static const double stepTime = 0.05;
  static const double gravity = 980;
  static const double terminalVelocity = 400;
  static const double wallSlideSpeed = 50;
  /// Releasing jump early multiplies upward speed by this (variable jump height).
  static const double jumpCutMultiplier = 0.5;
  static const double coyoteTime = 0.1;
  static const double jumpBufferTime = 0.1;
  static const double invulnerableTime = 1.2;
  /// After a wall jump, input is ignored briefly so the kick carries the hero.
  static const double wallKickLockTime = 0.15;
  /// Physics runs at a fixed rate so jumps behave identically on every device.
  static const double fixedDelta = 1 / 60;

  /// Tiny gap left after resolving a wall hit, so float rounding never makes
  /// the next stacked wall tile count as ground.
  static const double _skin = 0.01;

  static const hitbox = PlayerHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);

  CharacterStats get stats => hero.stats;

  double horizontalMovement = 0;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  List<CollisionBlock> collisionBlocks = [];

  /// -1 when pressing into a wall on the left, 1 on the right, 0 otherwise.
  int wallDirection = 0;

  /// Set by keyboard or touch buttons.
  bool jumpPressed = false;
  bool abilityPressed = false;

  bool _jumpWasPressed = false;
  bool _abilityWasPressed = false;
  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double _accumulator = 0;
  double _invulnerableLeft = 0;
  double _wallKickLeft = 0;
  bool _doubleJumping = false;

  /// Where the player reappears after dying; moved forward by checkpoints.
  Vector2 respawnPoint = Vector2.zero();
  bool isDead = false;
  bool reachedEnd = false;

  /// Upward push from a fan this frame (set by Fan, consumed by physics).
  double windLift = 0;

  double get facingDirection => scale.x >= 0 ? 1 : -1;
  bool get isInvincible => _invulnerableLeft > 0 || ability.isInvincible;
  bool get isAttacking => ability.isAttacking;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = PixelPeep.showHitboxes;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    game.session.maxHp.value = stats.maxHp;
    game.session.hp.value = stats.maxHp;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isDead || reachedEnd) {
      super.update(dt);
      return;
    }
    _accumulator += dt.clamp(0, 0.25);
    while (_accumulator >= fixedDelta) {
      _physicsStep(fixedDelta);
      _accumulator -= fixedDelta;
      if (isDead || reachedEnd) break;
    }
    windLift = 0;
    // die() may have switched to the hit animation mid-step; don't overwrite it.
    if (!isDead && !reachedEnd) {
      _updatePlayerState();
      _updateBlink(dt);
    }
    game.session.abilityCooldown.value = ability.cooldownProgress;
    super.update(dt);
  }

  void _physicsStep(double dt) {
    _startClockOnInput();
    _handleAbilityInput();
    ability.update(dt);
    if (_invulnerableLeft > 0) _invulnerableLeft -= dt;
    if (_wallKickLeft > 0) _wallKickLeft -= dt;

    if (ability.overrideMovement(dt)) {
      position.x += velocity.x * dt;
      _checkHorizontalCollisions();
      _checkVerticalCollisions();
    } else {
      _handleJumpInput(dt);
      if (_wallKickLeft <= 0) velocity.x = horizontalMovement * stats.moveSpeed;
      position.x += velocity.x * dt;
      _checkHorizontalCollisions();
      _applyGravity(dt);
      _checkVerticalCollisions();
    }
    if (position.y > game.level.mapSize.y + 32) die();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Continuous check so a fire that ignites while overlapping still hurts.
    if (other is Hazard && other.isActive) takeHit(from: other);
    super.onCollision(intersectionPoints, other);
  }

  /// Fired upward by a trampoline.
  void launch(double speed) {
    velocity.y = -speed;
    isOnGround = false;
    _doubleJumping = false;
    ability.onLanded();
  }

  /// Loses one heart with knockback; dies when out of hearts.
  void takeHit({PositionComponent? from}) {
    if (isDead || reachedEnd || isInvincible) return;
    game.session.hp.value--;
    game.shake();
    if (game.session.hp.value <= 0) {
      die();
      return;
    }
    AudioService.instance.playSfx(Sfx.hit);
    _invulnerableLeft = invulnerableTime;
    final away = from == null
        ? -facingDirection
        : (center.x >= from.center.x ? 1.0 : -1.0);
    velocity
      ..x = away * 140
      ..y = -200;
    _wallKickLeft = 0.2;
  }

  /// Bounces off an enemy that was stomped.
  void bounce() {
    velocity.y = -stats.jumpForce * 0.7;
    isOnGround = false;
  }

  void die() {
    if (isDead || reachedEnd) return;
    isDead = true;
    game.session.deaths.value++;
    game.shake(intensity: 5);
    AudioService.instance.playSfx(Sfx.hit);
    velocity.setZero();
    current = PlayerState.hit;
    animationTicker?.onComplete = _respawn;
  }

  void _respawn() {
    if (scale.x < 0) flipHorizontallyAroundCenter();
    final oldCenter = position + Vector2(16, 16);
    parent?.add(OneShotEffect.disappear(center: oldCenter));
    position = respawnPoint.clone();
    opacity = 0;
    ability.reset();
    parent?.add(OneShotEffect.appear(
      center: position + Vector2(16, 16),
      onDone: () {
        opacity = 1;
        isDead = false;
        _accumulator = 0;
        game.session.hp.value = stats.maxHp;
        _invulnerableLeft = 0.5;
      },
    ));
  }

  void reachEnd() {
    reachedEnd = true;
    velocity.setZero();
    AudioService.instance.playSfx(Sfx.levelComplete);
    if (scale.x < 0) flipHorizontallyAroundCenter();
    opacity = 0;
    parent?.add(OneShotEffect.disappear(
      center: position + Vector2(16, 16),
      onDone: game.completeLevel,
    ));
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.keyP)) {
      game.togglePause();
    }
    final left = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final right = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    horizontalMovement = (left ? -1 : 0) + (right ? 1 : 0).toDouble();

    // On web, arrow keys and W also scroll or navigate the page, so only
    // Space jumps there to avoid confusing players.
    jumpPressed = keysPressed.contains(LogicalKeyboardKey.space) ||
        (!kIsWeb &&
            (keysPressed.contains(LogicalKeyboardKey.keyW) ||
                keysPressed.contains(LogicalKeyboardKey.arrowUp)));
    abilityPressed = keysPressed.contains(LogicalKeyboardKey.keyE) ||
        keysPressed.contains(LogicalKeyboardKey.keyJ) ||
        keysPressed.contains(LogicalKeyboardKey.shiftLeft);

    return super.onKeyEvent(event, keysPressed);
  }

  /// The level clock starts on the player's first input, so looking around
  /// before moving doesn't cost the time star.
  void _startClockOnInput() {
    if (!game.session.started &&
        (horizontalMovement != 0 || jumpPressed || abilityPressed)) {
      game.session.started = true;
    }
  }

  void _handleAbilityInput() {
    if (abilityPressed && !_abilityWasPressed) ability.onPressed();
    if (!abilityPressed && _abilityWasPressed) ability.onReleased();
    _abilityWasPressed = abilityPressed;
  }

  void _handleJumpInput(double dt) {
    final justPressed = jumpPressed && !_jumpWasPressed;
    final justReleased = !jumpPressed && _jumpWasPressed;
    _jumpWasPressed = jumpPressed;

    _coyoteTimer = isOnGround ? coyoteTime : _coyoteTimer - dt;
    _jumpBufferTimer = justPressed ? jumpBufferTime : _jumpBufferTimer - dt;

    if (_jumpBufferTimer > 0 && _coyoteTimer > 0) {
      velocity.y = -stats.jumpForce;
      isOnGround = false;
      _coyoteTimer = 0;
      _jumpBufferTimer = 0;
      spawnDust();
      AudioService.instance.playSfx(Sfx.jump);
    } else if (justPressed && !isOnGround && ability.onAirJump()) {
      _jumpBufferTimer = 0;
    }

    if (justReleased && velocity.y < 0 && _wallKickLeft <= 0) {
      velocity.y *= jumpCutMultiplier;
    }
  }

  void _applyGravity(double dt) {
    var maxFall = ability.fallSpeedCap ?? terminalVelocity;
    if (wallDirection != 0 && ability.canWallSlide && velocity.y > 0) {
      maxFall = wallSlideSpeed;
    }
    velocity.y += gravity * stats.gravityScale * dt;
    if (windLift > 0) {
      velocity.y = (velocity.y - windLift * dt).clamp(-260, double.infinity);
    }
    velocity.y = velocity.y.clamp(-600, maxFall);
    position.y += velocity.y * dt;
  }

  void playDoubleJump() => _doubleJumping = true;

  void wallKick(int direction) {
    _wallKickLeft = wallKickLockTime;
    wallDirection = 0;
    if (direction != facingDirection) flipHorizontallyAroundCenter();
  }

  void spawnDust() =>
      parent?.add(Dust(position: Vector2(center.x, position.y + 32)));

  bool _collides(CollisionBlock block) => checkCollision(
        position: position,
        scaleX: scale.x,
        spriteWidth: width,
        hitbox: hitbox,
        block: block,
      );

  /// Left edge of the hitbox in world space, accounting for sprite flipping.
  double get _hitboxLeft => scale.x < 0
      ? position.x - width + (width - hitbox.offsetX - hitbox.width)
      : position.x + hitbox.offsetX;

  bool _overlapsX(CollisionBlock block) =>
      _hitboxLeft < block.x + block.width &&
      _hitboxLeft + hitbox.width > block.x;

  void _checkHorizontalCollisions() {
    wallDirection = 0;
    for (final block in collisionBlocks) {
      if (block.isPlatform || !_collides(block)) continue;
      if (velocity.x > 0) {
        position.x += block.x - (_hitboxLeft + hitbox.width) - _skin;
        wallDirection = 1;
      } else if (velocity.x < 0) {
        position.x += block.x + block.width - _hitboxLeft + _skin;
        wallDirection = -1;
      }
      velocity.x = 0;
      break;
    }
    if (isOnGround) wallDirection = 0;
  }

  void _checkVerticalCollisions() {
    final wasOnGround = isOnGround;
    isOnGround = false;
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        // Thin one-way platforms: sweep the feet across this step so a fast
        // fall can't skip past a 5px-tall plank.
        if (velocity.y <= 0 || !_overlapsX(block)) continue;
        final feet = position.y + hitbox.offsetY + hitbox.height;
        final feetBefore = feet - velocity.y * fixedDelta;
        if (feetBefore > block.y + 1 || feet < block.y) continue;
      } else if (!_collides(block)) {
        continue;
      }
      if (velocity.y > 0) {
        if (!wasOnGround && velocity.y > 250) spawnDust();
        velocity.y = 0;
        position.y = block.y - hitbox.offsetY - hitbox.height;
        isOnGround = true;
        _doubleJumping = false;
        ability.onLanded();
        break;
      }
      if (velocity.y < 0 && !block.isPlatform) {
        velocity.y = 0;
        position.y = block.y + block.height - hitbox.offsetY;
      }
    }
  }

  void _updatePlayerState() {
    final dashing = ability is Dash && (ability as Dash).isDashing;
    if (_wallKickLeft <= 0 && !dashing) {
      if (velocity.x < 0 && scale.x > 0) {
        flipHorizontallyAroundCenter();
      } else if (velocity.x > 0 && scale.x < 0) {
        flipHorizontallyAroundCenter();
      }
    }

    var state = velocity.x != 0 ? PlayerState.running : PlayerState.idle;
    if (!isOnGround) {
      if (wallDirection != 0 && ability.canWallSlide && velocity.y > 0) {
        state = PlayerState.wallSlide;
      } else if (_doubleJumping && velocity.y < 0) {
        state = PlayerState.doubleJump;
      } else {
        state = velocity.y < 0 ? PlayerState.jumping : PlayerState.falling;
      }
    }
    current = state;
  }

  /// Flicker while invulnerable after a hit.
  void _updateBlink(double dt) {
    if (_invulnerableLeft > 0) {
      opacity = (_invulnerableLeft * 10).floor().isEven ? 0.3 : 1;
    } else if (!ability.isInvincible) {
      opacity = 1;
    }
  }

  void _loadAllAnimations() {
    animations = {
      PlayerState.idle: _spriteAnimation('Idle', 11),
      PlayerState.running: _spriteAnimation('Run', 12),
      PlayerState.jumping: _spriteAnimation('Jump', 1),
      PlayerState.falling: _spriteAnimation('Fall', 1),
      PlayerState.doubleJump: _spriteAnimation('Double Jump', 6),
      PlayerState.wallSlide: _spriteAnimation('Wall Jump', 5),
      PlayerState.hit: _spriteAnimation('Hit', 7, loop: false),
    };
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount, {bool loop = true}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/${hero.sprite}/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
        loop: loop,
      ),
    );
  }
}
