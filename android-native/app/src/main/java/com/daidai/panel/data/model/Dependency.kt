package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class Dependency(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("version") val version: String = "",
    @SerializedName("type") val type: Int = 0,
    @SerializedName("python_version") val pythonVersion: String = "",
    @SerializedName("status") val status: Int = 0,
    @SerializedName("remark") val remark: String = "",
    @SerializedName("log") val log: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isQueued: Boolean get() = status == 0
    val isInstalling: Boolean get() = status == 1
    val isRemoving: Boolean get() = status == 3
    val isInstalled: Boolean get() = status == 2
    val isFailed: Boolean get() = status == 4
    val isBusy: Boolean get() = status == 1 || status == 3

    val statusText: String
        get() = when (status) {
            0 -> "队列中"
            1 -> "安装中"
            2 -> "已安装"
            3 -> "卸载中"
            4 -> "安装失败"
            else -> "未知"
        }
}
