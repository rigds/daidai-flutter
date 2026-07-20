package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class Task(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("command") val command: String = "",
    @SerializedName("cron_expression") val cronExpression: String = "",
    @SerializedName("cron_expressions") val cronExpressions: List<String> = emptyList(),
    @SerializedName("task_type") val taskType: Int = 0,
    @SerializedName("python_version") val pythonVersion: String = "",
    @SerializedName("status") val status: Int = 0,
    @SerializedName("labels") val labels: String = "",
    @SerializedName("display_labels") val displayLabels: List<String> = emptyList(),
    @SerializedName("last_run_at") val lastRunAt: String = "",
    @SerializedName("next_run_at") val nextRunAt: String = "",
    @SerializedName("last_run_status") val lastRunStatus: Int = 0,
    @SerializedName("timeout") val timeout: Int = 0,
    @SerializedName("random_delay_seconds") val randomDelaySeconds: Int = 0,
    @SerializedName("max_retries") val maxRetries: Int = 0,
    @SerializedName("retry_interval") val retryInterval: Int = 0,
    @SerializedName("notify_on_failure") val notifyOnFailure: Boolean = false,
    @SerializedName("notify_on_success") val notifyOnSuccess: Boolean = false,
    @SerializedName("notification_channel_id") val notificationChannelId: Int? = null,
    @SerializedName("depends_on") val dependsOn: String = "",
    @SerializedName("sort_order") val sortOrder: Int = 0,
    @SerializedName("is_pinned") val isPinned: Boolean = false,
    @SerializedName("task_before") val taskBefore: String = "",
    @SerializedName("task_after") val taskAfter: String = "",
    @SerializedName("allow_multiple_instances") val allowMultipleInstances: Boolean = false,
    @SerializedName("notification_channel_name") val notificationChannelName: String = "",
    @SerializedName("notification_channel_enabled") val notificationChannelEnabled: Boolean = false,
    @SerializedName("last_running_time") val lastRunningTime: Double = 0.0,
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isDisabled: Boolean get() = status == 0
    val isQueued: Boolean get() = status == 4
    val isEnabled: Boolean get() = status == 1
    val isRunning: Boolean get() = status == 3

    val statusText: String
        get() = when (status) {
            0 -> "已禁用"
            1 -> "已启用"
            2 -> "等待中"
            3 -> "运行中"
            4 -> "队列中"
            else -> "未知"
        }

    val labelList: List<String>
        get() = if (displayLabels.isNotEmpty()) displayLabels
        else labels.split(",").filter { it.isNotBlank() }.map { it.trim() }

    val groupName: String
        get() = labelList.firstOrNull() ?: ""
}
