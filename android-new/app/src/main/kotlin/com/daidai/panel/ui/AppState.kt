package com.daidai.panel.ui

import androidx.compose.runtime.compositionLocalOf

data class AppState(
    val colorMode: Int = 0,
    val enableSquircle: Boolean = true
)

val LocalAppState = compositionLocalOf { AppState() }
val LocalUpdateAppState = compositionLocalOf<(AppState) -> Unit> { {} }
