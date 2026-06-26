import 'package:flutter/material.dart';
import 'package:app_icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_topic_history_item.dart';
import '../navigation/nav_action_bus.dart';
import '../providers/local_topic_history_provider.dart';
import '../widgets/common/error_view.dart';
import '../l10n/s.dart';
import '../utils/time_utils.dart';
import '../utils/dialog_utils.dart';
import 'topic_detail_page/topic_detail_page.dart';

/// 本地帖子浏览历史页面
/// 与需要登录的 Discourse 浏览历史区分，这是纯本地存储的浏览记录
class LocalTopicHistoryPage extends ConsumerStatefulWidget {
  const LocalTopicHistoryPage({super.key, this.isActive = true});

  /// 是否为当前活跃的 tab（嵌入底栏时用于决定是否响应 NavActionBus）
  final bool isActive;

  @override
  ConsumerState<LocalTopicHistoryPage> createState() =>
      _LocalTopicHistoryPageState();
}

class _LocalTopicHistoryPageState extends ConsumerState<LocalTopicHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_publishScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _publishScrollProgress() {
    if (!_scrollController.hasClients) return;
    final raw = _scrollController.offset;
    final progress = raw < 0 ? 0.0 : raw;
    final current =
        ref.read(navScrollProgressProvider(NavEntryIds.localHistory));
    final atZero = progress == 0 && current != 0;
    final crossed = (progress >= navScrollIconThreshold) !=
        (current >= navScrollIconThreshold);
    if (!atZero && !crossed && (progress - current).abs() < 4.0) return;
    ref.read(navScrollProgressProvider(NavEntryIds.localHistory).notifier).state =
        progress;
  }

  void _onItemTap(LocalTopicHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(
          topicId: item.topicId,
          scrollToPostNumber: item.lastReadPostNumber,
        ),
      ),
    );
  }

  void _onItemLongPress(LocalTopicHistoryItem item) {
    showAppBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Symbols.delete_rounded),
            title: Text(context.l10n.localTopicHistory_deleteItem),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(localTopicHistoryProvider.notifier)
                  .removeByTopicId(item.topicId);
            },
          ),
        ],
      ),
    );
  }

  void _onClearAll() {
    showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.localTopicHistory_clearAllTitle),
        content: Text(context.l10n.localTopicHistory_clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(localTopicHistoryProvider.notifier).clearAll();
              Navigator.pop(context, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.localTopicHistory_clearAllButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(localTopicHistoryProvider);

    // 嵌入底栏时响应快捷动作（仅活跃 tab 响应）
    ref.listen(navActionBusProvider, (_, event) {
      if (event == null || event.targetId != NavEntryIds.localHistory) return;
      if (!widget.isActive) return;
      switch (event.action) {
        case NavAction.scrollToTop:
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          break;
        case NavAction.refresh:
          // 本地历史没有刷新操作，只执行滚动到顶部
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          ref.resetNavScrollProgress(NavEntryIds.localHistory);
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.localTopicHistory_title),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Symbols.delete_sweep_rounded),
              tooltip: context.l10n.localTopicHistory_clearAll,
              onPressed: _onClearAll,
            ),
        ],
      ),
      body: _buildHistoryList(history),
    );
  }

  Widget _buildHistoryList(List<LocalTopicHistoryItem> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.history_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              context.l10n.localTopicHistory_empty,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(LocalTopicHistoryItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onItemTap(item),
        onLongPress: () => _onItemLongPress(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.excerpt != null && item.excerpt!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.excerpt!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // 元信息行
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // 分类
                  if (item.categoryName != null)
                    _buildCategoryChip(item.categoryName!, item.categoryColor),
                  // 标签
                  ...item.tags.map((tag) => _buildTagChip(tag)),
                  // 访问时间
                  _buildTimeChip(item.visitedAt),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String categoryName, String? categoryColor) {
    final theme = Theme.of(context);
    Color? color;
    if (categoryColor != null && categoryColor.isNotEmpty) {
      try {
        color = Color(int.parse('0xFF$categoryColor'));
      } catch (_) {
        color = null;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.15) ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            categoryName,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildTimeChip(DateTime visitedAt) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Symbols.schedule_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          TimeUtils.formatRelativeTime(visitedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
