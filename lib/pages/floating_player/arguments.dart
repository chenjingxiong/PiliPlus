import 'dart:convert';

/// 窗口参数基类
abstract class WindowArguments {
  const WindowArguments();

  static const String businessIdMain = 'main';
  static const String businessIdFloatingPlayer = 'floating_player';

  factory WindowArguments.fromArguments(String arguments) {
    if (arguments.isEmpty) {
      return const MainWindowArguments();
    }
    try {
      final json = jsonDecode(arguments) as Map<String, dynamic>;
      final businessId = json['businessId'] as String? ?? '';
      switch (businessId) {
        case businessIdFloatingPlayer:
          return FloatingPlayerWindowArguments.fromJson(json);
        default:
          return const MainWindowArguments();
      }
    } catch (_) {
      return const MainWindowArguments();
    }
  }

  Map<String, dynamic> toJson();

  String get businessId;

  String toArguments() => jsonEncode({'businessId': businessId, ...toJson()});
}

/// 主窗口参数
class MainWindowArguments extends WindowArguments {
  const MainWindowArguments();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  String get businessId => WindowArguments.businessIdMain;
}

/// 浮动播放器窗口参数
class FloatingPlayerWindowArguments extends WindowArguments {
  const FloatingPlayerWindowArguments({
    required this.videoUrl,
    this.autoplay = true,
    this.position = 0,
    this.title,
  });

  factory FloatingPlayerWindowArguments.fromJson(Map<String, dynamic> json) {
    return FloatingPlayerWindowArguments(
      videoUrl: json['videoUrl'] as String? ?? '',
      autoplay: json['autoplay'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
      title: json['title'] as String?,
    );
  }

  final String videoUrl;
  final bool autoplay;
  final int position;
  final String? title;

  @override
  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'autoplay': autoplay,
      'position': position,
      if (title != null) 'title': title,
    };
  }

  @override
  String get businessId => WindowArguments.businessIdFloatingPlayer;
}
