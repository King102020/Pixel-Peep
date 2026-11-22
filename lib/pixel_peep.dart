import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/components/hud/action_button.dart';
import 'package:pixel_peep/components/hud/virtual_joystick.dart';
import 'package:pixel_peep/components/levels/level.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/game/game_session.dart';
import 'package:pixel_peep/services/audio_service.dart';

class PixelPeep extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  static const double viewWidth = 640;
  static const double viewHeight = 360;

  /// Draws collision boxes; flip on while tuning levels.
  static const bool showHitboxes = false;

  @override
  Color backgroundColor() => const Color(0xFF211F30);

  final session = GameSession();
  late CameraComponent cam;
  late Level level;
  late Player player;
  int levelIndex = 0;
  String character = 'Ninja Frog';

  JoystickComponent? joyStick;
  final bool showTouchControls = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();
    await AudioService.instance.preload();
    await loadLevel(0);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (joyStick != null) _updateJoystick();
    if (!player.reachedEnd) session.elapsed.value += dt;
    super.update(dt);
  }

  Future<void> loadLevel(int index) async {
    levelIndex = index;
    removeWhere((c) => c is Level || c is CameraComponent);
    player = Player(character: character);
    level = Level(levelName: levels[index].file, player: player);
    cam = CameraComponent.withFixedResolution(
      world: level,
      width: viewWidth,
      height: viewHeight,
    );
    await addAll([cam, level]);
    await level.loaded;
    _setupCamera();
    if (showTouchControls) _addTouchControls();
  }

  void _setupCamera() {
    final size = level.mapSize;
    const halfW = viewWidth / 2, halfH = viewHeight / 2;
    cam.follow(player, maxSpeed: 600, snap: true);
    cam.setBounds(Rectangle.fromLTRB(
      halfW,
      halfH,
      math.max(halfW, size.x - halfW),
      math.max(halfH, size.y - halfH),
    ));
  }

  /// Called by the player once the finish animation is done.
  void completeLevel() {
    final next = levelIndex + 1;
    loadLevel(next < levels.length ? next : 0);
  }

  void restartLevel() => loadLevel(levelIndex);

  void _addTouchControls() {
    cam.viewport.removeWhere((c) => c is JoystickComponent || c is ActionButton);
    joyStick = VirtualJoystick();
    cam.viewport.addAll([
      joyStick!,
      ActionButton(
        icon: ActionIcon.jump,
        margin: const EdgeInsets.only(right: 32, bottom: 32),
        onPressed: () => player.jumpPressed = true,
        onReleased: () => player.jumpPressed = false,
      ),
      ActionButton(
        icon: ActionIcon.ability,
        margin: const EdgeInsets.only(right: 100, bottom: 48),
        onPressed: () => player.abilityPressed = true,
        onReleased: () => player.abilityPressed = false,
      ),
    ]);
  }

  void _updateJoystick() {
    player.horizontalMovement = switch (joyStick!.direction) {
      JoystickDirection.left ||
      JoystickDirection.upLeft ||
      JoystickDirection.downLeft =>
        -1,
      JoystickDirection.right ||
      JoystickDirection.upRight ||
      JoystickDirection.downRight =>
        1,
      _ => 0,
    };
  }
}
