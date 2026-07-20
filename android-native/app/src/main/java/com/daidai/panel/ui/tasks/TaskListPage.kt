package com.daidai.panel.ui.tasks

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SelectAll
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.Task
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.SearchBar
import com.daidai.panel.ui.components.StatusBadge
import com.daidai.panel.ui.components.BadgeStatus

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun TaskListPage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    viewModel: TaskViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val snackbarHostState = remember { SnackbarHostState() }
    var deleteTarget by remember { mutableStateOf<Task?>(null) }
    var showFilters by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.padding(contentPadding),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            if (state.isBatchMode) {
                TopAppBar(
                    title = { Text("已选 ${state.selectedIds.size} 项") },
                    navigationIcon = {
                        IconButton(onClick = { viewModel.toggleBatchMode() }) {
                            Icon(Icons.Default.Close, contentDescription = "退出批量模式")
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.selectAll() }) {
                            Icon(Icons.Default.SelectAll, contentDescription = "全选")
                        }
                        IconButton(onClick = { viewModel.batchEnable() }) {
                            Icon(Icons.Default.CheckCircle, contentDescription = "批量启用", tint = AppColors.primary)
                        }
                        IconButton(onClick = { viewModel.batchDisable() }) {
                            Icon(Icons.Default.Stop, contentDescription = "批量禁用", tint = AppColors.amber500)
                        }
                        IconButton(onClick = { viewModel.batchDelete() }) {
                            Icon(Icons.Default.Delete, contentDescription = "批量删除", tint = AppColors.red500)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = if (isLight) AppColors.primaryContainer else AppColors.primaryDark
                    )
                )
            }
        },
        floatingActionButton = {
            if (!state.isBatchMode) {
                FloatingActionButton(
                    onClick = { onNavigate("taskForm") },
                    containerColor = AppColors.primary
                ) {
                    Icon(Icons.Default.Add, contentDescription = "新建任务", tint = AppColors.white)
                }
            }
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Search bar
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SearchBar(
                        query = state.keyword,
                        onQueryChange = { viewModel.updateKeyword(it) },
                        modifier = Modifier.weight(1f),
                        glassMode = glassMode,
                        placeholder = "搜索任务..."
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = "筛选",
                            tint = if (showFilters) AppColors.primary else AppColors.slate400
                        )
                    }
                }
            }

            // Status filter chips
            item {
                AnimatedVisibility(visible = showFilters) {
                    Column {
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            val filters = listOf(
                                -1 to "全部",
                                1 to "已启用",
                                0 to "已禁用",
                                3 to "运行中"
                            )
                            filters.forEach { (status, label) ->
                                AssistChip(
                                    onClick = { viewModel.updateStatusFilter(status) },
                                    label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                                    shape = RoundedCornerShape(20.dp),
                                    colors = AssistChipDefaults.assistChipColors(
                                        containerColor = if (state.statusFilter == status)
                                            AppColors.primary.copy(alpha = 0.15f)
                                        else MaterialTheme.colorScheme.surfaceVariant,
                                        labelColor = if (state.statusFilter == status)
                                            AppColors.primary
                                        else if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                    )
                                )
                            }
                        }

                        if (state.allLabels.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                state.allLabels.forEach { label ->
                                    AssistChip(
                                        onClick = {
                                            viewModel.updateLabelFilter(
                                                if (state.labelFilter == label) "" else label
                                            )
                                        },
                                        label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                                        shape = RoundedCornerShape(20.dp),
                                        colors = AssistChipDefaults.assistChipColors(
                                            containerColor = if (state.labelFilter == label)
                                                AppColors.blue500.copy(alpha = 0.15f)
                                            else MaterialTheme.colorScheme.surfaceVariant
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Loading
            if (state.isLoading && state.tasks.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = AppColors.primary)
                    }
                }
            }

            // Task list
            items(state.filteredTasks, key = { it.id }) { task ->
                TaskCard(
                    task = task,
                    glassMode = glassMode,
                    isBatchMode = state.isBatchMode,
                    isSelected = state.selectedIds.contains(task.id),
                    onClick = {
                        if (state.isBatchMode) {
                            viewModel.toggleSelection(task.id)
                        } else {
                            onNavigate("taskForm?taskId=${task.id}")
                        }
                    },
                    onLongClick = {
                        if (!state.isBatchMode) {
                            viewModel.toggleBatchMode()
                            viewModel.toggleSelection(task.id)
                        }
                    },
                    onRun = { viewModel.runTask(task.id) },
                    onStop = { viewModel.stopTask(task.id) },
                    onEnable = { viewModel.enableTask(task.id) },
                    onDisable = { viewModel.disableTask(task.id) },
                    onDelete = { deleteTarget = task }
                )
            }

            // Empty state
            if (!state.isLoading && state.filteredTasks.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                if (state.tasks.isEmpty()) "暂无任务" else "无匹配结果",
                                style = MaterialTheme.typography.bodyLarge,
                                color = AppColors.slate500
                            )
                            if (state.tasks.isEmpty()) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    "点击右下角按钮创建任务",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AppColors.slate400
                                )
                            }
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }

    deleteTarget?.let { task ->
        AlertDialog(
            onDismissRequest = { deleteTarget = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除任务 \"${task.name}\" 吗？此操作不可恢复。") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteTask(task.id)
                    deleteTarget = null
                }) {
                    Text("删除", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { deleteTarget = null }) {
                    Text("取消")
                }
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun TaskCard(
    task: Task,
    glassMode: Boolean,
    isBatchMode: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    onRun: () -> Unit,
    onStop: () -> Unit,
    onEnable: () -> Unit,
    onDisable: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    val badgeStatus = when {
        task.isRunning -> BadgeStatus.RUNNING
        task.isQueued -> BadgeStatus.QUEUED
        task.isEnabled -> BadgeStatus.SUCCESS
        task.isDisabled -> BadgeStatus.DISABLED
        else -> BadgeStatus.DISABLED
    }

    GlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            ),
        glassMode = glassMode,
        padding = PaddingValues(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = task.name,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    StatusBadge(status = badgeStatus)
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = task.cronExpression,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isLight) AppColors.slate500 else AppColors.slate400,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                if (task.lastRunAt.isNotEmpty()) {
                    Text(
                        text = "上次运行: ${task.lastRunAt}",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isLight) AppColors.slate400 else AppColors.slate500
                    )
                }

                if (task.labelList.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        task.labelList.take(3).forEach { label ->
                            androidx.compose.material3.Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = AppColors.primary.copy(alpha = 0.08f)
                            ) {
                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = AppColors.primary,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                }
            }

            if (!isBatchMode) {
                Row {
                    if (task.isRunning) {
                        IconButton(onClick = onStop, modifier = Modifier.size(36.dp)) {
                            Icon(Icons.Default.Stop, contentDescription = "停止", tint = AppColors.red500, modifier = Modifier.size(20.dp))
                        }
                    } else {
                        IconButton(onClick = onRun, modifier = Modifier.size(36.dp)) {
                            Icon(Icons.Default.PlayArrow, contentDescription = "运行", tint = AppColors.primary, modifier = Modifier.size(20.dp))
                        }
                    }
                }
            }

            if (isBatchMode) {
                if (isSelected) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "已选",
                        tint = AppColors.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }
}
