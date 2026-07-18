package com.daidai.panel.ui.screens.openapi

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class OpenApiToken(
    val id: Int,
    val name: String,
    val clientId: String,
    val enabled: Boolean
)

@Composable
fun OpenApiScreen() {
    val tokens = remember { mutableStateListOf<OpenApiToken>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(tokens) { token ->
            OpenApiCard(token = token)
        }
    }
}

@Composable
fun OpenApiCard(token: OpenApiToken) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = token.name)
            Text(text = "Client ID: ${token.clientId}")
            Text(text = if (token.enabled) "已启用" else "已禁用")
        }
    }
}
