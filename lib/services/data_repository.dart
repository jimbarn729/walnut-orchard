import '../engine/game_engine.dart';

class DataRepository {
  Future<void> initialize() async {
    await Future.delayed(Duration(milliseconds: 10));
  }

  Future<void> saveGame(GameEngine engine) async {
    await Future.delayed(Duration(milliseconds: 10));
  }

  Future<void> loadGame(GameEngine engine) async {
    await Future.delayed(Duration(milliseconds: 10));
  }
}
