package com.daidai.panel.ui.envs

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EnvFormState(
    val name: String = "",
    val value: String = "",
    val remarks: String = "",
    val enabled: Boolean = true,
    val group: String = "",
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null,
    val saved: Boolean = false,
    val isEdit: Boolean = false
)

@HiltViewModel
class EnvFormViewModel @Inject constructor(
    private val networkModule: NetworkModule,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val envId: Int = savedStateHandle.get<Int>("envId") ?: -1

    private val _state = MutableStateFlow(EnvFormState(isEdit = envId > 0))
    val state: StateFlow<EnvFormState> = _state.asStateFlow()

    init {
        if (envId > 0) load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getEnvVar(envId)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val env = response.body()?.data
                    _state.value = _state.value.copy(
                        name = env?.name ?: "",
                        value = env?.value ?: "",
                        remarks = env?.remarks ?: "",
                        enabled = env?.enabled ?: true,
                        group = env?.group ?: "",
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

    fun updateName(value: String) {
        _state.value = _state.value.copy(name = value)
    }

    fun updateValue(value: String) {
        _state.value = _state.value.copy(value = value)
    }

    fun updateRemarks(value: String) {
        _state.value = _state.value.copy(remarks = value)
    }

    fun updateEnabled(value: Boolean) {
        _state.value = _state.value.copy(enabled = value)
    }

    fun updateGroup(value: String) {
        _state.value = _state.value.copy(group = value)
    }

    fun save() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null)
            try {
                val api = networkModule.getApiService()
                val body = mutableMapOf<String, Any>(
                    "name" to _state.value.name,
                    "value" to _state.value.value,
                    "remarks" to _state.value.remarks,
                    "enabled" to _state.value.enabled
                )
                if (_state.value.group.isNotBlank()) {
                    body["group"] = _state.value.group
                }
                val response = if (envId > 0) {
                    api.updateEnvVar(envId, body)
                } else {
                    api.createEnvVar(body)
                }
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(isSaving = false, saved = true)
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

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
