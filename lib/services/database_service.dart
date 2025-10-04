import 'package:music_player/database/database.dart';
import 'package:music_player/models/song.dart' as model;
import 'package:music_player/services/uri_service.dart';
import 'package:drift/drift.dart';

/// 数据库服务类，负责基础的数据库CRUD操作和业务数据转换
class DatabaseService {
  /// 数据库实例
  final AppDatabase _database;

  /// 构造函数
  DatabaseService(this._database);

  /// 获取歌曲总数
  Future<int> getSongCount() async {
    final query = _database.selectOnly(_database.songs)
      ..addColumns([_database.songs.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.songs.id.count()) ?? 0;
  }

  /// 插入歌曲记录
  Future<int> insertSong(SongsCompanion companion) {
    return _database.into(_database.songs).insert(companion);
  }

  /// 批量插入歌曲记录
  Future<void> insertSongsBatch(List<SongsCompanion> companions) async {
    await _database.batch((batch) {
      batch.insertAll(_database.songs, companions);
    });
  }

  /// 查询所有歌曲记录
  Future<List<SongData>> getAllSongs() {
    return _database.select(_database.songs).get();
  }

  /// 分页查询歌曲记录
  Future<List<SongData>> getSongsPaginated({int offset = 0, int limit = 50}) {
    return (_database.select(_database.songs)
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 根据ID查询歌曲
  Future<SongData?> getSongById(int id) {
    return (_database.select(
      _database.songs,
    )..where((song) => song.id.equals(id))).getSingleOrNull();
  }

  /// 根据ID列表查询多首歌曲
  Future<List<SongData>> getSongsByIds(List<int> ids) {
    return (_database.select(
      _database.songs,
    )..where((song) => song.id.isIn(ids))).get();
  }

  /// 更新歌曲信息
  Future<bool> updateSong(SongsCompanion song) {
    return _database.update(_database.songs).replace(song);
  }

  /// 删除歌曲
  Future<int> deleteSong(int id) {
    return (_database.delete(
      _database.songs,
    )..where((song) => song.id.equals(id))).go();
  }

  /// 根据艺术家分页查询歌曲
  Future<List<SongData>> getSongsByArtistPaginated(
    String artist, {
    int offset = 0,
    int limit = 50,
  }) {
    return (_database.select(_database.songs)
          ..where((song) => song.artist.equals(artist))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 根据专辑分页查询歌曲
  Future<List<SongData>> getSongsByAlbumPaginated(
    String album, {
    int offset = 0,
    int limit = 50,
  }) {
    return (_database.select(_database.songs)
          ..where((song) => song.album.equals(album))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 将业务Song对象转换为SongsCompanion
  SongsCompanion toTableCompanion(
    model.Song song, {
    String? resourcePath,
    int? sourceConfigId,
  }) {
    return SongsCompanion(
      title: Value(song.title),
      artist: Value(song.artist),
      album: Value(song.album),
      duration: Value(song.duration),
      resourcePath: Value(resourcePath ?? ''),
      sourceConfigId: Value(sourceConfigId ?? 1), // 默认值为1
      playCount: Value(song.playCount),
      totalPlayTime: Value(song.totalPlayTime),
      favoriteLevel: Value(song.isFavorite ? 1 : 0),
    );
  }

  /// 批量转换歌曲对象为数据库伴随之类
  List<SongsCompanion> toTableCompanions(List<model.Song> songs) {
    return songs.map((song) => toTableCompanion(song)).toList();
  }

  /// 将SongData转换为业务Song对象
  Future<model.Song> fromTable(SongData table) async {
    String? fullUri;

    // 只有当sourceConfigId有效时才构建完整URI
    if (table.sourceConfigId > 0) {
      final sourceConfig = await getSourceConfigById(table.sourceConfigId);
      if (sourceConfig != null) {
        fullUri = UriService.buildFullUri(
          resourcePath: table.resourcePath,
          sourceConfigId: table.sourceConfigId,
          scheme: sourceConfig.scheme,
          config: sourceConfig.config,
        );
      }
    }

    return model.Song(
      title: table.title,
      artist: table.artist,
      album: table.album,
      duration: table.duration,
      resourcePath: table.resourcePath,
      sourceConfigId: table.sourceConfigId,
      playCount: table.playCount,
      totalPlayTime: table.totalPlayTime,
      isFavorite: table.favoriteLevel > 0,
      fullUri: fullUri ?? table.resourcePath,
    );
  }

  /// 批量转换SongData列表为Song对象列表
  Future<List<model.Song>> fromTableList(List<SongData> tables) async {
    final List<model.Song> songs = [];
    for (final table in tables) {
      songs.add(await fromTable(table));
    }
    return songs;
  }

  /// 分页获取歌曲（包含完整URI）并按艺术家过滤
  Future<List<model.Song>> getSongsWithUriByArtistPaginated(
    String artist, {
    int offset = 0,
    int limit = 50,
  }) async {
    final List<SongData> songTables = await getSongsByArtistPaginated(
      artist,
      offset: offset,
      limit: limit,
    );
    return fromTableList(songTables);
  }

  /// 分页获取歌曲（包含完整URI）并按专辑过滤
  Future<List<model.Song>> getSongsWithUriByAlbumPaginated(
    String album, {
    int offset = 0,
    int limit = 50,
  }) async {
    final List<SongData> songTables = await getSongsByAlbumPaginated(
      album,
      offset: offset,
      limit: limit,
    );
    return fromTableList(songTables);
  }

  /// 获取所有歌曲（包含完整URI）
  Future<List<model.Song>> getAllSongsWithUri() async {
    final List<SongData> songTables = await getAllSongs();
    return fromTableList(songTables);
  }

  /// 分页获取歌曲（包含完整URI）
  Future<List<model.Song>> getSongsWithUriPaginated({
    int offset = 0,
    int limit = 50,
  }) async {
    final List<SongData> songTables = await getSongsPaginated(
      offset: offset,
      limit: limit,
    );
    return fromTableList(songTables);
  }

  /// 搜索歌曲
  Future<List<model.Song>> searchSongs(String query) async {
    final List<SongData> allSongs = await getAllSongs();
    final List<SongData> filteredSongs = allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return fromTableList(filteredSongs);
  }

  /// 迁移现有数据
  Future<void> migrateExistingSongs(List<model.Song> existingSongs) async {
    for (final song in existingSongs) {
      final companion = toTableCompanion(song);
      await insertSong(companion);
    }
  }

  /// 获取歌曲及统计信息
  Future<Map<String, dynamic>?> getSongWithStats(int songId) async {
    final songTable = await getSongById(songId);
    if (songTable == null) return null;

    final song = await fromTable(songTable);

    return {
      'song': song,
      'playCount': songTable.playCount,
      'totalPlayTime': songTable.totalPlayTime,
    };
  }

  /// 获取热门歌曲（按播放次数排序）
  Future<List<model.Song>> getPopularSongs({int limit = 20}) async {
    final allSongs = await getAllSongs();

    // 按播放次数排序
    allSongs.sort((a, b) => b.playCount.compareTo(a.playCount));

    // 限制返回数量
    final limitedSongs = allSongs.take(limit).toList();

    // 返回排序后的歌曲列表
    return fromTableList(limitedSongs);
  }

  /// 增加歌曲播放次数
  Future<void> incrementPlayCount(int songId, {int playTime = 0}) async {
    final song = await getSongById(songId);
    if (song != null) {
      await updateSong(
        SongsCompanion(
          id: Value(song.id),
          title: Value(song.title),
          artist: Value(song.artist),
          album: Value(song.album),
          duration: Value(song.duration),
          resourcePath: Value(song.resourcePath),
          sourceConfigId: Value(song.sourceConfigId),
          playCount: Value(song.playCount + 1),
          totalPlayTime: Value(song.totalPlayTime + playTime),
          favoriteLevel: Value(song.favoriteLevel),
        ),
      );
    }
  }

  /// 创建播放列表
  Future<int> createPlaylist(PlaylistsCompanion companion) {
    return _database.into(_database.playlists).insert(companion);
  }

  /// 查询所有播放列表
  Future<List<PlaylistData>> getAllPlaylists() {
    return _database.select(_database.playlists).get();
  }

  /// 根据ID查询播放列表
  Future<PlaylistData?> getPlaylistById(int id) {
    return (_database.select(
      _database.playlists,
    )..where((playlist) => playlist.id.equals(id))).getSingleOrNull();
  }

  /// 更新播放列表
  Future<bool> updatePlaylist(PlaylistsCompanion playlist) {
    return _database.update(_database.playlists).replace(playlist);
  }

  /// 删除播放列表
  Future<int> deletePlaylist(int id) {
    return (_database.delete(
      _database.playlists,
    )..where((playlist) => playlist.id.equals(id))).go();
  }

  /// 插入数据源配置
  Future<int> insertSourceConfig(SourceConfigsCompanion companion) {
    return _database.into(_database.sourceConfigs).insert(companion);
  }

  /// 根据ID查询数据源配置
  Future<SourceConfigData?> getSourceConfigById(int id) {
    return (_database.select(
      _database.sourceConfigs,
    )..where((config) => config.id.equals(id))).getSingleOrNull();
  }

  /// 查询所有数据源配置
  Future<List<SourceConfigData>> getAllSourceConfigs() {
    return _database.select(_database.sourceConfigs).get();
  }

  /// 更新数据源配置
  Future<bool> updateSourceConfig(SourceConfigsCompanion config) {
    return _database.update(_database.sourceConfigs).replace(config);
  }

  /// 删除数据源配置
  Future<int> deleteSourceConfig(int id) {
    return (_database.delete(
      _database.sourceConfigs,
    )..where((config) => config.id.equals(id))).go();
  }

  /// 插入播放列表歌曲关联
  Future<int> insertPlaylistSong(PlaylistSongsCompanion companion) {
    return _database.into(_database.playlistSongs).insert(companion);
  }

  /// 从播放列表中移除歌曲
  Future<int> removeSongFromPlaylist(int playlistId, int songId) {
    return (_database.delete(_database.playlistSongs)..where(
          (tbl) =>
              tbl.playlistId.equals(playlistId) & tbl.songId.equals(songId),
        ))
        .go();
  }
}
