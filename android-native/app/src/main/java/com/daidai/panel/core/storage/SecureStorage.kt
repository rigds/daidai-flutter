package com.daidai.panel.core.storage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecureStorage @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gson: Gson
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "daidai_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_TRUSTED_LOGIN_UNTIL = "trusted_login_until"
        private const val KEY_TRUSTED_LOGIN_SERVER_URL = "trusted_login_server_url"
        private const val KEY_SERVER_URL = "server_url"
        private const val KEY_PANELS_CONFIG = "panels_config"
        private const val KEY_AUTH_USER = "auth_user"
        private const val KEY_APP_LOCK_CONFIG = "app_lock_config"
    }

    suspend fun getAccessToken(): String? = prefs.getString(KEY_ACCESS_TOKEN, null)

    suspend fun saveAccessToken(token: String) {
        prefs.edit().putString(KEY_ACCESS_TOKEN, token).apply()
    }

    suspend fun getRefreshToken(): String? = prefs.getString(KEY_REFRESH_TOKEN, null)

    suspend fun saveRefreshToken(token: String) {
        prefs.edit().putString(KEY_REFRESH_TOKEN, token).apply()
    }

    suspend fun saveTokens(accessToken: String, refreshToken: String) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN, accessToken)
            .putString(KEY_REFRESH_TOKEN, refreshToken)
            .apply()
    }

    suspend fun getServerUrl(): String? = prefs.getString(KEY_SERVER_URL, null)

    fun getServerUrlSync(): String? = prefs.getString(KEY_SERVER_URL, null)

    suspend fun saveServerUrl(url: String) {
        prefs.edit().putString(KEY_SERVER_URL, url).apply()
    }

    suspend fun getTrustedLoginUntil(): Long {
        return prefs.getLong(KEY_TRUSTED_LOGIN_UNTIL, 0)
    }

    suspend fun saveTrustedLoginUntil(timestamp: Long) {
        prefs.edit().putLong(KEY_TRUSTED_LOGIN_UNTIL, timestamp).apply()
    }

    suspend fun getTrustedLoginServerUrl(): String? =
        prefs.getString(KEY_TRUSTED_LOGIN_SERVER_URL, null)

    suspend fun saveTrustedLoginServerUrl(url: String) {
        prefs.edit().putString(KEY_TRUSTED_LOGIN_SERVER_URL, url).apply()
    }

    suspend fun getAuthUser(): Map<String, Any>? {
        val json = prefs.getString(KEY_AUTH_USER, null) ?: return null
        return try {
            val type = object : TypeToken<Map<String, Any>>() {}.type
            gson.fromJson(json, type)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun saveAuthUser(user: Map<String, Any>) {
        prefs.edit().putString(KEY_AUTH_USER, gson.toJson(user)).apply()
    }

    suspend fun getPanelsConfig(): List<Map<String, Any>> {
        val json = prefs.getString(KEY_PANELS_CONFIG, null) ?: return emptyList()
        return try {
            val type = object : TypeToken<List<Map<String, Any>>>() {}.type
            gson.fromJson(json, type)
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun savePanelsConfig(config: List<Map<String, Any>>) {
        prefs.edit().putString(KEY_PANELS_CONFIG, gson.toJson(config)).apply()
    }

    suspend fun getAppLockConfig(): Map<String, Any>? {
        val json = prefs.getString(KEY_APP_LOCK_CONFIG, null) ?: return null
        return try {
            val type = object : TypeToken<Map<String, Any>>() {}.type
            gson.fromJson(json, type)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun saveAppLockConfig(config: Map<String, Any>) {
        prefs.edit().putString(KEY_APP_LOCK_CONFIG, gson.toJson(config)).apply()
    }

    suspend fun clearAuth() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_AUTH_USER)
            .apply()
    }

    suspend fun clearAll() {
        prefs.edit().clear().apply()
    }
}
