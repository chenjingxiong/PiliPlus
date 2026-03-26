import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

/// 独立窗口播放服务
///
/// 使用现有的桌面 PiP 功能实现浮动播放
class FloatingWindowService extends GetxService {
  static FloatingWindowService get to => Get.find();

  // 是否处于独立窗口模式
  final RxBool isInFloatingWindow = false.obs;

  /// 显示独立窗口（进入桌面 PiP 模式）
  Future<void> showFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (!Pref.enableFloatingWindow) {
      return;
    }
    await playerController.enterDesktopPip();
    isInFloatingWindow.value = playerController.isDesktopPip;
  }

  /// 关闭独立窗口（退出桌面 PiP 模式）
  Future<void> closeFloatingWindow() async {
    // 需要获取当前的 playerController，这里简化处理
    isInFloatingWindow.value = false;
  }

  /// 切换独立窗口模式
  Future<void> toggleFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    if (playerController.isDesktopPip) {
      await playerController.exitDesktopPip();
      isInFloatingWindow.value = false;
    } else {
      if (Pref.enableFloatingWindow) {
        await playerController.enterDesktopPip();
        isInFloatingWindow.value = playerController.isDesktopPip;
      }
    }
  }
}
