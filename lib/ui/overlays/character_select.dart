import 'package:flame/components.dart' show Vector2;
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/ui/widgets.dart';

class CharacterSelect extends StatefulWidget {
  const CharacterSelect({super.key, required this.game});
  final PixelPeep game;

  @override
  State<CharacterSelect> createState() => _CharacterSelectState();
}

class _CharacterSelectState extends State<CharacterSelect> {
  late HeroId _selected = widget.game.hero;

  @override
  Widget build(BuildContext context) {
    final info = levels[widget.game.levelIndex];
    final tip = info.tip;
    return Scrim(
      opacity: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LEVEL ${widget.game.levelIndex + 1} · ${info.name.toUpperCase()}',
                style: pixelText.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text('Choose your hero',
                style: pixelText.copyWith(fontSize: 13, color: Palette.muted)),
            if (tip != null) ...[
              const SizedBox(height: 4),
              Text('Tip: $tip',
                  style: pixelText.copyWith(fontSize: 12, color: Palette.accent)),
            ],
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final hero in HeroId.values)
                      _HeroCard(
                        hero: hero,
                        game: widget.game,
                        selected: hero == _selected,
                        onTap: () {
                          AudioService.instance.playSfx(Sfx.buttonClick);
                          setState(() => _selected = hero);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameButton(
                  label: 'BACK',
                  color: Palette.muted,
                  onPressed: widget.game.showLevelSelect,
                ),
                const SizedBox(width: 12),
                GameButton(
                  label: 'GO!',
                  icon: Icons.play_arrow_rounded,
                  color: _selected.color,
                  onPressed: () => widget.game.startLevel(_selected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.hero,
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final HeroId hero;
  final PixelPeep game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = hero.stats;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(10),
        transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? hero.color : Palette.panelBorder,
            width: selected ? 4 : 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 64,
              child: SpriteAnimationWidget.asset(
                path: 'Main Characters/${hero.sprite}/'
                    '${selected ? 'Run' : 'Idle'} (32x32).png',
                images: game.images,
                data: SpriteAnimationData.sequenced(
                  amount: selected ? 12 : 11,
                  stepTime: 0.05,
                  textureSize: Vector2.all(32),
                ),
              ),
            ),
            Text(hero.displayName,
                style: pixelText.copyWith(fontSize: 14, color: hero.color)),
            Text(hero.role.toUpperCase(),
                style: pixelText.copyWith(fontSize: 10, color: Palette.muted)),
            const SizedBox(height: 6),
            _StatBar(label: 'SPEED', value: s.moveSpeed / 150),
            _StatBar(label: 'JUMP', value: s.jumpForce / 380),
            _StatBar(label: 'HEARTS', value: s.maxHp / 4),
            const SizedBox(height: 6),
            Text(hero.ability,
                textAlign: TextAlign.center,
                style: pixelText.copyWith(fontSize: 11, color: Palette.accent)),
            const SizedBox(height: 2),
            Text(hero.description,
                textAlign: TextAlign.center,
                style: pixelText.copyWith(
                    fontSize: 10, fontWeight: FontWeight.w600, shadows: [])),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(label,
                  style: pixelText.copyWith(fontSize: 9, color: Palette.muted)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Palette.background,
                  color: Palette.accent,
                ),
              ),
            ),
          ],
        ),
      );
}
