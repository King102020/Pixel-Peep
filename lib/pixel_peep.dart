import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_peep/components/hud/action_button.dart';
import 'package:pixel_peep/components/hud/virtual_joystick.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/components/actors/player.dart';

import 'components/levels/level.dart';

class PixelPeep extends FlameGame with HasKeyboardHandlerComponents, DragCallbacks{
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late final CameraComponent cam;
  Player player=Player(character: 'Mask Dude');
  late JoystickComponent joyStick;
  bool showJoyStick = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  FutureOr<void> onLoad() async{
    await images.loadAllImages();
    await AudioService.instance.preload();

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
    joyStick = VirtualJoystick();
    add(joyStick);
    add(ActionButton(
      icon: ActionIcon.jump,
      margin: const EdgeInsets.only(right: 32, bottom: 32),
      onPressed: () => player.jumpPressed = true,
      onReleased: () => player.jumpPressed = false,
    ));
    add(ActionButton(
      icon: ActionIcon.ability,
      margin: const EdgeInsets.only(right: 100, bottom: 48),
      onPressed: () => player.abilityPressed = true,
      onReleased: () => player.abilityPressed = false,
    ));
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
