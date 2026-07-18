package com.daidai.panel.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.Text

data class Task(
    val id: Int,
    val name: String,
    val cron: String,
    val enabled: Boolean
)

@Composable
fun TaskListScreen() {
    val tasks = remember { mutableStateListOf<Task>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(tasks) { task ->
            TaskCard(task = task)
        }
    }
}

@Composable
fun TaskCard(task: Task) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = task.name,
                style = top.yukonga.miuix.kmp.theme.MiuixTheme.textStyles.headline3
            )
            Text(text = "Cron: ${task.cron}")
            Text(text = if (task.enabled) "已启用" else "已禁用")
        }
    }
}
