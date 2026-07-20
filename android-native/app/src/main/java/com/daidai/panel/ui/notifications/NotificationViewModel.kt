package com.daidai.panel.ui.notifications

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.NotifyChannel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationListState(
    val channels: List<NotifyChannel> = emptyList(),
    val types: List<Map<String, Any>> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val testResult: String? = null
)

@HiltViewModel
class NotificationViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(NotificationListState())
    val state: StateFlow<NotificationListState> = _state.asStateFlow()

    init {
        load()
        loadTypes()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getNotifications(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val data = response.body()?.data
                    _state.value = _state.value.copy(
                        channels = data?.items ?: emptyList(),
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

    private fun loadTypes() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getNotificationTypes()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        types = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun create(body: Map<String, Any>, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.createNotification(body)
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
                val response = api.updateNotification(id, body)
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
                api.deleteNotification(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun enable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.enableNotification(mapOf("id" to id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun disable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.disableNotification(mapOf("id" to id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun test(id: Int) {
        viewModelScope.launch {
            _state.value = _state.value.copy(testResult = null)
            try {
                val api = networkModule.getApiService()
                val response = api.testNotification(mapOf("id" to id))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(testResult = "发送成功")
                } else {
                    _state.value = _state.value.copy(testResult = response.body()?.message ?: "发送失败")
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(testResult = e.message ?: "网络错误")
            }
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }

    fun clearTestResult() {
        _state.value = _state.value.copy(testResult = null)
    }
}
