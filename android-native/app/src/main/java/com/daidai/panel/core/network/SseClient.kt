package com.daidai.panel.core.network

import com.daidai.panel.core.storage.SecureStorage
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.runBlocking
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SseClient @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val secureStorage: SecureStorage
) {

    fun stream(url: String, headers: Map<String, String> = emptyMap()): Flow<String> = callbackFlow {
        val serverUrl = runBlocking { secureStorage.getServerUrl() } ?: ""
        val token = runBlocking { secureStorage.getAccessToken() }

        val requestBuilder = Request.Builder()
            .url("$serverUrl$url")
            .header("Accept", "text/event-stream")
            .header("Cache-Control", "no-cache")

        if (!token.isNullOrEmpty()) {
            requestBuilder.header("Authorization", "Bearer $token")
        }

        headers.forEach { (key, value) ->
            requestBuilder.header(key, value)
        }

        val factory = EventSources.createFactory(okHttpClient)
        val listener = object : EventSourceListener() {
            override fun onEvent(eventSource: EventSource, id: String?, type: String?, data: String) {
                trySend(data)
            }

            override fun onFailure(eventSource: EventSource, t: Throwable?, response: okhttp3.Response?) {
                close(t ?: Exception("SSE connection failed"))
            }

            override fun onClosed(eventSource: EventSource) {
                close()
            }
        }

        val eventSource = factory.newEventSource(requestBuilder.build(), listener)

        awaitClose {
            eventSource.cancel()
        }
    }
}
