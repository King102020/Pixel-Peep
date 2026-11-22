import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/save_repository.dart';
import 'package:pixel_peep/ui/overlays.dart';
import 'package:pixel_peep/ui/rotate_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  final save = await SharedPrefsSaveRepository.load();
  final game = PixelPeep(save: save);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixel Peep',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: RotateGuard(
          game: game,
          child: GameWidget<PixelPeep>(
            game: game,
            overlayBuilderMap: Overlays.builders,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    ),
  );
}
