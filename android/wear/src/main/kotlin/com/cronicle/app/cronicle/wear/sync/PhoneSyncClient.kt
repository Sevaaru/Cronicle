package com.cronicle.app.cronicle.wear.sync

import android.content.Context
import android.util.Log
import com.cronicle.app.cronicle.wear.model.LibraryItem
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.NodeClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

/**
 * Wear-side façade over the Google Play Services Wearable Data Layer. Reads cached
 * snapshots, requests a refresh from the phone, and dispatches user actions.
 */
class PhoneSyncClient(context: Context) {

    private val appContext = context.applicationContext
    private val dataClient: DataClient = Wearable.getDataClient(appContext)
    private val messageClient: MessageClient = Wearable.getMessageClient(appContext)
    private val nodeClient: NodeClient = Wearable.getNodeClient(appContext)

    /**
     * Reads the latest cached library snapshot already pushed by the phone, if any.
     * Returns an empty list when no snapshot exists (e.g. phone has never connected).
     */
    suspend fun loadCachedSnapshot(): List<LibraryItem> = withContext(Dispatchers.IO) {
        try {
            val items = dataClient.dataItems.await()
            Log.i(TAG, "loadCachedSnapshot: dataItems=${items.count} paths=${items.map { it.uri.path }}")
            val match = items
                .filter { it.uri.path == WearProtocol.PATH_LIBRARY_ITEMS }
                .maxByOrNull { DataMapItem.fromDataItem(it).dataMap.getLong(WearProtocol.KEY_TIMESTAMP, 0) }
                ?: return@withContext emptyList<LibraryItem>()
            val map = DataMapItem.fromDataItem(match).dataMap
            val json = map.getString(WearProtocol.KEY_ITEMS_JSON) ?: return@withContext emptyList()
            val parsed = parseItems(json)
            Log.i(TAG, "loadCachedSnapshot: parsed=${parsed.size}")
            parsed
        } catch (t: Throwable) {
            Log.w(TAG, "loadCachedSnapshot failed", t)
            emptyList()
        }
    }

    /**
     * Asks the phone to publish a fresh snapshot. Returns true when the message was
     * delivered to at least one paired node.
     */
    suspend fun requestSync(): Boolean = withContext(Dispatchers.IO) {
        try {
            val local = try { nodeClient.localNode.await() } catch (t: Throwable) { null }
            val nodes = nodeClient.connectedNodes.await()
            Log.i(TAG, "requestSync: localNode=${local?.displayName}/${local?.id} connectedNodes=${nodes.size} -> ${nodes.map { it.displayName + "/" + it.id + "/nearby=" + it.isNearby }}")
            if (nodes.isEmpty()) return@withContext false
            var ok = false
            for (node in nodes) {
                try {
                    messageClient.sendMessage(node.id, WearProtocol.PATH_REQUEST_SYNC, ByteArray(0)).await()
                    Log.i(TAG, "requestSync delivered to ${node.displayName}")
                    ok = true
                } catch (t: Throwable) {
                    Log.w(TAG, "sendMessage to ${node.id} failed", t)
                }
            }
            ok
        } catch (t: Throwable) {
            Log.w(TAG, "requestSync failed", t)
            false
        }
    }

    /**
     * Sends an action ("increment" or "complete") to the phone. The phone applies the
     * change to the local Drift database and then publishes an updated snapshot.
     */
    suspend fun sendAction(item: LibraryItem, action: String): Boolean = withContext(Dispatchers.IO) {
        val payload = JSONObject().apply {
            put("action", action)
            put("kind", item.kind)
            put("externalId", item.externalId)
            put("id", item.id)
        }.toString().toByteArray(Charsets.UTF_8)

        try {
            val nodes = nodeClient.connectedNodes.await()
            if (nodes.isEmpty()) return@withContext false
            var ok = false
            for (node in nodes) {
                try {
                    messageClient.sendMessage(node.id, WearProtocol.PATH_ACTION, payload).await()
                    ok = true
                } catch (t: Throwable) {
                    Log.w(TAG, "action to ${node.id} failed", t)
                }
            }
            ok
        } catch (t: Throwable) {
            Log.w(TAG, "sendAction failed", t)
            false
        }
    }

    companion object {
        private const val TAG = "PhoneSyncClient"

        fun parseItems(json: String): List<LibraryItem> {
            return try {
                val arr = JSONArray(json)
                buildList(arr.length()) {
                    for (i in 0 until arr.length()) {
                        val o = arr.optJSONObject(i) ?: continue
                        add(
                            LibraryItem(
                                id = o.optLong("id"),
                                kind = o.optInt("kind"),
                                externalId = o.optString("externalId"),
                                title = o.optString("title", "?"),
                                posterUrl = o.optString("posterUrl").takeIf { it.isNotBlank() && it != "null" },
                                status = o.optString("status", "CURRENT"),
                                progress = o.optIntOrNull("progress"),
                                totalEpisodes = o.optIntOrNull("totalEpisodes"),
                                releasedEpisodes = o.optIntOrNull("releasedEpisodes"),
                                currentChapter = o.optIntOrNull("currentChapter"),
                                totalPages = o.optIntOrNull("totalPages"),
                                totalChapters = o.optIntOrNull("totalChapters"),
                                bookTrackingMode = o.optString("bookTrackingMode").ifBlank { null },
                                updatedAt = o.optLong("updatedAt"),
                            )
                        )
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "parseItems failed", t)
                emptyList()
            }
        }

        private fun JSONObject.optIntOrNull(key: String): Int? =
            if (isNull(key)) null else if (has(key)) optInt(key) else null
    }
}
