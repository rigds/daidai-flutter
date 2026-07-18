package com.daidai.panel.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.Text

@Composable
fun DashboardScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            StatsCard(
                title = "启用任务",
                value = "0",
                icon = "📋"
            )
        }
        item {
            StatsCard(
                title = "环境变量",
                value = "0",
                icon = "🔑"
            )
        }
        item {
            StatsCard(
                title = "今日执行",
                value = "0",
                icon = "▶️"
            )
        }
        item {
            StatsCard(
                title = "失败任务",
                value = "0",
                icon = "❌"
            )
        }
    }
}

@Composable
fun StatsCard(
    title: String,
    value: String,
    icon: String
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(text = title)
                Text(
                    text = value,
                    style = top.yukonga.miuix.kmp.theme.MiuixTheme.textStyles.headline2
                )
            }
            Text(text = icon)
        }
    }
}
