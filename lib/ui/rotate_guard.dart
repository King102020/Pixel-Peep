import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/widgets.dart';

/// The game is a landscape game. On a narrow portrait screen, show a
/// "turn your phone" card instead of a thin 16:9 ribbon.
class RotateGuard extends StatelessWidget {
  const RotateGuard({super.key, required this.game, required this.child});
  final PixelPeep game;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final portrait = box.maxHeight > box.maxWidth && box.maxWidth < 600;
        if (portrait) {
          WidgetsBinding.instance.addPostFrameCallback((_) => game.pauseForRotation());
        }
        return Stack(
          children: [
            child,
            if (portrait)
              Positioned.fill(
                child: ColoredBox(
                  color: Palette.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.screen_rotation_rounded,
                            color: Palette.accent, size: 64),
                        const SizedBox(height: 16),
                        Text('TURN YOUR PHONE',
                            style: pixelText.copyWith(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text('Pixel Peep plays sideways.',
                            style: pixelText.copyWith(
                                fontSize: 13, color: Palette.muted)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      });
}
