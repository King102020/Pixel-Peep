import 'package:pixel_peep/components/abilities/bubble_float.dart';
import 'package:pixel_peep/components/abilities/dash.dart';
import 'package:pixel_peep/components/abilities/ground_pound.dart';
import 'package:pixel_peep/components/abilities/shadow_ninja.dart';
import 'package:pixel_peep/components/actors/player.dart';
import 'package:pixel_peep/data/characters.dart';

/// A hero's special power. Each hero owns exactly one (Strategy pattern), so
/// adding a hero means adding one subclass here.
abstract class Ability {
  Ability(this.player);

  final Player player;
  double _cooldownLeft = 0;

  double get cooldown => player.hero.stats.abilityCooldown;

  /// 0 = ready, 1 = just used. Drives the HUD cooldown ring.
  double get cooldownProgress =>
      cooldown == 0 ? 0 : (_cooldownLeft / cooldown).clamp(0, 1);

  bool get isReady => _cooldownLeft <= 0;

  /// True while the hero cannot be hurt by hazards or enemies.
  bool get isInvincible => false;

  /// True while touching an enemy or box should destroy it.
  bool get isAttacking => false;

  /// Lets the ability take over horizontal/vertical motion this step.
  /// Return true to skip the normal movement for this step.
  bool overrideMovement(double dt) => false;

  /// Max fall speed while the ability is active, or null for the default.
  double? get fallSpeedCap => null;

  /// Called when jump is pressed but a normal jump isn't possible.
  /// Return true if the ability consumed it (double jump, wall jump).
  bool onAirJump() => false;

  /// Whether this hero can cling to walls.
  bool get canWallSlide => false;

  void onPressed() {
    if (!isReady) return;
    if (activate()) _cooldownLeft = cooldown;
  }

  void onReleased() {}

  /// Return true if the ability actually fired (starts the cooldown).
  bool activate();

  void onLanded() {}

  void update(double dt) {
    if (_cooldownLeft > 0) _cooldownLeft -= dt;
  }

  void reset() => _cooldownLeft = 0;

  static Ability forHero(HeroId hero, Player player) => switch (hero) {
        HeroId.bubbleTrouper => BubbleFloat(player),
        HeroId.finalCall => Dash(player),
        HeroId.mastiTime => GroundPound(player),
        HeroId.blueNinja => ShadowNinja(player),
      };
}
