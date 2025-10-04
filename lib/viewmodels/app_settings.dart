import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置管理类
class AppSettings with ChangeNotifier {
  /// 分页相关默认值
  static const bool _defaultPaginationEnabled = true;
  static const int _defaultPageSize = 50;
  
  /// 应用设置键名
  static const String _keyPaginationEnabled = 'pagination_enabled';
  static const String _keyPageSize = 'page_size';
  
  /// 分页设置
  bool _paginationEnabled = _defaultPaginationEnabled;
  int _pageSize = _defaultPageSize;
  
  /// 私有构造函数
  AppSettings._privateConstructor();
  
  /// 单例实例
  static final AppSettings _instance = AppSettings._privateConstructor();
  
  /// 工厂构造函数，返回单例实例
  factory AppSettings() => _instance;
  
  /// 获取分页启用状态
  bool get paginationEnabled => _paginationEnabled;
  
  /// 获取页面大小
  int get pageSize => _pageSize;
  
  /// 初始化设置
  Future<void> init() async {
    await _loadSettings();
  }
  
  /// 从shared preferences加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _paginationEnabled = prefs.getBool(_keyPaginationEnabled) ?? _defaultPaginationEnabled;
    _pageSize = prefs.getInt(_keyPageSize) ?? _defaultPageSize;
  }
  
  /// 保存设置到shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPaginationEnabled, _paginationEnabled);
    await prefs.setInt(_keyPageSize, _pageSize);
  }
  
  /// 设置分页启用状态
  Future<void> setPaginationEnabled(bool enabled) async {
    if (_paginationEnabled != enabled) {
      _paginationEnabled = enabled;
      await _saveSettings();
      notifyListeners();
    }
  }
  
  /// 设置页面大小
  Future<void> setPageSize(int size) async {
    if (_pageSize != size && size > 0) {
      _pageSize = size;
      await _saveSettings();
      notifyListeners();
    }
  }
}