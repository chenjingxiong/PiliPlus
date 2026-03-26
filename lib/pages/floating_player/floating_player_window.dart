import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'view.dart';
import 'arguments.dart';

/// 浮动播放器窗口
class FloatingPlayerWindow extends StatefulWidget {
  const FloatingPlayerWindow({super.key});

  @override
  State<FloatingPlayerWindow> createState() => _FloatingPlayerWindowState();
}

class _FloatingPlayerWindowState extends State<FloatingPlayerWindow>
    with WindowListener {
  Player? _player;
  VideoController? _videoController;
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();

  WindowArguments? _arguments;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWindow();
  }

  Future<void> _initializeWindow() async {
    try {
      // 获取窗口控制器和参数
      final windowController = await WindowController.fromCurrentEngine();
      _arguments = WindowArguments.fromArguments(windowController.arguments);

      if (_arguments is! FloatingPlayerWindowArguments) {
        debugPrint('Invalid window arguments: ${_arguments?.businessId}');
        return;
      }

      final args = _arguments as FloatingPlayerWindowArguments;

      // 初始化播放器
      _player = Player();
      _videoController = VideoController(
        _player!,
        configuration: VideoControllerConfiguration(
          controls: NoVideoControls,
        ),
      );

      // 设置视频源
      await _player!.open(
        Playlist(
          [Media(args.videoUrl)],
        ),
        play: args.autoplay,
      );

      // 跳转到指定位置
      if (args.position > 0) {
        await _player!.seek(Duration(milliseconds: args.position));
      }

      // 设置窗口属性
      await windowManager.setPreventClose(true);
      windowManager.addListener(this);

      // 设置窗口标题
      await windowManager.setTitle(args.title ?? '视频播放');

      // 监听播放器状态
      _player!.stream.position.listen((position) {
        // 可以在这里同步播放进度到主窗口
      });

      _player!.stream.completed.listen((completed) {
        if (completed) {
          // 播放完成，可以关闭窗口或循环播放
        }
      });

      // 设置消息处理器
      await floatingPlayerChannel.setMethodCallHandler(_handleMethodCall);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize floating player window: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('Received method call: ${call.method} ${call.arguments}');

    switch (call.method) {
      case 'changeVideo':
        final args = call.arguments as Map<String, dynamic>;
        final videoUrl = args['videoUrl'] as String?;
        if (videoUrl != null) {
          await _player!.open(
            Playlist([Media(videoUrl)]),
            play: args['autoplay'] ?? true,
          );
          if (args['position'] != null) {
            await _player!.seek(Duration(milliseconds: args['position'] as int));
          }
        }
        return 'OK';

      case 'play':
        await _player!.play();
        return 'OK';

      case 'pause':
        await _player!.pause();
        return 'OK';

      case 'seek':
        final position = call.arguments as int?;
        if (position != null) {
          await _player!.seek(Duration(milliseconds: position));
        }
        return 'OK';

      case 'setVolume':
        final volume = call.arguments as double?;
        if (volume != null) {
          await _player!.setVolume(volume);
        }
        return 'OK';

      case 'close':
        await _closeWindow();
        return 'OK';

      default:
        debugPrint('Unknown method: ${call.method}');
        return null;
    }
  }

  Future<void> _closeWindow() async {
    await windowManager.setPreventClose(false);
    FloatingPlayerManager.clearController();
    await _player?.dispose();
    await windowManager.close();
  }

  @override
  void onWindowClose() async {
    await _closeWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    floatingPlayerChannel.setMethodCallHandler(null);
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _videoController == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final args = _arguments as FloatingPlayerWindowArguments;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // 自定义标题栏
            _buildTitleBar(args.title ?? '视频播放'),

            // 视频播放器
            Expanded(
              child: Video(
                key: _videoKey,
                controller: _videoController!,
              ),
            ),

            // 底部控制栏
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(String title) {
    return Container(
      height: 40,
      color: Colors.black87,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _closeWindow,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      height: 60,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 播放/暂停按钮
          StreamBuilder<bool>(
            stream: _player!.stream.playing,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isPlaying) {
                    _player!.pause();
                  } else {
                    _player!.play();
                  }
                },
              );
            },
          ),

          // 进度条
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player!.stream.position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player!.stream.duration,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Slider(
                      value: position.inMilliseconds.toDouble(),
                      min: 0,
                      max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        _player!.seek(Duration(milliseconds: value.toInt()));
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 时间显示
          StreamBuilder<Duration>(
            stream: _player!.stream.position,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player!.stream.duration,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              );
            },
          ),

          const SizedBox(width: 8),

          // 音量控制
          StreamBuilder<double>(
            stream: _player!.stream.volume,
            builder: (context, snapshot) {
              final volume = snapshot.data ?? 1.0;
              return IconButton(
                icon: Icon(
                  volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () {
                  _player!.setVolume(volume == 0 ? 1.0 : 0.0);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
