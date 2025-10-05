import 'package:flutter/material.dart';
import 'package:music_player/viewmodels/song_provider.dart';
import 'package:provider/provider.dart';

/// 艺术家标签页视图
class ArtistsTabView extends StatelessWidget {
  /// 构造函数
  const ArtistsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final artists = songProvider.getUniqueArtists().toList();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ListTile(
            title: Text(artist),
            onTap: () {
              // TODO: 实现艺术家详情页面跳转
            },
          );
        },
      ),
    );
  }
}