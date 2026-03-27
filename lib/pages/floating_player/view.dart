import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'arguments.dart';

/// 浮动播放器管理器
///
/// TODO: 使用 desktop_multi_window 0.2.1 的正确 API 实现真正的多窗口功能
/// 当前版本为桩实现，等待 API 文档更新
class FloatingPlayerManager {
  static int? _windowId;
  static bool _isInitialized = false;

  /// 初始化多窗口插件
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 启动浮动播放器窗口
  static Future<int?> start({
    required String videoUrl,
    String? title,
    Map<String, dynamic>? extraArgs,
  }) async {
    await init();
    SmartDialog.showToast('独立窗口播放功能即将上线');
    return null;
  }

  /// 关闭浮动播放器窗口
  static Future<void> close() async {
    _windowId = null;
  }

  /// 发送消息到浮动窗口
  static Future<void> sendMessage(String method, [Map<String, dynamic>? args]) async {
    // 桩实现
  }

  /// 检查窗口是否存在
  static bool get isActive => false;

  /// 获取窗口控制器
  static int? get windowId => _windowId;

  /// 设置窗口为空（供窗口关闭时调用）
  static void clearWindowId() {
    _windowId = null;
  }
}
