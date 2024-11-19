import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/utils.dart';
import 'package:pixel_peep/pixel_peep.dart';

enum PlayerState{idle, running}


class Player extends SpriteAnimationGroupComponent with HasGameRef<PixelPeep>, KeyboardHandler{

  String character;
  Player({position ,this.character='Ninja Frog'}):super(position:position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  final double stepTime=0.05;

  double horizontalMovement=0;
  double moveSpeed=100;
  Vector2 velocity= Vector2.zero();
  List<CollisionBlock> collisionBlocks =[];
  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    debugMode=true;
    return super.onLoad();
  }

  @override
  void update(double dt){
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();
    super.update(dt);
  }

 @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement=0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA)||keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD)||keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement+=isLeftKeyPressed?-1:0;
    horizontalMovement+=isRightKeyPressed?1:0;

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run',12);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
    };
    current = PlayerState.running;
  }
  SpriteAnimation _spriteAnimation(String state, int amount){
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),);
  }

  void _updatePlayerMovement(double dt) {
    double dirX =0.0;
    // switch (playerDirection){
    //   case PlayerDirection.left:
    //     if(isFacingRight){
    //       flipHorizontallyAroundCenter();
    //       isFacingRight=false;
    //     }
    //     current=PlayerState.running;
    //     dirX-=moveSpeed;
    //     break;
    //   case PlayerDirection.right:
    //     if(!isFacingRight){
    //       flipHorizontallyAroundCenter();
    //       isFacingRight=true;
    //     }
    //     current=PlayerState.running;
    //     dirX+=moveSpeed;
    //     break;
    //   case PlayerDirection.none:
    //     current=PlayerState.idle;
    //     break;
    //   default:
    // }
    // velocity=Vector2(dirX, 0.0);
    velocity.x=horizontalMovement*moveSpeed;
    position.x +=velocity.x*dt;
  }

  void _updatePlayerState(){
    PlayerState playerState=PlayerState.idle;
    if(velocity.x< 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    }else if(velocity.x>0&& scale.x<0){
      flipHorizontallyAroundCenter();
    }

    if(velocity.x>0||velocity.x<0){playerState=PlayerState.running;}
    current=playerState;
  }

  void _checkHorizontalCollisions() {
    for(final block in collisionBlocks){
      if(!block.isPlatform){
        if(checkCollisions(this, block)){
          if(velocity.x>0){
            velocity.x=0;
            position.x=block.x-width;
          }
          if(velocity.x>0){
            velocity.x=0;
            position.x=block.x + block.width +width;
          }
        }
      }
    }
  }
}
