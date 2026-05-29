import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool muted = false;

  Future<void> playAsset(String asset) async {
    if (muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // На вебе воспроизведение может не пройти, но это не должно ломать игру.
    }
  }

  Future<void> playClick() => playAsset('sounds/click.mp3');
  Future<void> playCoins() => playAsset('sounds/coins.mp3');
  Future<void> playWeatherChange() async {
    if (muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/click.mp3'));
    } catch (_) {}
  }

  void setMuted(bool value) {
    muted = value;
  }

  void dispose() {
    _player.dispose();
  }
}
