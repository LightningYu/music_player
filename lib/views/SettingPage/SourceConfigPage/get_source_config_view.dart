import 'package:flutter/material.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/services/file_service.dart';
import 'dart:convert';

/// 获取数据源配置视图
/// 用于处理用户添加新的数据源配置的界面和逻辑
class GetSourceConfigView extends StatefulWidget {
  final FileService fileService;
  final SourceSchemeType schemeType;
  final Function(SourceConfig sourceConfig)? onSourceConfigCreated;

  const GetSourceConfigView({
    super.key,
    required this.fileService,
    required this.schemeType,
    this.onSourceConfigCreated,
  });

  @override
  State<GetSourceConfigView> createState() => _GetSourceConfigViewState();
}

class _GetSourceConfigViewState extends State<GetSourceConfigView> {
  /// 表单相关状态
  final _formKey = GlobalKey<FormState>();
  String _sourceName = '';
  bool _isLoading = false;
  bool _isNameManuallyChanged = false; // 标记显示名称是否被用户手动修改过

  /// 表单状态管理
  final Map<String, dynamic> _formState = {};

  void _updateFormState(String key, dynamic value) {
    setState(() {
      _formState[key] = value;
    });
  }

  dynamic _getFormState(String key) {
    return _formState[key];
  }

  @override
  void initState() {
    super.initState();
  }

  /// 选择本地文件夹路径
  Future<void> _selectFolder() async {
    try {
      final selectedDirectory = await widget.fileService.pickDirectory();

      if (selectedDirectory != null) {
        setState(() {
          // 只有在用户未手动修改显示名称时，才使用文件夹名称作为默认数据源名称
          if (!_isNameManuallyChanged || _sourceName.isEmpty) {
            _sourceName = selectedDirectory.split(RegExp(r'[/\\]')).last;
            _isNameManuallyChanged = false; // 重置标记
          }
        });

        // 更新表单状态
        _updateFormState('folderPath', selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择文件夹时出错: $e')));
      }
    }
  }

  /// 创建数据源配置
  Future<void> _createSourceConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建配置JSON
      final Map<String, dynamic> configMap = {};

      // 构建URI基础路径（不含协议前缀）
      String basePath = '';
      switch (widget.schemeType) {
        case SourceSchemeType.file:
          configMap['folderPath'] = _getFormState('folderPath') ?? '';
          configMap['includeSubfolders'] =
              _getFormState('includeSubfolders') ?? false;
          basePath = configMap['folderPath'];
          break;
        case SourceSchemeType.webdav:
        case SourceSchemeType.http:
        case SourceSchemeType.https:
          configMap['baseUrl'] = _getFormState('baseUrl') ?? '';
          basePath = configMap['baseUrl'];
          break;
        case SourceSchemeType.smb:
        case SourceSchemeType.ftp:
        case SourceSchemeType.ltpp:
          configMap['host'] = _getFormState('host') ?? '';
          configMap['username'] = _getFormState('username') ?? '';
          configMap['password'] = _getFormState('password') ?? '';
          configMap['port'] = _getFormState('port') ?? 0;
          
          final port = configMap['port'] != 0 ? ':${configMap['port']}' : '';
          basePath = configMap['host'] + port;
          break;
        default:
          configMap['unknown'] = true;
          basePath = '';
      }

      final configJson = json.encode(configMap);

      // 创建SourceConfig对象，只传入基础路径，不包含协议前缀
      final sourceConfig = SourceConfig(
        id: -1, // 新创建的对象还没有ID，会在数据库中分配
        scheme: widget.schemeType,
        name: _sourceName,
        config: configJson,
        uri: basePath, // 只存储基础路径，不包含协议前缀
        isEnabled: true,
      );

      if (mounted) {
        // 回调通知创建成功
        if (widget.onSourceConfigCreated != null) {
          widget.onSourceConfigCreated!(sourceConfig);
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建数据源时出错: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getSchemeDisplayName(widget.schemeType)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 数据源名称
              TextFormField(
                initialValue: _sourceName,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '请输入显示名称',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入显示名称';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _sourceName = value;
                    _isNameManuallyChanged = true; // 标记用户已手动修改
                  });
                },
              ),
              const SizedBox(height: 16),

