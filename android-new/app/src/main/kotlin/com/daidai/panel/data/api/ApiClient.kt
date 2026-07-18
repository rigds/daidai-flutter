package com.daidai.panel.data.api

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

object ApiClient {
    private var baseUrl: String = "http://127.0.0.1:5700"
    private var accessToken: String? = null

    val client = HttpClient(Android) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }

    fun setBaseUrl(url: String) {
        baseUrl = url.trimEnd('/')
    }

    fun setAccessToken(token: String?) {
        accessToken = token
    }

    fun getBaseUrl(): String = baseUrl

    suspend fun checkHealth(): Boolean {
        return try {
            val response = client.get("$baseUrl/api/v1/health")
            response.status.value == 200
        } catch (e: Exception) {
            false
        }
    }

    suspend fun login(username: String, password: String): Result<Map<String, Any>> {
        return try {
            val response = client.post("$baseUrl/api/auth/login") {
                contentType(ContentType.Application.Json)
                setBody(mapOf("username" to username, "password" to password))
            }
            if (response.status.value == 200) {
                val body = response.body<Map<String, Any>>()
                val data = body["data"] as? Map<String, Any> ?: body
                val token = data["access_token"] as? String
                if (token != null) {
                    setAccessToken(token)
                }
                Result.success(data)
            } else {
                Result.failure(Exception("登录失败: ${response.status.value}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getDashboard(): Result<Map<String, Any>> {
        return try {
            val response = client.get("$baseUrl/api/system/dashboard")
            val body = response.body<Map<String, Any>>()
            Result.success(body["data"] as? Map<String, Any> ?: body)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getSystemInfo(): Result<Map<String, Any>> {
        return try {
            val response = client.get("$baseUrl/api/system/info")
            val body = response.body<Map<String, Any>>()
            Result.success(body["data"] as? Map<String, Any> ?: body)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
