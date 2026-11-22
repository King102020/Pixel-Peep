import 'package:pixel_peep/components/abilities/ability.dart';
import 'package:pixel_peep/services/audio_service.dart';

/// Final Call: a short, gravity-free burst that smashes boxes and enemies.
class Dash extends Ability {
  Dash(super.player);

  static const double dashSpeed = 380;
  static const double dashTime = 0.18;
  double _timeLeft = 0;
  double _direction = 1;
  bool _airDashUsed = false;

  bool get isDashing => _timeLeft > 0;

  @override
  bool get isAttacking => isDashing;

  @override
  bool activate() {
    if (!player.isOnGround && _airDashUsed) return false;
    if (!player.isOnGround) _airDashUsed = true;
    _direction = player.facingDirection;
    _timeLeft = dashTime;
    player.velocity.y = 0;
    player.spawnDust();
    AudioService.instance.playSfx(Sfx.dash);
    return true;
  }

  @override
  bool overrideMovement(double dt) {
    if (!isDashing) return false;
    _timeLeft -= dt;
    player.velocity
      ..x = _direction * dashSpeed
      ..y = 0;
    return true;
  }

  @override
  void onLanded() => _airDashUsed = false;

  @override
  void reset() {
    super.reset();
    _timeLeft = 0;
    _airDashUsed = false;
  }
}
