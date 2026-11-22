# Pixel Peep — Game Plan

A 2D side-scrolling platformer in **Flutter + Flame**, with levels made in **Tiled**. At the start of each level the player picks one of four heroes. Each hero has a special ability, and some parts of each level are easier, or only open, with the right hero.

---

## 1. The heroes

Each hero uses one of the four sprite sets that are already in `assets/images/Main Characters/`.

| Hero | Sprite set | What they're best at | Special ability (button **E** / on-screen button) | Weak spot |
|---|---|---|---|---|
| **Bubble Trouper** | Pink Man | Jumping | **Bubble Float**: high double jump, and holding jump makes them float down slowly. | Slow runner |
| **Final Call** | Virtual Guy | Speed | **Dash**: a short, fast dash that also breaks cracked blocks. 1.5× run speed. | Low jump, 2 HP |
| **Masti Time** | Mask Dude | Fighting | **Ground Pound / Punch**: defeats enemies and breaks boxes and Rock Heads. | Heavy, so falls faster |
| **Blue Ninja** | Ninja Frog | Moving on walls | **Wall Slide + Wall Jump**, plus a short **Shadow Phase** that makes them invincible for 0.6 s and lets them pass through spikes and saws. | Normal stats |

**How the stats will be set up:** all numbers live in one data class, `CharacterStats` (speed, jump force, gravity scale, max HP, ability cooldown). That way, rebalancing a hero means editing numbers, not code.

```dart
// lib/data/characters.dart
enum HeroId { bubbleTrouper, finalCall, mastiTime, blueNinja }
class CharacterStats { final double moveSpeed, jumpForce, gravityScale; final int maxHp; final Duration cooldown; ... }
```

Each ability is its own class built on a shared base, `Ability` (`onActivate`, `update`, `cooldown`). The player holds one of these. This is the Strategy pattern: adding a fifth hero later means adding one new class.

---

## 2. Game flow

```
Splash → Main Menu → Level Select (shows locked/unlocked + stars)
       → Character Select (4 cards with stats + ability preview)
       → Level (HUD: hearts, fruits, timer, ability cooldown)
            ├─ Pause menu (resume / restart / change hero / quit)
            ├─ Death → respawn at checkpoint (or restart)
            └─ Reach the end flag → Level Complete (1–3 stars) → next level
```

- **Stars:** ⭐ for finishing, ⭐ for collecting every fruit, ⭐ for beating the target time.
- **Progress** is saved on the device: unlocked levels, best stars, best times. This uses `shared_preferences`, behind a `SaveRepository` interface so the storage can be swapped later.
- Menus and the HUD are Flutter widgets drawn on top of the game (Flame `overlays`), not canvas drawing. This is Flame's standard approach and makes them easy to style and test.

---

## 3. Fun factor: what makes it fun

1. **Good-feeling controls:** coyote time (100 ms), jump buffering (100 ms), variable jump height, and capped fall speed.
2. **Juice:** dust particles when running and landing, a small squash and stretch, screen shake on hits, a short freeze-frame when an enemy is defeated, and confetti at the finish (the assets are already there).
3. **Hero choice matters:** each level has one main route anyone can finish, plus a **secret route for each hero** with bonus fruit. That gives a reason to replay with every character.
4. **Variety:** each world adds new traps (saws, fans, falling platforms, trampolines, Spike Heads, Rock Heads, fire, ice/mud). All of these assets are already in `assets/images/Traps/`.
5. **Enemies:** simple patrol and chase enemies. Only Masti Time can defeat them directly; everyone else stomps on them Mario-style or avoids them.
6. **Sound:** background music and sound effects through `flame_audio`. This needs sound assets, which aren't in the project yet (see §8).

---

## 4. Level roadmap (made in Tiled)

| World | Levels | Theme / new mechanic | Background |
|---|---|---|---|
| 1. Green Meadow | 1–3 | Tutorial: run, jump, fruits, checkpoints, saws | Green |
| 2. Fan Factory | 4–6 | Fans, trampolines, moving platforms | Blue |
| 3. Spike Caverns | 7–9 | Spikes, Spike Heads, falling platforms (Blue Ninja shines) | Gray |
| 4. Rock Ruins | 10–12 | Rock Heads, boxes, enemies (Masti Time shines) | Brown |
| 5. Fire Rush | 13–15 | Fire, timed runs (Final Call shines) | Yellow/Pink |
| Boss | 16 | Uses all mechanics | Purple |

**Rules for every level file (`.tmx`):**
- Layers: `Background`, `Terrain` (tiles), `Collisions` (objects: `Block` / `Platform` / `Wall`), and `Spawnpoints` (objects: `Player`, `Fruit`, `Saw`, `Checkpoint`, `Enemy`, `Trampoline`, `Fan`, `End`, …).
- Custom properties on objects (for example a saw's `offNeg`/`offPos`, or a fruit's `type`) are read in `Level`. Level designers then don't need to touch code.
- The level's own properties set `backgroundColor`, `targetTime` and `world`.

