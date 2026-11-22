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
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/game/game_session.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/services/save_repository.dart';
import 'package:pixel_peep/ui/overlays.dart';

class PixelPeep extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  static const double viewWidth = 640;
  static const double viewHeight = 360;

  /// Draws collision boxes; flip on while tuning levels.
  static const bool showHitboxes = false;

  @override
  Color backgroundColor() => const Color(0xFF211F30);

  PixelPeep({required this.save});

  final SaveRepository save;
  final session = GameSession();
  late CameraComponent cam;
  late Level level;
  late Player player;

  /// False while menus are showing and no level is loaded.
  bool inLevel = false;
  int levelIndex = 0;
  HeroId hero = HeroId.blueNinja;

  static final _rng = math.Random();
  double _shakeLeft = 0;
  double _shakeIntensity = 0;

  JoystickComponent? joyStick;
  final bool showTouchControls = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();
    await AudioService.instance.preload();
    showMainMenu();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (inLevel) {
      if (joyStick != null) _updateJoystick();
      if (!player.reachedEnd && !player.isDead) session.elapsed.value += dt;
      _updateShake(dt);
    }
    super.update(dt);
  }

  /// Brief screen shake for hits and ground pounds.
  void shake({double intensity = 3, double duration = 0.2}) {
    _shakeIntensity = intensity;
    _shakeLeft = duration;
  }

  void _updateShake(double dt) {
    if (_shakeLeft <= 0) return;
    _shakeLeft -= dt;
    final offset = _shakeLeft > 0
        ? Vector2((_rng.nextDouble() - 0.5) * 2, (_rng.nextDouble() - 0.5) * 2) *
            _shakeIntensity
        : Vector2.zero();
    cam.viewfinder.transform.offset = offset;
  }

  // ---------------------------------------------------------------- flow

  void _showOnly(String overlay) {
    overlays
      ..clear()
      ..add(overlay);
  }

  void showMainMenu() {
    _unloadLevel();
    _showOnly(Overlays.mainMenu);
    AudioService.instance.playMusic(Music.menu);
  }

  void showLevelSelect() => _showOnly(Overlays.levelSelect);

  void showCharacterSelect(int index) {
    levelIndex = index;
    _showOnly(Overlays.characterSelect);
  }

  Future<void> startLevel(HeroId chosen) async {
    hero = chosen;
    _showOnly(Overlays.hud);
    await loadLevel(levelIndex);
    AudioService.instance.playMusic(Music.level);
  }

  void togglePause() {
    if (!inLevel || player.reachedEnd) return;
    if (paused) {
      overlays.remove(Overlays.pause);
      resumeEngine();
    } else {
      overlays.add(Overlays.pause);
      pauseEngine();
    }
  }

  void restartLevel() {
    if (paused) resumeEngine();
    _showOnly(Overlays.hud);
    loadLevel(levelIndex);
  }

  void quitToMenu() {
    if (paused) resumeEngine();
    showMainMenu();
  }

  bool get hasNextLevel => levelIndex + 1 < levels.length;

  void playNextLevel() => showCharacterSelect(levelIndex + 1);

  /// Called by the player once the finish animation is done.
  Future<void> completeLevel() async {
    lastResult = LevelResult(stars: session.stars, seconds: session.elapsed.value);
    await save.recordResult(levelIndex, lastResult!);
    _showOnly(Overlays.levelComplete);
  }

  LevelResult? lastResult;

  void _unloadLevel() {
    inLevel = false;
    joyStick = null;
    removeWhere((c) => c is Level || c is CameraComponent);
  }

  Future<void> loadLevel(int index) async {
    levelIndex = index;
    _unloadLevel();
    player = Player(hero: hero);
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
    inLevel = true;
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
