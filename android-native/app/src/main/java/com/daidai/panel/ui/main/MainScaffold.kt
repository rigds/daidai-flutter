package com.daidai.panel.ui.main

import android.app.Activity
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.ThemeViewModel
import com.daidai.panel.ui.components.GlassScaffold
import com.daidai.panel.ui.components.GlassTabBar
import com.daidai.panel.ui.components.TabRoute
import com.daidai.panel.ui.dashboard.DashboardPage
import com.daidai.panel.ui.envs.EnvListPage
import com.daidai.panel.ui.logs.LogListPage
import com.daidai.panel.ui.settings.MorePage
import com.daidai.panel.ui.tasks.TaskListPage

@Composable
fun MainScaffold(
    initialTab: String = "dashboard",
    onNavigateToSubPage: (String) -> Unit,
    onLogout: () -> Unit,
    themeViewModel: ThemeViewModel = hiltViewModel()
) {
    var currentTab by remember { mutableStateOf(initialTab) }
    val glassMode by themeViewModel.glassMode.collectAsState()
    val backgroundImagePath by themeViewModel.backgroundImagePath.collectAsState()
    val blurIntensity by themeViewModel.blurIntensity.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current

    var lastBackPress by remember { mutableLongStateOf(0L) }
    BackHandler {
        val now = System.currentTimeMillis()
        if (now - lastBackPress < 2000) {
            (context as? Activity)?.finish()
        } else {
            lastBackPress = now
            Toast.makeText(context, "再按一次退出", Toast.LENGTH_SHORT).show()
        }
    }

    val handleNavigation: (String) -> Unit = { route ->
        when (route) {
            "dashboard", "tasks", "logs", "envs", "more" -> currentTab = route
            else -> onNavigateToSubPage(route)
        }
    }

    GlassScaffold(
        backgroundImagePath = backgroundImagePath,
        glassMode = glassMode,
        blurIntensity = blurIntensity * 40f
    ) { paddingValues ->
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            containerColor = androidx.compose.ui.graphics.Color.Transparent,
            snackbarHost = { SnackbarHost(snackbarHostState) },
            bottomBar = {
                GlassTabBar(
                    currentRoute = currentTab,
                    onTabSelected = { tab -> currentTab = tab.route },
                    glassMode = glassMode
                )
            }
        ) { innerPadding ->
            val contentPadding = PaddingValues(
                top = paddingValues.calculateTopPadding() + innerPadding.calculateTopPadding(),
                bottom = innerPadding.calculateBottomPadding()
            )

            when (currentTab) {
                "dashboard" -> DashboardPage(
                    contentPadding = contentPadding,
                    glassMode = glassMode,
                    onNavigate = handleNavigation
                )
                "tasks" -> TaskListPage(
                    contentPadding = contentPadding,
                    glassMode = glassMode,
                    onNavigate = handleNavigation
                )
                "logs" -> LogListPage(
                    contentPadding = contentPadding,
                    glassMode = glassMode,
                    onNavigate = handleNavigation
                )
                "envs" -> EnvListPage(
                    contentPadding = contentPadding,
                    glassMode = glassMode,
                    onNavigate = handleNavigation
                )
                "more" -> MorePage(
                    contentPadding = contentPadding,
                    glassMode = glassMode,
                    onNavigate = handleNavigation,
                    onLogout = onLogout
                )
            }
        }
    }
}
