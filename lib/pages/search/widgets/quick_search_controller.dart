import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/search/suggest.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:stream_transform/stream_transform.dart';

/// 快捷搜索控制器
/// 用于管理快捷搜索对话框的状态和搜索逻辑
class QuickSearchController extends GetxController
    with DebounceStreamMixin<String> {
  QuickSearchController();

  final textController = TextEditingController();
  final focusNode = FocusNode();

  // 搜索建议
  final RxList<SearchSuggestItem> searchSuggestList = <SearchSuggestItem>[].obs;

  // 搜索历史
  final historyList = List<String>.from(
    GStorage.historyWord.get('cacheList') ?? const <String>[],
  ).obs;

  final RxBool showUidBtn = false.obs;
  final recordSearchHistory = Pref.recordSearchHistory;
  final searchSuggestion = Pref.searchSuggestion;

  @override
  void onInit() {
    super.onInit();
    if (searchSuggestion) {
      subInit();
    }
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    validateUid();
    if (searchSuggestion) {
      if (textController.text.isEmpty) {
        searchSuggestList.clear();
      } else {
        ctr!.add(textController.text);
      }
    }
  }

  void validateUid() {
    showUidBtn.value = IdUtils.digitOnlyRegExp.hasMatch(textController.text);
  }

  /// 执行搜索
  void performSearch() {
    final keyword = textController.text.trim();
    if (keyword.isEmpty) {
      SmartDialog.showToast('请输入搜索关键词');
      return;
    }

    // 保存搜索历史
    if (recordSearchHistory) {
      historyList
        ..remove(keyword)
        ..insert(0, keyword);
      GStorage.historyWord.put('cacheList', historyList);
    }

    // 关闭对话框
    SmartDialog.dismiss();

    // 跳转到搜索结果页面
    Get.toNamed(
      '/searchResult',
      parameters: {
        'keyword': keyword,
      },
    );
  }

  /// 点击建议词
  void onClickSuggestion(String keyword) {
    textController.text = keyword;
    validateUid();
    if (searchSuggestion) {
      searchSuggestList.clear();
    }
    performSearch();
  }

  /// 点击历史记录
  void onClickHistory(String keyword) {
    textController.text = keyword;
    validateUid();
    performSearch();
  }

  /// 跳转到UID用户页面
  void toUidUserPage() {
    final uid = textController.text.trim();
    if (uid.isEmpty) return;
    SmartDialog.dismiss();
    Get.toNamed('/member?mid=$uid');
  }

  /// 清空输入
  void onClear() {
    textController.clear();
    searchSuggestList.clear();
    showUidBtn.value = false;
    focusNode.requestFocus();
  }

  @override
  Future<void> onValueChanged(String value) async {
    final res = await SearchHttp.searchSuggest(term: value);
    if (res case Success(:final response)) {
      if (response.tag?.isNotEmpty == true) {
        searchSuggestList.value = response.tag!;
      }
    }
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    subDispose();
    super.onClose();
  }
}

/// 防抖流混入
/// 用于搜索建议的防抖处理
mixin DebounceStreamMixin<T> {
  final Duration duration = const Duration(milliseconds: 200);
  StreamController<T>? ctr;
  StreamSubscription<T>? _sub;

  void onValueChanged(T value);

  void subInit() {
    _sub = (ctr = StreamController<T>()).stream
        .debounce(duration, trailing: true)
        .listen(onValueChanged);
  }

  void subDispose() {
    _sub?.cancel();
    ctr?.close();
    _sub = null;
    ctr = null;
  }
}
