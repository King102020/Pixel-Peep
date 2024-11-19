import 'dart:async';
import 'dart:ui';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_peep/components/actors/player.dart';

import 'components/levels/level.dart';

class PixelPeep extends FlameGame with HasKeyboardHandlerComponents, DragCallbacks{
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late final CameraComponent cam;
  Player player=Player(character: 'Mask Dude');
  late JoystickComponent joyStick;
  bool showJoyStick = !kIsWeb;

  @override
  FutureOr<void> onLoad() async{
    await images.loadAllImages();
    await images.load('HUD/Joystick.png');

    final world=Level(levelName: 'level-01', player: player );

    cam= CameraComponent.withFixedResolution(world:world, width: 640,height: 360);
    cam.viewfinder.anchor=Anchor.topLeft;
    addAll([cam, world]);

    if(showJoyStick){
      addJoyStick();
    }
    return super.onLoad();
  }

  @override
  void update(double dt){
    if(showJoyStick){
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoyStick() {
    joyStick = JoystickComponent(
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      //knobRadius: ,
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png'))
      ),
      margin: const EdgeInsets.only(left:32, bottom: 32),
    );
    add(joyStick);
  }

  void updateJoystick(){
    switch (joyStick.direction){
      case JoystickDirection.left || JoystickDirection.upLeft || JoystickDirection.downLeft:
        player.horizontalMovement=-1;
        // player.playerDirection=PlayerDirection.left;
        break;
      case JoystickDirection.right || JoystickDirection.upRight|| JoystickDirection.downRight:
        player.horizontalMovement=1;
        // player.playerDirection=PlayerDirection.right;
        break;
      default:
        player.horizontalMovement=0;
        // player.playerDirection=PlayerDirection.none;
        break;
    }
  }
  
}
