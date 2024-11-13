import 'dart:async';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'levels/level.dart';

class PixelPeep extends FlameGame with HasKeyboardHandlerComponents{
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late final CameraComponent cam;
  final world=Level(levelName: 'level-02');

  @override
  FutureOr<void> onLoad() async{

    await images.loadAllImages();

    cam= CameraComponent.withFixedResolution(world:world, width: 640,height: 360);
    cam.viewfinder.anchor=Anchor.topLeft;
    addAll([cam, world]);
    return super.onLoad();
  }
}