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
      if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      if (!enabled) _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedTaskIds.contains(id)
          ? _selectedTaskIds.remove(id)
          : _selectedTaskIds.add(id);

      if (_selectedTaskIds.isEmpty) _selectionMode = false;
    });
  }

  void _toggleSelectAllTasks(List<Task> tasks) {
    final visibleIds = tasks.map((t) => t.id).toSet();
    setState(() {
      if (visibleIds.every(_selectedTaskIds.contains)) {
        _selectedTaskIds.removeAll(visibleIds);
        if (_selectedTaskIds.isEmpty) _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedTaskIds.addAll(visibleIds);
      }
    });
  }

  Future<bool> _confirmBatchTaskDelete(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除任务'),
        content: Text('确定要删除选中的 $count 个任务吗？此操作不可恢复。'),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
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
    if (ids.isEmpty) return;

    if (action == _TaskBatchAction.run && ids.length > 10) {
      _showMessage('批量运行最多选择 10 个任务');
      return;
    }

    if (action == _TaskBatchAction.delete) {
      final confirmed = await _confirmBatchTaskDelete(ids.length);
      if (!confirmed) return;
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

      if (!mounted) return;
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
      if (!mounted) return;
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
      _openLiveLog(task);
      return;
    }
    try {
      final latestLog = await ref
          .read(taskProvider.notifier)
          .fetchLatestLog(task.id);
      if (!mounted) return;
      if (latestLog == null) {
        _showMessage('当前任务暂无日志');
        return;
      }
      context.push('/logs/${latestLog.id}/stream');
    } catch (_) {
      _showMessage('打开日志失败');
    }
  }

  void _openLiveLog(Task task) {
    context.push('/tasks/${task.id}/live-logs', extra: task.name);
  }

  Future<void> _runTask(Task task) async {
    try {
      await ref.read(taskProvider.notifier).runTask(task.id);
      if (!mounted) return;
      _openLiveLog(task);
    } catch (error) {
      final message = _extractTaskError(error, '启动任务失败');
      if (!mounted) return;
      if (message.contains('运行中')) {
        _openLiveLog(task);
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
    final collapsedRaw =
        await SecureStorage.getUiState(_collapsedGroupsStorageKey);
    final selectedGroup =
        await SecureStorage.getUiState(_selectedGroupStorageKey);

    final groups = <String>{};
    if (collapsedRaw != null && collapsedRaw.trim().isNotEmpty) {
      groups.addAll(collapsedRaw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty));
    } else {
      groups.add('');
    }

    final groupOrderRaw =
        await SecureStorage.getUiState(_groupOrderStorageKey);
    final savedGroupOrder = <String>[];
    if (groupOrderRaw != null && groupOrderRaw.trim().isNotEmpty) {
      savedGroupOrder.addAll(
        groupOrderRaw.split('\n').map((e) => e.trim()),
      );
    }

    if (!mounted) return;
    setState(() {
      _collapsedGroups
        ..clear()
        ..addAll(groups);
      _groupOrder = savedGroupOrder;
    });

    if (selectedGroup != null) {
      ref.read(taskProvider.notifier).setLabelFilter(
            selectedGroup.trim().isEmpty ? null : selectedGroup,
          );
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
    final orderMap = {for (int i = 0; i < _groupOrder.length; i++) _groupOrder[i]: i};
    groups.sort((a, b) {
      final ai = orderMap[a.key] ?? 9999;
      final bi = orderMap[b.key] ?? 9999;
      if (ai != bi) return ai.compareTo(bi);
      return 0;
    });
    return groups;
  }

  Future<void> _restoreScrollOffsetIfNeeded() async {
    if (_restoredScrollOffset || !_scrollController.hasClients) return;

    final raw = await SecureStorage.getUiState(_scrollOffsetStorageKey);
    final offset = raw == null ? null : double.tryParse(raw);
    if (offset == null) {
      _restoredScrollOffset = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, maxOffset));
      _restoredScrollOffset = true;
    });
  }

  void _collectKnownGroups(List<Task> tasks) {
    final groups = tasks
        .map((t) => t.groupName?.trim() ?? '')
        .where((g) => g.isNotEmpty)
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('选择任务分组'),
              subtitle: Text('可筛选已有分组任务'),
            ),
            ListTile(
              leading: const Icon(Icons.layers_clear_outlined),
              title: const Text('全部分组'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...options.map(
              (group) => ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(group),
                trailing:
                    ref.watch(taskProvider).labelFilter == group
                        ? const Icon(Icons.check,
                            color: AppColors.primary)
                        : null,
                onTap: () => Navigator.pop(ctx, group),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.jumpTo(0);
    }
    ref
        .read(taskProvider.notifier)
        .setLabelFilter(selected.isEmpty ? null : selected);
    await SecureStorage.saveUiState(
        _selectedGroupStorageKey, selected);
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
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
        ),
        child: Column(
          children: [
            // ====== 顶部标题 & 操作按钮 ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '定时任务',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      if (!_taskSortMode)
                        _TaskHeaderChipButton(
                          label: _selectionMode ? '取消' : '批量',
                          icon: _selectionMode
                              ? Icons.close
                              : Icons.done_all,
                          isLight: isLight,
                          onTap: () =>
                              _setSelectionMode(!_selectionMode),
                        ),
                      if (!_selectionMode) ...[
                        const SizedBox(width: 8),
                        _TaskHeaderChipButton(
                          label: _taskSortMode ? '完成' : '排序',
                          icon: _taskSortMode
                              ? Icons.check
                              : Icons.swap_vert,
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
                                  color: AppColors.primary
                                      .withAlpha(80),
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

            // ====== 搜索框 ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索任务名称或命令...',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.slate400),
                  filled: true,
                  fillColor: glassFillColor(
                      glassMode: glassMode, isLight: isLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isLight
                          ? AppColors.slate200
                          : AppColors.slate800,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isLight
                          ? AppColors.slate200
                          : AppColors.slate800,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16,
                              color: AppColors.slate400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref
                                .read(taskProvider.notifier)
                                .setKeyword('');
                          },
                        )
                      : null,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 12),

            // ====== 状态过滤 ======
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _taskStatusFilters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final filter = _taskStatusFilters[index];
                  final selected =
                      state.statusFilter == filter.value;
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
                    selectedColor:
                        AppColors.primary.withAlpha(18),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary.withAlpha(90)
                          : AppColors.slate200,
                    ),
                    labelStyle: TextStyle(
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : null,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ====== 统计 & 分组筛选 ======
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
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
                    icon: const Icon(Icons.label_outline,
                        size: 16),
                    label: Text(
                      state.labelFilter?.isNotEmpty == true
                          ? state.labelFilter!
                          : '全部分组',
                    ),
                  ),
                  if (state.statusFilter != null ||
                      state.labelFilter != null)
                    TextButton(
                      onPressed: () {
                        if (_scrollController.hasClients &&
                            _scrollController.offset > 0) {
                          _scrollController.jumpTo(0);
                        }
                        ref
                            .read(taskProvider.notifier)
                            .setStatusFilter(null);
                        ref
                            .read(taskProvider.notifier)
                            .setLabelFilter(null);
                        SecureStorage.saveUiState(
                            _selectedGroupStorageKey, '');
                      },
                      child: const Text('清除筛选'),
                    ),
                ],
              ),
            ),

            // ====== 批量操作栏 ======
            if (_selectionMode)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TaskBatchActionButton(
                        label: allSelected ? '取消全选' : '全选',
                        icon: allSelected
                            ? Icons.deselect
                            : Icons.select_all,
                        color: AppColors.slate500,
                        isLight: isLight,
                        enabled: state.tasks.isNotEmpty,
                        onTap: () =>
                            _toggleSelectAllTasks(state.tasks),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量运行',
                        icon: Icons.play_circle_outline,
                        color: AppColors.primary,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () => _performBatchTaskAction(
                            _TaskBatchAction.run),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量启用',
                        icon: Icons.toggle_on_outlined,
                        color: AppColors.primary,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () => _performBatchTaskAction(
                            _TaskBatchAction.enable),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量禁用',
                        icon: Icons.toggle_off_outlined,
                        color: AppColors.slate500,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () => _performBatchTaskAction(
                            _TaskBatchAction.disable),
                      ),
                      const SizedBox(width: 8),
                      _TaskBatchActionButton(
                        label: '批量删除',
                        icon: Icons.delete_outline,
                        color: AppColors.red500,
                        isLight: isLight,
                        enabled: selectedCount > 0,
                        onTap: () => _performBatchTaskAction(
                            _TaskBatchAction.delete),
                      ),
                    ],
                  ),
                ),
              ),

            // ====== 排序提示 ======
            if (_taskSortMode)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppColors.primary.withAlpha(12)
                        : AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withAlpha(40)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_vert,
                          size: 16, color: AppColors.primary),
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

            // ====== 主列表 ======
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(taskProvider.notifier)
                    .load(refresh: true),
                child: state.loading && state.tasks.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
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
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [_buildEmpty()],
                          )
                        : _taskSortMode
                            ? _buildTaskReorderView(
                                state.tasks, isLight, glassMode)
                            : _groupReorderMode
                                ? _buildGroupReorderView(
                                    groupedTasks,
                                    isLight,
                                    glassMode,
                                  )
                                : ListView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                            20, 0, 20, 110),
                                    children: groupedTasks
                                        .map((group) =>
                                            _buildTaskGroup(
                                              group,
                                              isLight,
                                              glassMode,
                                            ))
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
            style: TextStyle(
                color: AppColors.slate400, fontSize: 15),
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
      final key =
          (groupName == null || groupName.isEmpty) ? '' : groupName;
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

  Future<void> _renameGroup(
      String oldName, List<Task> tasks) async {
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
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null ||
        newName.isEmpty ||
        newName == oldName) {
      return;
    }
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
          SnackBar(
              content: Text('已将分组 "$oldName" 重命名为 "$newName"')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重命名分组失败')),
        );
      }
    }
  }

  Future<void> _deleteGroup(
      String groupName, List<Task> tasks) async {
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
            child: const Text('确定',
                style: TextStyle(color: Colors.red)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除分组 "$groupName"')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除分组失败')),
        );
      }
    }
  }

  Future<void> _addTasksToGroup(
    String targetGroup,
    List<Task> ungroupedTasks,
  ) async {
    if (ungroupedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有未分组的任务可添加')),
      );
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
                  title: Text(task.name,
                      style: const TextStyle(fontSize: 14)),
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
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('添加任务到分组失败')),
                    );
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

  Future<void> _showCreateGroupFromUngrouped(
      List<Task> ungroupedTasks) async {
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: ungroupedTasks.length,
                    itemBuilder: (ctx, i) {
                      final task = ungroupedTasks[i];
                      return CheckboxListTile(
                        value: selected.contains(task.id),
                        title: Text(task.name,
                            style:
                                const TextStyle(fontSize: 14)),
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
                final groupName =
                    nameController.text.trim();
                Navigator.pop(ctx);
                if (groupName.isEmpty ||
                    selected.isEmpty) {
                  return;
                }
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          '已创建分组 "$groupName" 并添加 ${tasksToMove.length} 个任务',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content: Text('创建分组失败')),
                    );
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

  Widget _buildGroupReorderView(
      List<_TaskGroup> groups, bool isLight, bool glassMode) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.swap_vert, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '长按拖拽调整分组顺序',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _groupReorderMode = false),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 110),
            itemCount: groups.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = groups.removeAt(oldIndex);
                groups.insert(newIndex, item);
                _groupOrder =
                    groups.map((g) => g.key).toList();
              });
              _persistGroupOrder();
            },
            itemBuilder: (ctx, i) {
              final group = groups[i];
              return Container(
                key: ValueKey(group.key),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: glassCardColor(
                      glassMode: glassMode, isLight: isLight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLight
                        ? AppColors.slate200
                        : AppColors.slate800,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle,
                        size: 20,
                        color: AppColors.slate400),
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

  Widget _buildTaskReorderView(
      List<Task> tasks, bool isLight, bool glassMode) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(taskProvider.notifier)
            .reorderLocalTasks(oldIndex, newIndex);
        setState(() => _taskOrderDirty = true);
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          key: ValueKey('task-sort-${task.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: glassCardColor(
                glassMode: glassMode, isLight: isLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight
                  ? AppColors.slate200
                  : AppColors.slate800,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_handle,
                  size: 20, color: AppColors.slate400),
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
              _MetaChip(
                  label: task.statusText,
                  active: !task.isDisabled),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskGroup(
      _TaskGroup group, bool isLight, bool glassMode) {
    final collapsed = _collapsedGroups.contains(group.key);
    final isUngrouped = group.key.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: glassCardColor(
                glassMode: glassMode, isLight: isLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight
                  ? AppColors.slate200
                  : AppColors.slate800,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                collapsed
                    ? _collapsedGroups.remove(group.key)
                    : _collapsedGroups.add(group.key);
              });
              _persistCollapsedGroups();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() => _groupReorderMode = true);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    collapsed
                        ? Icons.chevron_right
                        : Icons.expand_more,
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
                  if (!isUngrouped)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          size: 18, color: AppColors.slate400),
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            _renameGroup(
                                group.key, group.tasks);
                            break;
                          case 'delete':
                            _deleteGroup(
                                group.key, group.tasks);
                            break;
                          case 'add':
                            final ungrouped = ref
                                .read(taskProvider)
                                .tasks
                                .where((t) =>
                                    t.groupName == null ||
                                    t.groupName!.isEmpty)
                                .toList();
                            _addTasksToGroup(
                                group.key, ungrouped);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('重命名分组'),
                        ),
                        const PopupMenuItem(
                          value: 'add',
                          child: Text('添加未分组任务'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除分组',
                              style:
                                  TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!collapsed)
          ...group.tasks.map(
            (task) => _TaskListItem(
              task: task,
              isLight: isLight,
              glassMode: glassMode,
              selectionMode: _selectionMode,
              selected: _selectedTaskIds.contains(task.id),
              onSelect: () => _toggleTaskSelection(task.id),
              onRun: () => _runTask(task),
              onStop: () => _stopTask(task),
              onToggleEnabled: () =>
                  _toggleTaskEnabled(task),
              onCopy: () => _copyTask(task),
              onOpenLog: () => _openLatestLog(task),
              onTogglePinned: () => _togglePinned(task),
            ),
          ),
      ],
    );
  }

  String _extractTaskError(dynamic error, String fallback) {
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.replaceFirst('Exception: ', '');
      }
      return msg;
    }
    return fallback;
  }
}

