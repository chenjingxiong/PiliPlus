import 'dart:io';
import 'dart:isolate';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:multi_window/multi_window.dart';

/// 浮动播放器窗口视图
/// 运行在独立的进程中，专门负责视频播放
class FloatingPlayerView extends StatefulWidget {
  const FloatingPlayerView({super.key});

  @override
  State<FloatingPlayerView> createState() => _FloatingPlayerViewState();
}

class _FloatingPlayerViewState extends State<FloatingPlayerView> {
  PlPlayerController? _playerController;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messages = <Map<String, dynamic>>[];
  WindowController? _windowController;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _setupMessageListener();
  }

  void _initWindow() async {
    _windowController = WindowController();

    // 设置窗口属性
    final windowSize = Pref.floatingWindowSize;
    await _windowController?.setBounds(Rect.fromLTWH(
      100,
      100,
      windowSize.width,
      windowSize.height,
    ));
    await _windowController?.setTitle('PiliPlus - 播放窗口');
    await _windowController?.setResizable(true);
    await _windowController?.setAlwaysOnTop(true);

    // 监听窗口大小变化
    _windowController?.addEventListener(WindowEventEvent.resize, (event) {
      final bounds = event as WindowBoundsEvent;
      Pref.floatingWindowSize = Size(bounds.bounds.width, bounds.bounds.height);
    });
  }

  void _setupMessageListener() {
    // 监听来自主窗口的消息
    WindowController.windowManager?.setMethodCallHandler((call, arguments) async {
      switch (call.method) {
        case 'initPlayer':
          _initPlayer(arguments);
          break;
        case 'play':
          _playerController?.play();
          break;
        case 'pause':
          _playerController?.pause();
          break;
        case 'seek':
          _playerController?.seek(Duration(milliseconds: arguments['position'] as int));
          break;
        case 'setSpeed':
          _playerController?.setPlaybackSpeed(arguments['speed'] as double);
          break;
        case 'close':
          _closeWindow();
          break;
      }
    });
  }

  void _initPlayer(Map<String, dynamic> args) {
    if (_playerController != null) {
      _playerController?.dispose();
    }

    // 创建新的播放器控制器
    _playerController = PlPlayerController()
      ..dataSource = DataSource(
        type: DataSourceType.network,
        url: args['url'] as String,
        autoplay: true,
      );

    if (mounted) {
      setState(() {});
    }
  }

  void _closeWindow() {
    _playerController?.dispose();
    WindowController.windowManager?.closeAll();
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _messageController.close();
    _windowController?.dispose();
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
        body: _playerController == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  // 顶部控制栏
                  _buildTopBar(),
                  // 播放器区域
                  Expanded(
                    child: PlayerView(
                      controller: _playerController!,
                      showFullBtn: false,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return DragToMoveArea(
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
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _closeWindow,
              tooltip: '关闭',
            ),
          ],
        ),
      ),
    );
  }
}

/// 启动浮动播放器窗口
class FloatingPlayerWindow {
  static WindowController? _windowController;

  /// 启动浮动播放器窗口
  static Future<WindowController?> start({
    required String videoUrl,
    Map<String, dynamic>? extraArgs,
  }) async {
    if (!PlatformUtils.isDesktop) return null;

    // 如果窗口已存在，关闭它
    if (_windowController != null) {
      await close();
    }

    try {
      _windowController = await WindowController.create(
        FloatingPlayerView(),
        title: 'PiliPlus - 播放窗口',
      );

      // 设置窗口初始属性
      final windowSize = Pref.floatingWindowSize;
      await _windowController?.setBounds(Rect.fromLTWH(
        100,
        100,
        windowSize.width,
        windowSize.height,
      ));
      await _windowController?.setResizable(true);
      await _windowController?.setAlwaysOnTop(true);
      await _windowController->setTitleBarStyle(TitleBarStyle.hidden);
      await _windowController->show();
      await _windowController->focus();

      // 发送初始化消息
      _windowController->sendMessage({
        'method': 'initPlayer',
        'args': {
          'url': videoUrl,
          ...?extraArgs,
        },
      });

      return _windowController;
    } catch (e) {
      debugPrint('Failed to create floating player window: $e');
      return null;
    }
  }

  /// 关闭浮动播放器窗口
  static Future<void> close() async {
    if (_windowController != null) {
      await _windowController?.close();
      _windowController = null;
    }
  }

  /// 发送控制消息
  static Future<void> sendMessage(String method, [Map<String, dynamic>? args]) async {
    if (_windowController != null) {
      await _windowController->sendMessage({
        'method': method,
        if (args != null) 'args': args,
      });
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
}
