import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/sse_client.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/task.dart';
import '../../../shared/utils/ansi_text.dart';
import '../../../shared/utils/api_utils.dart';
import '../../../shared/utils/time_utils.dart';
import '../../../shared/utils/log_background.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/task_cron_list.dart';
import '../providers/task_provider.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskStatusFilter {
  final String label;
  final String? value;

  const _TaskStatusFilter(this.label, this.value);
}

const _taskStatusFilters = [
  _TaskStatusFilter('全部', null),
  _TaskStatusFilter('运行中', '2'),
  _TaskStatusFilter('排队中', '0.5'),
  _TaskStatusFilter('已启用', '1'),
  _TaskStatusFilter('已禁用', '0'),
];

enum _TaskBatchAction { run, enable, disable, delete }

class _TaskListPageState extends ConsumerState<TaskListPage> {
  static const _collapsedGroupsStorageKey = 'tasks.collapsed_groups';
  static const _scrollOffsetStorageKey = 'tasks.scroll_offset';
  static const _selectedGroupStorageKey = 'tasks.selected_group';
  static const _groupOrderStorageKey = 'tasks.group_order';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _collapsedGroups = <String>{};
  final Set<int> _selectedTaskIds = <int>{};
  final List<String> _knownGroups = <String>[];
  List<String> _groupOrder = <String>[];
  bool _groupReorderMode = false;
  bool _selectionMode = false;
  bool _taskSortMode = false;
  bool _taskOrderDirty = false;
  Timer? _debounce;
  bool _restoredScrollOffset = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _restoreTaskUiState();
      if (!mounted) {
        return;
      }
      await ref.read(taskProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(taskProvider.notifier).loadMore();
    }

    if (_scrollController.hasClients) {
      SecureStorage.saveUiState(
        _scrollOffsetStorageKey,
        _scrollController.offset.toStringAsFixed(2),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showActionError(dynamic error, String fallback) async {
    _showMessage(_extractTaskError(error, fallback));
  }

  bool _isAllTasksSelected(List<Task> tasks) =>
      tasks.isNotEmpty &&
      tasks.every((task) => _selectedTaskIds.contains(task.id));

  void _setSelectionMode(bool enabled) {
    setState(() {
      _selectionMode = enabled;
      if (!enabled) {
        _selectedTaskIds.clear();
      }
    });
  }

  void _toggleTaskSelection(int id) {
    setState(() {
      _selectionMode = true;
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
      if (_selectedTaskIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _toggleSelectAllTasks(List<Task> tasks) {
    final visibleIds = tasks.map((task) => task.id).toSet();
    setState(() {
      if (visibleIds.isNotEmpty &&
          visibleIds.every((id) => _selectedTaskIds.contains(id))) {
        _selectedTaskIds.removeAll(visibleIds);
        if (_selectedTaskIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectionMode = true;
        _selectedTaskIds.addAll(visibleIds);
      }
    });
  }

  Future<bool> _confirmBatchTaskDelete(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('批量删除任务'),
        content: Text('确定要删除选中的 $count 个任务吗？此操作不可恢复。'),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('取消'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red500,
                    ),
                    child: const Text('删除'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _performBatchTaskAction(_TaskBatchAction action) async {
    final ids = _selectedTaskIds.toList()..sort();
    if (ids.isEmpty) {
      return;
    }

    if (action == _TaskBatchAction.run && ids.length > 10) {
      _showMessage('批量运行最多选择 10 个任务');
      return;
    }

    if (action == _TaskBatchAction.delete) {
      final confirmed = await _confirmBatchTaskDelete(ids.length);
      if (!confirmed) {
        return;
      }
    }

    try {
      final notifier = ref.read(taskProvider.notifier);
      switch (action) {
        case _TaskBatchAction.run:
          await notifier.batchRun(ids);
          break;
        case _TaskBatchAction.enable:
          await notifier.batchEnable(ids);
          break;
        case _TaskBatchAction.disable:
          await notifier.batchDisable(ids);
          break;
        case _TaskBatchAction.delete:
          await notifier.batchDelete(ids);
          break;
      }

      if (!mounted) {
        return;
      }

      _setSelectionMode(false);
      final message = switch (action) {
        _TaskBatchAction.run => '已批量运行 ${ids.length} 个任务',
        _TaskBatchAction.enable => '已批量启用 ${ids.length} 个任务',
        _TaskBatchAction.disable => '已批量禁用 ${ids.length} 个任务',
        _TaskBatchAction.delete => '已批量删除 ${ids.length} 个任务',
      };
      _showMessage(message);
    } catch (error) {
      await _showActionError(error, '批量操作失败');
    }
  }

  Future<void> _finishTaskSortMode(List<Task> tasks) async {
    if (!_taskOrderDirty) {
      setState(() => _taskSortMode = false);
      return;
    }

    try {
      await ref.read(taskProvider.notifier).saveTaskOrder(tasks);
      if (!mounted) {
        return;
      }
      setState(() {
        _taskSortMode = false;
        _taskOrderDirty = false;
      });
      _showMessage('任务排序已保存');
    } catch (error) {
      await _showActionError(error, '保存任务排序失败');
    }
  }

  Future<void> _openLatestLog(Task task) async {
    if (task.isRunning) {
      await _openLiveLog(task);
      return;
    }
    try {
      final latestLog = await ref
          .read(taskProvider.notifier)
          .fetchLatestLog(task.id);
      if (!mounted) {
        return;
      }
      if (latestLog == null) {
        _showMessage('当前任务暂无日志');
        return;
      }
      await context.push('/logs/${latestLog.id}/stream');
      if (mounted) {
        ref.read(taskProvider.notifier).load(refresh: true);
      }
    } catch (_) {
      _showMessage('打开日志失败');
    }
  }

  Future<void> _openLiveLog(Task task) async {
    await context.push('/tasks/${task.id}/live-logs', extra: task.name);
    if (mounted) {
      ref.read(taskProvider.notifier).load(refresh: true);
    }
  }

  Future<void> _runTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).runTask(task.id);
      if (!mounted) {
        return;
      }
      await _openLiveLog(task);
    } catch (error) {
      final message = _extractTaskError(error, '启动任务失败');
      if (!mounted) {
        return;
      }
      if (message.contains('运行中')) {
        await _openLiveLog(task);
        return;
      }
      _showMessage(message);
    }
  }

  Future<void> _stopTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).stopTask(task.id);
      _showMessage('任务已停止');
    } catch (error) {
      await _showActionError(error, '停止任务失败');
    }
  }

  Future<void> _toggleTaskEnabled(Task task) async {
    try {
      if (task.isDisabled) {
        await ref.read(taskProvider.notifier).enableTask(task.id);
        _showMessage('任务已启用');
      } else {
        await ref.read(taskProvider.notifier).disableTask(task.id);
        _showMessage(task.isRunning ? '任务已设置为完成后禁用' : '任务已禁用');
      }
    } catch (error) {
      await _showActionError(error, '更新任务状态失败');
    }
  }

  Future<void> _copyTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).copyTask(task.id);
      _showMessage('任务已复制');
    } catch (error) {
      await _showActionError(error, '复制任务失败');
    }
  }

