import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/video/stat/video_stat.dart';
import 'package:PiliPlus/models_new/fav/fav_resource/list.dart';
import 'package:PiliPlus/pages/fav_detail/controller.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 我的页面 - 默认收藏夹视频列表
class MineFavVideoList extends StatefulWidget {
  const MineFavVideoList({super.key, required this.favId});

  final int favId;

  @override
  State<MineFavVideoList> createState() => _MineFavVideoListState();
}

class _MineFavVideoListState extends State<MineFavVideoList>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final FavDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      FavDetailController(favId: widget.favId),
      tag: 'mine_fav_${widget.favId}',
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
          onTap: () => Get.toNamed('/favDetail', parameters: {
            'mediaId': widget.favId.toString(),
          }),
          dense: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '默认收藏视频  ',
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
    LoadingState<FavResourceData> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) => Builder(
        builder: (context) {
          final list = response.list;
          if (list == null || list.isEmpty) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('暂无视频')),
            );
          }
          bool flag = response.count > list.length;
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
              itemCount: list.length + (flag ? 1 : 0),
              itemBuilder: (context, index) {
                if (flag && index == list.length) {
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
                      onPressed: () => Get.toNamed('/favDetail', parameters: {
                        'mediaId': widget.favId.toString(),
                      }),
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
                  source: 'favorite',
                  stat: VideoStat(
                    view: videoItem.cnt_info?.play ?? 0,
                    danmaku: videoItem.cnt_info?.danmaku ?? 0,
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
