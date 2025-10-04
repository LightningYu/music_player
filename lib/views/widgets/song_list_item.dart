import 'package:flutter/material.dart';
import 'package:music_player/models/song.dart';

/// 歌曲列表项组件
class SongListItem extends StatelessWidget {
  /// 歌曲数据
  final Song song;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 构造函数
  const SongListItem({
    super.key,
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.title),
      subtitle: Text('${song.artist} - ${song.album}'),
      trailing: Text(song.formattedDuration),
      onTap: onTap,
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withAlpha(50)
          : null,
    );
  }
}
