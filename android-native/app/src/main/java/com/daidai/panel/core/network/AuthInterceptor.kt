package com.daidai.panel.core.network

import com.daidai.panel.core.storage.SecureStorage
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val secureStorage: SecureStorage
) : Interceptor {

    private val refreshMutex = Mutex()
    private var isRefreshing = false
    private var refreshTokenJob: (() -> Unit)? = null

    var onAuthFailed: (() -> Unit)? = null

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val token = runBlocking { secureStorage.getAccessToken() }

        val authenticatedRequest = if (!token.isNullOrEmpty()) {
            originalRequest.newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
        } else {
            originalRequest
        }

        val response = chain.proceed(authenticatedRequest)

        if (response.code == 401) {
            synchronized(this) {
                return handle401Response(chain, originalRequest, response)
            }
        }

        return response
    }

    private fun handle401Response(
        chain: Interceptor.Chain,
        originalRequest: Request,
        response: Response
    ): Response {
        val refreshToken = runBlocking { secureStorage.getRefreshToken() }

        if (refreshToken.isNullOrEmpty()) {
            runBlocking { secureStorage.clearAuth() }
            onAuthFailed?.invoke()
            return response
        }

        return runBlocking {
            refreshMutex.withLock {
                val newToken = tryRefreshToken(refreshToken)
                if (newToken != null) {
                    runBlocking { secureStorage.saveAccessToken(newToken) }
                    val newRequest = originalRequest.newBuilder()
                        .header("Authorization", "Bearer $newToken")
                        .build()
                    response.close()
                    chain.proceed(newRequest)
                } else {
                    runBlocking { secureStorage.clearAuth() }
                    onAuthFailed?.invoke()
                    response
                }
            }
        }
    }

    private suspend fun tryRefreshToken(refreshToken: String): String? {
        return try {
            val retrofit = RetrofitClient.createPlainRetrofit(
                runBlocking { secureStorage.getServerUrl() } ?: return null
            )
            val service = retrofit.create(ApiService::class.java)
            val result = service.refresh(mapOf("refresh_token" to refreshToken))
            if (result.isSuccessful && result.body()?.isSuccess == true) {
                result.body()?.data?.get("access_token")
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
