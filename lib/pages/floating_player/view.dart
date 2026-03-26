import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:window_manager/window_manager.dart';

import 'arguments.dart';

/// 浮动播放器管理器
class FloatingPlayerManager {
  static WindowController? _windowController;
  static bool _isInitialized = false;

  /// 窗口通信频道名称
  static const String _channelName = 'piliplus_floating_player';

  /// 初始化多窗口插件
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 启动浮动播放器窗口
  static Future<void> start({
    required String videoUrl,
    String? title,
    Map<String, dynamic>? extraArgs,
  }) async {
    await init();

    // 如果窗口已存在，直接显示
    if (_windowController != null) {
      try {
        // 发送新的视频URL到现有窗口
        final channel = WindowMethodChannel(_channelName);
        await channel.invokeMethod('changeVideo', {
          'videoUrl': videoUrl,
          if (title != null) 'title': title,
          ...?extraArgs,
        });
        await _windowController!.show();
        return;
      } catch (e) {
        // 如果通信失败，重新创建窗口
        _windowController = null;
      }
    }

    try {
      final arguments = FloatingPlayerWindowArguments(
        videoUrl: videoUrl,
        title: title ?? '视频播放',
        autoplay: extraArgs?['autoplay'] ?? true,
        position: extraArgs?['position'] ?? 0,
      );

      _windowController = await WindowController.create(
        WindowConfiguration(
          arguments: arguments.toArguments(),
          hiddenAtLaunch: false,
        ),
      );

      SmartDialog.showToast('浮动播放器已启动');
    } catch (e) {
      SmartDialog.showToast('启动浮动播放器失败: $e');
      _windowController = null;
    }
  }

  /// 关闭浮动播放器窗口
  static Future<void> close() async {
    if (_windowController == null) return;

    try {
      // 使用 channel 通知窗口关闭
      final channel = WindowMethodChannel(_channelName);
      await channel.invokeMethod('close');
    } catch (_) {
      // 如果通信失败，尝试直接关闭
    }

    _windowController = null;
  }

  /// 发送消息到浮动窗口
  static Future<void> sendMessage(String method, [Map<String, dynamic>? args]) async {
    if (_windowController == null) return;

    try {
      final channel = WindowMethodChannel(_channelName);
      await channel.invokeMethod(method, args ?? {});
    } catch (e) {
      debugPrint('发送消息到浮动窗口失败: $e');
    }
  }

  /// 检查窗口是否存在
  static bool get isActive => _windowController != null;

  /// 获取窗口控制器
  static WindowController? get controller => _windowController;

  /// 设置窗口为空（供窗口关闭时调用）
  static void clearController() {
    _windowController = null;
  }
}

/// 浮动播放器窗口通信频道
const floatingPlayerChannel = WindowMethodChannel(
  FloatingPlayerManager._channelName,
  mode: ChannelMode.bidirectional,
);
