package com.daidai.panel.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.data.api.ApiClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class AuthState(
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val username: String? = null
)

class AuthViewModel : ViewModel() {
    private val _authState = MutableStateFlow(AuthState())
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun login(serverUrl: String, username: String, password: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(isLoading = true, error = null)
            ApiClient.setBaseUrl(serverUrl)
            val result = ApiClient.login(username, password)
            result.fold(
                onSuccess = {
                    _authState.value = _authState.value.copy(
                        isAuthenticated = true,
                        isLoading = false,
                        username = username
                    )
                },
                onFailure = { e ->
                    _authState.value = _authState.value.copy(
                        isLoading = false,
                        error = e.message ?: "登录失败"
                    )
                }
            )
        }
    }

    fun logout() {
        _authState.value = AuthState()
        ApiClient.setAccessToken(null)
    }
}
