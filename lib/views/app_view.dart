import 'package:flutter/material.dart';
import 'package:music_player/views/home_view.dart';

/// 音乐播放器应用根组件
class AppView extends StatelessWidget {
  /// 构造函数
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MusicPlayerHome();
  }
}
