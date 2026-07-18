package com.daidai.panel.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class EnvVar(
    val id: Int,
    val name: String,
    val value: String,
    val enabled: Boolean
)

@Composable
fun EnvListScreen() {
    val envVars = remember { mutableStateListOf<EnvVar>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(envVars) { env ->
            EnvCard(env = env)
        }
    }
}

@Composable
fun EnvCard(env: EnvVar) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = env.name,
                style = MaterialTheme.typography.titleMedium
            )
            Text(text = env.value)
            Text(text = if (env.enabled) "已启用" else "已禁用")
        }
    }
}
