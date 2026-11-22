import 'dart:ui';

/// Tunable numbers for a hero. Rebalancing a hero means editing these only.
class CharacterStats {
  const CharacterStats({
    required this.moveSpeed,
    required this.jumpForce,
    required this.maxHp,
    required this.abilityCooldown,
    this.gravityScale = 1,
  });

  final double moveSpeed;
  final double jumpForce;
  final double gravityScale;
  final int maxHp;

  /// Seconds before the ability can be used again.
  final double abilityCooldown;
}

enum HeroId {
  bubbleTrouper(
    displayName: 'Bubble Trouper',
    sprite: 'Pink Man',
    role: 'Jumper',
    ability: 'Bubble Float',
    description: 'Double jump, and hold the ability button to float down.',
    color: Color(0xFFFF7EB6),
    stats: CharacterStats(
      moveSpeed: 85,
      jumpForce: 380,
      gravityScale: 0.9,
      maxHp: 3,
      abilityCooldown: 0,
    ),
  ),
  finalCall(
    displayName: 'Final Call',
    sprite: 'Virtual Guy',
    role: 'Speedster',
    ability: 'Dash',
    description: 'Runs fastest. Dash through the air and smash boxes.',
    color: Color(0xFF5CC8FF),
    stats: CharacterStats(
      moveSpeed: 150,
      jumpForce: 330,
      maxHp: 2,
      abilityCooldown: 0.8,
    ),
  ),
  mastiTime(
    displayName: 'Masti Time',
    sprite: 'Mask Dude',
    role: 'Fighter',
    ability: 'Punch & Ground Pound',
    description: 'Punch on the ground, slam from the air. Beats any enemy.',
    color: Color(0xFFFFB347),
    stats: CharacterStats(
      moveSpeed: 100,
      jumpForce: 370,
      gravityScale: 1.15,
      maxHp: 4,
      abilityCooldown: 0.4,
    ),
  ),
  blueNinja(
    displayName: 'Blue Ninja',
    sprite: 'Ninja Frog',
    role: 'Acrobat',
    ability: 'Wall Jump & Shadow Phase',
    description: 'Slides and jumps off walls. Phase through traps for a moment.',
    color: Color(0xFF6CE0A0),
    stats: CharacterStats(
      moveSpeed: 110,
      jumpForce: 360,
      maxHp: 3,
      abilityCooldown: 2,
    ),
  );

  const HeroId({
    required this.displayName,
    required this.sprite,
    required this.role,
    required this.ability,
    required this.description,
    required this.color,
    required this.stats,
  });

  final String displayName;

  /// Folder in assets/images/Main Characters.
  final String sprite;
  final String role;
  final String ability;
  final String description;
  final Color color;
  final CharacterStats stats;
}
