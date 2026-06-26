import '../utils/time_utils.dart';

/// 本地帖子浏览历史项
/// 与需要登录的 Discourse 浏览历史区分，这是纯本地存储的浏览记录
class LocalTopicHistoryItem {
  final int topicId;
  final String title;
  final String? excerpt; // 摘要/简介
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final List<String> tags;
  final DateTime visitedAt; // 最近访问时间（本地生成）
  final int? lastReadPostNumber; // 最后阅读到的楼层

  const LocalTopicHistoryItem({
    required this.topicId,
    required this.title,
    this.excerpt,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.tags = const [],
    required this.visitedAt,
    this.lastReadPostNumber,
  });

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'title': title,
        'excerpt': excerpt,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryColor': categoryColor,
        'tags': tags,
        'visitedAt': visitedAt.toIso8601String(),
        'lastReadPostNumber': lastReadPostNumber,
      };

  factory LocalTopicHistoryItem.fromJson(Map<String, dynamic> json) =>
      LocalTopicHistoryItem(
        topicId: json['topicId'] as int,
        title: json['title'] as String,
        excerpt: json['excerpt'] as String?,
        categoryId: json['categoryId'] as int?,
        categoryName: json['categoryName'] as String?,
        categoryColor: json['categoryColor'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        visitedAt: TimeUtils.parseUtcTime(json['visitedAt'] as String?) ?? DateTime.now(),
        lastReadPostNumber: json['lastReadPostNumber'] as int?,
      );

  LocalTopicHistoryItem copyWith({
    String? title,
    String? excerpt,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    List<String>? tags,
    DateTime? visitedAt,
    int? lastReadPostNumber,
  }) =>
      LocalTopicHistoryItem(
        topicId: topicId,
        title: title ?? this.title,
        excerpt: excerpt ?? this.excerpt,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        categoryColor: categoryColor ?? this.categoryColor,
        tags: tags ?? this.tags,
        visitedAt: visitedAt ?? this.visitedAt,
        lastReadPostNumber: lastReadPostNumber ?? this.lastReadPostNumber,
      );
}
