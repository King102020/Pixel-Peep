import 'package:flame/components.dart' show Vector2;
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/data/level_goals.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/ui/widgets.dart';

/// Hero picker. Small hero tiles plus one big detail panel, so it reads on a
/// 390px-wide phone and a 320px-tall landscape window alike.
class CharacterSelect extends StatefulWidget {
  const CharacterSelect({super.key, required this.game});
  final PixelPeep game;

  @override
  State<CharacterSelect> createState() => _CharacterSelectState();
}

class _CharacterSelectState extends State<CharacterSelect> {
  late HeroId _selected = levels[widget.game.levelIndex].bestHero ?? widget.game.hero;
  late final Future<LevelGoals> _goals =
      LevelGoals.load(levels[widget.game.levelIndex].file);

  void _pick(HeroId hero) {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() => _selected = hero);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final info = levels[game.levelIndex];
    return ColoredBox(
      color: Palette.background,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          // Short landscape: details left, goals + buttons right.
          final twoColumn = box.maxWidth >= 600 && box.maxHeight < 560;
          final header = _Header(game: game, info: info, goals: _goals);
          final picker = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroTiles(game: game, selected: _selected, onPick: _pick),
              const SizedBox(height: 10),
              _HeroDetail(game: game, hero: _selected, shines: info.bestHero == _selected),
            ],
          );
          final buttons = Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              GameButton(
                label: 'BACK',
                color: Palette.muted,
                onPressed: game.showLevelSelect,
              ),
              GameButton(
                label: 'GO!',
                icon: Icons.play_arrow_rounded,
                color: _selected.color,
                onPressed: () => game.startLevel(_selected),
              ),
            ],
          );

          if (twoColumn) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ScrollHint(child: picker)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 230,
                    child: ScrollHint(
                      child: Column(
                        children: [header, const SizedBox(height: 14), buttons],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ScrollHint(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header,
                      const SizedBox(height: 12),
                      picker,
                      const SizedBox(height: 14),
                      buttons,
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.info, required this.goals});
  final PixelPeep game;
  final LevelInfo info;
  final Future<LevelGoals> goals;

  @override
  Widget build(BuildContext context) {
    final best = game.save.bestTimeFor(game.levelIndex);
    final tip = game.showTouchControls ? (info.touchTip ?? info.tip) : info.tip;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('LEVEL ${game.levelIndex + 1}',
            style: pixelText.copyWith(fontSize: 12, color: Palette.muted)),
        Text(info.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: pixelText.copyWith(fontSize: 22, color: Palette.accent)),
        const SizedBox(height: 6),
        // The three stars and what each one asks for.
        FutureBuilder<LevelGoals>(
          future: goals,
          builder: (_, snap) {
            final g = snap.data;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                const _Goal(icon: Icons.flag_rounded, text: 'Finish'),
                _Goal(
                    icon: Icons.apple,
                    text: g == null ? 'All fruit' : 'All ${g.fruit} fruit'),
                _Goal(
                    icon: Icons.timer_rounded,
                    text: g == null ? 'Beat the clock' : 'Under ${formatTime(g.targetSeconds)}'),
              ],
            );
          },
        ),
        if (best != null) ...[
          const SizedBox(height: 4),
          Text('Your best: ${formatTime(best)}  ·  ${game.save.starsFor(game.levelIndex)}★',
              style: pixelText.copyWith(fontSize: 11, color: Palette.muted)),
        ],
        if (tip != null) ...[
          const SizedBox(height: 6),
          Text(tip,
              textAlign: TextAlign.center,
              style: pixelText.copyWith(
                  fontSize: 12, color: Palette.text, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

class _Goal extends StatelessWidget {
  const _Goal({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.panelBorder, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_outline_rounded, color: Palette.accent, size: 14),
            const SizedBox(width: 3),
            Icon(icon, color: Palette.muted, size: 14),
            const SizedBox(width: 4),
            Text(text, style: pixelText.copyWith(fontSize: 11, shadows: [])),
          ],
        ),
      );
}

class _HeroTiles extends StatelessWidget {
  const _HeroTiles({required this.game, required this.selected, required this.onPick});
  final PixelPeep game;
  final HeroId selected;
  final ValueChanged<HeroId> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final hero in HeroId.values)
            GestureDetector(
              onTap: () => onPick(hero),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hero == selected ? hero.color : Palette.panelBorder,
                    width: hero == selected ? 4 : 2,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: _HeroSprite(game: game, hero: hero, state: 'Idle', frames: 11),
                    ),
                    Text(
                      hero.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: pixelText.copyWith(
                          fontSize: 10, color: hero.color, shadows: const []),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({required this.game, required this.hero, required this.shines});
  final PixelPeep game;
  final HeroId hero;
  final bool shines;

  /// Bars are scaled between the weakest and strongest hero, so the
  /// differences are easy to see at a glance.
  static double _norm(double v, Iterable<double> all) {
    final lo = all.reduce((a, b) => a < b ? a : b);
    final hi = all.reduce((a, b) => a > b ? a : b);
    return hi == lo ? 1 : 0.2 + 0.8 * (v - lo) / (hi - lo);
  }

  @override
  Widget build(BuildContext context) {
    final s = hero.stats;
    final all = HeroId.values.map((h) => h.stats);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(hero),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hero.color, width: 3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: _HeroSprite(game: game, hero: hero, state: 'Run', frames: 12),
                ),
                if (shines)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hero.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('SHINES HERE',
                        style: pixelText.copyWith(
                            fontSize: 9, color: Palette.background, shadows: [])),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${hero.displayName} · ${hero.role}',
                      style: pixelText.copyWith(fontSize: 15, color: hero.color)),
                  const SizedBox(height: 2),
                  Text('★ ${hero.ability}',
                      style: pixelText.copyWith(fontSize: 12, color: Palette.accent)),
                  Text(hero.description,
                      style: pixelText.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w600, shadows: [])),
                  const SizedBox(height: 6),
                  _StatBar(
                      label: 'SPEED',
                      value: _norm(s.moveSpeed, all.map((e) => e.moveSpeed)),
                      color: hero.color),
                  _StatBar(
                      label: 'JUMP',
                      value: _norm(s.jumpForce / s.gravityScale,
                          all.map((e) => e.jumpForce / e.gravityScale)),
                      color: hero.color),
                  _StatBar(
                      label: 'HEARTS',
                      value: _norm(s.maxHp.toDouble(), all.map((e) => e.maxHp.toDouble())),
                      color: hero.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSprite extends StatelessWidget {
  const _HeroSprite({
    required this.game,
    required this.hero,
    required this.state,
    required this.frames,
  });
  final PixelPeep game;
  final HeroId hero;
  final String state;
  final int frames;

  @override
  Widget build(BuildContext context) => SpriteAnimationWidget.asset(
        key: ValueKey('${hero.name}-$state'),
        path: 'Main Characters/${hero.sprite}/$state (32x32).png',
        images: game.images,
        data: SpriteAnimationData.sequenced(
          amount: frames,
          stepTime: 0.05,
          textureSize: Vector2.all(32),
        ),
      );
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(label,
                  style: pixelText.copyWith(fontSize: 10, color: Palette.muted)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 7,
                  backgroundColor: Palette.background,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}
