import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 独立窗口播放服务
///
/// 注意：当前 Flutter 的 window_manager 插件不支持多窗口功能。
/// 此服务保留用于将来可能的实现，目前作为占位符。
class FloatingWindowService extends GetxService {
  static FloatingWindowService get to => Get.find();

  // 是否处于独立窗口模式
  final RxBool isInFloatingWindow = false.obs;

  /// 显示独立窗口（占位实现）
  Future<void> showFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    SmartDialog.showToast('独立窗口播放功能开发中，敬请期待');
  }

  /// 关闭独立窗口（占位实现）
  Future<void> closeFloatingWindow() async {
    isInFloatingWindow.value = false;
  }

  /// 切换独立窗口模式（占位实现）
  Future<void> toggleFloatingWindow({
    required PlPlayerController playerController,
    required VideoDetailController videoController,
  }) async {
    SmartDialog.showToast('独立窗口播放功能开发中，敬请期待');
  }
}
