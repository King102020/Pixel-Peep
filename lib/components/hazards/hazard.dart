import 'package:flame/components.dart';

/// Marker for anything that hurts the player on touch.
mixin Hazard on PositionComponent {
  /// Hazards like fire switch on and off; only active ones hurt.
  bool get isActive => true;
}
