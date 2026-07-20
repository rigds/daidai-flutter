package com.daidai.panel.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import com.daidai.panel.core.theme.AppColors

@Composable
fun GlassScaffold(
    backgroundImage: ImageBitmap? = null,
    backgroundImagePath: String? = null,
    glassMode: Boolean = false,
    blurIntensity: Float = 20f,
    content: @Composable (PaddingValues) -> Unit
) {
    val isLight = !isSystemInDarkTheme()

    if (glassMode) {
        Box(modifier = Modifier.fillMaxSize()) {
            if (backgroundImage != null) {
                AppBackground(
                    backgroundImage = backgroundImage,
                    blurRadius = blurIntensity
                )
            } else if (backgroundImagePath != null) {
                AppBackground(
                    backgroundImagePath = backgroundImagePath,
                    blurRadius = blurIntensity
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            if (isLight) AppColors.lightBackground else AppColors.darkBackground
                        )
                )
            }
            Scaffold(
                containerColor = Color.Transparent,
                contentColor = MaterialTheme.colorScheme.onBackground,
                content = content
            )
        }
    } else {
        Scaffold(
            containerColor = MaterialTheme.colorScheme.background,
            contentColor = MaterialTheme.colorScheme.onBackground,
            content = content
        )
    }
}
