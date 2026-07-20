package com.daidai.panel.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.daidai.panel.core.theme.AppColors

@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    glassMode: Boolean = false,
    placeholder: String = "搜索..."
) {
    val isLight = !isSystemInDarkTheme()
    val shape = RoundedCornerShape(12.dp)

    if (glassMode) {
        TextField(
            value = query,
            onValueChange = onQueryChange,
            modifier = modifier
                .fillMaxWidth()
                .clip(shape)
                .then(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        Modifier
                            .background(Color.Transparent)
                            .glassBlur(15f)
                            .background(
                                color = if (isLight) AppColors.glassCard else Color(0x991E293B),
                                shape = shape
                            )
                    } else {
                        Modifier.background(
                            color = if (isLight) Color(0xCCFFFFFF) else Color(0xCC1E293B),
                            shape = shape
                        )
                    }
                )
                .border(
                    width = 0.5.dp,
                    color = if (isLight) AppColors.glassCardBorder else Color(0x33334155),
                    shape = shape
                ),
            placeholder = {
                Text(
                    text = placeholder,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isLight) AppColors.slate400 else AppColors.slate500
                )
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = "搜索",
                    tint = if (isLight) AppColors.slate400 else AppColors.slate500
                )
            },
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                cursorColor = AppColors.primary,
                focusedTextColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface,
                unfocusedTextColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )
    } else {
        TextField(
            value = query,
            onValueChange = onQueryChange,
            modifier = modifier.fillMaxWidth(),
            placeholder = {
                Text(
                    text = placeholder,
                    style = MaterialTheme.typography.bodyMedium
                )
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = "搜索"
                )
            },
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium,
            shape = shape,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                cursorColor = AppColors.primary
            )
        )
    }
}
