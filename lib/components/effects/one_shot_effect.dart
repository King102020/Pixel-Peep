import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pixel_peep/pixel_peep.dart';

/// Plays a sprite sheet once at a point, then removes itself.
class OneShotEffect extends SpriteAnimationComponent
    with HasGameReference<PixelPeep> {
  OneShotEffect({
    required this.path,
    required this.frames,
    required double frameSize,
    required Vector2 center,
    this.onDone,
    this.stepTime = 0.05,
  }) : super(
          position: center,
          size: Vector2.all(frameSize),
          anchor: Anchor.center,
        );

  OneShotEffect.appear({required Vector2 center, VoidCallback? onDone})
      : this(
          path: 'Main Characters/Appearing (96x96).png',
          frames: 7,
          frameSize: 96,
          center: center,
          onDone: onDone,
        );

  OneShotEffect.disappear({required Vector2 center, VoidCallback? onDone})
      : this(
          path: 'Main Characters/Desappearing (96x96).png',
          frames: 7,
          frameSize: 96,
          center: center,
          onDone: onDone,
        );

  final String path;
  final int frames;
  final double stepTime;
  final VoidCallback? onDone;

  @override
  FutureOr<void> onLoad() {
    final image = game.images.fromCache(path);
    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2(image.width / frames, image.height.toDouble()),
        loop: false,
      ),
    );
    animationTicker?.onComplete = () {
      removeFromParent();
      onDone?.call();
    };
    return super.onLoad();
  }
}
