import 'package:music_player/data/repositories/song_repository.dart';
import 'package:music_player/models/song.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/services/database_service.dart';
import 'package:music_player/database/database.dart';

/// 歌曲仓库实现类，实现了SongRepository接口
class SongRepositoryImpl implements SongRepository {
  /// 数据库服务
  final DatabaseService _databaseService;

  /// 构造函数
  SongRepositoryImpl(this._databaseService);

  @override
  Future<List<Song>> getAllSongsWithUri() {
    return _databaseService.getAllSongsWithUri();
  }

  @override
  Future<List<Song>> getSongsWithUriPaginated({
    int offset = 0,
    int limit = 50,
  }) {
    return _databaseService.getSongsWithUriPaginated(offset: offset, limit: limit);
  }

  @override
  Future<List<Song>> getSongsWithUriByArtistPaginated(
    String artist, {
    int offset = 0,
    int limit = 50,
  }) {
    return _databaseService.getSongsWithUriByArtistPaginated(artist, offset: offset, limit: limit);
  }

  @override
  Future<List<Song>> getSongsWithUriByAlbumPaginated(
    String album, {
    int offset = 0,
    int limit = 50,
  }) {
    return _databaseService.getSongsWithUriByAlbumPaginated(album, offset: offset, limit: limit);
  }

  @override
  Future<List<Song>> searchSongs(String query) {
    return _databaseService.searchSongs(query);
  }

  @override
  Future<int> getSongCount() {
    return _databaseService.getSongCount();
  }

  @override
  Future<Song?> getSongById(int id) async {
    final songData = await _databaseService.getSongById(id);
    if (songData != null) {
      // 因为DatabaseService中已经有fromTable方法可以转换SongData为Song，
      // 但这里我们需要调用它。由于SongProvider只需要Song对象，
      // 我们可以通过getAllSongsWithUri等方法间接获取Song对象。
      final songs = await _databaseService.fromTableList([songData]);
      return songs.isNotEmpty ? songs.first : null;
    }
    return null;
  }

  @override
  Future<void> incrementPlayCount(int songId, {int playTime = 0}) {
    return _databaseService.incrementPlayCount(songId, playTime: playTime);
  }

  @override
  Future<List<Song>> getPopularSongs({int limit = 20}) {
    return _databaseService.getPopularSongs(limit: limit);
  }
  
  @override
  SongsCompanion toTableCompanion(
    Song song, {
    String? resourcePath,
    int? sourceConfigId,
  }) {
    return _databaseService.toTableCompanion(song, resourcePath: resourcePath, sourceConfigId: sourceConfigId);
  }
  
  @override
  List<SongsCompanion> toTableCompanions(List<Song> songs) {
    return _databaseService.toTableCompanions(songs);
  }
  
  @override
  Future<void> insertSongsBatch(List<SongsCompanion> companions) {
    return _databaseService.insertSongsBatch(companions);
  }
  
  @override
  Future<SourceConfig?> getSourceConfigById(int id) async {
    final sourceConfigData = await _databaseService.getSourceConfigById(id);
    if (sourceConfigData != null) {
      return _databaseService.fromSourceConfigTable(sourceConfigData);
    }
    return null;
  }
}