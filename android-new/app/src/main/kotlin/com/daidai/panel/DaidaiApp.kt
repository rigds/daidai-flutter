package com.daidai.panel

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.daidai.panel.ui.screens.*
import com.daidai.panel.ui.screens.applock.AppLockScreen
import com.daidai.panel.ui.screens.deps.DepListScreen
import com.daidai.panel.ui.screens.logs.LogListScreen
import com.daidai.panel.ui.screens.notifications.NotificationListScreen
import com.daidai.panel.ui.screens.openapi.OpenApiScreen
import com.daidai.panel.ui.screens.scripts.ScriptListScreen
import com.daidai.panel.ui.screens.security.SecurityScreen
import com.daidai.panel.ui.screens.serverconfig.ServerConfigScreen
import com.daidai.panel.ui.screens.subscriptions.SubscriptionListScreen
import com.daidai.panel.ui.screens.system.SystemSettingsScreen
import com.daidai.panel.ui.screens.tasks.TaskFormScreen
import com.daidai.panel.ui.screens.tasks.TaskListScreen
import com.daidai.panel.ui.screens.users.UserListScreen
import com.daidai.panel.viewmodel.AuthViewModel

@Composable
fun DaidaiApp() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = viewModel()
    val authState by authViewModel.authState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("呆呆面板") }
            )
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = if (authState.isAuthenticated) "home" else "login",
            modifier = Modifier.padding(paddingValues)
        ) {
            composable("login") {
                LoginScreen(
                    onLoginSuccess = {
                        navController.navigate("home") {
                            popUpTo("login") { inclusive = true }
                        }
                    }
                )
            }
            composable("home") {
                HomeScreen(
                    navController = navController,
                    onLogout = {
                        authViewModel.logout()
                        navController.navigate("login") {
                            popUpTo("home") { inclusive = true }
                        }
                    }
                )
            }
            composable("tasks") {
                TaskListScreen()
            }
            composable("tasks/new") {
                TaskFormScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }
            composable("tasks/edit/{taskId}") { backStackEntry ->
                val taskId = backStackEntry.arguments?.getString("taskId")?.toIntOrNull()
                TaskFormScreen(
                    taskId = taskId,
                    onNavigateBack = { navController.popBackStack() }
                )
            }
            composable("envs") {
                EnvListScreen()
            }
            composable("deps") {
                DepListScreen()
            }
            composable("scripts") {
                ScriptListScreen()
            }
            composable("logs") {
                LogListScreen()
            }
            composable("subscriptions") {
                SubscriptionListScreen()
            }
            composable("notifications") {
                NotificationListScreen()
            }
            composable("openapi") {
                OpenApiScreen()
            }
            composable("security") {
                SecurityScreen()
            }
            composable("applock") {
                AppLockScreen()
            }
            composable("system-settings") {
                SystemSettingsScreen()
            }
            composable("server-config") {
                ServerConfigScreen()
            }
            composable("users") {
                UserListScreen()
            }
            composable("settings") {
                SettingsScreen()
            }
        }
    }
}

@Composable
fun HomeScreen(
    navController: androidx.navigation.NavController,
    onLogout: () -> Unit
) {
    var selectedTab by remember { mutableIntStateOf(0) }

    val tabs = listOf("仪表盘", "任务", "变量", "设置")

    Column(modifier = Modifier.fillMaxSize()) {
        when (selectedTab) {
            0 -> DashboardScreen()
            1 -> TaskListScreen()
            2 -> EnvListScreen()
            3 -> SettingsScreen()
        }
    }
}
