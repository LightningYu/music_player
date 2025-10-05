import 'dart:convert';

/// 数据源配置模型
class SourceConfig {
  /// 主键ID
  final int id;

  /// 协议类型枚举
  final SourceSchemeType scheme;

  /// 显示名称
  final String name;

  /// JSON配置
  final String config;

  /// 完整URI
  final String uri;

  /// 是否启用
  final bool isEnabled;

  /// 构造函数
  SourceConfig({
    required this.id,
    required this.scheme,
    required this.name,
    required this.config,
    required this.uri,
    this.isEnabled = true,
  });

  /// 获取配置的Map形式
  Map<String, dynamic> get configMap {
    try {
      return json.decode(config) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}

enum SourceSchemeType {
  /// 本地文件
  unknown,
  file,
  ltpp,
  http,
  https,
  webdav,
  smb,
  ftp,
}
