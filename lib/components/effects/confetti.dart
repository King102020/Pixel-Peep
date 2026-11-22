import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:pixel_peep/pixel_peep.dart';

/// Celebratory burst when the player reaches the finish.
class Confetti extends ParticleSystemComponent with HasGameReference<PixelPeep> {
  Confetti({required Vector2 position}) : super(position: position);

  static final _rng = math.Random();
  static const _pieces = 6; // colours in the confetti sheet

  @override
  FutureOr<void> onLoad() {
    final sheet = game.images.fromCache('Other/Confetti (16x16).png');
    final sprites = [
      for (var i = 0; i < _pieces; i++)
        Sprite(sheet, srcPosition: Vector2(i * 16.0, 0), srcSize: Vector2.all(16)),
    ];
    particle = Particle.generate(
      count: 40,
      lifespan: 1.4,
      generator: (i) {
        final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 2.2;
        final speed = 120 + _rng.nextDouble() * 140;
        return AcceleratedParticle(
          speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
          acceleration: Vector2(0, 260),
          child: RotatingParticle(
            to: (_rng.nextDouble() - 0.5) * 12,
            child: SpriteParticle(
              sprite: sprites[i % _pieces],
              size: Vector2.all(8),
            ),
          ),
        );
      },
    );
    return super.onLoad();
  }
}
