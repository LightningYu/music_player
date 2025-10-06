import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:music_player/models/source_config.dart';
import 'package:path/path.dart' as p;
import 'package:music_player/models/song.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';

/// 音频播放管理器，负责处理歌曲播放逻辑
class AudioPlayerManager {
  /// 单例实例
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  /// 音频播放器实例
  late AudioPlayer _player;

  /// 当前播放状态
  PlaybackState _playbackState = PlaybackState.idle;

  /// 当前播放的歌曲
  Song? _currentSong;

  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal() {
    // 初始化 just_audio player
    _player = AudioPlayer();

    // 监听播放器状态变化
    _player.playerStateStream.listen((playerState) {
      if (playerState.playing) {
        _playbackState = PlaybackState.playing;
      } else if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        _playbackState = PlaybackState.loading;
      } else {
        _playbackState = PlaybackState.paused;
      }
    });

    _player.positionStream.listen((position) {
      // 可以在这里添加位置变化的处理逻辑
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _playbackState = PlaybackState.stopped;
      }
    });

    _player.playingStream.listen((isPlaying) {
      if (!isPlaying && _playbackState != PlaybackState.stopped) {
        _playbackState = PlaybackState.paused;
      }
    });

    _player.sequenceStateStream.listen((sequenceState) {});
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
      debugPrint('Playing song: $fullUri');
      // 设置播放状态为加载中
      _playbackState = PlaybackState.loading;
      // 根据协议类型创建不同的AudioSource
      AudioSource audioSource;
      switch (sourceConfig.scheme) {
        case SourceSchemeType.file:
          Uri u = Uri(
            scheme: 'file',
            path: p.join(sourceConfig.uri, song.resourcePath),
          );
          debugPrint('Playing song: $u');
          debugPrint('Path: ${u.toFilePath()}');
          // 本地文件协议
          audioSource = AudioSource.uri(u);
          // audioSource = AudioSource.uri(fullUri);
          break;
        case SourceSchemeType.http:
        case SourceSchemeType.https:
          // HTTP/HTTPS协议
          audioSource = AudioSource.uri(fullUri);
          break;
        case SourceSchemeType.webdav:
          // WebDAV协议
          audioSource = AudioSource.uri(fullUri);
          break;
        case SourceSchemeType.smb:
          // SMB协议
          audioSource = AudioSource.uri(fullUri);
          break;
        case SourceSchemeType.ftp:
          // FTP协议
          audioSource = AudioSource.uri(fullUri);
          break;
        case SourceSchemeType.ltpp:
          // LTPP协议
          audioSource = AudioSource.uri(fullUri);
          break;
        default:
          // 默认处理
          audioSource = AudioSource.uri(fullUri);
      }

      // // 使用just_audio播放歌曲
      _player.setAudioSource(audioSource);
      _player.play();

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
      await _player.seek(Duration.zero);
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
