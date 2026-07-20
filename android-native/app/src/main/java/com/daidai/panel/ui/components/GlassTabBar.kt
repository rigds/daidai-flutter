package com.daidai.panel.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.SpaceDashboard
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.SpaceDashboard
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.daidai.panel.core.theme.AppColors

enum class TabRoute(
    val route: String,
    val label: String,
    val icon: ImageVector,
    val activeIcon: ImageVector
) {
    DASHBOARD("dashboard", "主页", Icons.Outlined.SpaceDashboard, Icons.Filled.SpaceDashboard),
    TASKS("tasks", "任务", Icons.Outlined.Schedule, Icons.Filled.Schedule),
    LOGS("logs", "日志", Icons.Outlined.Terminal, Icons.Filled.Terminal),
    ENVS("envs", "环境变量", Icons.Outlined.Key, Icons.Filled.Key),
    MORE("more", "更多", Icons.Outlined.MoreHoriz, Icons.Filled.MoreHoriz)
}

@Composable
fun GlassTabBar(
    currentRoute: String,
    onTabSelected: (TabRoute) -> Unit,
    glassMode: Boolean = false,
    modifier: Modifier = Modifier
) {
    val isLight = !isSystemInDarkTheme()

    if (glassMode) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
                .then(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        Modifier
                            .background(Color.Transparent)
                            .glassBlur(20f)
                            .background(
                                color = if (isLight) AppColors.glassCard else Color(0x991E293B)
                            )
                    } else {
                        Modifier.background(
                            color = if (isLight) Color(0xCCFFFFFF) else Color(0xCC1E293B)
                        )
                    }
                )
                .border(
                    width = 0.5.dp,
                    color = if (isLight) AppColors.glassCardBorder else Color(0x33334155),
                    shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
                )
        ) {
            NavigationBar(
                containerColor = Color.Transparent,
                contentColor = MaterialTheme.colorScheme.onSurface,
                tonalElevation = 0.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                TabRoute.entries.forEach { tab ->
                    val selected = currentRoute == tab.route
                    NavigationBarItem(
                        selected = selected,
                        onClick = { onTabSelected(tab) },
                        icon = {
                            Icon(
                                imageVector = if (selected) tab.activeIcon else tab.icon,
                                contentDescription = tab.label
                            )
                        },
                        label = {
                            Text(
                                text = tab.label,
                                style = MaterialTheme.typography.labelSmall
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = AppColors.primary,
                            selectedTextColor = AppColors.primary,
                            unselectedIconColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                            unselectedTextColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                            indicatorColor = AppColors.primary.copy(alpha = 0.12f)
                        )
                    )
                }
            }
        }
    } else {
        NavigationBar(
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface,
            modifier = modifier.fillMaxWidth()
        ) {
            TabRoute.entries.forEach { tab ->
                val selected = currentRoute == tab.route
                NavigationBarItem(
                    selected = selected,
                    onClick = { onTabSelected(tab) },
                    icon = {
                        Icon(
                            imageVector = if (selected) tab.activeIcon else tab.icon,
                            contentDescription = tab.label
                        )
                    },
                    label = {
                        Text(
                            text = tab.label,
                            style = MaterialTheme.typography.labelSmall
                        )
                    },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = AppColors.primary,
                        selectedTextColor = AppColors.primary,
                        unselectedIconColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                        unselectedTextColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                        indicatorColor = AppColors.primary.copy(alpha = 0.12f)
                    )
                )
            }
        }
    }
}
