import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  bool muted = false;
  String? _backgroundAsset;

  Future<void> playAsset(String asset) async {
    if (muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // На вебе воспроизведение может не пройти, но это не должно ломать игру.
    }
  }

  Future<void> playBackground(String asset) async {
    _backgroundAsset = asset;
    if (muted) return;
    try {
      await _bgPlayer.stop();
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource(asset));
    } catch (_) {}
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
    if (muted) {
      _player.stop();
      _bgPlayer.stop();
    } else if (_backgroundAsset != null) {
      playBackground(_backgroundAsset!);
    }
  }

  void dispose() {
    _player.dispose();
    _bgPlayer.dispose();
  }
}
