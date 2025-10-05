// 这是一个基本的Flutter组件测试
// 在Unity中，这类似于单元测试或集成测试，用于验证游戏对象的行为

// 导入Material Design组件库
import 'package:flutter/material.dart';
// 导入Flutter测试库，用于编写和运行测试
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/models/source_config.dart';
import 'package:music_player/views/HomePage/music_player_home.dart';
// 导入Provider状态管理库
import 'package:provider/provider.dart';
// 导入Drift数据库库
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// 导入歌曲提供者视图模型
import 'package:music_player/viewmodels/song_provider.dart';
// 导入数据库
import 'package:music_player/database/database.dart';
// 导入数据库服务
import 'package:music_player/services/database_service.dart';

// 测试入口点，类似于Unity中的测试方法
void main() {
  // 定义一个测试用例，testWidgets是Flutter测试特有的方法
  // 在Unity中，这类似于[Test]属性标记的测试方法
  testWidgets('Music player has playlist with songs', (
    WidgetTester tester,
  ) async {
    // 创建内存数据库用于测试
    final database = AppDatabase(
      DatabaseConnection.fromExecutor(NativeDatabase.memory()),
    );

    // 创建测试数据
    final databaseService = DatabaseService(database);

    // 添加测试数据源配置
    await database
        .into(database.sourceConfigs)
        .insert(
          SourceConfigsCompanion(
            scheme: Value(SourceSchemeType.file), // file scheme
            name: Value('Local'),
            config: Value('{"basePath":"/music"}'),
            isEnabled: Value(true),
          ),
        );

    // 添加测试歌曲到数据库
    await database
        .into(database.songs)
        .insert(
          SongsCompanion(
            title: Value('Shape of You'),
            artist: Value('Ed Sheeran'),
            album: Value('÷ (Divide)'),
            duration: Value(233),
            resourcePath: Value('shape_of_you.mp3'),
            sourceConfigId: Value(1), // 关联到第一个数据源配置
          ),
        );

    await database
        .into(database.songs)
        .insert(
          SongsCompanion(
            title: Value('Blinding Lights'),
            artist: Value('The Weeknd'),
            album: Value('After Hours'),
            duration: Value(200),
            resourcePath: Value('blinding_lights.mp3'),
            sourceConfigId: Value(1), // 关联到第一个数据源配置
          ),
        );

    // 构建我们的应用程序并触发一帧渲染
    // 在Unity中，这类似于设置测试场景并运行一帧游戏循环
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SongProvider(database),
        child: const MaterialApp(home: MusicPlayerHome()),
      ),
    );

    // 等待异步操作完成
    await tester.pumpAndSettle();

    // 验证播放列表中是否包含歌曲标题
    // 在Unity测试中，这类似于检查场景中是否存在特定的游戏对象
    expect(find.text('Shape of You'), findsOneWidget);
    expect(find.text('Blinding Lights'), findsOneWidget);
  });
}
