package com.daidai.panel.ui.security

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

data class SecurityState(
    val loginLogs: List<Map<String, Any>> = emptyList(),
    val sessions: List<Map<String, Any>> = emptyList(),
    val ipWhitelist: List<Map<String, Any>> = emptyList(),
    val twoFaStatus: Map<String, Any> = emptyMap(),
    val auditLogs: List<Map<String, Any>> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedTab: Int = 0,
    val twoFaSecret: String = "",
    val twoFaQrUrl: String = ""
)

@HiltViewModel
class SecurityViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(SecurityState())
    val state: StateFlow<SecurityState> = _state.asStateFlow()

    init {
        loadLoginLogs()
        loadSessions()
        loadIpWhitelist()
        load2FaStatus()
    }

    fun selectTab(tab: Int) {
        _state.value = _state.value.copy(selectedTab = tab)
        when (tab) {
            0 -> loadLoginLogs()
            1 -> loadSessions()
            2 -> loadIpWhitelist()
            3 -> load2FaStatus()
            4 -> loadAuditLogs()
        }
    }

    fun loadLoginLogs() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getLoginLogs(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        loginLogs = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(isLoading = false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun loadSessions() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getSessions()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        sessions = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(isLoading = false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun kickSession(id: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteSessionById(ApiEndpoints.sessionById(id.toInt()))
                loadSessions()
            } catch (_: Exception) {}
        }
    }

    fun kickOtherSessions() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteOtherSessions()
                loadSessions()
            } catch (_: Exception) {}
        }
    }

    fun loadIpWhitelist() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getIpWhitelist()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        ipWhitelist = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(isLoading = false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun addIpWhitelist(ip: String, remark: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.addIpWhitelist(mapOf("ip" to ip, "remark" to remark))
                loadIpWhitelist()
            } catch (_: Exception) {}
        }
    }

    fun removeIpWhitelist(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteIpWhitelist(ApiEndpoints.ipWhitelistById(id))
                loadIpWhitelist()
            } catch (_: Exception) {}
        }
    }

    fun load2FaStatus() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.get2FaStatus()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        twoFaStatus = response.body()?.data ?: emptyMap()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun setup2Fa() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.setup2Fa()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val data = response.body()?.data ?: emptyMap()
                    _state.value = _state.value.copy(
                        twoFaSecret = data["secret"] as? String ?: "",
                        twoFaQrUrl = data["qr_url"] as? String ?: ""
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun verify2Fa(code: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.verify2Fa(mapOf("code" to code))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    load2FaStatus()
                    onResult(true)
                } else {
                    _state.value = _state.value.copy(error = response.body()?.message ?: "验证失败")
                    onResult(false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "网络错误")
                onResult(false)
            }
        }
    }

    fun disable2Fa(code: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.disable2Fa(mapOf("code" to code))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    load2FaStatus()
                    onResult(true)
                } else {
                    _state.value = _state.value.copy(error = response.body()?.message ?: "禁用失败")
                    onResult(false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "网络错误")
                onResult(false)
            }
        }
    }

    fun loadAuditLogs() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getAuditLogs(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        auditLogs = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(isLoading = false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
