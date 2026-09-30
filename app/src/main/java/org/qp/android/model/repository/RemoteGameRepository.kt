package org.qp.android.model.repository

import android.util.Log
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.CompletableFuture

class RemoteGameRepository(
    private val client: HttpClient = HttpClient(OkHttp)
) {
    companion object {
        private const val TAG = "RemoteGameRepo"
        private const val BASE_URL = "https://qsp.org/gamestock/gamestock2.php"
    }

    suspend fun fetchRemoteGamesXml(): String {
        return client.get(BASE_URL).bodyAsText()
    }

    fun fetchRemoteGamesXmlAsync(): CompletableFuture<String> {
        val future = CompletableFuture<String>()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = fetchRemoteGamesXml()
                future.complete(result)
            } catch (e: Throwable) {
                Log.e(TAG, "Failed fetching remote games: ${e.message}", e)
                future.completeExceptionally(e)
            }
        }
        return future
    }
}
