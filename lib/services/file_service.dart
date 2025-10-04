import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

/// 文件处理服务类
class FileService {
  /// 获取用户选择的文件夹中的音乐文件路径
  Future<List<File>> pickSongFilesFromDirectory() async {
    try {
      // 选择文件夹
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory != null) {
        final Directory directory = Directory(selectedDirectory);
        final List<FileSystemEntity> entities = directory.listSync();
        final List<File> songFiles = [];

        // 遍历文件夹中的音乐文件
        for (final entity in entities) {
          if (entity is File) {
            final String fileName = entity.uri.pathSegments.last;
            // 简单的文件扩展名检查
            if (fileName.toLowerCase().endsWith('.mp3') ||
                fileName.toLowerCase().endsWith('.wav') ||
                fileName.toLowerCase().endsWith('.flac') ||
                fileName.toLowerCase().endsWith('.m4a')) {
              songFiles.add(entity);
            }
          }
        }

        return songFiles;
      }

      return [];
    } catch (e) {
      // 错误处理
      debugPrint('Error picking song files from directory: $e');
      return [];
    }
  }
}
