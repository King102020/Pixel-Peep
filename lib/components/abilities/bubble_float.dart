import 'package:pixel_peep/components/abilities/ability.dart';
import 'package:pixel_peep/services/audio_service.dart';

/// Bubble Trouper: one extra jump in the air, and floats while holding the
/// ability button.
class BubbleFloat extends Ability {
  BubbleFloat(super.player);

  static const double floatFallSpeed = 45;
  bool _hasDoubleJump = true;
  bool _floating = false;

  @override
  double? get fallSpeedCap => _floating ? floatFallSpeed : null;

  @override
  bool onAirJump() {
    if (!_hasDoubleJump) return false;
    _hasDoubleJump = false;
    player.velocity.y = -player.hero.stats.jumpForce * 0.9;
    player.playDoubleJump();
    AudioService.instance.playSfx(Sfx.doubleJump);
    return true;
  }

  @override
  bool activate() {
    _floating = true;
    return true;
  }

  @override
  void onReleased() => _floating = false;

  @override
  void onLanded() => _hasDoubleJump = true;

  @override
  void reset() {
    super.reset();
    _floating = false;
    _hasDoubleJump = true;
  }
}
