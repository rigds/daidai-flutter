package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class User(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("username") val username: String = "",
    @SerializedName("role") val role: String = "viewer",
    @SerializedName("enabled") val enabled: Boolean = true,
    @SerializedName("avatar_url") val avatarUrl: String = "",
    @SerializedName("last_login_at") val lastLoginAt: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isAdmin: Boolean get() = role == "admin"
    val isOperator: Boolean get() = role == "operator" || isAdmin
}
