import 'package:music_player/models/song.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/database/database.dart';

/// 歌曲仓库接口，定义歌曲相关的数据操作方法
abstract class SongRepository {
  /// 获取所有歌曲（包含完整URI）
  Future<List<Song>> getAllSongsWithUri();

  /// 分页获取歌曲（包含完整URI）
  Future<List<Song>> getSongsWithUriPaginated({
    int offset = 0,
    int limit = 50,
  });

  /// 根据艺术家分页获取歌曲（包含完整URI）
  Future<List<Song>> getSongsWithUriByArtistPaginated(
    String artist, {
    int offset = 0,
    int limit = 50,
  });

  /// 根据专辑分页获取歌曲（包含完整URI）
  Future<List<Song>> getSongsWithUriByAlbumPaginated(
    String album, {
    int offset = 0,
    int limit = 50,
  });

  /// 搜索歌曲
  Future<List<Song>> searchSongs(String query);

  /// 获取歌曲总数
  Future<int> getSongCount();

  /// 根据ID获取歌曲详情
  Future<Song?> getSongById(int id);

  /// 增加歌曲播放次数
  Future<void> incrementPlayCount(int songId, {int playTime = 0});

  /// 获取热门歌曲（按播放次数排序）
  Future<List<Song>> getPopularSongs({int limit = 20});
  
  /// 将业务Song对象转换为SongsCompanion
  SongsCompanion toTableCompanion(
    Song song, {
    String? resourcePath,
    int? sourceConfigId,
  });
  
  /// 批量转换歌曲对象为数据库伴随之类
  List<SongsCompanion> toTableCompanions(List<Song> songs);
  
  /// 批量插入歌曲记录
  Future<void> insertSongsBatch(List<SongsCompanion> companions);
  
  /// 根据ID查询数据源配置
  Future<SourceConfig?> getSourceConfigById(int id);
}