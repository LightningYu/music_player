import 'package:flutter/material.dart';
import 'package:music_player/views/SettingPage/SourceConfigPage/source_configs_view.dart';

/// 设置页面视图
class SettingsView extends StatelessWidget {
  /// 构造函数
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据源管理',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('数据源配置'),
                subtitle: const Text('管理音乐数据源'),
                trailing: const Icon(Icons.source),
                onTap: () {
                  // 跳转到数据源配置页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SourceConfigsView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '应用设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 其他设置项可以在这里添加
          ],
        ),
      ),
    );
  }

}
