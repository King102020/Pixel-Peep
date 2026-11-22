import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/utils.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';

enum PlayerState { idle, running, jumping, falling }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<PixelPeep>, KeyboardHandler {
  Player({super.position, this.character = 'Ninja Frog'});

  String character;

  // Tuning. These move to CharacterStats in Milestone 3.
  static const double stepTime = 0.05;
  static const double gravity = 980;
  /// Full jump reaches ~66px (about 4 tiles), clearing 3-tile ledges.
  static const double jumpForce = 360;
  static const double terminalVelocity = 400;
  static const double moveSpeed = 100;
  /// Releasing jump early multiplies upward speed by this (variable jump height).
  static const double jumpCutMultiplier = 0.5;
  static const double coyoteTime = 0.1;
  static const double jumpBufferTime = 0.1;
  /// Physics runs at a fixed rate so jumps behave identically on every device.
  static const double fixedDelta = 1 / 60;

  static const hitbox = PlayerHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);

  double horizontalMovement = 0;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  List<CollisionBlock> collisionBlocks = [];

  /// Set by keyboard or touch buttons.
  bool jumpPressed = false;
  bool abilityPressed = false;

  bool _jumpWasPressed = false;
  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double _accumulator = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = kDebugMode;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _accumulator += dt.clamp(0, 0.25);
    while (_accumulator >= fixedDelta) {
      _physicsStep(fixedDelta);
      _accumulator -= fixedDelta;
    }
    _updatePlayerState();
    super.update(dt);
  }

  void _physicsStep(double dt) {
    _handleJumpInput(dt);
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
    _checkHorizontalCollisions();
    _applyGravity(dt);
    _checkVerticalCollisions();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
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
    abilityPressed = keysPressed.contains(LogicalKeyboardKey.keyE);

    return super.onKeyEvent(event, keysPressed);
  }

  void _handleJumpInput(double dt) {
    final justPressed = jumpPressed && !_jumpWasPressed;
    final justReleased = !jumpPressed && _jumpWasPressed;
    _jumpWasPressed = jumpPressed;

    _coyoteTimer = isOnGround ? coyoteTime : _coyoteTimer - dt;
    _jumpBufferTimer = justPressed ? jumpBufferTime : _jumpBufferTimer - dt;

    if (_jumpBufferTimer > 0 && _coyoteTimer > 0) {
      velocity.y = -jumpForce;
      isOnGround = false;
      _coyoteTimer = 0;
      _jumpBufferTimer = 0;
      AudioService.instance.playSfx(Sfx.jump);
    }

    if (justReleased && velocity.y < 0) {
      velocity.y *= jumpCutMultiplier;
    }
  }

  void _applyGravity(double dt) {
    velocity.y = (velocity.y + gravity * dt).clamp(-jumpForce, terminalVelocity);
    position.y += velocity.y * dt;
  }

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

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform || !_collides(block)) continue;
      if (velocity.x > 0) {
        position.x += block.x - (_hitboxLeft + hitbox.width);
      } else if (velocity.x < 0) {
        position.x += block.x + block.width - _hitboxLeft;
      }
      velocity.x = 0;
      break;
    }
  }

  void _checkVerticalCollisions() {
    isOnGround = false;
    for (final block in collisionBlocks) {
      if (!_collides(block)) continue;
      if (velocity.y > 0) {
        if (block.isPlatform) {
          // Only land if the feet were above the platform before this step.
          final feetBefore =
              position.y + hitbox.offsetY + hitbox.height - velocity.y * fixedDelta;
          if (feetBefore > block.y + 1) continue;
        }
        velocity.y = 0;
        position.y = block.y - hitbox.offsetY - hitbox.height;
        isOnGround = true;
        break;
      }
      if (velocity.y < 0 && !block.isPlatform) {
        velocity.y = 0;
        position.y = block.y + block.height - hitbox.offsetY;
      }
    }
  }

  void _updatePlayerState() {
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    var state = velocity.x != 0 ? PlayerState.running : PlayerState.idle;
    if (!isOnGround) {
      state = velocity.y < 0 ? PlayerState.jumping : PlayerState.falling;
    }
    current = state;
  }

  void _loadAllAnimations() {
    animations = {
      PlayerState.idle: _spriteAnimation('Idle', 11),
      PlayerState.running: _spriteAnimation('Run', 12),
      PlayerState.jumping: _spriteAnimation('Jump', 1),
      PlayerState.falling: _spriteAnimation('Fall', 1),
    };
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }
}
