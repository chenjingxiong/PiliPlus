import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models/common/video/stat/video_stat.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 我的页面 - 稍后再看列表
class MineLaterVideoList extends StatefulWidget {
  const MineLaterVideoList({super.key});

  @override
  State<MineLaterVideoList> createState() => _MineLaterVideoListState();
}

class _MineLaterVideoListState extends State<MineLaterVideoList>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final LaterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      LaterController(LaterViewType.later),
      tag: 'mine_later',
    );
    _controller.queryData();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;

    return Column(
      children: [
        Divider(
          height: 20,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        ListTile(
          onTap: () => Get.toNamed('/later'),
          dense: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '稍后再看  ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  WidgetSpan(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: Obx(
            () => IconButton(
              tooltip: '刷新',
              onPressed: _controller.loadingState.value is Loading
                  ? null
                  : _controller.onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ),
        ),
        Obx(() => _buildBody(theme, secondary, _controller.loadingState.value)),
      ],
    );
  }

  Widget _buildBody(
    ThemeData theme,
    Color secondary,
    LoadingState<List<LaterItemModel>> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) => Builder(
        builder: (context) {
          final list = response;
          if (list.isEmpty) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('暂无视频')),
            );
          }
          return SizedBox(
            height: 200,
            child: GridView.builder(
              controller: _controller.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 10,
                childAspectRatio: 16 / 9,
              ),
              itemCount: list.length + 1,
              itemBuilder: (context, index) {
                if (index == list.length) {
                  return Center(
                    child: IconButton(
                      tooltip: '查看更多',
                      style: ButtonStyle(
                        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: () => Get.toNamed('/later'),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: secondary,
                      ),
                    ),
                  );
                }
                final videoItem = list[index];
                return VideoCardH(
                  videoItem: videoItem,
                  source: 'later',
                  stat: VideoStat(
                    view: videoItem.stat?.view ?? 0,
                    danmaku: videoItem.stat?.danmaku ?? 0,
                  ),
                );
              },
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 100,
        child: Center(child: Text('加载失败: ${errMsg ?? ""}')),
      ),
    };
  }

  Widget get _buildSkeleton => const SizedBox(
    height: 200,
    child: Center(child: CircularProgressIndicator()),
  );
}
