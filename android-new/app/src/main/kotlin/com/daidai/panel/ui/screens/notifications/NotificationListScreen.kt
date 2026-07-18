package com.daidai.panel.ui.screens.notifications

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class NotificationChannel(
    val id: Int,
    val name: String,
    val type: String,
    val enabled: Boolean
)

@Composable
fun NotificationListScreen() {
    val channels = remember { mutableStateListOf<NotificationChannel>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(channels) { channel ->
            NotificationCard(channel = channel)
        }
    }
}

@Composable
fun NotificationCard(channel: NotificationChannel) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = channel.name)
            Text(text = "类型: ${channel.type}")
            Text(text = if (channel.enabled) "已启用" else "已禁用")
        }
    }
}
