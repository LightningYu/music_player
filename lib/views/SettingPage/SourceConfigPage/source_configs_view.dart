import 'package:flutter/material.dart';
import 'package:music_player/views/SettingPage/SourceConfigPage/get_source_config_view.dart';
import 'package:provider/provider.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/services/file_service.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:music_player/views/widgets/source_config_list_item.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:music_player/database/database.dart';
import 'package:music_player/services/song_parser.dart';
import 'package:music_player/services/song_importer.dart';

/// 数据源配置列表视图
class SourceConfigsView extends StatefulWidget {
  const SourceConfigsView({super.key});

  @override
  State<SourceConfigsView> createState() => _SourceConfigsViewState();
}

class _SourceConfigsViewState extends State<SourceConfigsView> {
  @override
  void initState() {
    super.initState();
    // 初始化时加载数据源配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sourceConfigProvider = Provider.of<SourceConfigProvider>(
        context,
        listen: false,
      );
      sourceConfigProvider.loadSourceConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据源配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSourceConfigDialog(context),
          ),
        ],
      ),
      body: Consumer<SourceConfigProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sourceConfigs.isEmpty) {
            return _buildEmptyStateView(context);
          }

          return ListView.builder(
            itemCount: provider.sourceConfigs.length,
            itemBuilder: (context, index) {
              final sourceConfig = provider.sourceConfigs[index];
              return SourceConfigListItem(
                sourceConfig: sourceConfig,
                onTap: () => _showSourceConfigDetails(context, sourceConfig),
                onRefresh: () => _refreshSourceConfig(context, sourceConfig),
                onDelete: () => _deleteSourceConfig(context, sourceConfig),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无数据源配置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮添加数据源',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddSourceConfigDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加数据源'),
          ),
        ],
      ),
    );
  }

  /// 显示添加数据源配置对话框
  void _showAddSourceConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择数据源类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('本地文件'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.web),
                title: const Text('WebDAV'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.webdav);
                },
              ),
              ListTile(
                leading: const Icon(Icons.http),
                title: const Text('HTTP'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.http);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('HTTPS'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.https);
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('SMB'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.smb);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('FTP'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.ftp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('LTPP'),
                onTap: () {
                  Navigator.pop(context);
                  _showGetSourceConfigView(context, SourceSchemeType.ltpp);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示数据源配置视图
  void _showGetSourceConfigView(
    BuildContext context,
    SourceSchemeType schemeType,
  ) {
    final fileService = FileService();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GetSourceConfigView(
          fileService: fileService,
          schemeType: schemeType,
          onSourceConfigCreated: (sourceConfig) async {
            // 数据源创建成功后的回调
            final sourceConfigProvider = Provider.of<SourceConfigProvider>(
              context,
              listen: false,
            );

            // 插入数据源配置
            final id = await sourceConfigProvider.insertSourceConfig(
              SourceConfigsCompanion(
                scheme: Value(sourceConfig.scheme),
                name: Value(sourceConfig.name),
                config: Value(sourceConfig.config),
                uri: Value(sourceConfig.uri), // 添加uri字段
                isEnabled: Value(sourceConfig.isEnabled),
              ),
            );

            // 获取新创建的数据源配置
            final newSourceConfig = sourceConfigProvider.getSourceConfigById(id);
            
            if (newSourceConfig != null) {
              try {
                // 创建歌曲导入器并导入歌曲
                final songImporter = SongImporter(
                  fileService: fileService,
                  songParser: SongParser(),
                  databaseService: sourceConfigProvider.databaseService,
                );
                
                // 导入歌曲
                await songImporter.importSongsFromSource(newSourceConfig);
                
                // 通知歌曲提供者重新加载数据
                final songProvider = Provider.of<SongProvider>(
                  context,
                  listen: false,
                );
                songProvider.refreshSongs();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('数据源创建成功，歌曲已导入')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('数据源创建成功，但导入歌曲时出错: $e')),
                  );
                }
              }
            }

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  /// 显示数据源配置详情
  void _showSourceConfigDetails(
    BuildContext context,
    SourceConfig sourceConfig,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceConfig.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('ID: ${sourceConfig.id}'),
                Text('类型: ${_getSchemeDescription(sourceConfig.scheme)}'),
                Text('启用状态: ${sourceConfig.isEnabled ? '已启用' : '已禁用'}'),
                const SizedBox(height: 16),
                const Text('配置详情:'),
                const SizedBox(height: 8),
                Text(sourceConfig.config),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 刷新数据源
  void _refreshSourceConfig(
    BuildContext context,
    SourceConfig sourceConfig,
  ) async {
    final sourceConfigProvider = Provider.of<SourceConfigProvider>(
      context,
      listen: false,
    );

    final fileService = FileService();
    final songImporter = SongImporter(
      fileService: fileService,
      songParser: SongParser(),
      databaseService: sourceConfigProvider.databaseService,
    );

    // 显示加载指示器
    final snackBar = SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 16),
          Text('正在刷新数据源: ${sourceConfig.name}'),
        ],
      ),
      duration: const Duration(seconds: 10),
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    try {
      // 导入歌曲
      await songImporter.importSongsFromSource(sourceConfig);
      
      // 通知歌曲提供者重新加载数据
      final songProvider = Provider.of<SongProvider>(
        context,
        listen: false,
      );
      songProvider.refreshSongs();
      
      if (context.mounted) {
        // 显示成功消息
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据源 "${sourceConfig.name}" 刷新成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // 显示错误消息
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新数据源时出错: $e')),
        );
      }
    }
  }

  /// 删除数据源（带确认对话框）
  void _deleteSourceConfig(
    BuildContext context,
    SourceConfig sourceConfig,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除数据源 "${sourceConfig.name}" 吗？此操作将删除该数据源及其相关歌曲信息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 取消
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 确认删除
                Navigator.of(context).pop(); // 关闭对话框
                
                final sourceConfigProvider = Provider.of<SourceConfigProvider>(
                  context,
                  listen: false,
                );
                
                try {
                  // 删除数据源
                  final success = await sourceConfigProvider.deleteSourceConfig(sourceConfig.id);
                  
                  if (context.mounted) {
                    if (success) {
                      // 通知歌曲提供者重新加载数据
                      final songProvider = Provider.of<SongProvider>(
                        context,
                        listen: false,
                      );
                      songProvider.refreshSongs();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('数据源 "${sourceConfig.name}" 删除成功')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('删除数据源 "${sourceConfig.name}" 失败')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('删除数据源时出错: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  /// 获取协议类型描述
  String _getSchemeDescription(SourceSchemeType scheme) {
    switch (scheme) {
      case SourceSchemeType.file:
        return '本地文件';
      case SourceSchemeType.ltpp:
        return 'LTPP协议';
      case SourceSchemeType.http:
        return 'HTTP协议';
      case SourceSchemeType.https:
        return 'HTTPS协议';
      case SourceSchemeType.webdav:
        return 'WebDAV协议';
      case SourceSchemeType.smb:
        return 'SMB协议';
      case SourceSchemeType.ftp:
        return 'FTP协议';
      default:
        return '未知协议';
    }
  }
}