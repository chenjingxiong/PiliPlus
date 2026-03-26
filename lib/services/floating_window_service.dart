import 'package:PiliPlus/pages/floating_player/view.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 独立窗口播放服务
///
/// 使用多窗口实现真正的独立播放器进程
class FloatingWindowService extends GetxService {
  static FloatingWindowService get to => Get.find();

  // 是否处于独立窗口模式
  final RxBool isInFloatingWindow = false.obs;

  // 当前播放的控制器（主窗口）
  PlPlayerController? _mainPlayerController;
  VideoDetailController? _videoController;

  /// 显示独立窗口
  Future<void> showFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (!PlatformUtils.isDesktop) return;

    _mainPlayerController = playerController;
    _videoController = videoController;

    // 获取当前视频URL
    final videoUrl = videoController.data?.playData?.dash?.video?.first?.baseUrl ??
                      videoController.data?.playData?.dash?.video?.first?.base_url;

    if (videoUrl == null) {
      Get.snackbar('提示', '无法获取视频地址');
      return;
    }

    // 暂停主窗口播放
    final wasPlaying = playerController.playerStatus.value.isPlaying;
    await playerController.pause();

    // 启动浮动播放器窗口
    final windowId = await FloatingPlayerManager.start(
      videoUrl: videoUrl,
      title: videoController.data?.title ?? '',
      extraArgs: {
        'autoplay': wasPlaying,
        'position': playerController.position.value.inMilliseconds,
      },
    );

    if (windowId != null) {
      isInFloatingWindow.value = true;
    }
  }

  /// 关闭独立窗口并返回主窗口
  Future<void> closeFloatingWindow() async {
    await FloatingPlayerManager.close();
    isInFloatingWindow.value = false;

    // 恢复主窗口播放
    if (_mainPlayerController != null) {
      await _mainPlayerController!.play();
    }

    _mainPlayerController = null;
    _videoController = null;
  }

  /// 切换独立窗口模式
  Future<void> toggleFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (FloatingPlayerManager.isActive) {
      await closeFloatingWindow();
    } else {
      await showFloatingWindow(
        playerController: playerController,
        videoController: videoController,
      );
    }
  }

  /// 发送控制消息到浮动窗口
  Future<void> sendCommand(String command, {Map<String, dynamic>? args}) async {
    await FloatingPlayerManager.sendMessage(command, args);
  }
}
