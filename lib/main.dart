// 导入Flutter Material Design组件库
import 'package:flutter/material.dart';
import 'package:music_player/views/HomePage/music_player_home.dart';
import 'package:provider/provider.dart';
import 'package:music_player/database/database.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:music_player/viewmodels/app_settings.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// 程序主入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 请求存储权限
  await _requestStoragePermission();

  // 初始化应用设置
  final appSettings = AppSettings();
  await appSettings.init();

  // 初始化数据库
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'music_player.db'));
  await dbFolder.create(recursive: true);
  final db = AppDatabase(NativeDatabase(file));

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<SourceConfigProvider>(
          create: (context) => SourceConfigProvider(context.read<AppDatabase>()),
        ),
        ChangeNotifierProxyProvider<AppDatabase, SongProvider>(
          create: (context) => SongProvider(context.read<AppDatabase>()),
          update: (context, database, previous) => SongProvider(database),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// 请求存储权限
Future<void> _requestStoragePermission() async {
  final status = await Permission.storage.status;
  if (status.isDenied || status.isPermanentlyDenied) {
    await Permission.storage.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MusicPlayerHome(),
    );
  }
}