/// 分组数据模型
class _TaskGroup {
  final String key;
  final String title;
  final List<Task> tasks = [];

  _TaskGroup({required this.key, required this.title});
}

/// 头部 Chip 按钮
class _TaskHeaderChipButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isLight
              ? AppColors.slate50
              : AppColors.slate900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight
                ? AppColors.slate200
                : AppColors.slate800,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.slate500),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 批量操作按钮
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
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

/// 任务列表项
class _TaskListItem extends StatelessWidget {
  final Task task;
  final bool isLight;
  final bool glassMode;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onToggleEnabled;
  final VoidCallback onCopy;
  final VoidCallback onOpenLog;
  final VoidCallback onTogglePinned;

  const _TaskListItem({
    required this.task,
    required this.isLight,
    required this.glassMode,
    required this.selectionMode,
    required this.selected,
    required this.onSelect,
    required this.onRun,
    required this.onStop,
    required this.onToggleEnabled,
    required this.onCopy,
    required this.onOpenLog,
    required this.onTogglePinned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: glassCardColor(
            glassMode: glassMode, isLight: isLight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.primary.withAlpha(120)
              : isLight
                  ? AppColors.slate200
                  : AppColors.slate800,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selectionMode ? onSelect : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectionMode)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => onSelect(),
                    )
                  else
                    const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.isPinned)
                    const Icon(Icons.push_pin,
                        size: 14, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.command,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetaChip(
                    label: task.statusText,
                    active: !task.isDisabled,
                  ),
                  const SizedBox(width: 8),
                  // ✅ 关键修复：使用 task.command 而非 task.cron
                  _MetaChip(
                    label: task.command,
                    active: true,
                  ),
                  const Spacer(),
                  _TaskItemActions(
                    task: task,
                    onRun: onRun,
                    onStop: onStop,
                    onToggleEnabled: onToggleEnabled,
                    onCopy: onCopy,
                    onOpenLog: onOpenLog,
                    onTogglePinned: onTogglePinned,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态 / Cron Chip
class _MetaChip extends StatelessWidget {
  final String label;
  final bool active;

  const _MetaChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withAlpha(15)
            : AppColors.slate200.withAlpha(100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.primary : AppColors.slate400,
        ),
      ),
    );
  }
}

