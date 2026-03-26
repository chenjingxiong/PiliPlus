import 'dart:io';

import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 浮动播放器窗口 - 独立子窗口
/// 运行在独立的 Flutter 引擎实例中
class FloatingPlayerWindow extends StatefulWidget {
  const FloatingPlayerWindow({super.key, required this.windowId});

  final int windowId;

  @override
  State<FloatingPlayerWindow> createState() => _FloatingPlayerWindowState();
}

class _FloatingPlayerWindowState extends State<FloatingPlayerWindow>
    with WidgetsBindingObserver {
  PlPlayerController? _playerController;
  final _messages = <Message>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWindow();
    _setupMessageListener();
  }

  void _initWindow() async {
    // 设置窗口属性
    try {
      final window = DesktopMultiWindow.getWindow(widget.windowId);
      final windowSize = Pref.floatingWindowSize;

      await window.setBounds(Rect.fromLTWH(
        100,
        100,
        windowSize.width,
        windowSize.height,
      ));
      await window.setTitle('PiliPlus - 播放窗口');
      await window.setResizable(true);
      // 注意：alwaysOnTop 在某些平台可能需要原生支持
    } catch (e) {
      debugPrint('Failed to init window: $e');
    }
  }

  void _setupMessageListener() {
    // 监听来自主窗口的消息
    DesktopMultiWindow.setMessageHandler(widget.windowId, (message) async {
      _messages.add(message);
      if (!mounted) return;

      final args = message.arguments;
      if (args == null) return;

      switch (message.method) {
        case 'initPlayer':
          _initPlayer(args);
          break;
        case 'play':
          _playerController?.play();
          break;
        case 'pause':
          _playerController?.pause();
          break;
        case 'seek':
          final position = args['position'] as int?;
          if (position != null) {
            _playerController?.seek(Duration(milliseconds: position));
          }
          break;
        case 'setSpeed':
          final speed = args['speed'] as double?;
          if (speed != null) {
            _playerController?.setPlaybackSpeed(speed);
          }
          break;
        case 'close':
          _closeWindow();
          break;
      }
    });
  }

  void _initPlayer(Map<String, dynamic> args) {
    final url = args['url'] as String?;
    if (url == null) return;

    if (_playerController != null) {
      _playerController?.dispose();
    }

    // 创建新的播放器控制器
    _playerController = PlPlayerController()
      ..dataSource = DataSource(
        type: DataSourceType.network,
        url: url,
        autoplay: args['autoplay'] ?? false,
      );

    // 设置初始位置
    final position = args['position'] as int?;
    if (position != null && position > 0) {
      _playerController?.seek(Duration(milliseconds: position));
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _closeWindow() {
    _playerController?.dispose();
    DesktopMultiWindow.destroyWindow(widget.windowId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理应用生命周期变化
    if (state == AppLifecycleState.paused) {
      _playerController?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerController?.dispose();
    super.dispose();
  }

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
        body: Column(
          children: [
            // 顶部可拖动控制栏
            _buildDraggableTopBar(),
            // 播放器区域
            Expanded(
              child: _playerController == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : PlayerView(
                      controller: _playerController!,
                      showFullBtn: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableTopBar() {
    return GestureDetector(
      onPanUpdate: (details) {
        // 实现窗口拖动
        DesktopMultiWindow.getWindow(widget.windowId).then((window) {
          final bounds = window.getBounds();
          window.setBounds(Rect.fromLTWH(
            bounds.left + details.delta.dx,
            bounds.top + details.delta.dy,
            bounds.width,
            bounds.height,
          ));
        });
      },
      child: Container(
        height: 40,
        color: Colors.black.withValues(alpha: 0.8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              'PiliPlus 播放器',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // 最小化按钮
            IconButton(
              icon: const Icon(Icons.remove_outline, color: Colors.white, size: 18),
              onPressed: () {
                DesktopMultiWindow.getWindow(widget.windowId).then((window) {
                  window.minimize();
                });
              },
              tooltip: '最小化',
              iconSize: 18,
              padding: const EdgeInsets.all(8),
            ),
            // 关闭按钮
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _closeWindow,
              tooltip: '关闭',
              iconSize: 18,
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// 浮动播放器管理器
class FloatingPlayerManager {
  static int? _windowId;
  static bool _isInitialized = false;

  /// 初始化多窗口插件
  static Future<void> init() async {
    if (_isInitialized) return;

    // 设置子窗口回调
    DesktopMultiWindow.setSubWindowHandler((windowId) {
      return FloatingPlayerWindow(windowId: windowId);
    });

    _isInitialized = true;
  }

  /// 启动浮动播放器窗口
  static Future<int?> start({
    required String videoUrl,
    String? title,
    Map<String, dynamic>? extraArgs,
  }) async {
    if (!PlatformUtils.isDesktop) return null;

    await init();

    // 如果窗口已存在，关闭它
    if (_windowId != null) {
      await close();
    }

    try {
      // 创建子窗口
      _windowId = await DesktopMultiWindow.createWindow(
        const FloatingPlayerWindow(),
      );

      final window = DesktopMultiWindow.getWindow(_windowId!);

      // 设置窗口属性
      final windowSize = Pref.floatingWindowSize;
      await window.setBounds(Rect.fromLTWH(
        100,
        100,
        windowSize.width,
        windowSize.height,
      ));
      await window.setTitle(title ?? 'PiliPlus - 播放窗口');
      await window.setResizable(true);
      await window.show();
      await window.focus();

      // 发送初始化消息
      await window.sendMessage(Message(
        method: 'initPlayer',
        arguments: {
          'url': videoUrl,
          ...?extraArgs,
        },
      ));

      return _windowId;
    } catch (e) {
      debugPrint('Failed to create floating player window: $e');
      return null;
    }
  }

  /// 关闭浮动播放器窗口
  static Future<void> close() async {
    if (_windowId != null) {
      await DesktopMultiWindow.destroyWindow(_windowId!);
      _windowId = null;
    }
  }

  /// 发送消息到浮动窗口
  static Future<void> sendMessage(String method, [Map<String, dynamic>? args]) async {
    if (_windowId != null) {
      final window = DesktopMultiWindow.getWindow(_windowId!);
      await window.sendMessage(Message(
        method: method,
        arguments: args,
      ));
    }
  }

  /// 播放
  static Future<void> play() => sendMessage('play');

  /// 暂停
  static Future<void> pause() => sendMessage('pause');

  /// 跳转
  static Future<void> seek(Duration position) => sendMessage('seek', {
    'position': position.inMilliseconds,
  });

  /// 设置播放速度
  static Future<void> setSpeed(double speed) => sendMessage('setSpeed', {
    'speed': speed,
  });

  /// 检查窗口是否存在
  static bool get isActive => _windowId != null;
}
