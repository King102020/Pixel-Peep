import 'package:flame/components.dart';
import 'package:pixel_peep/pixel_peep.dart';

class CollisionBlock extends PositionComponent {
  CollisionBlock({super.position, super.size, this.isPlatform = false}) {
    debugMode = PixelPeep.showHitboxes;
  }

  /// One-way platform: the player can jump up through it and land on top.
  final bool isPlatform;
}
