import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:music_player/viewmodels/app_settings.dart';
import 'package:music_player/models/song.dart';
import 'package:music_player/services/file_service.dart';
import 'package:music_player/services/song_parser.dart';
import 'package:music_player/database/database.dart';
import 'package:music_player/services/database_service.dart';

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
      _songs = await _databaseService.getSongsWithUriPaginated(
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
      _songs = await _databaseService.getAllSongsWithUri();
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
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      final moreSongs = await _databaseService.getSongsWithUriPaginated(
        offset: _currentOffset,
        limit: _appSettings.pageSize,
      );
      
      // 更新歌曲列表
      _songs.addAll(moreSongs);
      
      // 更新分页状态
      _currentOffset += moreSongs.length;
      _hasMoreData = moreSongs.length == _appSettings.pageSize;
      _isLoadingMore = false;
      
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('Error loading more songs: $e');
      }
    }
  }

  /// 获取歌曲列表
  List<Song> get songs => _songs;

  /// 获取当前选中歌曲索引
  int get currentSongIndex => _currentSongIndex;

  /// 获取当前选中歌曲
  Song get currentSong => _songs[_currentSongIndex];

  /// 是否有更多数据
  bool get hasMoreData => _hasMoreData;

  /// 是否正在加载更多数据
  bool get isLoadingMore => _isLoadingMore;
  
  /// 是否启用分页
  bool get paginationEnabled => _appSettings.paginationEnabled;
  
  /// 获取页面大小
  int get pageSize => _appSettings.pageSize;

  /// 选择歌曲
  void selectSong(int index) {
    _currentSongIndex = index;
    notifyListeners();
  }

  /// 获取唯一的艺术家列表
  List<String> get artists {
    final artistSet = <String>{};
    for (final song in _songs) {
      artistSet.add(song.artist);
    }
    return artistSet.toList();
  }

  /// 获取唯一的专辑列表
  List<String> get albums {
    final albumSet = <String>{};
    for (final song in _songs) {
      albumSet.add(song.album);
    }
    return albumSet.toList();
  }

  /// 添加本地歌曲
  Future<void> addLocalSongsToData() async {
    try {
      // 通过文件服务获取歌曲文件
      final List<File> songFiles = await _fileService
          .pickSongFilesFromDirectory();

      // 通过歌曲解析服务解析歌曲信息
      final List<Song> newSongs = await _songParser.parseSongsFromFiles(
        songFiles,
      );

      // 使用数据库服务批量转换并插入歌曲到数据库
      final companions = _databaseService.toTableCompanions(newSongs);
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
}