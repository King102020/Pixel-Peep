import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

class LevelComplete extends StatelessWidget {
  const LevelComplete({super.key, required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) {
    final result = game.lastResult;
    final s = game.session;
    final stars = result?.stars ?? 1;
    final last = !game.hasNextLevel;
    return Scrim(
      child: Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(last ? 'YOU BEAT PIXEL PEEP!' : 'LEVEL CLEAR!',
                textAlign: TextAlign.center,
                style: pixelText.copyWith(fontSize: 26, color: Palette.accent)),
            const SizedBox(height: 10),
            // Stars pop in one after another.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stars.toDouble()),
              duration: Duration(milliseconds: 350 * stars),
              builder: (_, v, __) => StarRow(stars: v.floor(), size: 40),
            ),
            const SizedBox(height: 10),
            _line('Fruit', '${s.fruits.value} / ${s.totalFruits.value}',
                s.fruits.value >= s.totalFruits.value),
            _line('Time', '${formatTime(s.elapsed.value)}  (goal ${formatTime(s.targetTime)})',
                s.elapsed.value <= s.targetTime),
            _line('Falls', '${s.deaths.value}', s.deaths.value == 0),
            const SizedBox(height: 8),
            _Split(game: game),
            const SizedBox(height: 14),
            // Wraps onto two rows on narrow phones instead of overflowing.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                GameButton(
                  label: 'MENU',
                  icon: Icons.home_rounded,
                  color: Palette.muted,
                  onPressed: game.quitToMenu,
                ),
                GameButton(
                  label: 'REPLAY',
                  icon: Icons.replay_rounded,
                  color: Palette.muted,
                  onPressed: () => game.showCharacterSelect(game.levelIndex),
                ),
                if (!last)
                  GameButton(
                    label: 'NEXT',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: game.playNextLevel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, bool good) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              child: Text(label, style: pixelText.copyWith(fontSize: 13, color: Palette.muted)),
            ),
            Text(value, style: pixelText.copyWith(fontSize: 13)),
            const SizedBox(width: 6),
            Icon(good ? Icons.check_circle_rounded : Icons.remove_circle_outline,
                size: 16, color: good ? const Color(0xFF6CE0A0) : Palette.muted),
          ],
        ),
      );
}


/// "One more try" hook: how this run compares to your best.
class _Split extends StatelessWidget {
  const _Split({required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    final previous = game.previousBest;
    final missed = s.totalFruits.value - s.fruits.value;
    final parts = <String>[];
    if (previous == null) {
      parts.add('First clear!');
    } else {
      final diff = s.elapsed.value - previous;
      parts.add(diff < 0
          ? 'New best! ${(-diff).toStringAsFixed(1)}s faster'
          : '+${diff.toStringAsFixed(1)}s vs your best');
    }
    if (missed > 0) parts.add('missed $missed fruit');
    return Text(
      parts.join('  ·  '),
      textAlign: TextAlign.center,
      style: pixelText.copyWith(fontSize: 13, color: Palette.accent),
    );
  }
}