---

## 5. Architecture (industry-standard Flame layout)

```
lib/
  main.dart                    // bootstraps the app and the game
  app/                         // MaterialApp, routes, theme
  game/
    pixel_peep_game.dart       // FlameGame: owns camera, input, loads level
    game_state.dart            // current level, hero, score (ChangeNotifier/ValueNotifier)
  components/
    actors/player.dart         // movement, physics, state machine
    actors/enemies/*.dart
    abilities/ability.dart + bubble_float.dart, dash.dart, ground_pound.dart, wall_jump.dart
    hazards/ saw.dart, spike.dart, fan.dart, falling_platform.dart ...
    collectibles/ fruit.dart, checkpoint.dart, end_flag.dart
    level/level.dart, collision_block.dart
    hud/ joystick + action buttons
  data/ characters.dart, levels.dart (level list + metadata)
  services/ audio_service.dart, save_repository.dart
  ui/overlays/ main_menu, level_select, character_select, hud, pause, level_complete, game_over
test/ unit tests for physics helpers, stats, save repo; widget tests for overlays
```

**Main technical decisions:**
- **Collisions:** keep the current lightweight AABB check for terrain, since it's deterministic and fast. Use Flame's `CollisionCallbacks` and hitboxes for things like fruit, hazards and enemies.
- **Physics:** a fixed timestep, so jumps behave the same on every device. Gravity, jump and speed come from `CharacterStats`.
- **Player behaviour:** a state machine with idle / run / jump / fall / hit / wallSlide / doubleJump / appearing / disappearing. The sprite sheets for all of these already exist.
- **Input:** keyboard (WASD / arrows / Space / E) and touch (joystick plus Jump and Ability buttons), both feeding one shared `InputState`.
- **State management:** `ValueNotifier`s inside the game, which the overlays listen to. No heavy state library is needed.
- **Code quality:** `flutter_lints` with stricter rules, `dart format`, and the rule "no magic numbers": everything goes in constants or data classes.

---

## 6. Problems in the current code (fix first)

1. In `player.dart`, `_checkHorizontalCollisions` checks `velocity.x > 0` twice. The second check should be `< 0`, and it should use `block.x + block.width`, not `+ width`.
2. `utils.dart` swaps width and height (`blockHeight = block.width`).
3. There's no gravity or vertical collision yet. The player can't jump or fall.
4. `pixel_peep.dart` loads `HUD/Knob.png`, but there is **no `assets/images/HUD/` folder**. This will crash on mobile.
5. `main.dart` creates `PixelPeep()` twice.
6. `debugMode = true` is hard-coded. It should only be on when `kDebugMode` is true.
7. In `pubspec.yaml`, only some image folders are listed. `Background`, `Items`, `Traps`, `Menu` and `Other` are missing, so their images won't load.
8. The project's spawn layer is named `spawnPoints`. That name needs to stay the same between code and Tiled files.

---

## 7. Milestones

All milestones are implemented. Each one is a separate pull request, stacked on the previous one.

| # | Milestone | Status |
|---|---|---|
| M1 | Core movement: gravity, jumping, collisions, coyote time, jump buffering | ✅ |
| M2 | Level objects: fruit, checkpoints, finish, saws, spikes, respawn, camera | ✅ |
| M3 | Four heroes: `CharacterStats` plus the four abilities | ✅ |
| M4 | UI: menus, level select, character select, HUD, pause, saved progress | ✅ |
| M5 | Content: 16 levels with hero-specific secrets | ✅ |
| M6 | Enemies and traps: slime, bat, golem, boss, fans, trampolines, falling platforms, fire, crates | ✅ |
| M7 | Polish: dust, screen shake, hit-stop, confetti, level banner, music | ✅ |

**Next ideas:** hand-drawn art pass on the levels in Tiled, achievements, more bosses, and online leaderboards (the `SaveRepository` interface is ready for this).

## 8. Assets & decisions (resolved)

- **Touch controls:** drawn in code. `lib/components/hud/virtual_joystick.dart` and `action_button.dart` (Jump and Ability buttons). They only show on Android and iOS.
- **Enemies:** generated by `tool/gen_assets.py` into `assets/images/Enemies/`:
  - Slime: Idle, Run, Hit
  - Bat: Fly, Hit
  - Rock Golem: Walk, Hit
- **Audio:** chiptune sound effects and music loops, also generated by `tool/gen_assets.py`, in `assets/audio/`. Played through `lib/services/audio_service.dart`.
- **Hero → sprite mapping:** confirmed as in §1.
- **Platforms:** Android and Windows first; Web and iOS after.
- **Rive:** deferred. Menus use Flutter animations.

To regenerate the art and sound, run `python tool/gen_assets.py` (needs Pillow).
