import 'package:flame/components.dart';
import 'package:pixel_peep/components/collision_block.dart';

/// The player's collision box, relative to the top-left of its 32x32 sprite.
class PlayerHitbox {
  const PlayerHitbox({
    required this.offsetX,
    required this.offsetY,
    required this.width,
    required this.height,
  });
  final double offsetX;
  final double offsetY;
  final double width;
  final double height;
}

/// Axis-aligned overlap test between the player's hitbox and a block.
///
/// [position] is the sprite's top-left corner and [scaleX] its horizontal
/// scale; when flipped (scaleX < 0) Flame keeps the position on the right edge
/// of the sprite, so the box is mirrored back.
bool checkCollision({
  required Vector2 position,
  required double scaleX,
  required double spriteWidth,
  required PlayerHitbox hitbox,
  required CollisionBlock block,
}) {
  final x = scaleX < 0
      ? position.x - spriteWidth + (spriteWidth - hitbox.offsetX - hitbox.width)
      : position.x + hitbox.offsetX;
  final y = position.y + hitbox.offsetY;

  // One-way platforms only collide with the player's feet.
  final top = block.isPlatform ? y + hitbox.height : y;

  return top < block.y + block.height &&
      y + hitbox.height > block.y &&
      x < block.x + block.width &&
      x + hitbox.width > block.x;
}
