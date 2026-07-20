package com.daidai.panel.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class Sponsor(
    val name: String = "",
    val amount: Double = 0.0,
    val message: String = "",
    val time: String = ""
)

data class SponsorState(
    val sponsors: List<Sponsor> = emptyList(),
    val total: Double = 0.0,
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SponsorViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(SponsorState())
    val state: StateFlow<SponsorState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getSponsors()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    val rawList = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    val sponsors = rawList.map { map ->
                        Sponsor(
                            name = map["name"] as? String ?: "",
                            amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
                            message = map["message"] as? String ?: "",
                            time = map["time"] as? String ?: ""
                        )
                    }
                    _state.value = _state.value.copy(
                        sponsors = sponsors,
                        total = sponsors.sumOf { it.amount },
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

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
