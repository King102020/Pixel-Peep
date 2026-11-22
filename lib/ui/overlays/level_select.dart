import 'package:flutter/material.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/ui/widgets.dart';

class LevelSelect extends StatelessWidget {
  const LevelSelect({super.key, required this.game});
  final PixelPeep game;

  static const _worldNames = {
    1: 'Green Meadow',
    2: 'Fan Factory',
    3: 'Spike Caverns',
    4: 'Rock Ruins',
    5: 'Fire Rush',
    6: 'Boss',
  };

  @override
  Widget build(BuildContext context) {
    final unlocked = game.save.unlockedLevels;
    final worlds = <int, List<int>>{};
    for (var i = 0; i < levels.length; i++) {
      worlds.putIfAbsent(levels[i].world, () => []).add(i);
    }
    return Scrim(
      opacity: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GameButton(
                  label: 'BACK',
                  icon: Icons.arrow_back_rounded,
                  color: Palette.muted,
                  onPressed: game.showMainMenu,
                ),
                const SizedBox(width: 16),
                Text('CHOOSE A LEVEL', style: pixelText.copyWith(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in worlds.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'WORLD ${entry.key} · ${_worldNames[entry.key] ?? ''}',
                        style: pixelText.copyWith(
                            fontSize: 14, color: Palette.muted),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final i in entry.value)
                          _LevelTile(
                            index: i,
                            locked: i >= unlocked,
                            stars: game.save.starsFor(i),
                            onTap: () => game.showCharacterSelect(i),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.locked,
    required this.stars,
    required this.onTap,
  });

  final int index;
  final bool locked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = levels[index];
    return GestureDetector(
      onTap: locked
          ? null
          : () {
              AudioService.instance.playSfx(Sfx.buttonClick);
              onTap();
            },
      child: Opacity(
        opacity: locked ? 0.45 : 1,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Palette.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: locked ? Palette.panelBorder : Palette.accent,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${index + 1}',
                style: pixelText.copyWith(fontSize: 26, color: Palette.accent),
              ),
              Text(
                info.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pixelText.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 4),
              locked
                  ? const Icon(Icons.lock_rounded, color: Palette.muted, size: 18)
                  : StarRow(stars: stars),
            ],
          ),
        ),
      ),
    );
  }
}
