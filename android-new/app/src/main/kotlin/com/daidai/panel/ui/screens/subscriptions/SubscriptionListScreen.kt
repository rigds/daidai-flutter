package com.daidai.panel.ui.screens.subscriptions

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class Subscription(
    val id: Int,
    val name: String,
    val url: String,
    val enabled: Boolean
)

@Composable
fun SubscriptionListScreen() {
    val subscriptions = remember { mutableStateListOf<Subscription>() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(subscriptions) { sub ->
            SubscriptionCard(subscription = sub)
        }
    }
}

@Composable
fun SubscriptionCard(subscription: Subscription) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = subscription.name)
            Text(text = "URL: ${subscription.url}")
            Text(text = if (subscription.enabled) "已启用" else "已禁用")
        }
    }
}
