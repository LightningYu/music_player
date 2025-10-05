import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:music_player/database/database.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/services/database_service.dart';
import 'package:drift/drift.dart';

/// 数据源配置提供者，管理所有数据源配置
class SourceConfigProvider with ChangeNotifier {
  /// 数据库服务
  late final DatabaseService _databaseService;

  /// 数据库
  late final AppDatabase _database;

  /// 数据源配置列表
  List<SourceConfig> _sourceConfigs = [];

  /// 是否正在加载数据
  bool _isLoading = false;

  /// 构造函数，通过依赖注入提供数据库实例
  SourceConfigProvider(AppDatabase database) {
    _database = database;
    _databaseService = DatabaseService(_database);
    // 加载数据源配置
    loadSourceConfigs();
  }

  /// 从数据库加载数据源配置
  Future<void> loadSourceConfigs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<SourceConfigData> sourceConfigTables = 
          await _databaseService.getAllSourceConfigs();
      
      _sourceConfigs = sourceConfigTables
          .map((table) => _databaseService.fromSourceConfigTable(table))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading source configs: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取所有数据源配置
  List<SourceConfig> get sourceConfigs => _sourceConfigs;

  /// 获取数据库服务
  DatabaseService get databaseService => _databaseService;

  /// 是否正在加载数据
  bool get isLoading => _isLoading;

  /// 根据ID获取数据源配置
  SourceConfig? getSourceConfigById(int id) {
    try {
      return _sourceConfigs.firstWhere((config) => config.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建本地文件数据源配置
  Future<SourceConfig?> createLocalFileSourceConfig(String folderPath, {bool includeSubfolders = false}) async {
    try {
      // 创建配置JSON
      final configMap = {
        'folderPath': folderPath,
        'includeSubfolders': includeSubfolders,
      };
      
      final configJson = json.encode(configMap);
      
      // 使用文件夹名称作为数据源名称
      final folderName = folderPath.split(RegExp(r'[/\\]')).last;
      
      // 创建新的本地文件数据源配置
      final id = await _databaseService.insertSourceConfig(
        SourceConfigsCompanion(
          scheme: Value(SourceSchemeType.file), // 使用SourceSchemeType.file枚举值
          name: Value(folderName),
          config: Value(configJson),
          isEnabled: Value(true),
        ),
      );

      // 重新加载数据源配置
      await loadSourceConfigs();

      // 返回新创建的配置
      return getSourceConfigById(id);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating local file source config: $e');
      }
      return null;
    }
  }

  /// 创建网络数据源配置
  Future<SourceConfig?> createNetworkSourceConfig(String name, String baseUrl) async {
    try {
      // 创建网络数据源配置
      final configMap = {
        'baseUrl': baseUrl,
      };
      
      final configJson = json.encode(configMap);
      
      final id = await _databaseService.insertSourceConfig(
        SourceConfigsCompanion(
          scheme: Value(SourceSchemeType.webdav), // 使用SourceSchemeType.webdav枚举值
          name: Value(name),
          config: Value(configJson),
          isEnabled: Value(true),
        ),
      );

      // 重新加载数据源配置
      await loadSourceConfigs();

      // 返回新创建的配置
      return getSourceConfigById(id);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating network source config: $e');
      }
      return null;
    }
  }

  /// 插入数据源配置
  Future<int> insertSourceConfig(SourceConfigsCompanion sourceConfig) async {
    try {
      final id = await _databaseService.insertSourceConfig(sourceConfig);
      
      // 重新加载数据源配置
      await loadSourceConfigs();
      
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting source config: $e');
      }
      rethrow;
    }
  }

  /// 更新数据源配置
  Future<bool> updateSourceConfig(SourceConfig config) async {
    try {
      final success = await _databaseService.updateSourceConfig(
        SourceConfigsCompanion(
          id: Value(config.id),
          scheme: Value(config.scheme),
          name: Value(config.name),
          config: Value(config.config),
          isEnabled: Value(config.isEnabled),
        ),
      );

      if (success) {
        // 重新加载数据源配置
        await loadSourceConfigs();
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating source config: $e');
      }
      return false;
    }
  }

  /// 删除数据源配置
  Future<bool> deleteSourceConfig(int id) async {
    try {
      final result = await _databaseService.deleteSourceConfig(id);

      if (result > 0) {
        // 重新加载数据源配置
        await loadSourceConfigs();
      }

      return result > 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting source config: $e');
      }
      return false;
    }
  }
}