/// 浮动播放器与主窗口之间的通信协议
class FloatingPlayerMessages {
  /// 初始化播放器
  static const String initPlayer = 'initPlayer';

  /// 播放
  static const String play = 'play';

  /// 暂停
  static const String pause = 'pause';

  /// 跳转
  static const String seek = 'seek';

  /// 设置播放速度
  static const String setSpeed = 'setSpeed';

  /// 关闭窗口
  static const String close = 'close';

  /// 更新播放进度（从播放器发送到主窗口）
  static const String updateProgress = 'updateProgress';

  /// 播放状态变化
  static const String playbackStateChanged = 'playbackStateChanged';

  /// 构建消息
  static Map<String, dynamic> buildMessage(String method, [Map<String, dynamic>? args]) {
    return {
      'method': method,
      if (args != null) 'args': args,
    };
  }

  /// 解析消息
  static String? getMethod(Map<String, dynamic> message) {
    return message['method'] as String?;
  }

  /// 获取参数
  static Map<String, dynamic>? getArguments(Map<String, dynamic> message) {
    return message['args'] as Map<String, dynamic>?;
  }
}
