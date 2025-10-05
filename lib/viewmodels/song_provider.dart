import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:music_player/viewmodels/app_settings.dart';
import 'package:music_player/models/song.dart';
import 'package:music_player/services/file_service.dart';
import 'package:music_player/services/song_parser.dart';
import 'package:music_player/database/database.dart';
import 'package:music_player/data/repositories/song_repository.dart';
import 'package:music_player/data/repositories/song_repository_impl.dart';
import 'package:music_player/services/database_service.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';
import 'package:music_player/services/audio_player_manager.dart';

/// 歌曲数据提供者，管理歌曲列表和当前选中歌曲
class SongProvider with ChangeNotifier {
  /// 当前选中的歌曲索引
  int _currentSongIndex = 0;

  /// 文件处理服务
  final FileService _fileService = FileService();

  /// 歌曲解析服务
  final SongParser _songParser = SongParser();

  /// 数据库服务
  late final DatabaseService _databaseService;

  /// 歌曲仓库
  late final SongRepository _songRepository;

  /// 数据库
  late final AppDatabase _database;

  /// 歌曲列表
  List<Song> _songs = [];

  /// 分页相关状态
  int _currentOffset = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  /// 应用设置
  final AppSettings _appSettings = AppSettings();

  /// 构造函数，通过依赖注入提供数据库实例
  SongProvider(AppDatabase database) {
    _database = database;
    _databaseService = DatabaseService(_database);
    _songRepository = SongRepositoryImpl(_databaseService);
    // 监听设置变化
    _appSettings.addListener(_onSettingsChanged);
    // 加载歌曲数据
    _loadSongs();
  }

  /// 设置变化回调
  void _onSettingsChanged() {
    _loadSongs();
  }

  /// 从数据库加载歌曲数据
  Future<void> _loadSongs() async {
    if (_appSettings.paginationEnabled) {
      await _loadInitialSongs();
    } else {
      await _loadAllSongs();
    }
  }

