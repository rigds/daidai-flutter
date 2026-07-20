package com.daidai.panel.ui.tasks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.Task
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TaskListState(
    val tasks: List<Task> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val keyword: String = "",
    val statusFilter: Int = -1,
    val labelFilter: String = "",
    val selectedIds: Set<Int> = emptySet(),
    val isBatchMode: Boolean = false
) {
    val filteredTasks: List<Task>
        get() {
            var result = tasks
            if (keyword.isNotBlank()) {
                result = result.filter {
                    it.name.contains(keyword, ignoreCase = true) ||
                            it.command.contains(keyword, ignoreCase = true) ||
                            it.labels.contains(keyword, ignoreCase = true)
                }
            }
            if (statusFilter >= 0) {
                result = result.filter { it.status == statusFilter }
            }
            if (labelFilter.isNotBlank()) {
                result = result.filter { it.labelList.contains(labelFilter) }
            }
            return result
        }

    val allLabels: List<String>
        get() = tasks.flatMap { it.labelList }.distinct().filter { it.isNotBlank() }
}

@HiltViewModel
class TaskViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(TaskListState())
    val state: StateFlow<TaskListState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val params = mutableMapOf<String, String>()
                val response = api.getTasks(params)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val data = response.body()?.data
                    _state.value = _state.value.copy(
                        tasks = data?.items ?: emptyList(),
                        total = data?.total ?: 0,
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = response.body()?.message ?: "加载失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "网络错误"
                )
            }
        }
    }

    fun updateKeyword(value: String) {
        _state.value = _state.value.copy(keyword = value)
    }

    fun updateStatusFilter(status: Int) {
        _state.value = _state.value.copy(statusFilter = status)
    }

    fun updateLabelFilter(label: String) {
        _state.value = _state.value.copy(labelFilter = label)
    }

    fun toggleBatchMode() {
        val newMode = !_state.value.isBatchMode
        _state.value = _state.value.copy(
            isBatchMode = newMode,
            selectedIds = if (!newMode) emptySet() else _state.value.selectedIds
        )
    }

    fun toggleSelection(taskId: Int) {
        val current = _state.value.selectedIds.toMutableSet()
        if (current.contains(taskId)) current.remove(taskId) else current.add(taskId)
        _state.value = _state.value.copy(selectedIds = current)
    }

    fun selectAll() {
        val allIds = _state.value.filteredTasks.map { it.id }.toSet()
        _state.value = _state.value.copy(selectedIds = allIds)
    }

    fun deselectAll() {
        _state.value = _state.value.copy(selectedIds = emptySet())
    }

    fun runTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.runTask(mapOf("task_id" to taskId))
                load()
            } catch (_: Exception) {}
        }
    }

    fun stopTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.stopTask(mapOf("task_id" to taskId))
                load()
            } catch (_: Exception) {}
        }
    }

    fun enableTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.enableTask(mapOf("task_id" to taskId))
                load()
            } catch (_: Exception) {}
        }
    }

    fun disableTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.disableTask(mapOf("task_id" to taskId))
                load()
            } catch (_: Exception) {}
        }
    }

    fun deleteTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteTask(taskId)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchDelete() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchTasks(mapOf("action" to "delete", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchEnable() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchTasks(mapOf("action" to "enable", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchDisable() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchTasks(mapOf("action" to "disable", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }
}
