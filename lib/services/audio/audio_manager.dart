import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  // 🎵 定義你的黑金賽道曲目庫（請確保 assets 中有對應音檔）
  static const Map<String, String> trackMap = {
    '冒險旅程 (預設)': 'bgms/Moavii - Adventure (freetouse.com).mp3',
    '暗夜極速 (Neon)': 'bgms/neon_speed.mp3',
    '午夜極簡 (Lo-Fi)': 'bgms/midnight_lofi.mp3',
  };

  final AudioPlayer _bgmPlayer = AudioPlayer();
  int _pauseRequestCount = 0;
  bool _bgmStarted = false;

  // 記憶播放狀態
  bool _isBgmEnabled = true;
  double _volume = 0.35;
  String _currentTrackName = '冒險旅程 (預設)';

  bool get isBgmEnabled => _isBgmEnabled;
  double get volume => _volume;
  String get currentTrackName => _currentTrackName;
  List<String> get trackNames => trackMap.keys.toList();

  /// 啟動背景音樂
  Future<void> startBgm() async {
    if (_bgmStarted) return;

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    // 如果關閉了 BGM，音量設為 0
    await _bgmPlayer.setVolume(_isBgmEnabled ? _volume : 0.0);
    
    final path = trackMap[_currentTrackName] ?? 'bgms/Moavii - Adventure (freetouse.com).mp3';
    await _bgmPlayer.play(AssetSource(path));
    _bgmStarted = true;
  }

  /// 實時調整音量
  Future<void> setVolume(double vol) async {
    _volume = vol;
    if (_isBgmEnabled) {
      await _bgmPlayer.setVolume(_volume);
    }
  }

  /// 切換 BGM 開關
  Future<void> toggleBgm(bool enabled) async {
    _isBgmEnabled = enabled;
    if (_isBgmEnabled) {
      await _bgmPlayer.setVolume(_volume);
      if (!_bgmStarted) {
        await startBgm();
      } else {
        await _bgmPlayer.resume();
      }
    } else {
      await _bgmPlayer.setVolume(0.0);
      await _bgmPlayer.pause();
    }
  }

  /// 切換不同曲目
  Future<void> changeTrack(String trackName) async {
    if (!trackMap.containsKey(trackName)) return;
    _currentTrackName = trackName;
    
    if (_bgmStarted) {
      await _bgmPlayer.stop();
      _bgmStarted = false;
    }
    await startBgm();
  }

  Future<void> pauseBgmForEngineSound() async {
    if (!_bgmStarted || !_isBgmEnabled) return;

    _pauseRequestCount++;
    if (_pauseRequestCount == 1) {
      await _bgmPlayer.pause();
    }
  }

  Future<void> resumeBgmAfterEngineSound() async {
    if (!_bgmStarted || !_isBgmEnabled) return;
    if (_pauseRequestCount == 0) return;

    _pauseRequestCount--;
    if (_pauseRequestCount == 0) {
      await _bgmPlayer.resume();
    }
  }
}