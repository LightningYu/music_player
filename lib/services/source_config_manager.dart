// import 'dart:convert';
// import 'package:flutter/rendering.dart';
// import 'package:music_player/database/database.dart';
// import 'package:music_player/models/source_config.dart';
// import 'package:music_player/services/database_service.dart';
// import 'package:music_player/services/file_service.dart';
// import 'package:drift/drift.dart';

// /// 数据源配置管理器，负责处理数据源配置的创建和管理
// class SourceConfigManager {
//   final DatabaseService _databaseService;
//   final FileService _fileService;

//   SourceConfigManager({
//     required DatabaseService databaseService,
//     required FileService fileService,
//   })  : _databaseService = databaseService,
//         _fileService = fileService;

//   /// 创建本地文件数据源配置
//   /// 该方法会调用文件服务选择文件夹，然后创建数据源配置
//   Future<SourceConfig?> createLocalFileSourceConfig({
//     bool includeSubfolders = false,
//   }) async {
//     try {
//       // 通过文件服务选择文件夹
//       final selectedDirectory = await _fileService.pickDirectory();
      
//       if (selectedDirectory == null) {
//         return null; // 用户取消选择
//       }

//       // 解析文件夹名称作为数据源名称
//       final folderName = selectedDirectory.split(RegExp(r'[/\\]')).last;
      
//       // 创建配置JSON
//       final configMap = {
//         'folderPath': selectedDirectory,
//         'includeSubfolders': includeSubfolders,
//       };
      
//       final configJson = json.encode(configMap);
      
//       // 创建新的本地文件数据源配置
//       final id = await _databaseService.insertSourceConfig(
//         SourceConfigsCompanion(
//           scheme: Value(SourceSchemeType.file),
//           name: Value(folderName),
//           config: Value(configJson),
//           isEnabled: const Value(true),
//         ),
//       );

//       // 获取并返回新创建的配置
//       final sourceConfigData = await _databaseService.getSourceConfigById(id);
//       if (sourceConfigData != null) {
//         return SourceConfig(
//           id: sourceConfigData.id,
//           scheme: sourceConfigData.scheme,
//           name: sourceConfigData.name,
//           config: sourceConfigData.config,
//           isEnabled: sourceConfigData.isEnabled,
//         );
//       }

//       return null;
//     } catch (e) {
//       debugPrint('Error creating local file source config: $e');
//       return null;
//     }
//   }

//   /// 创建网络数据源配置
//   Future<SourceConfig?> createNetworkSourceConfig(String name, String baseUrl) async {
//     try {
//       // 创建网络数据源配置
//       final configMap = {
//         'baseUrl': baseUrl,
//       };
      
//       final configJson = json.encode(configMap);
      
//       final id = await _databaseService.insertSourceConfig(
//         SourceConfigsCompanion(
//           scheme: Value(SourceSchemeType.smb), // 1表示网络数据源
//           name: Value(name),
//           config: Value(configJson),
//           isEnabled: const Value(true),
//         ),
//       );

//       // 获取并返回新创建的配置
//       final sourceConfigData = await _databaseService.getSourceConfigById(id);
//       if (sourceConfigData != null) {
//         return SourceConfig(
//           id: sourceConfigData.id,
//           scheme: sourceConfigData.scheme,
//           name: sourceConfigData.name,
//           config: sourceConfigData.config,
//           isEnabled: sourceConfigData.isEnabled,
//         );
//       }

//       return null;
//     } catch (e) {
//       debugPrint('Error creating network source config: $e');
//       return null;
//     }
//   }
// }