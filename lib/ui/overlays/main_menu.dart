import 'package:flame/components.dart' show Vector2;
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:pixel_peep/data/characters.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/audio_service.dart';
import 'package:pixel_peep/ui/widgets.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game});
  final PixelPeep game;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;
    return Scrim(
      opacity: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bobs gently.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -4, end: 4),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (_, y, child) =>
                Transform.translate(offset: Offset(0, y), child: child),
            onEnd: () => setState(() {}),
            child: Text(
              'PIXEL PEEP',
              style: pixelText.copyWith(fontSize: 48, color: Palette.accent),
            ),
          ),
          const SizedBox(height: 4),
          Text('Pick a hero. Clear the level.',
              style: pixelText.copyWith(fontSize: 14, color: Palette.muted)),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final hero in HeroId.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox.square(
                    dimension: 56,
                    child: SpriteAnimationWidget.asset(
                      path: 'Main Characters/${hero.sprite}/Run (32x32).png',
                      images: widget.game.images,
                      data: SpriteAnimationData.sequenced(
                        amount: 12,
                        stepTime: 0.06,
                        textureSize: Vector2.all(32),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          GameButton(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            onPressed: widget.game.showLevelSelect,
          ),
          const SizedBox(height: 12),
          GameButton(
            label: audio.muted ? 'SOUND OFF' : 'SOUND ON',
            icon: audio.muted ? Icons.volume_off : Icons.volume_up,
            color: Palette.muted,
            onPressed: () async {
              await audio.toggleMute();
              if (!audio.muted) audio.playMusic(Music.menu);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
