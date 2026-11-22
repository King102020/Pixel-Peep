import 'package:flutter/widgets.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/ui/overlays/character_select.dart';
import 'package:pixel_peep/ui/overlays/hud.dart';
import 'package:pixel_peep/ui/overlays/level_complete.dart';
import 'package:pixel_peep/ui/overlays/level_select.dart';
import 'package:pixel_peep/ui/overlays/main_menu.dart';
import 'package:pixel_peep/ui/overlays/pause_menu.dart';

/// Names of every Flutter overlay drawn on top of the game.
abstract final class Overlays {
  static const mainMenu = 'mainMenu';
  static const levelSelect = 'levelSelect';
  static const characterSelect = 'characterSelect';
  static const hud = 'hud';
  static const pause = 'pause';
  static const levelComplete = 'levelComplete';

  static final Map<String, Widget Function(BuildContext, PixelPeep)> builders = {
    mainMenu: (_, game) => MainMenu(game: game),
    levelSelect: (_, game) => LevelSelect(game: game),
    characterSelect: (_, game) => CharacterSelect(game: game),
    hud: (_, game) => Hud(game: game),
    pause: (_, game) => PauseMenu(game: game),
    levelComplete: (_, game) => LevelComplete(game: game),
  };
}
