
/// 歌曲数据模型
class Song {
  /// 歌曲ID
  final int id;

  /// 歌曲标题
  final String title;
  
  /// 歌手
  final String artist;
  
  /// 专辑
  final String album;
  
  /// 时长（秒）
  final int duration;
  
  /// 资源路径（相对路径）
  final String? resourcePath;
  
  /// 数据源配置ID
  final int sourceConfigId;
  
  /// 播放次数
  final int playCount;
  
  /// 总播放时长（秒）
  final int totalPlayTime;
  
  /// 是否收藏
  final bool isFavorite;
  
  /// 完整URI（运行时构建）
  String? fullUri;

  /// 构造函数
  Song({
    this.id = 0, // 默认值为0
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.resourcePath,
    this.sourceConfigId = 1, // 默认值为1
    this.playCount = 0,
    this.totalPlayTime = 0,
    this.isFavorite = false,
    this.fullUri,
  });

  /// 格式化时长显示 (mm:ss)
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}