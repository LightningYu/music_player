import 'dart:convert';
import 'package:music_player/models/source_config.dart';

/// URI处理服务类，用于构建完整的资源URI
class UriService {
  /// 构建完整URI（静态方法）
  static String buildFullUri({
    required String resourcePath,
    required int sourceConfigId,
    required SourceSchemeType scheme,
    required String config,
  }) {
    try {
      // 根据协议类型构建完整URI
      switch (scheme) {
        case SourceSchemeType.file:
          // 本地文件协议
          final configMap = jsonDecode(config);
          final basePath = configMap['basePath'] as String? ?? '';
          // 确保路径连接正确
          if (basePath.endsWith('/') || resourcePath.startsWith('/')) {
            return '$basePath$resourcePath';
          } else {
            return '$basePath/$resourcePath';
          }
          
        case SourceSchemeType.smb:
          // SMB协议
          final configMap = jsonDecode(config);
          final host = configMap['host'] as String? ?? '';
          final username = configMap['username'] as String? ?? '';
          final password = configMap['password'] as String? ?? '';
          return 'smb://$username:$password@$host$resourcePath';
          
        case SourceSchemeType.webdav:
          // WebDAV协议
          final configMap = jsonDecode(config);
          final baseUrl = configMap['baseUrl'] as String? ?? '';
          // 确保URL连接正确
          if (baseUrl.endsWith('/') || resourcePath.startsWith('/')) {
            return '$baseUrl$resourcePath';
          } else {
            return '$baseUrl/$resourcePath';
          }
          
        default:
          return resourcePath;
      }
    } catch (e) {
      // 如果解析配置出错，则返回原始资源路径
      return resourcePath;
    }
  }
  
  /// 解析URI获取相关信息（静态方法）
  static UriInfo parseUri(String uri, List<SourceConfigInfo> sourceConfigs) {
    final uriObj = Uri.parse(uri);
    
    // 根据scheme查找对应的sourceConfig
    SourceConfigInfo? matchedConfig;
    
    for (final config in sourceConfigs) {
      // 将int类型的scheme转换为SourceSchemeType
      final scheme = _intToSchemeType(config.scheme);
      if (_schemeTypeToString(scheme) == uriObj.scheme) {
        matchedConfig = config;
        break;
      }
    }
    
    return UriInfo(
      uri: uri,
      scheme: uriObj.scheme,
      sourceConfig: matchedConfig,
      path: uriObj.path,
    );
  }
  
  /// 将int类型的scheme转换为SourceSchemeType枚举
  static SourceSchemeType _intToSchemeType(int value) {
    switch (value) {
      case 0:
        return SourceSchemeType.file;
      case 1:
        return SourceSchemeType.smb;
      case 2:
        return SourceSchemeType.webdav;
      default:
        return SourceSchemeType.unknown;
    }
  }
  
  /// 将SourceSchemeType枚举转换为字符串
  static String _schemeTypeToString(SourceSchemeType type) {
    switch (type) {
      case SourceSchemeType.file:
        return 'file';
      case SourceSchemeType.smb:
        return 'smb';
      case SourceSchemeType.webdav:
        return 'webdav';
      default:
        return 'unknown';
    }
  }
}

/// URI信息类
class UriInfo {
  final String uri;
  final String scheme;
  final SourceConfigInfo? sourceConfig;
  final String path;
  
  UriInfo({
    required this.uri,
    required this.scheme,
    required this.sourceConfig,
    required this.path,
  });
}

/// 数据源配置信息类（用于URI服务）
class SourceConfigInfo {
  final int id;
  final int scheme;
  final String name;
  final String config;
  final bool isEnabled;
  
  SourceConfigInfo({
    required this.id,
    required this.scheme,
    required this.name,
    required this.config,
    required this.isEnabled,
  });
}