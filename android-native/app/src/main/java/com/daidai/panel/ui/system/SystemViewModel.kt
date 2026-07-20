package com.daidai.panel.ui.system

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SystemSettingsState(
    val settings: Map<String, Any> = emptyMap(),
    val panelLogs: List<Map<String, Any>> = emptyList(),
    val backups: List<Map<String, Any>> = emptyList(),
    val restoreProgress: Map<String, Any> = emptyMap(),
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null,
    val updateInfo: Map<String, Any> = emptyMap(),
    val currentVersion: String = ""
)

@HiltViewModel
class SystemViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(SystemSettingsState())
    val state: StateFlow<SystemSettingsState> = _state.asStateFlow()

    init {
        loadSettings()
        loadVersion()
    }

    fun loadSettings() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getPanelSettings()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        settings = response.body()?.data ?: emptyMap(),
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

    private fun loadVersion() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.version()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        currentVersion = response.body()?.data?.get("version") as? String ?: ""
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun saveSettings(body: Map<String, Any>) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null, successMessage = null)
            try {
                val api = networkModule.getApiService()
                val response = api.updatePanelSettings(body)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        successMessage = "保存成功"
                    )
                    loadSettings()
                } else {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = response.body()?.message ?: "保存失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    error = e.message ?: "网络错误"
                )
            }
        }
    }

    fun loadPanelLogs(keyword: String = "", level: String = "") {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val params = mutableMapOf<String, String>()
                if (keyword.isNotBlank()) params["keyword"] = keyword
                if (level.isNotBlank()) params["level"] = level
                val response = api.getPanelLog(params)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        panelLogs = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
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

    fun loadBackups() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getBackups()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        backups = response.body()?.data as? List<Map<String, Any>> ?: emptyList(),
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

    fun createBackup() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null, successMessage = null)
            try {
                val api = networkModule.getApiService()
                val response = api.createBackup()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(isSaving = false, successMessage = "备份创建成功")
                    loadBackups()
                } else {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = response.body()?.message ?: "备份失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isSaving = false, error = e.message ?: "网络错误")
            }
        }
    }

    fun uploadBackup(fileName: String, fileBytes: ByteArray) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null, successMessage = null)
            try {
                val api = networkModule.getApiService()
                val part = okhttp3.MultipartBody.Part.createFormData(
                    "file", fileName,
                    okhttp3.RequestBody.create(null, fileBytes)
                )
                val response = api.uploadBackup(part)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(isSaving = false, successMessage = "上传成功")
                    loadBackups()
                } else {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = response.body()?.message ?: "上传失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isSaving = false, error = e.message ?: "网络错误")
            }
        }
    }

    fun downloadBackup(name: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.downloadBackup(name)
            } catch (_: Exception) {}
        }
    }

    fun restoreBackup(name: String, options: String = "") {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null, successMessage = null)
            try {
                val api = networkModule.getApiService()
                val body = mutableMapOf<String, String>("name" to name)
                if (options.isNotBlank()) body["options"] = options
                val response = api.restore(body)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(isSaving = false, successMessage = "恢复成功")
                } else {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = response.body()?.message ?: "恢复失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(isSaving = false, error = e.message ?: "网络错误")
            }
        }
    }

    fun loadRestoreProgress() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getRestoreProgress()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        restoreProgress = response.body()?.data ?: emptyMap()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun checkUpdate() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.checkUpdate()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        updateInfo = response.body()?.data ?: emptyMap(),
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

    fun clearMessages() {
        _state.value = _state.value.copy(error = null, successMessage = null)
    }
}
