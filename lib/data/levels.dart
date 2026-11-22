import 'package:pixel_peep/data/characters.dart';

/// Static description of every playable level, in order.
class LevelInfo {
  const LevelInfo({
    required this.file,
    required this.name,
    required this.world,
    this.tip,
    this.touchTip,
    this.bestHero,
  });

  /// Tiled map file name in assets/tiles, without extension.
  final String file;
  final String name;
  final int world;

  /// Hint shown on character select about which hero shines here.
  final String? tip;

  /// Replaces [tip] on touch screens (no keyboard keys to mention).
  final String? touchTip;

  /// Hero this level was built to show off; pre-selected and badged.
  final HeroId? bestHero;
}

const levels = <LevelInfo>[
  LevelInfo(file: 'l01', name: 'First Steps', world: 1,
      tip: 'Arrows or A/D to run, Space to jump, E for your ability. Each hero has a secret here.',
      touchTip: 'Joystick to run, ▲ to jump, ★ for your ability. Each hero has a secret here.'),
  LevelInfo(file: 'l02', name: 'Saw Valley', world: 1,
      tip: 'Saws move. Watch their path, then go.'),
  LevelInfo(file: 'l03', name: 'Bouncy Hills', world: 1,
      tip: 'Stomp slimes. A crate hides fruit: dash or punch it.',
      bestHero: HeroId.finalCall),
  LevelInfo(file: 'l04', name: 'Fan Factory', world: 2,
      tip: 'Ride the fans. Bubble Trouper can float to the top fruit.',
      bestHero: HeroId.bubbleTrouper),
  LevelInfo(file: 'l05', name: 'Spin Cycle', world: 2,
      tip: 'Blue Ninja can wall-jump up the narrow shaft.',
      bestHero: HeroId.blueNinja),
  LevelInfo(file: 'l06', name: 'Factory Floor', world: 2,
      tip: 'Falling platforms drop when you stand on them.'),
  LevelInfo(file: 'l07', name: 'Spike Caverns', world: 3,
      tip: 'Spikes everywhere. Blue Ninja can phase through them.',
      bestHero: HeroId.blueNinja),
  LevelInfo(file: 'l08', name: 'Crumbling Path', world: 3,
      tip: "Keep moving across the falling platforms."),
  LevelInfo(file: 'l09', name: 'Needle Run', world: 3,
      tip: 'Time your jumps between the saws.'),
  LevelInfo(file: 'l10', name: 'Rock Ruins', world: 4,
      tip: 'Golems shrug off stomps. Masti Time can knock them out.',
      bestHero: HeroId.mastiTime),
  LevelInfo(file: 'l11', name: 'Golem Gate', world: 4,
      tip: 'Masti Time clears the golems; others jump over.',
      bestHero: HeroId.mastiTime),
  LevelInfo(file: 'l12', name: 'Crate Canyon', world: 4,
      tip: 'Lots of crates. Final Call or Masti Time to smash them.',
      bestHero: HeroId.finalCall),
  LevelInfo(file: 'l13', name: 'Fire Rush', world: 5,
      tip: 'Fire switches on and off. Final Call races the timer.',
      bestHero: HeroId.finalCall),
  LevelInfo(file: 'l14', name: 'Lava Lane', world: 5,
      tip: 'A long fall-away bridge. Bubble Trouper floats safely.',
      bestHero: HeroId.bubbleTrouper),
  LevelInfo(file: 'l15', name: 'Gauntlet', world: 5,
      tip: 'Everything at once. Pick your favourite hero.'),
  LevelInfo(file: 'l16', name: 'Golem King', world: 6,
      tip: 'Dodge the charge. Stomp the king while he is dizzy!'),
];
