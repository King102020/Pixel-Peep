import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:pixel_peep/pixel_peep.dart';

/// A small puff of dust at the player's feet (jumping, landing, dashing).
class Dust extends ParticleSystemComponent with HasGameReference<PixelPeep> {
  Dust({required Vector2 position}) : super(position: position);

  static final _rng = math.Random();

  @override
  FutureOr<void> onLoad() {
    final sprite = Sprite(game.images.fromCache('Other/Dust Particle.png'));
    particle = Particle.generate(
      count: 5,
      lifespan: 0.35,
      generator: (i) => AcceleratedParticle(
        speed: Vector2((_rng.nextDouble() - 0.5) * 80, -_rng.nextDouble() * 30),
        acceleration: Vector2(0, 60),
        child: ScalingParticle(
          to: 0,
          child: SpriteParticle(sprite: sprite, size: Vector2.all(8)),
        ),
      ),
    );
    return super.onLoad();
  }
}
