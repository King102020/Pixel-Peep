import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

/// In-level heads-up display: hearts, fruit, time, ability cooldown, pause.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.topCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Chip(
                child: ListenableBuilder(
                  listenable: Listenable.merge([s.hp, s.maxHp]),
                  builder: (_, __) => Row(
                    children: [
                      for (var i = 0; i < s.maxHp.value; i++)
                        Icon(
                          i < s.hp.value
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: const Color(0xFFFF5D73),
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Chip(
                child: ListenableBuilder(
                  listenable: Listenable.merge([s.fruits, s.totalFruits]),
                  builder: (_, __) => Text(
                    '🍎 ${s.fruits.value}/${s.totalFruits.value}',
                    style: pixelText.copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Chip(
                child: ValueListenableBuilder(
                  valueListenable: s.elapsed,
                  builder: (_, t, __) => Text(
                    '⏱ ${formatTime(t)}',
                    style: pixelText.copyWith(
                      fontSize: 14,
                      color: t <= s.targetTime ? Palette.text : Palette.muted,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _Chip(
                child: Row(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: s.abilityCooldown,
                      builder: (_, cd, __) => SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          value: 1 - cd,
                          strokeWidth: 4,
                          backgroundColor: Palette.background,
                          color: cd == 0 ? game.hero.color : Palette.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      game.hero.ability.toUpperCase(),
                      style: pixelText.copyWith(fontSize: 11, color: game.hero.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: game.togglePause,
                child: const _Chip(
                  child: Icon(Icons.pause_rounded, color: Palette.text, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
}