/// 任务操作按钮组
class _TaskItemActions extends StatelessWidget {
  final Task task;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onToggleEnabled;
  final VoidCallback onCopy;
  final VoidCallback onOpenLog;
  final VoidCallback onTogglePinned;

  const _TaskItemActions({
    required this.task,
    required this.onRun,
    required this.onStop,
    required this.onToggleEnabled,
    required this.onCopy,
    required this.onOpenLog,
    required this.onTogglePinned,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (task.isRunning)
          IconButton(
            onPressed: onStop,
            icon: const Icon(Icons.stop_circle_outlined,
                size: 20, color: AppColors.red500),
          )
        else
          IconButton(
            onPressed: onRun,
            icon: const Icon(Icons.play_circle_outlined,
                size: 20, color: AppColors.primary),
          ),
        IconButton(
          onPressed: onToggleEnabled,
          icon: Icon(
            task.isDisabled
                ? Icons.toggle_off_outlined
                : Icons.toggle_on_outlined,
            size: 20,
            color: task.isDisabled
                ? AppColors.slate400
                : AppColors.primary,
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined,
              size: 18, color: AppColors.slate400),
        ),
        IconButton(
          onPressed: onOpenLog,
          icon: const Icon(Icons.article_outlined,
              size: 18, color: AppColors.slate400),
        ),
        IconButton(
          onPressed: onTogglePinned,
          icon: Icon(
            task.isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            size: 18,
            color: task.isPinned
                ? AppColors.primary
                : AppColors.slate400,
          ),
        ),
      ],
    );
  }
}

