import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:music_player/viewmodels/app_settings.dart';

/// 设置页面视图
class SettingsView extends StatelessWidget {
  /// 构造函数
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'General Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Theme'),
              subtitle: const Text('Light'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 实现主题切换功能
              },
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 实现语言切换功能
              },
            ),
            ListTile(
              title: const Text('Add Songs'),
              trailing: const Icon(Icons.add),
              onTap: () {
                // 显示添加歌曲选项对话框
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Add Songs'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Add Local Songs'),
                            onTap: () {
                              Provider.of<SongProvider>(
                                context,
                                listen: false,
                              ).addLocalSongsToData();
                              Navigator.of(context).pop();
                              // 调用添加本地歌曲功能
                            },
                          ),
                          ListTile(
                            title: const Text('Add Network Storage'),
                            onTap: () {
                              // TODO: 实现添加网络存储功能
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Performance Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Consumer<AppSettings>(
              builder: (context, appSettings, child) {
                return SwitchListTile(
                  title: const Text('Pagination Loading'),
                  subtitle: const Text('Enable pagination for better performance'),
                  value: appSettings.paginationEnabled,
                  onChanged: (bool value) {
                    appSettings.setPaginationEnabled(value);
                  },
                );
              },
            ),
            Consumer<AppSettings>(
              builder: (context, appSettings, child) {
                return ListTile(
                  title: const Text('Page Size'),
                  subtitle: Text('${appSettings.pageSize} songs per page'),
                  enabled: appSettings.paginationEnabled,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: appSettings.paginationEnabled
                      ? () {
                          _showPageSizeDialog(context, appSettings);
                        }
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Audio Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Equalizer'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 实现均衡器功能
              },
            ),
            ListTile(
              title: const Text('Audio Quality'),
              subtitle: const Text('High'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 实现音频质量设置功能
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
            ListTile(
              title: const Text('Terms of Service'),
              onTap: () {
                // TODO: 实现服务条款功能
              },
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              onTap: () {
                // TODO: 实现隐私政策功能
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示页面大小设置对话框
  void _showPageSizeDialog(BuildContext context, AppSettings appSettings) {
    final TextEditingController controller = TextEditingController(
      text: appSettings.pageSize.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Page Size'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Page Size',
              hintText: 'Enter number of songs per page',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String input = controller.text;
                final int? pageSize = int.tryParse(input);
                if (pageSize != null && pageSize > 0) {
                  appSettings.setPageSize(pageSize);
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}