              // 根据协议类型显示不同的配置字段
              ..._buildConfigFieldsByScheme(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSourceConfig,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }

  /// 根据协议类型构建配置字段
  List<Widget> _buildConfigFieldsByScheme() {
    switch (widget.schemeType) {
      case SourceSchemeType.file:
        return _buildLocalFolderFields();
      case SourceSchemeType.webdav:
      case SourceSchemeType.http:
      case SourceSchemeType.https:
        return _buildWebFields();
      case SourceSchemeType.smb:
      case SourceSchemeType.ftp:
      case SourceSchemeType.ltpp:
        return _buildNetworkFields();
      default:
        return [];
    }
  }

  /// 构建本地文件夹相关字段
  List<Widget> _buildLocalFolderFields() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '文件夹路径',
                hintText: '请选择文件夹',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择文件夹路径';
                }
                return null;
              },
              controller: TextEditingController(
                text: _getFormState('folderPath') ?? '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _selectFolder, child: const Text('选择')),
        ],
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('包含子文件夹'),
        value: _getFormState('includeSubfolders') ?? false,
        onChanged: (value) {
          _updateFormState('includeSubfolders', value ?? false);
        },
      ),
    ];
  }

  /// 构建Web相关字段
  List<Widget> _buildWebFields() {
    return [
      TextFormField(
        initialValue: _getFormState('baseUrl') ?? '',
        decoration: InputDecoration(
          labelText: '基础URL',
          hintText: '例如: ${_getExampleBaseUrl(widget.schemeType)}',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入基础URL';
          }
          return null;
        },
        onChanged: (value) {
          _updateFormState('baseUrl', value);
        },
      ),
    ];
  }

  /// 构建网络相关字段
  List<Widget> _buildNetworkFields() {
    return [
      TextFormField(
        initialValue: _getFormState('host') ?? '',
        decoration: const InputDecoration(
          labelText: '主机地址',
          hintText: '例如: 192.168.1.100',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入主机地址';
          }
          return null;
        },
        onChanged: (value) {
          _updateFormState('host', value);
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: _getFormState('username') ?? '',
        decoration: const InputDecoration(labelText: '用户名'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入用户名';
          }
          return null;
        },
        onChanged: (value) {
          _updateFormState('username', value);
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: _getFormState('password') ?? '',
        decoration: const InputDecoration(labelText: '密码'),
        obscureText: true,
        onChanged: (value) {
          _updateFormState('password', value);
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: (_getFormState('port') ?? 0) == 0
            ? ''
            : (_getFormState('port') ?? 0).toString(),
        decoration: const InputDecoration(
          labelText: '端口号',
          hintText: '例如: 445',
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _updateFormState('port', int.tryParse(value) ?? 0);
        },
      ),
    ];
  }

  /// 获取协议显示名称
  String _getSchemeDisplayName(SourceSchemeType scheme) {
    switch (scheme) {
      case SourceSchemeType.file:
        return '本地文件';
      case SourceSchemeType.webdav:
        return 'WebDAV';
      case SourceSchemeType.http:
        return 'HTTP';
      case SourceSchemeType.https:
        return 'HTTPS';
      case SourceSchemeType.smb:
        return 'SMB';
      case SourceSchemeType.ftp:
        return 'FTP';
      case SourceSchemeType.ltpp:
        return 'LTPP';
      default:
        return '未知';
    }
  }

  /// 获取示例基础URL
  String _getExampleBaseUrl(SourceSchemeType scheme) {
    switch (scheme) {
      case SourceSchemeType.webdav:
        return 'https://example.com/webdav';
      case SourceSchemeType.http:
        return 'http://example.com/api';
      case SourceSchemeType.https:
        return 'https://example.com/api';
      default:
        return 'https://example.com';
    }
  }
}
