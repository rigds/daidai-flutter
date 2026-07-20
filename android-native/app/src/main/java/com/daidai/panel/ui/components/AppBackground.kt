package com.daidai.panel.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.daidai.panel.core.theme.AppColors
import java.io.File

@Composable
fun AppBackground(
    backgroundImage: ImageBitmap? = null,
    backgroundImagePath: String? = null,
    blurRadius: Float = 20f,
    modifier: Modifier = Modifier
) {
    val isLight = !isSystemInDarkTheme()

    Box(modifier = modifier.fillMaxSize()) {
        if (backgroundImage != null) {
            androidx.compose.foundation.Image(
                bitmap = backgroundImage,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .then(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            Modifier.blur(blurRadius.dp)
                        } else {
                            Modifier
                        }
                    ),
                contentScale = ContentScale.Crop
            )
        } else if (backgroundImagePath != null) {
            val imageModel = remember(backgroundImagePath) {
                val file = File(backgroundImagePath)
                if (file.exists()) file else backgroundImagePath
            }
            AsyncImage(
                model = imageModel,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .then(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            Modifier.blur(blurRadius.dp)
                        } else {
                            Modifier
                        }
                    ),
                contentScale = ContentScale.Crop
            )
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    if (isLight) {
                        Color.White.copy(alpha = 0.3f)
                    } else {
                        AppColors.slate950.copy(alpha = 0.5f)
                    }
                )
        )
    }
}
