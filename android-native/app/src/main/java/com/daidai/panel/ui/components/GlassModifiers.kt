package com.daidai.panel.ui.components

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.RenderEffect
import androidx.compose.ui.graphics.Shader.TileMode
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.graphicsLayer

@RequiresApi(Build.VERSION_CODES.S)
fun Modifier.glassBlur(blurRadius: Float): Modifier = this.graphicsLayer {
    renderEffect = RenderEffect
        .createBlurEffect(blurRadius, blurRadius, TileMode.CLAMP)
        .asComposeRenderEffect()
}
