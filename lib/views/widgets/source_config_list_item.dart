import 'package:flutter/material.dart';
import 'package:music_player/models/source_config.dart';

/// 数据源配置列表项组件
class SourceConfigListItem extends StatelessWidget {
  final SourceConfig sourceConfig;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const SourceConfigListItem({
    super.key,
    required this.sourceConfig,
    required this.onTap,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(sourceConfig.name),
        subtitle: Text(_getSchemeDescription(sourceConfig.scheme)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: '删除数据源',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: '刷新数据源',
            ),
            sourceConfig.isEnabled
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  /// 获取协议类型描述
  String _getSchemeDescription(SourceSchemeType scheme) {
    switch (scheme) {
      case SourceSchemeType.http:
        return 'HTTP';
      case SourceSchemeType.https:
        return 'HTTPS';
      case SourceSchemeType.file:
        return '本地文件';
      case SourceSchemeType.unknown:
        return '未知';
      case SourceSchemeType.ltpp:
        return 'LTPP';
      case SourceSchemeType.webdav:
        return 'WebDAV';
      case SourceSchemeType.smb:
        return 'SMB';
      case SourceSchemeType.ftp:
        return 'FTP';
    }
  }
}