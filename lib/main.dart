import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_peep/pixel_peep.dart';
import 'package:pixel_peep/services/save_repository.dart';
import 'package:pixel_peep/ui/overlays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  final save = await SharedPrefsSaveRepository.load();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixel Peep',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget<PixelPeep>(
          game: PixelPeep(save: save),
          overlayBuilderMap: Overlays.builders,
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        ),
      ),
    ),
  );
}
