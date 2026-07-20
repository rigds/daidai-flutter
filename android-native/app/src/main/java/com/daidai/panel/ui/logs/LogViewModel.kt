package com.daidai.panel.ui.logs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.TaskLog
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LogListState(
    val logs: List<TaskLog> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val keyword: String = "",
    val statusFilter: Int = -1,
    val selectedIds: Set<Int> = emptySet(),
    val isBatchMode: Boolean = false
) {
    val filteredLogs: List<TaskLog>
        get() {
            var result = logs
            if (keyword.isNotBlank()) {
                result = result.filter {
                    it.taskName.contains(keyword, ignoreCase = true) ||
                            it.content.contains(keyword, ignoreCase = true)
                }
            }
            if (statusFilter >= 0) {
                result = result.filter { it.status == statusFilter }
            }
            return result
        }
}

@HiltViewModel
class LogViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(LogListState())
    val state: StateFlow<LogListState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val params = mutableMapOf<String, String>()
                val response = api.getLogs(params)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val data = response.body()?.data
                    _state.value = _state.value.copy(
                        logs = data?.items ?: emptyList(),
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

    fun toggleBatchMode() {
        val newMode = !_state.value.isBatchMode
        _state.value = _state.value.copy(
            isBatchMode = newMode,
            selectedIds = if (!newMode) emptySet() else _state.value.selectedIds
        )
    }

    fun toggleSelection(logId: Int) {
        val current = _state.value.selectedIds.toMutableSet()
        if (current.contains(logId)) current.remove(logId) else current.add(logId)
        _state.value = _state.value.copy(selectedIds = current)
    }

    fun selectAll() {
        _state.value = _state.value.copy(
            selectedIds = _state.value.filteredLogs.map { it.id }.toSet()
        )
    }

    fun deleteLog(logId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteLog(logId)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchDelete() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchDeleteLogs(mapOf("ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun cleanAll() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.cleanAllLogs()
                load()
            } catch (_: Exception) {}
        }
    }
}
