import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

/// On-screen joystick drawn with shapes, so it needs no image assets.
class VirtualJoystick extends JoystickComponent {
  VirtualJoystick({super.margin = const EdgeInsets.only(left: 32, bottom: 32)})
      : super(
          knob: CircleComponent(
            radius: 16,
            paint: Paint()..color = const Color(0xCCFFFFFF),
          ),
          background: CircleComponent(
            radius: 40,
            paint: Paint()..color = const Color(0x55FFFFFF),
          ),
        );
}
