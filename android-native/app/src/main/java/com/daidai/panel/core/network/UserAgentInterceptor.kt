package com.daidai.panel.core.network

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserAgentInterceptor @Inject constructor() : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request().newBuilder()
            .header("X-Client-Type", "android")
            .header("X-Client-Version", "1.0.0")
            .header("X-Client-Name", "daidai-panel-android")
            .header("User-Agent", "DaidaiPanel-Android/1.0.0")
            .build()
        return chain.proceed(request)
    }
}
