package com.daidai.panel.ui.logs

import androidx.lifecycle.SavedStateHandle
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

data class LogStreamState(
    val log: TaskLog? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) {
    val decodedContent: String
        get() {
            val raw = log?.content ?: ""
            if (raw.isEmpty()) return ""
            return try {
                val decoded = android.util.Base64.decode(raw, android.util.Base64.DEFAULT)
                String(decoded, Charsets.UTF_8)
            } catch (_: Exception) {
                raw
            }
        }

    val statusText: String
        get() = log?.statusText ?: ""

    val durationText: String
        get() = log?.durationText ?: ""
}

@HiltViewModel
class LogStreamViewModel @Inject constructor(
    private val networkModule: NetworkModule,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val logId: Int = savedStateHandle.get<Int>("logId") ?: 0

    private val _state = MutableStateFlow(LogStreamState())
    val state: StateFlow<LogStreamState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getLog(logId)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        log = response.body()?.data,
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
}
