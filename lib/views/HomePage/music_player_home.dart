import 'package:flutter/material.dart';
import 'package:music_player/views/HomePage/albums_tab_view.dart';
import 'package:music_player/views/HomePage/artists_tab_view.dart';
import 'package:music_player/views/HomePage/songs_tab_view.dart';
import 'package:music_player/views/SettingPage/settings_view.dart';
import 'package:provider/provider.dart';
import 'package:music_player/viewmodels/song_provider.dart';

/// 音乐播放器主界面
class MusicPlayerHome extends StatefulWidget {
  /// 构造函数
  const MusicPlayerHome({super.key});

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

/// 音乐播放器主界面状态
class _MusicPlayerHomeState extends State<MusicPlayerHome>
    with TickerProviderStateMixin {
  /// 标签控制器
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SongProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [const PopupMenuItem(value: 1, child: Text('Settings'))];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [SongsTabView(), ArtistsTabView(), AlbumsTabView()],
      ),
    );
  }
}
