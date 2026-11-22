import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});
  final PixelPeep game;

  @override
  Widget build(BuildContext context) => Scrim(
        child: Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED', style: pixelText.copyWith(fontSize: 28)),
              const SizedBox(height: 16),
              GameButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                onPressed: game.togglePause,
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'RESTART',
                icon: Icons.replay_rounded,
                color: Palette.muted,
                onPressed: game.restartLevel,
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'CHANGE HERO',
                icon: Icons.people_alt_rounded,
                color: Palette.muted,
                onPressed: () {
                  game.quitToMenu();
                  game.showCharacterSelect(game.levelIndex);
                },
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'QUIT',
                icon: Icons.home_rounded,
                color: Palette.muted,
                onPressed: game.quitToMenu,
              ),
            ],
          ),
        ),
      );
}
