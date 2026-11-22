import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_peep/components/collision_block.dart';
import 'package:pixel_peep/components/utils.dart';

void main() {
  const hitbox = PlayerHitbox(offsetX: 10, offsetY: 4, width: 14, height: 28);

  bool hits(Vector2 pos, CollisionBlock block, {double scaleX = 1}) =>
      checkCollision(
        position: pos,
        scaleX: scaleX,
        spriteWidth: 32,
        hitbox: hitbox,
        block: block,
      );

  test('detects overlap with a solid block', () {
    final block = CollisionBlock(position: Vector2(30, 0), size: Vector2(16, 64));
    expect(hits(Vector2(10, 0), block), isTrue); // hitbox x 20..34
    expect(hits(Vector2(0, 0), block), isFalse); // hitbox x 10..24
  });

  test('uses width and height correctly for wide blocks', () {
    final floor = CollisionBlock(position: Vector2(0, 100), size: Vector2(200, 16));
    expect(hits(Vector2(150, 70), floor), isTrue); // feet at 102
    expect(hits(Vector2(150, 60), floor), isFalse); // feet at 92
  });

  test('mirrors the hitbox when the sprite is flipped', () {
    final block = CollisionBlock(position: Vector2(30, 0), size: Vector2(16, 64));
    // Flipped: position is the right edge, hitbox x = 42-32+8 = 18..32.
    expect(hits(Vector2(42, 0), block, scaleX: -1), isTrue);
    expect(hits(Vector2(38, 0), block, scaleX: -1), isFalse);
  });

  test('platforms only collide with the feet', () {
    final platform = CollisionBlock(
      position: Vector2(0, 100),
      size: Vector2(64, 16),
      isPlatform: true,
    );
    expect(hits(Vector2(0, 70), platform), isTrue); // feet inside platform
    expect(hits(Vector2(0, 85), platform), isFalse); // body inside, feet below
  });
}
