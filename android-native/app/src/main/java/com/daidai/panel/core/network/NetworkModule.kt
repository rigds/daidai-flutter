package com.daidai.panel.core.network

import com.daidai.panel.core.storage.SecureStorage
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

object RetrofitClient {
    fun createPlainRetrofit(baseUrl: String): Retrofit {
        val cleanUrl = baseUrl.trim().trimEnd('/')
        val client = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()

        return Retrofit.Builder()
            .baseUrl("$cleanUrl/")
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
}

@Singleton
class NetworkModule @Inject constructor(
    private val secureStorage: SecureStorage,
    private val authInterceptor: AuthInterceptor,
    private val userAgentInterceptor: UserAgentInterceptor
) {
    private var currentBaseUrl: String? = null
    private var currentApiService: ApiService? = null

    fun getApiService(): ApiService {
        val baseUrl = secureStorage.getServerUrlSync()?.trim()?.trimEnd('/')
        if (baseUrl.isNullOrBlank()) {
            throw IllegalStateException("Server URL not configured")
        }

        if (currentApiService != null && currentBaseUrl == baseUrl) {
            return currentApiService!!
        }

        val okHttpClient = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .addInterceptor(userAgentInterceptor)
            .addInterceptor(authInterceptor)
            .build()

        val retrofit = Retrofit.Builder()
            .baseUrl("$baseUrl/")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()

        val service = retrofit.create(ApiService::class.java)
        currentBaseUrl = baseUrl
        currentApiService = service
        return service
    }

    fun invalidateApiService() {
        currentApiService = null
        currentBaseUrl = null
    }
}
