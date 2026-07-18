package com.daidai.panel.ui.screens.scripts

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class Script(
    val id: Int,
    val name: String,
    val path: String,
    val content: String?
)

@Composable
fun ScriptListScreen() {
    val scripts = remember { mutableStateListOf<Script>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(scripts) { script ->
            ScriptCard(script = script)
        }
    }
}

@Composable
fun ScriptCard(script: Script) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = script.name)
            Text(text = "路径: ${script.path}")
        }
    }
}
