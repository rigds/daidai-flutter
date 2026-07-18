package com.daidai.panel.ui.screens.logs

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class LogEntry(
    val id: Int,
    val taskId: Int,
    val taskName: String,
    val status: String,
    val startTime: String,
    val endTime: String?
)

@Composable
fun LogListScreen() {
    val logs = remember { mutableStateListOf<LogEntry>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(logs) { log ->
            LogCard(log = log)
        }
    }
}

@Composable
fun LogCard(log: LogEntry) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = log.taskName)
            Text(text = "状态: ${log.status}")
            Text(text = "开始时间: ${log.startTime}")
            if (log.endTime != null) {
                Text(text = "结束时间: ${log.endTime}")
            }
        }
    }
}
