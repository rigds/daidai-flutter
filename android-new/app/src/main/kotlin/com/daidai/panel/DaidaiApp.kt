package com.daidai.panel

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.daidai.panel.ui.screens.*
import com.daidai.panel.viewmodel.AuthViewModel
import top.yukonga.miuix.kmp.basic.Scaffold
import top.yukonga.miuix.kmp.basic.TopAppBar

@Composable
fun DaidaiApp() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = viewModel()
    val authState by authViewModel.authState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = "呆呆面板"
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
                    onLogout = {
                        authViewModel.logout()
                        navController.navigate("login") {
                            popUpTo("home") { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun HomeScreen(
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
