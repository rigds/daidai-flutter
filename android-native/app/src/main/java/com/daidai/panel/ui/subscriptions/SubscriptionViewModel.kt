package com.daidai.panel.ui.subscriptions

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiEndpoints
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.Subscription
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SubscriptionListState(
    val subscriptions: List<Subscription> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedIds: Set<Int> = emptySet(),
    val isBatchMode: Boolean = false
)

@HiltViewModel
class SubscriptionViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(SubscriptionListState())
    val state: StateFlow<SubscriptionListState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getSubscriptions(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        subscriptions = response.body()?.data ?: emptyList(),
                        total = response.body()?.total ?: 0,
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

    fun create(body: Map<String, Any>, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.createSubscription(body)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    load()
                    onResult(true)
                } else {
                    _state.value = _state.value.copy(error = response.body()?.message ?: "创建失败")
                    onResult(false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "网络错误")
                onResult(false)
            }
        }
    }

    fun update(id: Int, body: Map<String, Any>, onResult: (Boolean) -> Unit = {}) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.updateSubscription(id, body)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    load()
                    onResult(true)
                } else {
                    _state.value = _state.value.copy(error = response.body()?.message ?: "更新失败")
                    onResult(false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "网络错误")
                onResult(false)
            }
        }
    }

    fun delete(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteSubscription(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun enable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.enableSubscription(ApiEndpoints.subscriptionEnable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun disable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.disableSubscription(ApiEndpoints.subscriptionDisable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun pull(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.pullSubscription(ApiEndpoints.subscriptionPull(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun pullStop(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.stopPullSubscription(ApiEndpoints.subscriptionPullStop(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun toggleBatchMode() {
        val newMode = !_state.value.isBatchMode
        _state.value = _state.value.copy(
            isBatchMode = newMode,
            selectedIds = if (!newMode) emptySet() else _state.value.selectedIds
        )
    }

    fun toggleSelection(id: Int) {
        val current = _state.value.selectedIds.toMutableSet()
        if (current.contains(id)) current.remove(id) else current.add(id)
        _state.value = _state.value.copy(selectedIds = current)
    }

    fun batchDelete() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchDeleteSubscriptions(mapOf("ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
