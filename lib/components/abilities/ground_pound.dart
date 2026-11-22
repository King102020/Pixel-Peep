import 'package:pixel_peep/components/abilities/ability.dart';
import 'package:pixel_peep/services/audio_service.dart';

/// Masti Time: punches on the ground, slams down from the air.
class GroundPound extends Ability {
  GroundPound(super.player);

  static const double slamSpeed = 620;
  static const double punchTime = 0.22;
  double _punchLeft = 0;
  bool _slamming = false;

  bool get isPunching => _punchLeft > 0;
  bool get isSlamming => _slamming;

  @override
  bool get isAttacking => isPunching || _slamming;

  /// Lets the slam exceed the normal fall-speed cap.
  @override
  double? get fallSpeedCap => _slamming ? slamSpeed : null;

  @override
  bool activate() {
    if (player.isOnGround) {
      _punchLeft = punchTime;
    } else {
      _slamming = true;
      player.velocity.y = slamSpeed;
    }
    AudioService.instance.playSfx(Sfx.dash);
    return true;
  }

  @override
  bool overrideMovement(double dt) {
    if (_punchLeft > 0) _punchLeft -= dt;
    if (_slamming) {
      player.velocity
        ..x = 0
        ..y = slamSpeed;
    }
    return false;
  }

  @override
  void onLanded() {
    if (!_slamming) return;
    _slamming = false;
    // Keep hitting for a moment so whatever we landed on takes the blow.
    _punchLeft = 0.1;
    player.game.shake(intensity: 4);
    player.spawnDust();
    AudioService.instance.playSfx(Sfx.enemyDefeat);
  }

  @override
  void reset() {
    super.reset();
    _punchLeft = 0;
    _slamming = false;
  }
}
