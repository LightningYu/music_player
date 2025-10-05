import 'package:flutter/foundation.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/services/file_service.dart';
import 'package:music_player/services/song_parser.dart';
import 'package:music_player/services/database_service.dart';
import 'package:music_player/database/database.dart';

/// 歌曲导入器，用于从数据源获取歌曲并添加到数据库
class SongImporter {
  /// 文件服务
  final FileService _fileService;

  /// 歌曲解析服务
  final SongParser _songParser;

  /// 数据库服务
  final DatabaseService _databaseService;

  /// 构造函数
  SongImporter({
    required FileService fileService,
    required SongParser songParser,
    required DatabaseService databaseService,
  })  : _fileService = fileService,
        _songParser = songParser,
        _databaseService = databaseService;

  /// 从本地文件数据源导入歌曲
  Future<void> importSongsFromLocalSource(SourceConfig sourceConfig) async {
    try {
      // 解析配置
      final configMap = sourceConfig.configMap;
      final folderPath = configMap['folderPath'] as String?;
      final includeSubfolders = configMap['includeSubfolders'] as bool? ?? false;

      if (folderPath == null || folderPath.isEmpty) {
        debugPrint('Invalid folder path in source config: ${sourceConfig.id}');
        return;
      }

      // 获取文件夹中的音频文件
      final audioFiles = await _fileService.getAudioFilesFromDirectory(
        folderPath,
        includeSubfolders: includeSubfolders,
      );

      // 解析歌曲信息
      final songs = await _songParser.parseSongsFromFiles(audioFiles);

      // 转换为数据库伴随之类并插入数据库
      final companions = <SongsCompanion>[];
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        final file = audioFiles[i];

        // 计算相对于源文件夹的路径
        final relativePath = file.path
            .replaceFirst(folderPath, '')
            .replaceAll(r'\', '/')
            .replaceFirst(RegExp(r'^/+'), ''); // 移除开头的斜杠
        
        final companion = _databaseService.toTableCompanion(
          song,
          resourcePath: relativePath,
          sourceConfigId: sourceConfig.id,
        );

        companions.add(companion);
      }

      // 批量插入歌曲到数据库
      await _databaseService.insertSongsBatch(companions);

      debugPrint('Successfully imported ${songs.length} songs from source: ${sourceConfig.name}');
    } catch (e) {
      debugPrint('Error importing songs from local source: $e');
      rethrow;
    }
  }

  /// 从网络数据源导入歌曲（占位方法，需要根据具体协议实现）
  Future<void> importSongsFromNetworkSource(SourceConfig sourceConfig) async {
    try {
      // 根据不同的协议类型实现对应的导入逻辑
      switch (sourceConfig.scheme) {
        case SourceSchemeType.webdav:
          // TODO: 实现WebDAV协议的歌曲导入
          debugPrint('WebDAV import not implemented yet');
          break;
        case SourceSchemeType.http:
        case SourceSchemeType.https:
          // TODO: 实现HTTP/HTTPS协议的歌曲导入
          debugPrint('HTTP/HTTPS import not implemented yet');
          break;
        case SourceSchemeType.smb:
          // TODO: 实现SMB协议的歌曲导入
          debugPrint('SMB import not implemented yet');
          break;
        case SourceSchemeType.ftp:
          // TODO: 实现FTP协议的歌曲导入
          debugPrint('FTP import not implemented yet');
          break;
        case SourceSchemeType.ltpp:
          // TODO: 实现LTPP协议的歌曲导入
          debugPrint('LTPP import not implemented yet');
          break;
        default:
          debugPrint('Unsupported network source scheme: ${sourceConfig.scheme}');
      }
    } catch (e) {
      debugPrint('Error importing songs from network source: $e');
      rethrow;
    }
  }

  /// 根据数据源类型导入歌曲
  Future<void> importSongsFromSource(SourceConfig sourceConfig) async {
    switch (sourceConfig.scheme) {
      case SourceSchemeType.file:
        await importSongsFromLocalSource(sourceConfig);
        break;
      case SourceSchemeType.webdav:
      case SourceSchemeType.http:
      case SourceSchemeType.https:
      case SourceSchemeType.smb:
      case SourceSchemeType.ftp:
      case SourceSchemeType.ltpp:
        await importSongsFromNetworkSource(sourceConfig);
        break;
      default:
        debugPrint('Unsupported source scheme: ${sourceConfig.scheme}');
    }
  }
}