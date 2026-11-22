import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class CollisionBlock extends PositionComponent {
  CollisionBlock({super.position, super.size, this.isPlatform = false}) {
    debugMode = kDebugMode;
  }

  /// One-way platform: the player can jump up through it and land on top.
  final bool isPlatform;
}
