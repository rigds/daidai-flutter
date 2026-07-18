package com.daidai.panel.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.Button
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.Text
import top.yukonga.miuix.kmp.basic.TextField

@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit
) {
    var serverUrl by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "呆呆面板",
                    style = top.yukonga.miuix.kmp.theme.MiuixTheme.textStyles.headline1
                )

                TextField(
                    value = serverUrl,
                    onValueChange = { serverUrl = it },
                    label = "服务器地址",
                    modifier = Modifier.fillMaxWidth()
                )

                TextField(
                    value = username,
                    onValueChange = { username = it },
                    label = "用户名",
                    modifier = Modifier.fillMaxWidth()
                )

                TextField(
                    value = password,
                    onValueChange = { password = it },
                    label = "密码",
                    visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth()
                )

                Button(
                    onClick = {
                        isLoading = true
                        // TODO: 实现登录逻辑
                        onLoginSuccess()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading
                ) {
                    Text(if (isLoading) "登录中..." else "登录")
                }
            }
        }
    }
}
