import 'package:flutter/material.dart';
import 'package:pixel_peep/data/levels.dart';
import 'package:pixel_peep/game/game_session.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

/// In-level heads-up display: hearts, fruit, time, ability cooldown, pause.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    // Draw inside the letterboxed 16:9 playfield, not in the black bars.
    return GameRect(
      builder: (rect) => Stack(
        children: [
          _LevelBanner(
            key: ValueKey(game.levelIndex),
            title: 'LEVEL ${game.levelIndex + 1}',
            subtitle: levels[game.levelIndex].name,
          ),
          _DeathQuip(deaths: s.deaths),
          _bar(s, compact: rect.width < 700),
        ],
      ),
    );
  }

  Widget _bar(GameSession s, {required bool compact}) {
    final gap = compact ? 4.0 : 8.0;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 10),
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
                          size: compact ? 14 : 18,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: gap),
              _Chip(
                child: ListenableBuilder(
                  listenable: Listenable.merge([s.fruits, s.totalFruits]),
                  builder: (_, __) => Text(
                    '🍎 ${s.fruits.value}/${s.totalFruits.value}',
                    style: pixelText.copyWith(fontSize: compact ? 12 : 14),
                  ),
                ),
              ),
              SizedBox(width: gap),
              _Chip(
                child: ValueListenableBuilder(
                  valueListenable: s.elapsed,
                  builder: (_, t, __) => Text(
                    '⏱ ${formatTime(t)}',
                    style: pixelText.copyWith(
                      fontSize: compact ? 12 : 14,
                      color: t <= s.targetTime ? Palette.text : Palette.muted,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(width: gap),
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
                    // Narrow screens: just a star, the ring shows readiness.
                    compact
                        ? Icon(Icons.star_rounded, size: 16, color: game.hero.color)
                        : Text(
                            game.hero.ability.toUpperCase(),
                            style: pixelText.copyWith(
                                fontSize: 11, color: game.hero.color),
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


/// Shows the level name for a moment when the level starts.
class _LevelBanner extends StatefulWidget {
  const _LevelBanner({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  State<_LevelBanner> createState() => _LevelBannerState();
}

class _LevelBannerState extends State<_LevelBanner>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final t = _controller.value;
            // Fade in, hold, fade out.
            final opacity =
                t < 0.15 ? t / 0.15 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
            return Opacity(
              opacity: opacity.clamp(0, 1),
              child: Transform.scale(scale: 0.9 + 0.1 * opacity, child: child),
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title,
                    style: pixelText.copyWith(fontSize: 18, color: Palette.muted)),
                Text(widget.subtitle.toUpperCase(),
                    style: pixelText.copyWith(fontSize: 34, color: Palette.accent)),
              ],
            ),
          ),
        ),
      );
}


/// One-liner on the first fall of a level: deaths should sting a little and
/// then be funny, so the retry loop stays light.
class _DeathQuip extends StatefulWidget {
  const _DeathQuip({required this.deaths});
  final ValueNotifier<int> deaths;

  @override
  State<_DeathQuip> createState() => _DeathQuipState();
}

class _DeathQuipState extends State<_DeathQuip> {
  static const _quips = [
    'The floor was a lie.',
    'Gravity: 1, You: 0.',
    'That spike had it coming.',
    'Bold strategy!',
    'Practice run. Obviously.',
    'Nobody saw that. Probably.',
  ];
  String? _text;

  @override
  void initState() {
    super.initState();
    widget.deaths.addListener(_onDeath);
  }

  @override
  void dispose() {
    widget.deaths.removeListener(_onDeath);
    super.dispose();
  }

  void _onDeath() {
    if (widget.deaths.value != 1) return;
    final quip = (_quips.toList()..shuffle()).first;
    setState(() => _text = quip);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _text = null);
    });
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.45),
          child: AnimatedOpacity(
            opacity: _text == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Text(_text ?? '',
                style: pixelText.copyWith(fontSize: 18, color: Palette.text)),
          ),
        ),
      );
}
