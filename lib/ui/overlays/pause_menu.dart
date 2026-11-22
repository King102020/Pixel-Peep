import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) {
    final short = isShortScreen(context);
    final buttons = [
      GameButton(
        label: 'RESUME',
        icon: Icons.play_arrow_rounded,
        onPressed: game.togglePause,
      ),
      GameButton(
        label: 'RESTART',
        icon: Icons.replay_rounded,
        color: Palette.muted,
        onPressed: game.restartLevel,
      ),
      GameButton(
        label: 'CHANGE HERO',
        icon: Icons.people_alt_rounded,
        color: Palette.muted,
        onPressed: () {
          game.quitToMenu();
          game.showCharacterSelect(game.levelIndex);
        },
      ),
      GameButton(
        label: 'QUIT',
        icon: Icons.home_rounded,
        color: Palette.muted,
        onPressed: game.quitToMenu,
      ),
    ];
    return Scrim(
      child: Panel(
        padding: short ? 12 : 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: pixelText.copyWith(fontSize: short ? 22 : 28)),
            SizedBox(height: short ? 10 : 16),
            // Short screens: a 2x2 grid so QUIT never falls off the bottom.
            if (short)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: buttons,
                ),
              )
            else
              for (final b in buttons)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: b),
          ],
        ),
      ),
    );
  }
}
