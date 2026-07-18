package com.daidai.panel.ui.screens.system

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun SystemSettingsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(text = "面板设置")
                    Text(text = "配置面板的基本设置")
                }
            }
        }
        item {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(text = "面板日志")
                    Text(text = "查看面板运行日志")
                }
            }
        }
        item {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(text = "备份恢复")
                    Text(text = "备份和恢复面板数据")
                }
            }
        }
    }
}

@Composable
fun PanelLogScreen() {
    // TODO: 实现面板日志页面
}

@Composable
fun BackupScreen() {
    // TODO: 实现备份恢复页面
}
