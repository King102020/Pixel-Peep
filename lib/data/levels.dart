/// Static description of every playable level, in order.
class LevelInfo {
  const LevelInfo({
    required this.file,
    required this.name,
    required this.world,
    this.tip,
  });

  /// Tiled map file name in assets/tiles, without extension.
  final String file;
  final String name;
  final int world;

  /// Hint shown on character select about which hero shines here.
  final String? tip;
}

const levels = <LevelInfo>[
  LevelInfo(file: 'l01', name: 'First Steps', world: 1,
      tip: 'Run with arrows or A/D, jump with Space.'),
  LevelInfo(file: 'l02', name: 'Saw Valley', world: 1,
      tip: 'Saws move. Watch their path, then go.'),
  LevelInfo(file: 'l03', name: 'Bouncy Hills', world: 1,
      tip: 'Stomp slimes. A crate hides fruit: dash or punch it.'),
  LevelInfo(file: 'l04', name: 'Fan Factory', world: 2,
      tip: 'Ride the fans. Bubble Trouper can float to the top fruit.'),
  LevelInfo(file: 'l05', name: 'Spin Cycle', world: 2,
      tip: 'Blue Ninja can wall-jump up the narrow shaft.'),
  LevelInfo(file: 'l06', name: 'Factory Floor', world: 2,
      tip: 'Falling platforms drop when you stand on them.'),
  LevelInfo(file: 'l07', name: 'Spike Caverns', world: 3,
      tip: 'Blue Ninja can phase through the spike row for fruit.'),
  LevelInfo(file: 'l08', name: 'Crumbling Path', world: 3,
      tip: "Keep moving across the falling platforms."),
  LevelInfo(file: 'l09', name: 'Needle Run', world: 3,
      tip: 'Time your jumps between the saws.'),
  LevelInfo(file: 'l10', name: 'Rock Ruins', world: 4,
      tip: 'Golems shrug off stomps. Masti Time can knock them out.'),
  LevelInfo(file: 'l11', name: 'Golem Gate', world: 4,
      tip: 'Masti Time clears the golems; others jump over.'),
  LevelInfo(file: 'l12', name: 'Crate Canyon', world: 4,
      tip: 'Lots of crates. Final Call or Masti Time to smash them.'),
  LevelInfo(file: 'l13', name: 'Fire Rush', world: 5,
      tip: 'Fire switches on and off. Final Call races the timer.'),
  LevelInfo(file: 'l14', name: 'Lava Lane', world: 5,
      tip: 'A long fall-away bridge. Bubble Trouper floats safely.'),
  LevelInfo(file: 'l15', name: 'Gauntlet', world: 5,
      tip: 'Everything at once. Pick your favourite hero.'),
  LevelInfo(file: 'l16', name: 'Golem King', world: 6,
      tip: 'Dodge the charge. Stomp the king while he is dizzy!'),
];
