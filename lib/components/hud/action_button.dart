import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/widgets.dart';

enum ActionIcon { jump, ability }

/// Round on-screen button with an icon drawn in code (no image assets).
class ActionButton extends HudButtonComponent {
  ActionButton({
    required ActionIcon icon,
    required EdgeInsets margin,
    super.onPressed,
    super.onReleased,
    double radius = 26,
  }) : super(
          margin: margin,
          button: _ButtonFace(icon: icon, radius: radius, pressed: false),
          buttonDown: _ButtonFace(icon: icon, radius: radius, pressed: true),
        );
}

class _ButtonFace extends PositionComponent {
  _ButtonFace({required this.icon, required double radius, required this.pressed})
      : super(size: Vector2.all(radius * 2));

  final ActionIcon icon;
  final bool pressed;

  static final _iconPaint = Paint()..color = const Color(0xFF211F30);

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final center = Offset(r, r);
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Color(pressed ? 0xEEFFFFFF : 0x88FFFFFF),
    );
    switch (icon) {
      case ActionIcon.jump:
        final path = Path()
          ..moveTo(r, r * 0.45)
          ..lineTo(r * 1.5, r * 1.15)
          ..lineTo(r * 0.5, r * 1.15)
          ..close();
        canvas.drawPath(path, _iconPaint);
      case ActionIcon.ability:
        canvas.drawPath(_star(center, r * 0.55, r * 0.25), _iconPaint);
    }
  }

  Path _star(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}
