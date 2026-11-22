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
  LevelInfo(file: 'l01', name: 'First Steps', world: 1),
  LevelInfo(file: 'l02', name: 'Saw Valley', world: 1),
];
