import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/viewmodels/song_provider.dart';

/// 专辑标签页视图
class AlbumsTabView extends StatelessWidget {
  /// 构造函数
  const AlbumsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: songProvider.albums.length,
        itemBuilder: (context, index) {
          final album = songProvider.albums[index];
          return ListTile(
            title: Text(album),
            onTap: () {
              // TODO: 实现专辑详情页面跳转
            },
          );
        },
      ),
    );
  }
}