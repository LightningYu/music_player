import 'package:media_kit/media_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:music_player/models/song.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';

/// 音频播放管理器，负责处理歌曲播放逻辑
class AudioPlayerManager {
  /// 单例实例
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  /// 音频播放器实例
  late Player _player;

  /// 当前播放状态
  PlaybackState _playbackState = PlaybackState.idle;

  /// 当前播放的歌曲
  Song? _currentSong;

  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal() {
    MediaKit.ensureInitialized();

    // 初始化 media_kit player
    _player = Player();

    // 监听播放器状态变化
    _player.stream.playing.listen((playing) {
      if (playing) {
        _playbackState = PlaybackState.playing;
      } else {
        _playbackState = PlaybackState.paused;
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _playbackState = PlaybackState.stopped;
      }
    });

    _player.stream.error.listen((error) {
      debugPrint('Playback error: $error');
      _playbackState = PlaybackState.error;
    });
  }

  /// 播放歌曲
  ///
  /// 该方法会根据歌曲信息和数据源配置构建完整URI并播放歌曲
  Future<void> play(
    Song song,
    SourceConfigProvider sourceConfigProvider,
  ) async {
    try {
      // 如果正在播放同一首歌曲，则忽略
      if (_currentSong?.sourceConfigId == song.sourceConfigId &&
          _playbackState == PlaybackState.playing) {
        return;
      }

      // 更新当前歌曲
      _currentSong = song;

      // 获取SourceConfig
      var sourceConfig = sourceConfigProvider.getSourceConfigById(
        song.sourceConfigId,
      );

      // 如果sourceConfig为空，无法播放
      if (sourceConfig == null) {
        debugPrint(
          'Could not find source config for song: ${song.sourceConfigId}',
        );
        _playbackState = PlaybackState.error;
        return;
      }

      // 构建完整URI
      final fullUri = Uri.parse(p.join(sourceConfig.uri, song.resourcePath));

      // 设置播放状态为加载中
      _playbackState = PlaybackState.loading;

      // 使用media_kit播放歌曲
      await _player.open(Media(fullUri.toString()));
      await _player.play();

      // 播放状态将通过监听器自动更新
    } catch (e) {
      debugPrint('Error playing song: $e');
      _playbackState = PlaybackState.error;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _player.stop();
      _playbackState = PlaybackState.stopped;
      _currentSong = null;
    } catch (e) {
      debugPrint('Error stopping player: $e');
      _playbackState = PlaybackState.error;
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      await _player.pause();
      _playbackState = PlaybackState.paused;
    } catch (e) {
      debugPrint('Error pausing player: $e');
      _playbackState = PlaybackState.error;
    }
  }

  /// 恢复播放
  Future<void> resume() async {
    try {
      await _player.play();
      _playbackState = PlaybackState.playing;
    } catch (e) {
      debugPrint('Error resuming player: $e');
      _playbackState = PlaybackState.error;
    }
  }

  /// 获取当前播放状态
  PlaybackState get currentState => _playbackState;

  /// 获取当前播放的歌曲
  Song? get currentSong => _currentSong;
}

enum PlaybackState { idle, loading, playing, paused, stopped, error }
