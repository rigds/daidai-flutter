package com.daidai.panel.ui.screens.deps

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class Dependency(
    val id: Int,
    val name: String,
    val version: String,
    val type: String
)

@Composable
fun DepListScreen() {
    val deps = remember { mutableStateListOf<Dependency>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(deps) { dep ->
            DepCard(dep = dep)
        }
    }
}

@Composable
fun DepCard(dep: Dependency) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = dep.name)
            Text(text = "版本: ${dep.version}")
            Text(text = "类型: ${dep.type}")
        }
    }
}
