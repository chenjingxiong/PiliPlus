import 'dart:io';

import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

/// 独立窗口播放服务
class FloatingWindowService extends GetxService {
  static FloatingWindowService get to => Get.find();

  // 是否处于独立窗口模式
  final RxBool isInFloatingWindow = false.obs;

  // 独立窗口的控制器
  WindowController? _floatingWindowController;
  PlPlayerController? _playerController;
  VideoDetailController? _videoController;

  // 主窗口状态
  bool _mainWindowWasMaximized = false;
  Size? _mainWindowPreviousSize;

  /// 显示独立窗口
  Future<void> showFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (!PlatformUtils.isDesktop) return;

    _playerController = playerController;
    _videoController = videoController;

    // 保存主窗口状态
    _mainWindowWasMaximized = await windowManager.isMaximized();
    _mainWindowPreviousSize = await windowManager.getSize();

    // 创建独立窗口
    await _createFloatingWindow();

    isInFloatingWindow.value = true;
  }

  /// 创建独立窗口
  Future<void> _createFloatingWindow() async {
    final windowSize = Pref.floatingWindowSize;

    final windowOptions = WindowOptions(
      size: windowSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
      resizable: true,
    );

    await WindowManager.createWindow(windowOptions);
  }

  /// 关闭独立窗口并返回主窗口
  Future<void> closeFloatingWindow() async {
    if (!PlatformUtils.isDesktop) return;

    // 关闭独立窗口
    await WindowManager.destroyWindow();

    // 恢复主窗口焦点
    await WindowManager.activeWindow();

    _floatingWindowController = null;
    _playerController = null;
    _videoController = null;

    isInFloatingWindow.value = false;
  }

  /// 切换独立窗口模式
  Future<void> toggleFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (isInFloatingWindow.value) {
      await closeFloatingWindow();
    } else {
      await showFloatingWindow(
        playerController: playerController,
        videoController: videoController,
      );
    }
  }

  /// 更新独立窗口大小
  Future<void> updateFloatingWindowSize(Size size) async {
    if (!PlatformUtils.isDesktop) return;

    Pref.floatingWindowSize = size;
    await windowManager.setSize(size);
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    if (isInFloatingWindow.value) {
      closeFloatingWindow();
    }
    super.onClose();
  }
}

/// 独立窗口内容
class FloatingWindowContent extends StatelessWidget {
  const FloatingWindowContent({
    super.key,
    required this.playerController,
    required this.videoController,
  });

  final PlPlayerController playerController;
  final VideoDetailController videoController;

  @override
  Widget build(BuildContext context) {
    final (lightTheme, darkTheme) = MyApp.getAllTheme();
    final theme = Pref.themeType == ThemeType.dark ? darkTheme : lightTheme;

    return MaterialApp(
      title: 'PiliPlus - 播放窗口',
      theme: theme,
      darkTheme: darkTheme,
      themeMode: Pref.themeMode,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: DragToMoveArea(
          child: Stack(
            children: [
              // 播放器
              Positioned.fill(
                child: PlayerView(
                  controller: playerController,
                  showFullBtn: false,
                ),
              ),
              // 顶部控制栏（用于拖动窗口）
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        videoController.videoTitle.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          FloatingWindowService.to.closeFloatingWindow();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
