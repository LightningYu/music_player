import 'package:flutter/material.dart';
import 'package:music_player/viewmodels/app_settings.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:music_player/viewmodels/source_config_provider.dart';
import 'package:music_player/views/SettingPage/SourceConfigPage/source_configs_view.dart';
import 'package:music_player/views/widgets/song_list_item.dart';
import 'package:provider/provider.dart';

/// 歌曲标签页视图
class SongsTabView extends StatelessWidget {
  /// 构造函数
  const SongsTabView({super.key});
  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // 检查是否为滚动更新通知
          if (scrollInfo is ScrollUpdateNotification) {
            // 获取滚动控制器
            final metrics = scrollInfo.metrics;
            if (metrics.extentAfter / metrics.viewportDimension < 1.5) {
              // 如果有更多数据且未在加载中，则加载更多歌曲
              if (songProvider.hasMoreData && !songProvider.isLoadingMore) {
                songProvider.loadMoreSongs();
              }
            }
          }
          return false;
        },
        child: songProvider.songs.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                itemCount: songProvider.songs.length +
                    (songProvider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // 如果是最后一个项目且正在加载更多，则显示加载指示器
                  if (index >= songProvider.songs.length &&
                      AppSettings().paginationEnabled) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return SongListItem(
                    song: songProvider.songs[index],
                    isSelected: songProvider.currentSongIndex == index,
                    onTap: () => _playSong(context, songProvider.songs[index].id),
                  );
                },
              ),
      ),
    );
  }

  /// 播放歌曲
  void _playSong(BuildContext context, int songId) {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final sourceConfigProvider = Provider.of<SourceConfigProvider>(context, listen: false);
    songProvider.playSong(songId, sourceConfigProvider);
  }

  /// 构建空状态视图
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_note,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无歌曲',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮添加音乐',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SourceConfigsView(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('添加音乐'),
          ),
        ],
      ),
    );
  }
}