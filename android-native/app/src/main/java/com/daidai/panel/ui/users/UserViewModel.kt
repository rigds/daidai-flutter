package com.daidai.panel.ui.users

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class UserListState(
    val users: List<User> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class UserViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(UserListState())
    val state: StateFlow<UserListState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getUsers()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        users = response.body()?.data ?: emptyList(),
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

    fun create(username: String, password: String, role: Int, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.createUser(
                    mapOf("username" to username, "password" to password, "role" to role)
                )
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
                val response = api.updateUser(id, body)
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
                api.deleteUser(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun resetPassword(id: Int, newPassword: String, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.resetPassword(
                    mapOf("user_id" to id, "new_password" to newPassword)
                )
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    onResult(true)
                } else {
                    _state.value = _state.value.copy(error = response.body()?.message ?: "重置失败")
                    onResult(false)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "网络错误")
                onResult(false)
            }
        }
    }

    fun toggleEnabled(id: Int, enabled: Boolean) {
        update(id, mapOf("enabled" to enabled))
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
