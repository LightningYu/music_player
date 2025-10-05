import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// 文件处理服务类
class FileService {
  /// 支持的音频文件扩展名集合
  static const Set<String> _supportedExtensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
    '.aac',
    '.ogg',
    '.wma',
    '.aiff',
    '.aif',
    '.ape',
    '.wv',
    '.mpc',
    '.opus',
  };

  /// 获取用户选择的文件夹路径
  Future<String?> pickDirectory() async {
    try {
      // 选择文件夹
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      // 错误处理
      if (kDebugMode) {
        print('Error picking directory: $e');
      }
      return null;
    }
  }

  /// 获取用户选择的文件夹中的音乐文件路径
  Future<List<File>> pickSongFilesFromDirectory() async {
    try {
      // 选择文件夹
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        final Directory directory = Directory(selectedDirectory);
        final List<FileSystemEntity> entities = directory.listSync();
        final List<File> songFiles = [];
        
        // 遍历文件夹中的音乐文件
        for (final entity in entities) {
          if (entity is File) {
            final String fileName = entity.uri.pathSegments.last;
            final String fileExtension = '.${fileName.split('.').last.toLowerCase()}';
            
            // 检查文件扩展名是否在支持的集合中
            if (_supportedExtensions.contains(fileExtension)) {
              songFiles.add(entity);
            }
          }
        }
        
        return songFiles;
      }
      
      return [];
    } catch (e) {
      // 错误处理
      if (kDebugMode) {
        print('Error picking song files from directory: $e');
      }
      return [];
    }
  }

  /// 获取目录中的音频文件
  Future<List<File>> getAudioFilesFromDirectory(
    String directoryPath, {
    bool includeSubfolders = false,
  }) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        throw Exception('Directory does not exist: $directoryPath');
      }

      final files = <File>[];
      await _getAudioFilesFromDirectoryRecursive(
        dir,
        files,
        includeSubfolders: includeSubfolders,
      );
      return files;
    } catch (e) {
      debugPrint('Error getting audio files from directory: $e');
      rethrow;
    }
  }

  /// 递归获取目录中的音频文件
  Future<void> _getAudioFilesFromDirectoryRecursive(
    Directory directory,
    List<File> files, {
    bool includeSubfolders = false,
  }) async {
    try {
      await for (final entity in directory.list()) {
        if (entity is File) {
          // 检查文件扩展名是否为音频文件
          final extension = entity.path.split('.').last.toLowerCase();
          if (_isAudioFileExtension(extension)) {
            files.add(entity);
          }
        } else if (entity is Directory && includeSubfolders) {
          // 递归处理子目录
          await _getAudioFilesFromDirectoryRecursive(
            entity,
            files,
            includeSubfolders: includeSubfolders,
          );
        }
      }
    } catch (e) {
      debugPrint('Error listing directory contents: $e');
      rethrow;
    }
  }

  /// 检查文件扩展名是否为音频文件
  bool _isAudioFileExtension(String extension) {
    const audioExtensions = {
      'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', 'wma', 'ape', 'alac', 'aiff'
    };
    return audioExtensions.contains(extension);
  }
}