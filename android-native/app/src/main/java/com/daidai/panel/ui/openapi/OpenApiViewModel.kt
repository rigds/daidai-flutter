package com.daidai.panel.ui.openapi

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiEndpoints
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class OpenApiState(
    val apps: List<Map<String, Any>> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val secret: String? = null,
    val logs: List<Map<String, Any>> = emptyList()
)

@HiltViewModel
class OpenApiViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(OpenApiState())
    val state: StateFlow<OpenApiState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getOpenApiApps(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        apps = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
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

    fun create(name: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.createOpenApiApp(mapOf("name" to name))
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

    fun update(id: Int, body: Map<String, Any>) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.updateOpenApiApp(id, body)
                load()
            } catch (_: Exception) {}
        }
    }

    fun delete(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteOpenApiApp(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun enable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.enableOpenApiApp(ApiEndpoints.openApiAppEnable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun disable(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.disableOpenApiApp(ApiEndpoints.openApiAppDisable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun resetSecret(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.resetOpenApiAppSecret(ApiEndpoints.openApiAppResetSecret(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun viewSecret(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.viewOpenApiAppSecret(ApiEndpoints.openApiAppViewSecret(id))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        secret = response.body()?.data?.get("secret") as? String
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun loadLogs(appId: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getOpenApiAppLogs(ApiEndpoints.openApiAppLogs(appId))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        logs = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun clearSecret() {
        _state.value = _state.value.copy(secret = null)
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
