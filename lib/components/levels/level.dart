import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../actors/player.dart';

class Level extends World{

  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;

  @override
  FutureOr<void> onLoad() async{

    level=await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);

    final spawnPointsLayer =level.tileMap.getLayer<ObjectGroup>('spawnPoints');
    if (spawnPointsLayer != null) {
      for (final spawnPoint in spawnPointsLayer!.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
            break;
          default:
        }
      }
    }
    final collisionsLayer =level.tileMap.getLayer<ObjectGroup>('Collision');
    if(collisionsLayer!=null){
      for(final collision in collisionsLayer.objects){
        switch(collision.class_){
          case 'Platform':
            //final platform=
            break;
          default:
        }
      }
    }
    return super.onLoad();
  }
}