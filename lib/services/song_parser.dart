import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:music_player/models/song.dart';

/// 歌曲解析服务类
class SongParser {
  /// 从文件解析歌曲信息
  Future<Song> parseSongFromFile(File file) async {
    try {
      final String fileName = file.uri.pathSegments.last;
      final String title = fileName.split('.').first;
      
      // 使用audio_metadata_reader库读取音频文件元数据
      final metadata = readMetadata(file, getImage: false);
      
      // 从元数据中提取信息
      String songTitle = metadata.title ?? title;
      String artist = metadata.artist ?? "Unknown Artist";
      String album = metadata.album ?? "Unknown Album";
      int duration = metadata.duration?.inSeconds ?? 0;
      
      return Song(
        title: songTitle,
        artist: artist,
        album: album,
        duration: duration,
      );
    } catch (e) {
      // 错误处理，返回默认歌曲信息
      debugPrint('Error parsing song from file: $e');
      return Song(
        title: "Unknown Title",
        artist: "Unknown Artist",
        album: "Unknown Album",
        duration: 0,
      );
    }
  }
  
  /// 从文件列表解析歌曲信息列表
  Future<List<Song>> parseSongsFromFiles(List<File> files) async {
    final List<Song> songs = [];
    for (final file in files) {
      songs.add(await parseSongFromFile(file));
    }
    return songs;
  }
}