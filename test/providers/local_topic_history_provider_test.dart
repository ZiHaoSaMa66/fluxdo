import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluxdo/providers/local_topic_history_provider.dart';
import 'package:fluxdo/models/local_topic_history_item.dart';

void main() {
  group('LocalTopicHistoryNotifier', () {
    late SharedPreferences prefs;
    late LocalTopicHistoryNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notifier = LocalTopicHistoryNotifier(prefs, debounceDuration: Duration.zero);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('初始状态为空列表', () {
      expect(notifier.state, isEmpty);
    });

    test('record 保存历史记录', () {
      notifier.record(
        topicId: 1,
        title: '测试标题',
        excerpt: '测试摘要',
        categoryId: 1,
        categoryName: '分类',
        categoryColor: 'FF0000',
        tags: ['tag1'],
        lastReadPostNumber: 5,
      );

      expect(notifier.state.length, 1);
      expect(notifier.state.first.topicId, 1);
      expect(notifier.state.first.title, '测试标题');
      expect(notifier.state.first.excerpt, '测试摘要');
      expect(notifier.state.first.categoryId, 1);
      expect(notifier.state.first.categoryName, '分类');
      expect(notifier.state.first.categoryColor, 'FF0000');
      expect(notifier.state.first.tags, ['tag1']);
      expect(notifier.state.first.lastReadPostNumber, 5);
    });

    test('record 按 topicId 去重并将最新访问移到头部', () {
      notifier.record(topicId: 1, title: '标题1');
      notifier.record(topicId: 2, title: '标题2');
      notifier.record(topicId: 1, title: '标题1更新');

      expect(notifier.state.length, 2);
      expect(notifier.state.first.topicId, 1);
      expect(notifier.state.first.title, '标题1更新');
      expect(notifier.state.last.topicId, 2);
    });

    test('record 超出上限时截断', () {
      // 添加 maxLocalTopicHistoryItems + 10 条记录
      for (var i = 0; i < maxLocalTopicHistoryItems + 10; i++) {
        notifier.record(topicId: i, title: '标题$i');
      }

      expect(notifier.state.length, maxLocalTopicHistoryItems);
      // 最新的记录应该在前面
      expect(notifier.state.first.topicId, maxLocalTopicHistoryItems + 9);
    });

    test('removeByTopicId 删除指定历史记录', () {
      notifier.record(topicId: 1, title: '标题1');
      notifier.record(topicId: 2, title: '标题2');
      notifier.record(topicId: 3, title: '标题3');

      notifier.removeByTopicId(2);

      expect(notifier.state.length, 2);
      expect(notifier.state.any((e) => e.topicId == 2), isFalse);
    });

    test('removeByTopicId 删除不存在的 topicId 不影响列表', () {
      notifier.record(topicId: 1, title: '标题1');

      notifier.removeByTopicId(999);

      expect(notifier.state.length, 1);
    });

    test('clearAll 清空所有历史记录', () {
      notifier.record(topicId: 1, title: '标题1');
      notifier.record(topicId: 2, title: '标题2');

      notifier.clearAll();

      expect(notifier.state, isEmpty);
    });

    test('持久化到 SharedPreferences', () async {
      notifier.record(topicId: 1, title: '标题1');

      // debounceDuration 为 Duration.zero，立即保存
      // 等待一小段时间确保异步保存完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 创建新的 notifier 实例，从 SharedPreferences 加载
      final newNotifier = LocalTopicHistoryNotifier(prefs);

      expect(newNotifier.state.length, 1);
      expect(newNotifier.state.first.topicId, 1);
      expect(newNotifier.state.first.title, '标题1');

      newNotifier.dispose();
    });

    test('SharedPreferences 数据损坏时返回空列表', () async {
      // 手动写入损坏的数据
      await prefs.setString('local_topic_history_items', 'invalid json');

      final newNotifier = LocalTopicHistoryNotifier(prefs);

      expect(newNotifier.state, isEmpty);

      newNotifier.dispose();
    });

    test('JSON 解析异常时返回空列表', () async {
      // 写入格式错误的 JSON
      await prefs.setString('local_topic_history_items', '{invalid}');

      final newNotifier = LocalTopicHistoryNotifier(prefs);

      expect(newNotifier.state, isEmpty);

      newNotifier.dispose();
    });
  });
}