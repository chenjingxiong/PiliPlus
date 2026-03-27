import 'package:flutter/material.dart';

import 'view.dart';

/// 浮动播放器窗口
///
/// TODO: 使用 desktop_multi_window 0.2.1 的正确 API 实现真正的多窗口功能
/// 当前版本为桩实现，等待 API 文档更新
class FloatingPlayerWindow extends StatefulWidget {
  const FloatingPlayerWindow({super.key});

  @override
  State<FloatingPlayerWindow> createState() => _FloatingPlayerWindowState();
}

class _FloatingPlayerWindowState extends State<FloatingPlayerWindow> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('独立窗口播放功能即将上线'),
      ),
    );
  }
}
