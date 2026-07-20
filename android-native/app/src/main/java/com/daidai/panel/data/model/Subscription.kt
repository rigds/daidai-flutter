package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class Subscription(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("type") val type: Int = 0,
    @SerializedName("url") val url: String = "",
    @SerializedName("branch") val branch: String = "",
    @SerializedName("sub_path") val subPath: String = "",
    @SerializedName("schedule") val schedule: String = "",
    @SerializedName("whitelist") val whitelist: String = "",
    @SerializedName("blacklist") val blacklist: String = "",
    @SerializedName("auto_add_task") val autoAddTask: Boolean = false,
    @SerializedName("auto_del_task") val autoDelTask: Boolean = false,
    @SerializedName("enabled") val enabled: Boolean = true,
    @SerializedName("status") val status: Int = 0,
    @SerializedName("last_pull_at") val lastPullAt: String = "",
    @SerializedName("save_dir") val saveDir: String = "",
    @SerializedName("ssh_key_id") val sshKeyId: Int? = null,
    @SerializedName("alias") val alias: String = "",
    @SerializedName("depend_on") val dependOn: String = "",
    @SerializedName("hook_script") val hookScript: String = "",
    @SerializedName("force_overwrite") val forceOverwrite: Boolean = false,
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isRunning: Boolean get() = status == 1
    val isSingleFile: Boolean get() = type == 1
    val isGitRepo: Boolean get() = type == 0

    val typeLabel: String
        get() = when (type) {
            0 -> "Git 仓库"
            1 -> "单文件"
            else -> "未知"
        }

    val statusText: String
        get() = when (status) {
            0 -> "空闲"
            1 -> "拉取中"
            2 -> "拉取成功"
            3 -> "拉取失败"
            else -> "未知"
        }
}
