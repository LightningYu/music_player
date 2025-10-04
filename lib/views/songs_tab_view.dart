import 'package:flutter/material.dart';
import 'package:music_player/viewmodels/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:music_player/views/widgets/song_list_item.dart';

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
            // // 计算已滚动的像素和总可滚动像素
            // final pixels = metrics.pixels;
            // final maxScrollExtent = metrics.maxScrollExtent;

            // // 计算剩余可滚动像素
            // final remainingPixels = maxScrollExtent - pixels;

            // // 估算每个项目的大致高度（使用默认 ListTile 高度）
            // const itemHeight = 56.0; // ListTile 的默认高度

            // // 计算剩余项目数量
            // final remainingItems = (remainingPixels / itemHeight).ceil();

            // // 计算提前加载阈值（列表总长度的20%）
            // final threshold = (songProvider.songs.length * 0.3).ceil();

            // // 检查是否需要提前加载更多数据
            // if (remainingItems <= threshold) {
            //   // 如果有更多数据且未在加载中，则加载更多歌曲
            //   if (songProvider.hasMoreData && !songProvider.isLoadingMore) {
            //     songProvider.loadMoreSongs();
            //   }
            // }
            if (metrics.extentAfter / metrics.viewportDimension < 1.5) {
              // 如果有更多数据且未在加载中，则加载更多歌曲
              if (songProvider.hasMoreData && !songProvider.isLoadingMore) {
                songProvider.loadMoreSongs();
              }
            }
          }
          return false;
        },
        child: ListView.builder(
          itemCount:
              songProvider.songs.length + (songProvider.isLoadingMore ? 1 : 0),
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
              onTap: () => songProvider.selectSong(index),
            );
          },
        ),
      ),
    );
  }
}
