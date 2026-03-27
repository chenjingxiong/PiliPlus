import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/models/search/suggest.dart';
import 'package:PiliPlus/pages/search/widgets/quick_search_controller.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 快捷搜索对话框
/// 使用 CTRL+F 快捷键触发的悬浮搜索窗口
class QuickSearchDialog extends StatelessWidget {
  const QuickSearchDialog({super.key});

  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  /// 显示快捷搜索对话框
  static void show() {
    final controller = Get.put(QuickSearchController(), tag: 'quickSearch');

    SmartDialog.show(
      tag: 'quickSearch',
      alignment: Alignment.topCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      maskColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => const QuickSearchDialog(),
      onDismiss: () {
        Get.delete<QuickSearchController>(tag: 'quickSearch');
      },
    );

    // 自动聚焦
    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickSearchController>(tag: 'quickSearch');
    final theme = Theme.of(context);

    return Container(
      width: 500,
      constraints: const BoxConstraints(maxHeight: 500),
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchBar(context, controller, theme),
            _buildContent(context, controller, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    QuickSearchController controller,
    ThemeData theme,
  ) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller.textController,
                focusNode: controller.focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索视频、番剧、UP主...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => controller.performSearch(),
              ),
            ),
            Obx(() {
              if (controller.showUidBtn.value) {
                return TextButton(
                  onPressed: controller.toUidUserPage,
                  child: const Text('UID'),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              final hasText = controller.textController.text.isNotEmpty;
              if (hasText) {
                return IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: controller.onClear,
                  tooltip: '清空',
                );
              }
              return IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => SmartDialog.dismiss(),
                tooltip: '关闭',
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuickSearchController controller,
    ThemeData theme,
  ) {
    return Obx(() {
      final hasText = controller.textController.text.isNotEmpty;

      if (!hasText && controller.historyList.isNotEmpty) {
        return _buildHistoryList(context, controller, theme);
      }

      if (hasText && controller.searchSuggestList.isNotEmpty) {
        return _buildSuggestionList(context, controller, theme);
      }

      return const SizedBox.shrink();
    });
  }

  Widget _buildHistoryList(
    BuildContext context,
    QuickSearchController controller,
    ThemeData theme,
  ) {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.historyList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final keyword = controller.historyList[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 18),
            title: Text(keyword),
            onTap: () => controller.onClickHistory(keyword),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionList(
    BuildContext context,
    QuickSearchController controller,
    ThemeData theme,
  ) {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.searchSuggestList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = controller.searchSuggestList[index];
          return _buildSuggestionTile(context, controller, item);
        },
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    QuickSearchController controller,
    SearchSuggestItem item,
  ) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.search, size: 18),
      title: Text(
        item.term ?? '',
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () => controller.onClickSuggestion(item.term ?? ''),
    );
  }
}
