package com.daidai.panel.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiService
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardState(
    val systemInfo: Map<String, Any> = emptyMap(),
    val dashboardData: Map<String, Any> = emptyMap(),
    val panelSettings: Map<String, Any> = emptyMap(),
    val versionInfo: Map<String, Any> = emptyMap(),
    val isLoading: Boolean = false,
    val error: String? = null
) {
    val cpuUsage: Float
        get() {
            val cpu = systemInfo["cpu"] as? Map<*, *> ?: return 0f
            return (cpu["usage"] as? Number)?.toFloat() ?: 0f
        }

    val memoryUsage: Float
        get() {
            val mem = systemInfo["mem"] as? Map<*, *> ?: return 0f
            val used = (mem["used"] as? Number)?.toLong() ?: return 0f
            val total = (mem["total"] as? Number)?.toLong() ?: return 1f
            return if (total > 0) (used.toFloat() / total * 100f) else 0f
        }

    val diskUsage: Float
        get() {
            val disk = systemInfo["disk"] as? Map<*, *> ?: return 0f
            val used = (disk["used"] as? Number)?.toLong() ?: return 0f
            val total = (disk["total"] as? Number)?.toLong() ?: return 1f
            return if (total > 0) (used.toFloat() / total * 100f) else 0f
        }

    val hostname: String
        get() = systemInfo["hostname"] as? String ?: ""

    val os: String
        get() = systemInfo["os"] as? String ?: ""

    val uptime: String
        get() {
            val uptimeSeconds = (systemInfo["uptime"] as? Number)?.toLong() ?: return ""
            val days = uptimeSeconds / 86400
            val hours = (uptimeSeconds % 86400) / 3600
            val minutes = (uptimeSeconds % 3600) / 60
            return when {
                days > 0 -> "${days}天${hours}小时"
                hours > 0 -> "${hours}小时${minutes}分钟"
                else -> "${minutes}分钟"
            }
        }

    val panelTitle: String
        get() = panelSettings["title"] as? String ?: "呆呆面板"

    val panelVersion: String
        get() = versionInfo["version"] as? String ?: ""

    val totalTasks: Int
        get() = (dashboardData["total"] as? Number)?.toInt() ?: 0

    val enabledTasks: Int
        get() = (dashboardData["enabled"] as? Number)?.toInt() ?: 0

    val runningTasks: Int
        get() = (dashboardData["running"] as? Number)?.toInt() ?: 0

    val disabledTasks: Int
        get() = (dashboardData["disabled"] as? Number)?.toInt() ?: 0

    val todaySuccess: Int
        get() = (dashboardData["today_success"] as? Number)?.toInt() ?: 0

    val todayFailed: Int
        get() = (dashboardData["today_failed"] as? Number)?.toInt() ?: 0

    val executionTrend: List<Map<String, Any>>
        get() {
            @Suppress("UNCHECKED_CAST")
            return dashboardData["execution_trend"] as? List<Map<String, Any>> ?: emptyList()
        }
}

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(DashboardState())
    val state: StateFlow<DashboardState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()

                val systemInfoDeferred = async { runCatching { api.systemInfo() } }
                val dashboardDeferred = async { runCatching { api.dashboard() } }
                val settingsDeferred = async { runCatching { api.getPanelSettings() } }
                val versionDeferred = async { runCatching { api.version() } }

                val systemInfoResult = systemInfoDeferred.await()
                val dashboardResult = dashboardDeferred.await()
                val settingsResult = settingsDeferred.await()
                val versionResult = versionDeferred.await()

                _state.value = _state.value.copy(
                    systemInfo = systemInfoResult.getOrNull()?.body()?.data ?: emptyMap(),
                    dashboardData = dashboardResult.getOrNull()?.body()?.data ?: emptyMap(),
                    panelSettings = settingsResult.getOrNull()?.body()?.data ?: emptyMap(),
                    versionInfo = versionResult.getOrNull()?.body()?.data ?: emptyMap(),
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "加载失败"
                )
            }
        }
    }
}
