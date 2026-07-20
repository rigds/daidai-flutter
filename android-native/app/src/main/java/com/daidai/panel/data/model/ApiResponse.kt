package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class ApiResponse<T>(
    @SerializedName("code") val code: Int = 0,
    @SerializedName("message") val message: String = "",
    @SerializedName("data") val data: T? = null
) {
    val isSuccess: Boolean get() = code == 0 || code == 200
}

data class PaginatedData<T>(
    @SerializedName("items") val items: List<T> = emptyList(),
    @SerializedName("total") val total: Int = 0
)
