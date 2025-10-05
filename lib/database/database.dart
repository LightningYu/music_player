import 'package:drift/drift.dart';
import 'package:music_player/models/source_config.dart';
part 'database.g.dart';

/// 歌曲表
@DataClassName('SongData')
class Songs extends Table {
  /// 整数，自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 文本，歌曲标题
  TextColumn get title => text()();

  /// 文本，歌手
  TextColumn get artist => text()();

  /// 文本，专辑
  TextColumn get album => text()();

  /// 整数，时长（秒）
  IntColumn get duration => integer()();

  /// 整数，关联source_configs.id
  IntColumn get sourceConfigId => integer().references(SourceConfigs, #id, onDelete: KeyAction.cascade)();

  /// 文本，资源路径
  TextColumn get resourcePath => text()();

  /// 整数，播放次数
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  /// 整数，总播放时长（秒）
  IntColumn get totalPlayTime => integer().withDefault(const Constant(0))();

  /// 整数，喜欢度级别（0-3）
  IntColumn get favoriteLevel => integer().withDefault(const Constant(0))();
}

/// 数据源配置表
@DataClassName('SourceConfigData')
class SourceConfigs extends Table {
  /// 整数，自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 枚举，协议类型
  TextColumn get scheme => textEnum<SourceSchemeType>()();

  /// 文本，显示名称
  TextColumn get name => text()();

  /// 文本，JSON配置
  TextColumn get config => text()();

  /// 文本，完整URI
  TextColumn get uri => text()();

  /// 布尔值，是否启用
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}

/// 用户播放列表表
@DataClassName('PlaylistData')
class Playlists extends Table {
  /// 整数，自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 文本，列表名称
  TextColumn get name => text()();

  /// 整数，歌曲数量
  IntColumn get songCount => integer().withDefault(const Constant(0))();
}

/// 播放列表关联表
@DataClassName('PlaylistSongData')
class PlaylistSongs extends Table {
  /// 整数，关联playlists.id
  IntColumn get playlistId => integer().references(Playlists, #id)();

  /// 整数，关联songs.id
  IntColumn get songId => integer().references(Songs, #id)();

  /// 整数，添加时间戳
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

/// Drift数据库类
@DriftDatabase(tables: [Songs, SourceConfigs, Playlists, PlaylistSongs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(sourceConfigs, sourceConfigs.uri);
        }
      },
    );
  }
}
