import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  static const String _bgmAssetPath =
      'bgms/Moavii - Adventure (freetouse.com).mp3';

  final AudioPlayer _bgmPlayer = AudioPlayer();
  int _pauseRequestCount = 0;
  bool _bgmStarted = false;

  Future<void> startBgm() async {
    if (_bgmStarted) return;

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.35);
    await _bgmPlayer.play(AssetSource(_bgmAssetPath));
    _bgmStarted = true;
  }

  Future<void> pauseBgmForEngineSound() async {
    if (!_bgmStarted) return;

    _pauseRequestCount++;
    if (_pauseRequestCount == 1) {
      await _bgmPlayer.pause();
    }
  }

  Future<void> resumeBgmAfterEngineSound() async {
    if (!_bgmStarted) return;
    if (_pauseRequestCount == 0) return;

    _pauseRequestCount--;
    if (_pauseRequestCount == 0) {
      await _bgmPlayer.resume();
    }
  }
}
