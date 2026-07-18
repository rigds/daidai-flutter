package com.daidai.panel.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import top.yukonga.miuix.kmp.theme.ColorSchemeMode
import top.yukonga.miuix.kmp.theme.MiuixTheme
import top.yukonga.miuix.kmp.theme.ThemeController

@Composable
fun AppTheme(
    colorMode: Int = 0,
    keyColor: Color? = null,
    content: @Composable () -> Unit,
) {
    val controller = remember(colorMode, keyColor) {
        when (colorMode) {
            1 -> ThemeController(ColorSchemeMode.Light)
            2 -> ThemeController(ColorSchemeMode.Dark)
            else -> ThemeController(ColorSchemeMode.System)
        }
    }
    MiuixTheme(
        controller = controller,
        content = content,
    )
}

@Composable
fun isInDarkTheme(): Boolean = when (LocalAppState.current.colorMode) {
    1 -> false
    2 -> true
    else -> isSystemInDarkTheme()
}
