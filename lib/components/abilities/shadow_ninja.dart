import 'package:pixel_peep/components/abilities/ability.dart';
import 'package:pixel_peep/services/audio_service.dart';

/// Blue Ninja: clings to and jumps off walls; Shadow Phase makes them
/// invincible for a moment so they can pass through traps.
class ShadowNinja extends Ability {
  ShadowNinja(super.player);

  static const double phaseTime = 0.6;
  static const double wallJumpPush = 180;
  double _phaseLeft = 0;

  bool get isPhasing => _phaseLeft > 0;

  @override
  bool get isInvincible => isPhasing;

  @override
  bool get canWallSlide => true;

  @override
  bool onAirJump() {
    final wall = player.wallDirection;
    if (wall == 0) return false;
    // Kick away from the wall.
    player.velocity
      ..y = -player.hero.stats.jumpForce
      ..x = -wall * wallJumpPush;
    player.wallKick(-wall);
    AudioService.instance.playSfx(Sfx.jump);
    return true;
  }

  @override
  bool activate() {
    _phaseLeft = phaseTime;
    AudioService.instance.playSfx(Sfx.dash);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_phaseLeft > 0) {
      _phaseLeft -= dt;
      player.opacity = _phaseLeft > 0 ? 0.45 : 1;
    }
  }

  @override
  void reset() {
    super.reset();
    _phaseLeft = 0;
  }
}
