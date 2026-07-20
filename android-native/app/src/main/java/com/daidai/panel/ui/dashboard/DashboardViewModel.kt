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
        get() = (systemInfo["cpu_usage"] as? Number)?.toFloat() ?: 0f

    val memoryUsage: Float
        get() = (systemInfo["memory_usage"] as? Number)?.toFloat() ?: 0f

    val diskUsage: Float
        get() = (systemInfo["disk_usage"] as? Number)?.toFloat() ?: 0f

    val memoryTotal: Long
        get() = (systemInfo["memory_total"] as? Number)?.toLong() ?: 0L

    val memoryUsed: Long
        get() = (systemInfo["memory_used"] as? Number)?.toLong() ?: 0L

    val diskTotal: Long
        get() = (systemInfo["disk_total"] as? Number)?.toLong() ?: 0L

    val diskUsed: Long
        get() = (systemInfo["disk_used"] as? Number)?.toLong() ?: 0L

    val memoryFormatted: String
        get() = "${formatBytes(memoryUsed)} / ${formatBytes(memoryTotal)}"

    val diskFormatted: String
        get() = "${formatBytes(diskUsed)} / ${formatBytes(diskTotal)}"

    val hostname: String
        get() = systemInfo["hostname"] as? String ?: ""

    val os: String
        get() = systemInfo["os"] as? String ?: ""

    val uptime: String
        get() = systemInfo["uptime"] as? String ?: ""

    val panelTitle: String
        get() = panelSettings["title"] as? String ?: "呆呆面板"

    val panelVersion: String
        get() = versionInfo["version"] as? String ?: ""

    val totalTasks: Int
        get() = (dashboardData["task_count"] as? Number)?.toInt() ?: 0

    val enabledTasks: Int
        get() = (dashboardData["enabled_tasks"] as? Number)?.toInt() ?: 0

    val runningTasks: Int
        get() = (dashboardData["running_tasks"] as? Number)?.toInt() ?: 0

    val disabledTasks: Int
        get() = totalTasks - enabledTasks

    val todaySuccess: Int
        get() = (dashboardData["success_logs"] as? Number)?.toInt() ?: 0

    val todayFailed: Int
        get() = (dashboardData["failed_logs"] as? Number)?.toInt() ?: 0

    val executionTrend: List<Map<String, Any>>
        get() {
            @Suppress("UNCHECKED_CAST")
            return dashboardData["daily_stats"] as? List<Map<String, Any>> ?: emptyList()
        }

    private fun formatBytes(bytes: Long): String {
        if (bytes <= 0) return "0 B"
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        val digitGroups = (Math.log10(bytes.toDouble()) / Math.log10(1024.0)).toInt().coerceIn(0, units.size - 1)
        val value = bytes / Math.pow(1024.0, digitGroups.toDouble())
        return "%.1f %s".format(value, units[digitGroups])
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
