import 'dart:async';
import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_topic_history_item.dart';
import 'theme_provider.dart'; // sharedPreferencesProvider

/// 本地帖子浏览历史最大条数
const int maxLocalTopicHistoryItems = 500;

/// 本地帖子浏览历史状态管理
/// 与需要登录的 Discourse 浏览历史区分，这是纯本地存储的浏览记录
class LocalTopicHistoryNotifier
    extends StateNotifier<List<LocalTopicHistoryItem>> {
  static const String _storageKey = 'local_topic_history_items';
  static const Duration _defaultDebounceDuration = Duration(seconds: 2);

  final SharedPreferences _prefs;
  final Duration _debounceDuration;
  Timer? _saveTimer;

  LocalTopicHistoryNotifier(this._prefs, {Duration? debounceDuration})
      : _debounceDuration = debounceDuration ?? _defaultDebounceDuration,
        super(_load(_prefs));

  static List<LocalTopicHistoryItem> _load(SharedPreferences prefs) {
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => LocalTopicHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 记录一条浏览历史
  /// 同 topicId 去重：更新信息和时间，移到头部
  void record({
    required int topicId,
    required String title,
    String? excerpt,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    List<String>? tags,
    int? lastReadPostNumber,
  }) {
    final now = DateTime.now();
    final newItem = LocalTopicHistoryItem(
      topicId: topicId,
      title: title,
      excerpt: excerpt,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      tags: tags ?? [],
      visitedAt: now,
      lastReadPostNumber: lastReadPostNumber,
    );

    // 快速路径：首访帖子（最常见），无需 filter 拷贝
    final existingIndex = state.indexWhere((e) => e.topicId == topicId);
    if (existingIndex == -1) {
      // 新条目：直接 prepend，超出上限则截断尾部
      final list = [newItem, ...state];
      state = list.length > maxLocalTopicHistoryItems
          ? list.sublist(0, maxLocalTopicHistoryItems)
          : list;
    } else if (existingIndex == 0 &&
        state.first.title == title &&
        state.first.lastReadPostNumber == lastReadPostNumber) {
      // 命中同一帖子且信息未变（重复打开同一帖子），仅更新时间
      state = [newItem, ...state.sublist(1)];
    } else {
      // 已有条目需更新：移除旧条目后插入头部
      final list = [
        newItem,
        ...state.sublist(0, existingIndex),
        ...state.sublist(existingIndex + 1),
      ];
      state = list.length > maxLocalTopicHistoryItems
          ? list.sublist(0, maxLocalTopicHistoryItems)
          : list;
    }
    _debounceSave();
  }

  /// 删除单条历史
  void removeByTopicId(int topicId) {
    state = state.where((e) => e.topicId != topicId).toList();
    _debounceSave();
  }

  /// 清空全部历史
  void clearAll() {
    state = [];
    _debounceSave();
  }

  /// 防抖保存：延迟写入 SharedPreferences，避免频繁序列化
  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_debounceDuration, _save);
  }

  void _save() {
    final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
    _prefs.setString(_storageKey, jsonStr);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // dispose 前立即保存，避免丢失数据
    _save();
    super.dispose();
  }
}

final localTopicHistoryProvider = StateNotifierProvider<
    LocalTopicHistoryNotifier, List<LocalTopicHistoryItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalTopicHistoryNotifier(prefs);
});