  Future<void> _togglePinned(Task task) async {
    try {
      if (task.isPinned) {
        await ref.read(taskProvider.notifier).unpinTask(task.id);
        _showMessage('已取消置顶');
      } else {
        await ref.read(taskProvider.notifier).pinTask(task.id);
        _showMessage('已置顶任务');
      }
    } catch (error) {
      await _showActionError(error, '更新置顶状态失败');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0);
      }
      ref.read(taskProvider.notifier).setKeyword(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreTaskUiState() async {
    final collapsedRaw = await SecureStorage.getUiState(
      _collapsedGroupsStorageKey,
    );
    final selectedGroup = await SecureStorage.getUiState(
      _selectedGroupStorageKey,
    );
    final groups = <String>{};
    if (collapsedRaw != null && collapsedRaw.trim().isNotEmpty) {
      groups.addAll(
        collapsedRaw
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    } else {
      groups.add('');
    }
    if (!mounted) {
      return;
    }
    final groupOrderRaw = await SecureStorage.getUiState(_groupOrderStorageKey);
    final savedGroupOrder = <String>[];
    if (groupOrderRaw != null && groupOrderRaw.trim().isNotEmpty) {
      savedGroupOrder.addAll(groupOrderRaw.split('\n').map((s) => s.trim()));
    }
    if (!mounted) return;
    setState(() {
      _collapsedGroups
        ..clear()
        ..addAll(groups);
      _groupOrder = savedGroupOrder;
    });
    if (selectedGroup != null) {
      ref
          .read(taskProvider.notifier)
          .setLabelFilter(selectedGroup.trim().isEmpty ? null : selectedGroup);
    }
  }

  Future<void> _persistCollapsedGroups() {
    return SecureStorage.saveUiState(
      _collapsedGroupsStorageKey,
      _collapsedGroups.join('\n'),
    );
  }

  Future<void> _persistGroupOrder() {
    return SecureStorage.saveUiState(
      _groupOrderStorageKey,
      _groupOrder.join('\n'),
    );
  }

  List<_TaskGroup> _sortGroupsByOrder(List<_TaskGroup> groups) {
    if (_groupOrder.isEmpty) return groups;
    final orderMap = <String, int>{};
    for (var i = 0; i < _groupOrder.length; i++) {
      orderMap[_groupOrder[i]] = i;
    }
    groups.sort((a, b) {
      final ai = orderMap[a.key] ?? 9999;
      final bi = orderMap[b.key] ?? 9999;
      if (ai != bi) return ai.compareTo(bi);
      return 0;
    });
    return groups;
  }

  Future<void> _restoreScrollOffsetIfNeeded() async {
    if (_restoredScrollOffset || !_scrollController.hasClients) {
      return;
    }
    final raw = await SecureStorage.getUiState(_scrollOffsetStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      _restoredScrollOffset = true;
      return;
    }
    final offset = double.tryParse(raw);
    if (offset == null) {
      _restoredScrollOffset = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, maxOffset));
      _restoredScrollOffset = true;
    });
  }

  void _collectKnownGroups(List<Task> tasks) {
    final groups =
        tasks
            .map((task) => task.groupName?.trim() ?? '')
            .where((group) => group.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    _knownGroups
      ..clear()
      ..addAll(groups);
  }

  Future<void> _showGroupPicker() async {
    final options = [..._knownGroups];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('选择任务分组'), subtitle: Text('可筛选已有分组任务')),
            ListTile(
              leading: const Icon(Icons.layers_clear_outlined),
              title: const Text('全部分组'),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            ...options.map(
              (group) => ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(group),
                trailing: ref.watch(taskProvider).labelFilter == group
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, group),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.jumpTo(0);
    }
    ref
        .read(taskProvider.notifier)
        .setLabelFilter(selected.isEmpty ? null : selected);
    await SecureStorage.saveUiState(_selectedGroupStorageKey, selected);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final glassMode = ref.watch(appStyleProvider).glassMode;
    _collectKnownGroups(state.tasks);
    final groupedTasks = _sortGroupsByOrder(_groupTasks(state.tasks));
    final selectedCount = _selectedTaskIds.length;
    final allSelected = _isAllTasksSelected(state.tasks);
    _restoreScrollOffsetIfNeeded();

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '定时任务',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      if (!_taskSortMode)
                        _TaskHeaderChipButton(
                          label: _selectionMode ? '取消' : '批量',
                          icon: _selectionMode ? Icons.close : Icons.done_all,
                          isLight: isLight,
                          onTap: () => _setSelectionMode(!_selectionMode),
                        ),
                      if (!_selectionMode) ...[
                        const SizedBox(width: 8),
                        _TaskHeaderChipButton(
                          label: _taskSortMode ? '完成' : '排序',
                          icon: _taskSortMode ? Icons.check : Icons.swap_vert,
                          isLight: isLight,
                          onTap: () async {
                            if (_taskSortMode) {
                              await _finishTaskSortMode(state.tasks);
                            } else {
                              setState(() {
                                _taskSortMode = true;
                                _groupReorderMode = false;
                                _taskOrderDirty = false;
                              });
                            }
                          },
                        ),
                      ],
                      if (!_selectionMode && !_taskSortMode) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/tasks/new'),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(80),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索任务名称或命令...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.slate400,
                  ),
                  filled: true,
                  fillColor: glassFillColor(glassMode: glassMode, isLight: isLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isLight ? AppColors.slate200 : AppColors.slate800,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isLight ? AppColors.slate200 : AppColors.slate800,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.slate400,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(taskProvider.notifier).setKeyword('');
                          },
                        )
                      : null,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _taskStatusFilters.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final filter = _taskStatusFilters[index];
                  final selected = state.statusFilter == filter.value;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    onSelected: (_) {
                      if (_scrollController.hasClients &&
                          _scrollController.offset > 0) {
                        _scrollController.jumpTo(0);
                      }
                      ref
                          .read(taskProvider.notifier)
                          .setStatusFilter(filter.value);
                    },
                    selectedColor: AppColors.primary.withAlpha(18),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary.withAlpha(90)
                          : AppColors.slate200,
                    ),
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : null,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '共 ${state.total} 个任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showGroupPicker,
                    icon: const Icon(Icons.label_outline, size: 16),
                    label: Text(
                      state.labelFilter?.isNotEmpty == true
                          ? state.labelFilter!
                          : '全部分组',
                    ),
                  ),
                  if (state.statusFilter != null || state.labelFilter != null)
                    TextButton(
                      onPressed: () {
                        if (_scrollController.hasClients &&
                            _scrollController.offset > 0) {
                          _scrollController.jumpTo(0);
                        }
                        ref.read(taskProvider.notifier).setStatusFilter(null);
                        ref.read(taskProvider.notifier).setLabelFilter(null);
                        SecureStorage.saveUiState(_selectedGroupStorageKey, '');
                      },
                      child: const Text('清除筛选'),
                    ),
                ],
              ),
            ),
            if (_selectionMode) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TaskBatchActionButton(
                        label: allSelected ? '取消全选' : '全选',
                        icon: allSelected ? Icons.deselect : Icons.select_all,
                        color: AppColors.slate500,
                        isLight: isLight,
                        enabled: state.tasks.isNotEmpty,
                        onTap: () => _toggleSelectAllTasks(state.tasks),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量运行',
                        icon: Icons.play_circle_outline,
                        color: AppColors.primary,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () =>
                            _performBatchTaskAction(_TaskBatchAction.run),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量启用',
                        icon: Icons.toggle_on_outlined,
                        color: AppColors.primary,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () =>
                            _performBatchTaskAction(_TaskBatchAction.enable),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量禁用',
                        icon: Icons.toggle_off_outlined,
                        color: AppColors.slate500,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () =>
                            _performBatchTaskAction(_TaskBatchAction.disable),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量删除',
                        icon: Icons.delete_outline,
                        color: AppColors.red500,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () =>
                            _performBatchTaskAction(_TaskBatchAction.delete),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_taskSortMode) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppColors.primary.withAlpha(12)
                        : AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_vert, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '长按拖拽调整当前任务列表顺序，点击「完成」保存',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(taskProvider.notifier).load(refresh: true),
                child: state.loading && state.tasks.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    : state.tasks.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_buildEmpty()],
                      )
                    : _taskSortMode
                    ? _buildTaskReorderView(state.tasks, isLight, glassMode)
                    : _groupReorderMode
                    ? _buildGroupReorderView(groupedTasks, isLight, glassMode)
                    : ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        children: groupedTasks
                            .map((group) => _buildTaskGroup(group, isLight, glassMode))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.slate400.withAlpha(120),
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无任务',
            style: TextStyle(color: AppColors.slate400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  List<_TaskGroup> _groupTasks(List<Task> tasks) {
    final groups = <_TaskGroup>[];
    final map = <String, _TaskGroup>{};

    for (final task in tasks) {
      final groupName = task.groupName?.trim();
      final key = (groupName == null || groupName.isEmpty) ? '' : groupName;
      final title = key.isEmpty ? '未分组' : key;
      final entry = map.putIfAbsent(key, () {
        final created = _TaskGroup(key: key, title: title);
        groups.add(created);
        return created;
      });
      entry.tasks.add(task);
    }

    return groups;
  }

  Future<void> _renameGroup(String oldName, List<Task> tasks) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名分组'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '分组名称',
            hintText: '输入新的分组名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == oldName) return;
    try {
      await ref
          .read(taskProvider.notifier)
          .batchUpdateGroupLabel(
            tasks: tasks,
            oldGroupName: oldName,
            newGroupName: newName,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将分组 "$oldName" 重命名为 "$newName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('重命名分组失败')));
      }
    }
  }

  Future<void> _deleteGroup(String groupName, List<Task> tasks) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定将 "$groupName" 分组中的 ${tasks.length} 个任务移回未分组？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(taskProvider.notifier)
          .batchUpdateGroupLabel(
            tasks: tasks,
            oldGroupName: groupName,
            newGroupName: null,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除分组 "$groupName"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除分组失败')));
      }
    }
  }

  Future<void> _addTasksToGroup(
    String targetGroup,
    List<Task> ungroupedTasks,
  ) async {
    if (ungroupedTasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有未分组的任务可添加')));
      return;
    }
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('添加任务到 "$targetGroup"'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: ungroupedTasks.length,
              itemBuilder: (ctx, i) {
                final task = ungroupedTasks[i];
                return CheckboxListTile(
                  value: selected.contains(task.id),
                  title: Text(task.name, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  onChanged: (v) {
                    setDialogState(() {
                      if (v == true) {
                        selected.add(task.id);
                      } else {
                        selected.remove(task.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (selected.isEmpty) return;
                final tasksToMove = ungroupedTasks
                    .where((t) => selected.contains(t.id))
                    .toList();
                try {
                  await ref
                      .read(taskProvider.notifier)
                      .batchUpdateGroupLabel(
                        tasks: tasksToMove,
                        oldGroupName: null,
                        newGroupName: targetGroup,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '已将 ${tasksToMove.length} 个任务添加到 "$targetGroup"',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('添加任务到分组失败')));
                  }
                }
              },
              child: Text('添加 (${selected.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupFromUngrouped(List<Task> ungroupedTasks) async {
    final nameController = TextEditingController();
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建分组'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '分组名称',
                    hintText: '输入新分组的名称',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择要加入的任务:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: ungroupedTasks.length,
                    itemBuilder: (ctx, i) {
                      final task = ungroupedTasks[i];
                      return CheckboxListTile(
                        value: selected.contains(task.id),
                        title: Text(
                          task.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        dense: true,
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(task.id);
                            } else {
                              selected.remove(task.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final groupName = nameController.text.trim();
                Navigator.pop(ctx);
                if (groupName.isEmpty || selected.isEmpty) return;
                final tasksToMove = ungroupedTasks
                    .where((t) => selected.contains(t.id))
                    .toList();
                try {
                  await ref
                      .read(taskProvider.notifier)
                      .batchUpdateGroupLabel(
                        tasks: tasksToMove,
                        oldGroupName: null,
                        newGroupName: groupName,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '已创建分组 "$groupName" 并添加 ${tasksToMove.length} 个任务',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('创建分组失败')));
                  }
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  Widget _buildGroupReorderView(List<_TaskGroup> groups, bool isLight, bool glassMode) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.swap_vert, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '长按拖拽调整分组顺序',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _groupReorderMode = false),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            itemCount: groups.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = groups.removeAt(oldIndex);
                groups.insert(newIndex, item);
                _groupOrder = groups.map((g) => g.key).toList();
              });
              _persistGroupOrder();
            },
            itemBuilder: (ctx, i) {
              final group = groups[i];
              return Container(
                key: ValueKey(group.key),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: glassCardColor(glassMode: glassMode, isLight: isLight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLight ? AppColors.slate200 : AppColors.slate800,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        group.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${group.tasks.length} 条',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskReorderView(List<Task> tasks, bool isLight, bool glassMode) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(taskProvider.notifier).reorderLocalTasks(oldIndex, newIndex);
        setState(() => _taskOrderDirty = true);
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          key: ValueKey('task-sort-${task.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: glassCardColor(glassMode: glassMode, isLight: isLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.drag_handle,
                size: 20,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.groupName?.isNotEmpty == true
                          ? '分组：${task.groupName}'
                          : '未分组',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              _MetaChip(label: task.statusText, active: !task.isDisabled),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskGroup(_TaskGroup group, bool isLight, bool glassMode) {
    final collapsed = _collapsedGroups.contains(group.key);
    final enabledCount = group.tasks.where((task) => task.isEnabled).length;
    final runningCount = group.tasks.where((task) => task.isRunning).length;
    final isUngrouped = group.key.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: glassCardColor(glassMode: glassMode, isLight: isLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (collapsed) {
                  _collapsedGroups.remove(group.key);
                } else {
                  _collapsedGroups.add(group.key);
                }
              });
              _persistCollapsedGroups();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() => _groupReorderMode = true);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    collapsed ? Icons.chevron_right : Icons.expand_more,
                    size: 20,
                    color: AppColors.slate400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${group.tasks.length} 条',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (runningCount > 0)
                    _MetaChip(label: '$runningCount 运行中', active: true)
                  else
                    _MetaChip(
                      label: '$enabledCount 已启用',
                      active: enabledCount > 0,
                    ),
                  const SizedBox(width: 4),
                  _GroupPopupMenu(
                    isUngrouped: isUngrouped,
                    onRename: isUngrouped
                        ? null
                        : () => _renameGroup(group.key, group.tasks),
                    onDelete: isUngrouped
                        ? null
                        : () => _deleteGroup(group.key, group.tasks),
                    onAddTasks: () {
                      final allTasks = ref.read(taskProvider).tasks;
                      final ungrouped = allTasks
                          .where((t) => (t.groupName ?? '').isEmpty)
                          .toList();
                      final targetGroup = isUngrouped ? null : group.key;
                      if (targetGroup == null) {
                        _showCreateGroupFromUngrouped(ungrouped);
                      } else {
                        _addTasksToGroup(targetGroup, ungrouped);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!collapsed)
          ...group.tasks.map(
            (task) => _TaskCard(
              key: ValueKey('task-card-${task.id}'),
              task: task,
              isLight: isLight,
              glassMode: glassMode,
              selectionMode: _selectionMode,
              selected: _selectedTaskIds.contains(task.id),
              onTap: () => _selectionMode
                  ? _toggleTaskSelection(task.id)
                  : _openLatestLog(task),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _toggleTaskSelection(task.id);
              },
              onSelectedChanged: () => _toggleTaskSelection(task.id),
              onRun: () => _runTask(task),
              onStop: () => _stopTask(task),
              onToggleEnabled: () => _toggleTaskEnabled(task),
              onCopy: () => _copyTask(task),
              onTogglePinned: () => _togglePinned(task),
              onEdit: () => context.push('/tasks/edit', extra: task),
              onDelete: () => _confirmDelete(task),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final scriptPath = _extractScriptPathFromCommand(task.command);
    var deleteScript = false;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('删除任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('确定要删除「${task.name}」吗？'),
              if (scriptPath != null) ...[
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: deleteScript,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('同时删除关联脚本'),
                  subtitle: Text(scriptPath),
                  onChanged: (value) {
                    setDialogState(() => deleteScript = value ?? false);
                  },
                ),
              ],
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('取消'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red500,
                      ),
                      child: const Text('删除'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm != true) {
      return;
    }
    try {
      await ref.read(taskProvider.notifier).deleteTask(task.id);
      if (deleteScript && scriptPath != null) {
        try {
          await DioClient.instance.dio.delete(
            ApiEndpoints.scripts,
            queryParameters: {'path': scriptPath, 'type': 'file'},
          );
          _showMessage('任务和关联脚本已删除');
        } catch (error) {
          _showMessage(
            '任务已删除，但脚本删除失败：${extractErrorMessage(error, '请稍后手动删除脚本')}',
          );
        }
        return;
      }
      _showMessage('任务已删除');
    } catch (error) {
      await _showActionError(error, '删除任务失败');
    }
  }

  Future<void> _openLatestLog(Task task) async {
    if (task.isRunning) {
      await _openLiveLog(task);
      return;
    }
    try {
      final latestLog = await ref
          .read(taskProvider.notifier)
          .fetchLatestLog(task.id);
      if (!mounted) {
        return;
      }
      if (latestLog == null) {
        _showMessage('当前任务暂无日志');
        return;
      }
      await context.push('/logs/${latestLog.id}/stream');
      if (mounted) {
        ref.read(taskProvider.notifier).load(refresh: true);
      }
    } catch (_) {
      _showMessage('打开日志失败');
    }
  }

  Future<void> _openLiveLog(Task task) async {
    await context.push('/tasks/${task.id}/live-logs', extra: task.name);
    if (mounted) {
      ref.read(taskProvider.notifier).load(refresh: true);
    }
  }

  Future<void> _runTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).runTask(task.id);
      if (!mounted) {
        return;
      }
      await _openLiveLog(task);
    } catch (error) {
      final message = _extractTaskError(error, '启动任务失败');
      if (!mounted) {
        return;
      }
      if (message.contains('运行中')) {
        await _openLiveLog(task);
        return;
      }
      _showMessage(message);
    }
  }

  Future<void> _stopTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).stopTask(task.id);
      _showMessage('任务已停止');
    } catch (error) {
      await _showActionError(error, '停止任务失败');
    }
  }

  Future<void> _toggleTaskEnabled(Task task) async {
    try {
      if (task.isDisabled) {
        await ref.read(taskProvider.notifier).enableTask(task.id);
        _showMessage('任务已启用');
      } else {
        await ref.read(taskProvider.notifier).disableTask(task.id);
        _showMessage(task.isRunning ? '任务已设置为完成后禁用' : '任务已禁用');
      }
    } catch (error) {
      await _showActionError(error, '更新任务状态失败');
    }
  }

  Future<void> _copyTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).copyTask(task.id);
      _showMessage('任务已复制');
    } catch (error) {
      await _showActionError(error, '复制任务失败');
    }
  }

  Future<void> _togglePinned(Task task) async {
    try {
      if (task.isPinned) {
        await ref.read(taskProvider.notifier).unpinTask(task.id);
        _showMessage('已取消置顶');
      } else {
        await ref.read(taskProvider.notifier).pinTask(task.id);
        _showMessage('已置顶任务');
      }
    } catch (error) {
      await _showActionError(error, '更新置顶状态失败');
    }
  }
}

class _TaskCard extends StatefulWidget {
  final Task task;
  final bool isLight;
  final bool glassMode;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSelectedChanged;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onToggleEnabled;
  final VoidCallback onCopy;
  final VoidCallback onTogglePinned;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    super.key,
    required this.task,
    required this.isLight,
    required this.glassMode,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectedChanged,
    required this.onRun,
    required this.onStop,
    required this.onToggleEnabled,
    required this.onCopy,
    required this.onTogglePinned,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  static const double _actionWidth = 52;
  static const double _actionGap = 6;
  static const double _actionsWidth = _actionWidth * 3 + _actionGap * 2 + 8;

  double _dragOffset = 0;
  bool _dragging = false;

  Task get task => widget.task;

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionMode || oldWidget.task.id != widget.task.id) {
      _dragOffset = 0;
      _dragging = false;
    }
  }

  Color _dotColor() {
    if (task.isRunning) {
      return AppColors.primary;
    }
    if (task.isQueued) {
      return AppColors.amber500;
    }
    if (task.lastRunStatus == 1) {
      return AppColors.red500;
    }
    if (task.isEnabled) {
      return AppColors.primary;
    }
    return AppColors.slate300;
  }

  String _statusLabel() {
    if (task.isRunning) {
      return '运行中';
    }
    if (task.isQueued) {
      return '排队中';
    }
    if (task.isEnabled) {
      return '已启用';
    }
    return '已禁用';
  }

  Color _statusBg() {
    if (task.isRunning) {
      return widget.isLight
          ? AppColors.primaryLight
          : AppColors.primary.withAlpha(25);
    }
    if (task.isQueued) {
      return AppColors.amber500.withAlpha(widget.isLight ? 18 : 25);
    }
    if (task.isEnabled) {
      return widget.isLight
          ? AppColors.blue100
          : AppColors.blue500.withAlpha(25);
    }
    return widget.isLight ? AppColors.slate100 : AppColors.slate800;
  }

  Color _statusFg() {
    if (task.isRunning) {
      return widget.isLight ? const Color(0xFF047857) : AppColors.primary;
    }
    if (task.isQueued) {
      return AppColors.amber500;
    }
    if (task.isEnabled) {
      return widget.isLight ? AppColors.blue600 : AppColors.blue500;
    }
    return AppColors.slate500;
  }

  String _taskTypeLabel() {
    switch (task.taskType) {
      case 'manual':
        return '手动运行';
      case 'startup':
        return '开机运行';
      default:
        return '常规定时';
    }
  }

  List<String> _scheduleExpressions() {
    if (task.cronExpressions.isNotEmpty) {
      return task.cronExpressions;
    }
    if (task.cronExpression.trim().isNotEmpty) {
      return [task.cronExpression.trim()];
    }
    return const [];
  }

  String _bottomText() {
    if (task.isRunning) {
      return '点击查看实时日志';
    }
    if (task.lastRunStatus == 1 && task.lastRunAt != null) {
      return '上次失败：${formatTimeCn(task.lastRunAt, short: true)}';
    }
    if (task.nextRunAt != null) {
      return '下次运行：${formatTimeCn(task.nextRunAt, short: true)}';
    }
    if (task.taskType == 'manual') {
      return '手动触发';
    }
    if (task.taskType == 'startup') {
      return '面板启动时自动执行';
    }
    return '暂无计划';
  }

  void _closeActions() {
    if (_dragOffset == 0) {
      return;
    }
    setState(() => _dragOffset = 0);
  }

  void _runSwipeAction(VoidCallback action) {
    _closeActions();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor();
    final borderColor = widget.isLight
        ? AppColors.slate200
        : AppColors.slate800;
    final labels = task.userLabelsForDisplay;
    final hasFailure = task.lastRunStatus == 1;
    final primaryColor = task.isRunning ? AppColors.red500 : AppColors.primary;

    return PopScope(
      canPop: _dragOffset == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _dragOffset == 0) {
          return;
        }
        _closeActions();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TaskSwipeActionButton(
                            label: task.isDisabled ? '启用' : '禁用',
                            icon: task.isDisabled
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            color: task.isDisabled
                                ? AppColors.primary
                                : AppColors.slate500,
                            onTap: () => _runSwipeAction(widget.onToggleEnabled),
                          ),
                          const SizedBox(width: _actionGap),
                          _TaskSwipeActionButton(
                            label: task.isPinned ? '取消' : '置顶',
                            icon: task.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                            color: AppColors.amber500,
                            onTap: () => _runSwipeAction(widget.onTogglePinned),
                          ),
                          const SizedBox(width: _actionGap),
                          _TaskSwipeActionButton(
                            label: '复制',
                            icon: Icons.copy_outlined,
                            color: AppColors.blue500,
                            onTap: () => _runSwipeAction(widget.onCopy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _actionGap),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TaskSwipeActionButton(
                            label: '编辑',
                            icon: Icons.edit_outlined,
                            color: AppColors.slate500,
                            onTap: () => _runSwipeAction(widget.onEdit),
                          ),
                          const SizedBox(width: _actionGap),
                          _TaskSwipeActionButton(
                            label: '删除',
                            icon: Icons.delete_outline,
                            color: AppColors.red500,
                            onTap: () => _runSwipeAction(widget.onDelete),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_dragOffset != 0) {
                  _closeActions();
                  return;
                }
                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              onHorizontalDragStart: widget.selectionMode
                  ? null
                  : (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: widget.selectionMode
                  ? null
                  : (details) {
                      final nextOffset = (_dragOffset + details.delta.dx)
                          .clamp(-_actionsWidth, 0.0)
                          .toDouble();
                      if (nextOffset == _dragOffset) {
                        return;
                      }
                      setState(() => _dragOffset = nextOffset);
                    },
              onHorizontalDragCancel: widget.selectionMode
                  ? null
                  : () => setState(() => _dragging = false),
              onHorizontalDragEnd: widget.selectionMode
                  ? null
                  : (_) {
                      final nextOffset =
                          _dragOffset.abs() > _actionsWidth * 0.42
                          ? -_actionsWidth
                          : 0.0;
                      setState(() {
                        _dragging = false;
                        _dragOffset = nextOffset;
                      });
                      if (nextOffset == -_actionsWidth) {
                        HapticFeedback.selectionClick();
                      }
                    },
              child: AnimatedContainer(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: glassCardColor(glassMode: widget.glassMode, isLight: widget.isLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.primary
                        : (hasFailure
                              ? AppColors.red500.withAlpha(60)
                              : borderColor),
                    width: widget.selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.selectionMode) ...[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: widget.selected,
                              onChanged: (_) => widget.onSelectedChanged(),
                              activeColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            boxShadow: task.isRunning || hasFailure
                                ? [
                                    BoxShadow(
                                      color: dotColor.withAlpha(140),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin,
                              size: 13,
                              color: AppColors.amber500,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg(),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusFg(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _TaskScheduleSummary(
                      taskType: task.taskType,
                      taskTypeLabel: _taskTypeLabel(),
                      expressions: _scheduleExpressions(),
                      isLight: widget.isLight,
                    ),
                    if (labels.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _TaskSubscriptionSummary(
                        labels: labels,
                        isLight: widget.isLight,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _bottomText(),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasFailure
                                  ? AppColors.red500
                                  : (widget.isLight
                                        ? AppColors.slate400
                                        : AppColors.slate500),
                            ),
                          ),
                        ),
                        if (!widget.selectionMode) ...[
                          _TaskPrimaryActionButton(
                            label: task.isRunning ? '停止' : '运行',
                            icon: task.isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: primaryColor,
                            onTap: task.isRunning
                                ? widget.onStop
                                : widget.onRun,
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.swipe_left_alt_rounded,
                            size: 16,
                            color: AppColors.slate400,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskPrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TaskPrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Material(
      color: color.withAlpha(isLight ? 22 : 34),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSwipeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TaskSwipeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: _TaskCardState._actionWidth,
      child: Material(
        color: color.withAlpha(isLight ? 22 : 34),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskScheduleSummary extends StatelessWidget {
  final String taskType;
  final String taskTypeLabel;
  final List<String> expressions;
  final bool isLight;

  const _TaskScheduleSummary({
    required this.taskType,
    required this.taskTypeLabel,
    required this.expressions,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final isCron = taskType == 'cron';
    final cleanExpressions = expressions
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final title = isCron
        ? (cleanExpressions.length > 1
              ? 'Cron 定时 · ${cleanExpressions.length} 条'
              : 'Cron 定时')
        : taskTypeLabel;
    final value = isCron
        ? (cleanExpressions.isEmpty ? '暂无定时规则' : cleanExpressions.first)
        : (taskType == 'manual' ? '手动触发运行' : '面板启动时自动执行');
    final icon = isCron
        ? Icons.schedule_rounded
        : taskType == 'manual'
        ? Icons.touch_app_outlined
        : Icons.power_settings_new_rounded;
    final color = isCron
        ? AppColors.primary
        : taskType == 'manual'
        ? AppColors.blue500
        : AppColors.amber500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLight ? AppColors.slate50 : AppColors.slate800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? AppColors.slate200 : AppColors.slate700,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(isLight ? 22 : 36),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isLight ? AppColors.slate600 : AppColors.slate300,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    fontFamily: isCron ? 'monospace' : null,
                    color: isLight ? AppColors.slate800 : AppColors.slate100,
                  ),
                ),
              ],
            ),
          ),
          if (cleanExpressions.length > 1) ...[
            const SizedBox(width: 8),
            _TaskMiniCountChip(
              label: '+${cleanExpressions.length - 1}',
              isLight: isLight,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskSubscriptionSummary extends ConsumerWidget {
  final List<String> labels;
  final bool isLight;

  const _TaskSubscriptionSummary({required this.labels, required this.isLight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;
    final visibleLabels = labels.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: glassCardColor(glassMode: glassMode, isLight: isLight),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? AppColors.slate200 : AppColors.slate800,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: AppColors.blue500.withAlpha(isLight ? 18 : 30),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_rounded, size: 12, color: AppColors.blue500),
                SizedBox(width: 3),
                Text(
                  '订阅',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...visibleLabels.map(
                  (label) =>
                      _TaskSubscriptionChip(label: label, isLight: isLight),
                ),
                if (labels.length > visibleLabels.length)
                  _TaskMiniCountChip(
                    label: '+${labels.length - visibleLabels.length}',
                    isLight: isLight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSubscriptionChip extends StatelessWidget {
  final String label;
  final bool isLight;

  const _TaskSubscriptionChip({required this.label, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLight ? AppColors.slate50 : AppColors.slate800,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLight ? AppColors.slate200 : AppColors.slate700,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLight ? AppColors.slate600 : AppColors.slate300,
        ),
      ),
    );
  }
}

class _TaskMiniCountChip extends StatelessWidget {
  final String label;
  final bool isLight;

  const _TaskMiniCountChip({required this.label, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isLight ? AppColors.slate100 : AppColors.slate800,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isLight ? AppColors.slate500 : AppColors.slate400,
        ),
      ),
    );
  }
}

class _TaskGroup {
  final String key;
  final String title;
  final List<Task> tasks = <Task>[];

  _TaskGroup({required this.key, required this.title});
}

String? _extractScriptPathFromCommand(String command) {
  final trimmed = command.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final tokens = _splitCommandTokens(trimmed);
  if (tokens.isEmpty) {
    return null;
  }

  bool hasSupportedExtension(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.py') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.sh') ||
        lower.endsWith('.go');
  }

  String? joinCandidate(List<String> items) {
    for (var count = items.length; count >= 1; count--) {
      final candidate = items.take(count).join(' ').trim();
      if (hasSupportedExtension(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  switch (tokens.first) {
    case 'task':
    case 'desi':
      final rest = tokens.sublist(1);
      var idx = 0;
      while (idx < rest.length) {
        if (rest[idx] == '-m' && idx + 1 < rest.length) {
          idx += 2;
          continue;
        }
        if (rest[idx] == '-l') {
          idx += 1;
          continue;
        }
        break;
      }
      return joinCandidate(rest.sublist(idx));
    case 'python':
    case 'python3':
    case 'node':
    case 'ts-node':
    case 'bash':
    case 'go':
      if (tokens.length <= 1) {
        return null;
      }
      return joinCandidate(tokens.sublist(1));
    default:
      return null;
  }
}

List<String> _splitCommandTokens(String command) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  String? quote;

  for (final rune in command.runes) {
    final char = String.fromCharCode(rune);
    if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        buffer.write(char);
      }
      continue;
    }

    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }

    if (char.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }

    buffer.write(char);
  }

  if (buffer.isNotEmpty) {
    tokens.add(buffer.toString());
  }

  return tokens;
}

class _MetaChip extends ConsumerWidget {
  final String label;
  final bool active;

  const _MetaChip({required this.label, this.active = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final glassMode = ref.watch(appStyleProvider).glassMode;
    final background = active
        ? (isLight ? AppColors.slate50 : AppColors.slate800)
        : (isLight ? AppColors.slate100 : AppColors.slate900);
    final foreground = active
        ? (isLight ? AppColors.slate700 : AppColors.slate300)
        : AppColors.slate400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLight ? AppColors.slate200 : AppColors.slate800,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHeaderChipButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool isLight;
  final VoidCallback onTap;

  const _TaskHeaderChipButton({
    required this.label,
    required this.icon,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: glassCardColor(glassMode: glassMode, isLight: isLight),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLight ? AppColors.slate200 : AppColors.slate800,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.slate400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBatchActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLight;
  final bool enabled;
  final VoidCallback onTap;

  const _TaskBatchActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLight,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled
        ? (isLight ? color.withAlpha(18) : color.withAlpha(24))
        : (isLight ? AppColors.slate50 : AppColors.slate800);
    final borderColor = enabled
        ? color.withAlpha(isLight ? 60 : 90)
        : (isLight ? AppColors.slate200 : AppColors.slate700);
    final foregroundColor = enabled ? color : AppColors.slate400;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