  /// 从数据库加载初始歌曲数据（分页模式）
  Future<void> _loadInitialSongs() async {
    try {
      _songs = await _songRepository.getSongsWithUriPaginated(
        offset: 0,
        limit: _appSettings.pageSize,
      );

      // 更新分页状态
      _currentOffset = _songs.length;
      _hasMoreData = _songs.length == _appSettings.pageSize;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading initial songs: $e');
      }
    }
  }

  /// 加载所有歌曲数据（非分页模式）
  Future<void> _loadAllSongs() async {
    try {
      _songs = await _songRepository.getAllSongsWithUri();
      _hasMoreData = false;
      _currentOffset = _songs.length;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading all songs: $e');
      }
    }
  }

  /// 加载更多歌曲数据
  Future<void> loadMoreSongs() async {
    // 如果没有更多数据或正在加载中，则直接返回
    if (!_hasMoreData || _isLoadingMore) return;

    // 设置加载状态
    _isLoadingMore = true;
    notifyListeners();

    try {
      final moreSongs = await _songRepository.getSongsWithUriPaginated(
        offset: _currentOffset,
        limit: _appSettings.pageSize,
      );

      // 更新歌曲列表和分页状态
      _songs.addAll(moreSongs);
      _currentOffset = _songs.length;
      _hasMoreData = moreSongs.length == _appSettings.pageSize;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading more songs: $e');
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 获取所有歌曲
  List<Song> get songs => _songs;

  /// 获取当前选中歌曲索引
  int get currentSongIndex => _currentSongIndex;

  /// 是否还有更多数据
  bool get hasMoreData => _hasMoreData;

  /// 是否正在加载更多数据
  bool get isLoadingMore => _isLoadingMore;

  /// 选择歌曲
  void selectSong(int index) {
    _currentSongIndex = index;
    notifyListeners();
  }

  /// 获取唯一的艺术家列表
  Set<String> getUniqueArtists() {
    return _songs.map((song) => song.artist).toSet();
  }

  /// 获取唯一的专辑列表
  List<String> get albums {
    final albumSet = <String>{};
    for (final song in _songs) {
      albumSet.add(song.album);
    }
    return albumSet.toList();
  }

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String query) async {
    try {
      return await _songRepository.searchSongs(query);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching songs: $e');
      }
      return [];
    }
  }

  /// 获取热门歌曲
  Future<List<Song>> getPopularSongs({int limit = 20}) async {
    try {
      return await _songRepository.getPopularSongs(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting popular songs: $e');
      }
      return [];
    }
  }

  /// 增加歌曲播放次数
  Future<void> incrementPlayCount(int songId, {int playTime = 0}) async {
    try {
      await _songRepository.incrementPlayCount(songId, playTime: playTime);
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing play count: $e');
      }
    }
  }

  /// 切换到下一首歌曲
  void nextSong() {
    if (_songs.isEmpty) return;

    _currentSongIndex = (_currentSongIndex + 1) % _songs.length;
    notifyListeners();
  }

  /// 切换到上一首歌曲
  void previousSong() {
    if (_songs.isEmpty) return;

    _currentSongIndex = (_currentSongIndex - 1 + _songs.length) % _songs.length;
    notifyListeners();
  }

  /// 设置当前歌曲
  void setCurrentSong(int index) {
    if (index >= 0 && index < _songs.length) {
      _currentSongIndex = index;
      notifyListeners();
    }
  }

  /// 切换收藏状态
  void toggleFavorite(int index) {
    if (index >= 0 && index < _songs.length) {
      final song = _songs[index];
      final updatedSong = Song(
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        resourcePath: song.resourcePath,
        sourceConfigId: song.sourceConfigId,
        playCount: song.playCount,
        totalPlayTime: song.totalPlayTime,
        isFavorite: !song.isFavorite,
        fullUri: song.fullUri,
      );

      _songs[index] = updatedSong;
      notifyListeners();
    }
  }

  /// 获取当前歌曲
  Song? get currentSong {
    if (_songs.isEmpty) return null;
    return _songs[_currentSongIndex];
  }

  /// 通过数据源配置添加本地歌曲
  Future<void> addLocalSongsToDataBySourceConfig(int sourceConfigId) async {
    try {
      // 通过文件服务获取歌曲文件
      final List<File> songFiles = await _fileService
          .pickSongFilesFromDirectory();

      // 通过歌曲解析服务解析歌曲信息
      final List<Song> newSongs = await _songParser.parseSongsFromFiles(
        songFiles,
      );

      // 使用数据库服务批量转换并插入歌曲到数据库
      // 为每首歌曲设置正确的sourceConfigId和resourcePath
      final companions = <SongsCompanion>[];
      for (int i = 0; i < newSongs.length; i++) {
        final song = newSongs[i];
        final file = songFiles[i];

        final companion = _databaseService.toTableCompanion(
          song,
          resourcePath: file.path,
          sourceConfigId: sourceConfigId,
        );

        companions.add(companion);
      }

      await _databaseService.insertSongsBatch(companions);

      // 重新加载歌曲列表
      await _loadSongs();

      // 通知监听者数据已更新
      notifyListeners();
    } catch (e) {
      // 错误处理
      if (kDebugMode) {
        debugPrint('Error adding local songs: $e');
      }
    }
  }

  Future<bool> deleteSong(Song song) async {
    try {
      // 注意：这里需要根据实际情况实现删除逻辑
      // 由于我们没有存储歌曲ID，暂时无法实现真实的删除操作
      // 在实际应用中，应该通过歌曲ID删除数据库中的记录

      // 重新加载歌曲列表
      await _loadSongs();

      // 通知监听者数据已更新
      notifyListeners();

      return true;
    } catch (e) {
      // 错误处理
      if (kDebugMode) {
        debugPrint('Error deleting song: $e');
      }
      return false;
    }
  }

  /// 刷新歌曲数据（重新从数据库加载）
  Future<void> refreshSongs() async {
    await _loadSongs();
  }

  /// 根据歌曲ID播放歌曲
  Future<void> playSong(
    int songId,
    SourceConfigProvider sourceConfigProvider,
  ) async {
    try {
      // 查找歌曲
      final song = _songs.firstWhere((s) => s.id == songId);

      // 获取SourceConfig
      var sourceConfig = sourceConfigProvider.getSourceConfigById(
        song.sourceConfigId,
      );

      // 如果sourceConfig为空，则从数据库加载
      if (sourceConfig == null) {
        final sourceConfigData = await _databaseService.getSourceConfigById(
          song.sourceConfigId,
        );
        if (sourceConfigData != null) {
          sourceConfig = _databaseService.fromSourceConfigTable(
            sourceConfigData,
          );
          // 更新sourceConfigProvider中的配置列表
          sourceConfigProvider.loadSourceConfigs();
        }
      }

      // 如果仍然为空，则无法播放
      if (sourceConfig == null) {
        if (kDebugMode) {
          print('Could not find source config for song: $songId');
        }
        return;
      }

      // 调用AudioPlayerManager播放歌曲
      await AudioPlayerManager().play(song, sourceConfigProvider);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing song: $e');
      }
    }
  }
}
