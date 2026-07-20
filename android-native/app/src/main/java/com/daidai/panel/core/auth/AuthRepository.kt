package com.daidai.panel.core.auth

import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.core.storage.SecureStorage
import com.daidai.panel.data.model.ApiResponse
import com.daidai.panel.data.model.User
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val secureStorage: SecureStorage,
    private val networkModule: NetworkModule
) {
    suspend fun needsInitialization(): Result<Boolean> {
        return try {
            val response = networkModule.getApiService().checkInit()
            if (response.isSuccessful) {
                Result.success(response.body()?.data ?: false)
            } else {
                Result.failure(Exception(response.body()?.message ?: "Check init failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun initAdmin(username: String, password: String): Result<Any> {
        return try {
            val response = networkModule.getApiService().initAdmin(
                mapOf("username" to username, "password" to password)
            )
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "Init failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun login(
        username: String,
        password: String,
        captchaCode: String? = null,
        captchaId: String? = null,
        totpCode: String? = null
    ): Result<User> {
        return try {
            val body = mutableMapOf(
                "username" to username,
                "password" to password
            )
            captchaCode?.let { body["captcha_code"] = it }
            captchaId?.let { body["captcha_id"] = it }
            totpCode?.let { body["totp_code"] = it }

            val response = networkModule.getApiService().login(body)
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                val data = response.body()?.data
                val accessToken = data?.get("access_token") as? String ?: ""
                val refreshToken = data?.get("refresh_token") as? String ?: ""
                secureStorage.saveTokens(accessToken, refreshToken)
                val user = getUser()
                user.onSuccess { return Result.success(it) }
                Result.failure(user.exceptionOrNull() ?: Exception("Failed to get user"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "Login failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun logout(): Result<Unit> {
        return try {
            networkModule.getApiService().logout()
            secureStorage.clearAuth()
            networkModule.invalidateApiService()
            Result.success(Unit)
        } catch (e: Exception) {
            secureStorage.clearAuth()
            networkModule.invalidateApiService()
            Result.success(Unit)
        }
    }

    suspend fun getUser(): Result<User> {
        return try {
            val response = networkModule.getApiService().getUser()
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                val user = response.body()?.data
                if (user != null) {
                    secureStorage.saveAuthUser(mapOf(
                        "id" to user.id,
                        "username" to user.username,
                        "role" to user.role
                    ))
                    Result.success(user)
                } else {
                    Result.failure(Exception("User data is null"))
                }
            } else {
                Result.failure(Exception(response.body()?.message ?: "Get user failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit> {
        return try {
            val response = networkModule.getApiService().changePassword(
                mapOf("old_password" to oldPassword, "new_password" to newPassword)
            )
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "Change password failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun checkHealth(): Result<Boolean> {
        return try {
            val response = networkModule.getApiService().health()
            Result.success(response.isSuccessful)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun isTrustedLogin(serverUrl: String): Boolean {
        val until = secureStorage.getTrustedLoginUntil()
        val trustedUrl = secureStorage.getTrustedLoginServerUrl()
        return until > System.currentTimeMillis() && trustedUrl == serverUrl
    }

    suspend fun setTrustedLogin(serverUrl: String, durationMillis: Long) {
        secureStorage.saveTrustedLoginUntil(System.currentTimeMillis() + durationMillis)
        secureStorage.saveTrustedLoginServerUrl(serverUrl)
    }
}
