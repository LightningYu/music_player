// import 'package:music_player/models/song.dart' as model;
// import 'package:music_player/services/database_service.dart';
// import 'package:music_player/services/uri_service.dart';
// import 'package:music_player/database/database.dart';
// import 'package:drift/drift.dart';

// /// 歌曲仓库类，负责在业务层Song对象和数据库Table对象之间进行转换
// class SongRepository {
//   /// 数据库服务实例
//   final DatabaseService _databaseService;

//   /// 构造函数
//   SongRepository(this._databaseService);

//   /// 将业务Song对象转换为SongsCompanion
//   SongsCompanion toTableCompanion(model.Song song, {String? resourcePath, int? sourceConfigId}) {
//     return SongsCompanion(
//       title: Value(song.title),
//       artist: Value(song.artist),
//       album: Value(song.album),
//       duration: Value(song.duration),
//       resourcePath: Value(resourcePath ?? ''),
//       sourceConfigId: Value(sourceConfigId ?? 1), // 默认值为1
//       playCount: Value(song.playCount),
//       totalPlayTime: Value(song.totalPlayTime),
//       favoriteLevel: Value(song.isFavorite ? 1 : 0),
//     );
//   }

//   /// 将SongData转换为业务Song对象
//   Future<model.Song> fromTable(SongData table) async {
//     String? fullUri;
    
//     // 只有当sourceConfigId有效时才构建完整URI
//     if (table.sourceConfigId > 0) {
//       final sourceConfig = await _databaseService.getSourceConfigById(table.sourceConfigId);
//       if (sourceConfig != null) {
//         fullUri = UriService.buildFullUri(
//           resourcePath: table.resourcePath,
//           sourceConfigId: table.sourceConfigId,
//           scheme: sourceConfig.scheme,
//           config: sourceConfig.config,
//         );
//       }
//     }
    
//     return model.Song(
//       title: table.title,
//       artist: table.artist,
//       album: table.album,
//       duration: table.duration,
//       resourcePath: table.resourcePath,
//       sourceConfigId: table.sourceConfigId,
//       playCount: table.playCount,
//       totalPlayTime: table.totalPlayTime,
//       isFavorite: table.favoriteLevel > 0,
//       fullUri: fullUri ?? table.resourcePath,
//     );
//   }

//   /// 批量转换SongData列表为Song对象列表
//   Future<List<model.Song>> fromTableList(List<SongData> tables) async {
//     final List<model.Song> songs = [];
//     for (final table in tables) {
//       songs.add(await fromTable(table));
//     }
//     return songs;
//   }

//   /// 获取所有歌曲（包含完整URI）
//   Future<List<model.Song>> getAllSongsWithUri() async {
//     final List<SongData> songTables = await _databaseService.getAllSongs();
//     return fromTableList(songTables);
//   }

//   /// 获取所有歌曲
//   Future<List<model.Song>> getAllSongs() async {
//     final List<SongData> songTables = await _databaseService.getAllSongs();
//     return fromTableList(songTables);
//   }

//   /// 搜索歌曲
//   Future<List<model.Song>> searchSongs(String query) async {
//     final List<SongData> allSongs = await _databaseService.getAllSongs();
//     final List<SongData> filteredSongs = allSongs.where((song) {
//       return song.title.toLowerCase().contains(query.toLowerCase()) ||
//           song.artist.toLowerCase().contains(query.toLowerCase()) ||
//           song.album.toLowerCase().contains(query.toLowerCase());
//     }).toList();
    
//     return fromTableList(filteredSongs);
//   }

//   /// 迁移现有数据
//   Future<void> migrateExistingSongs(List<model.Song> existingSongs) async {
//     for (final song in existingSongs) {
//       final companion = toTableCompanion(song);
//       await _databaseService.insertSong(companion);
//     }
//   }

//   /// 获取歌曲及统计信息
//   Future<Map<String, dynamic>?> getSongWithStats(int songId) async {
//     final songTable = await _databaseService.getSongById(songId);
//     if (songTable == null) return null;

//     final song = await fromTable(songTable);
    
//     return {
//       'song': song,
//       'playCount': songTable.playCount,
//       'totalPlayTime': songTable.totalPlayTime,
//     };
//   }

//   /// 获取热门歌曲（按播放次数排序）
//   Future<List<model.Song>> getPopularSongs() async {
//     final allSongs = await _databaseService.getAllSongs();
    
//     // 按播放次数排序
//     allSongs.sort((a, b) => b.playCount.compareTo(a.playCount));
    
//     // 返回排序后的歌曲列表
//     return fromTableList(allSongs);
//   }
// }