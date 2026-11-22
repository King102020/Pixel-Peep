# Pixel Peep

A 2D platformer built with Flutter and Flame. Before each level you pick one of four heroes, each with their own special ability, and then try to reach the finish trophy.

| Hero | Strength | Ability |
|---|---|---|
| Bubble Trouper | Jumps highest | Double jump, and hold the ability button to float down |
| Final Call | Fastest runner | Dash through the air and smash crates |
| Masti Time | Most hearts | Punch on the ground, slam from the air; beats any enemy |
| Blue Ninja | Acrobat | Wall slide and wall jump; Shadow Phase makes them invincible for a moment |

There are 16 levels across 5 worlds, ending with a boss fight. Every level can be finished with any hero, and each one hides fruit that only some heroes can reach.

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | ← → or A / D | Joystick |
| Jump | Space (also W / ↑ outside the browser) | ▲ button |
| Ability | E, J or Left Shift | ★ button |
| Pause | Esc or P | Pause button |

In the browser, the arrow keys and W don't jump, because they also scroll the page.

## Run it

```bash
flutter pub get
flutter run -d chrome     # or: -d windows / android device
```

On Windows, building plugins needs Developer Mode (`start ms-settings:developers`).

## Project layout

```
lib/
  pixel_peep.dart          game: camera, level loading, menus flow, shake/hit-stop
  components/
    actors/                player, enemies and boss
    abilities/             one class per hero ability (Strategy pattern)
    hazards/               saws, spikes, fire, fans, trampolines, crates, falling platforms
    items/                 fruit, checkpoints, finish trophy
    effects/               dust, confetti, appear/disappear
    hud/                   on-screen joystick and buttons (drawn in code)
    levels/level.dart      turns Tiled objects into components
  data/                    hero stats and the level list
  game/game_session.dart   live score, hearts, timer (ValueNotifiers)
  services/                audio and saved progress
  ui/                      Flutter overlays: menus, character select, HUD
tool/
  gen_assets.py            generates enemy sprites and chiptune audio
  level_layouts.py         ASCII layouts for levels 3-16
  gen_levels.py            ASCII -> Tiled .tmx
  check_levels.py          checks every level can be finished
```

## Making levels

Levels are normal Tiled maps in `assets/tiles/`, so you can open and edit them in Tiled. For quick block-outs, edit `tool/levels/*.txt` or `tool/level_layouts.py`, then run:

```bash
python tool/level_layouts.py && python tool/check_levels.py && python tool/gen_levels.py
```

Add new levels to `lib/data/levels.dart`.

## Tests

```bash
flutter test
```
