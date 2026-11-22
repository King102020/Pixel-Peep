import 'package:flame_audio/flame_audio.dart';

enum Sfx {
  jump,
  doubleJump,
  collectFruit,
  hit,
  enemyDefeat,
  dash,
  checkpoint,
  levelComplete,
  buttonClick,
}

enum Music { menu, level }

/// Thin wrapper over flame_audio so game code never deals with file paths.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool muted = false;
  double sfxVolume = 0.7;
  double musicVolume = 0.4;

  static String _sfxFile(Sfx s) => switch (s) {
        Sfx.jump => 'sfx/jump.wav',
        Sfx.doubleJump => 'sfx/double_jump.wav',
        Sfx.collectFruit => 'sfx/collect_fruit.wav',
        Sfx.hit => 'sfx/hit.wav',
        Sfx.enemyDefeat => 'sfx/enemy_defeat.wav',
        Sfx.dash => 'sfx/dash.wav',
        Sfx.checkpoint => 'sfx/checkpoint.wav',
        Sfx.levelComplete => 'sfx/level_complete.wav',
        Sfx.buttonClick => 'sfx/button_click.wav',
      };

  static String _musicFile(Music m) => switch (m) {
        Music.menu => 'music/menu_loop.wav',
        Music.level => 'music/level_loop.wav',
      };

  Future<void> preload() async {
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([
      ...Sfx.values.map(_sfxFile),
      ...Music.values.map(_musicFile),
    ]);
  }

  void playSfx(Sfx sfx) {
    if (!muted) FlameAudio.play(_sfxFile(sfx), volume: sfxVolume);
  }

  Future<void> playMusic(Music music) async {
    if (muted) return;
    await FlameAudio.bgm.play(_musicFile(music), volume: musicVolume);
  }

  Future<void> stopMusic() => FlameAudio.bgm.stop();

  Future<void> toggleMute() async {
    muted = !muted;
    if (muted) await stopMusic();
  }
}
