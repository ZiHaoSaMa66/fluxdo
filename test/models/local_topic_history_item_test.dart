import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/models/local_topic_history_item.dart';

void main() {
  group('LocalTopicHistoryItem', () {
    test('toJson/fromJson 往返序列化', () {
      final item = LocalTopicHistoryItem(
        topicId: 123,
        title: '测试标题',
        excerpt: '测试摘要',
        categoryId: 1,
        categoryName: '测试分类',
        categoryColor: 'FF0000',
        tags: ['tag1', 'tag2'],
        visitedAt: DateTime(2024, 1, 15, 10, 30),
        lastReadPostNumber: 5,
      );

      final json = item.toJson();
      final restored = LocalTopicHistoryItem.fromJson(json);

      expect(restored.topicId, 123);
      expect(restored.title, '测试标题');
      expect(restored.excerpt, '测试摘要');
      expect(restored.categoryId, 1);
      expect(restored.categoryName, '测试分类');
      expect(restored.categoryColor, 'FF0000');
      expect(restored.tags, ['tag1', 'tag2']);
      expect(restored.visitedAt, DateTime(2024, 1, 15, 10, 30));
      expect(restored.lastReadPostNumber, 5);
    });

    test('fromJson 处理空值', () {
      final json = {
        'topicId': 456,
        'title': '标题',
        'visitedAt': '2024-01-15T10:30:00.000Z',
      };

      final item = LocalTopicHistoryItem.fromJson(json);

      expect(item.topicId, 456);
      expect(item.title, '标题');
      expect(item.excerpt, isNull);
      expect(item.categoryId, isNull);
      expect(item.categoryName, isNull);
      expect(item.categoryColor, isNull);
      expect(item.tags, isEmpty);
      expect(item.lastReadPostNumber, isNull);
    });

    test('fromJson 处理空 tags 列表', () {
      final json = {
        'topicId': 789,
        'title': '标题',
        'tags': [],
        'visitedAt': '2024-01-15T10:30:00.000',
      };

      final item = LocalTopicHistoryItem.fromJson(json);
      expect(item.tags, isEmpty);
    });

    test('copyWith 正确更新字段', () {
      final item = LocalTopicHistoryItem(
        topicId: 123,
        title: '原标题',
        visitedAt: DateTime(2024, 1, 15),
      );

      final updated = item.copyWith(
        title: '新标题',
        excerpt: '新摘要',
        categoryId: 2,
      );

      expect(updated.topicId, 123); // 保持不变
      expect(updated.title, '新标题');
      expect(updated.excerpt, '新摘要');
      expect(updated.categoryId, 2);
      expect(updated.visitedAt, DateTime(2024, 1, 15)); // 保持不变
    });

    test('copyWith 不传参数时保持原值', () {
      final item = LocalTopicHistoryItem(
        topicId: 123,
        title: '标题',
        excerpt: '摘要',
        visitedAt: DateTime(2024, 1, 15),
      );

      final copied = item.copyWith();

      expect(copied.topicId, 123);
      expect(copied.title, '标题');
      expect(copied.excerpt, '摘要');
      expect(copied.visitedAt, DateTime(2024, 1, 15));
    });
  });
}