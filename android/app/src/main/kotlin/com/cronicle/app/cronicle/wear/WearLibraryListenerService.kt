package com.cronicle.app.cronicle.wear

import android.content.Intent
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONArray
import org.json.JSONObject

/**
 * Phone-side service that responds to messages sent from the Wear OS companion app.
 *
 * Two endpoints (paths) are handled:
 *   - `/library/request_sync` → reads the in-progress rows from the Drift database and
 *     publishes a JSON snapshot at the DataClient path `/library/items`. The watch's
 *     `WearableListenerService` picks up the change and refreshes its UI.
 *   - `/library/action` → applies an `increment` or `complete` action against the
 *     given `(kind, externalId)` row, then re-publishes the snapshot so the watch
 *     reflects the new state immediately.
 *
 * Important: this service runs even when the Flutter app is not in the foreground —
 * Android starts it on-demand when a message arrives. It must therefore be free of
 * Flutter dependencies and write directly to the SQLite file.
 */
class WearLibraryListenerService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            PATH_REQUEST_SYNC -> publishSnapshot()
            PATH_ACTION -> handleAction(messageEvent.data)
            else -> Log.d(TAG, "Ignoring message on path: ${messageEvent.path}")
        }
    }

    private fun handleAction(payload: ByteArray) {
        val json = try {
            JSONObject(String(payload, Charsets.UTF_8))
        } catch (t: Throwable) {
            Log.w(TAG, "Malformed action payload", t)
            return
        }
        val action = json.optString("action")
        val kind = json.optInt("kind", -1)
        val externalId = json.optString("externalId")
        if (action.isEmpty() || kind < 0 || externalId.isEmpty()) {
            Log.w(TAG, "Incomplete action payload: $json")
            return
        }

        val db = CronicleLibraryDb.openOrNull(applicationContext)
        if (db == null) {
            Log.w(TAG, "Database unavailable; ignoring $action for $kind:$externalId")
            return
        }
        try {
            val applied = when (action) {
                ACTION_INCREMENT -> db.incrementProgress(kind, externalId)
                ACTION_COMPLETE -> db.markCompleted(kind, externalId)
                else -> false
            }
            Log.d(TAG, "Applied $action on $kind:$externalId → $applied")
            if (applied) {
                // Push the change to AniList / Trakt by booting a hidden Flutter
                // engine. Drift already has the new local state.
                WearRemoteSyncService.enqueueAndLaunch(applicationContext, kind, externalId)
                // Notify the foreground Flutter app (if running) so it invalidates
                // its in-memory Drift streams and re-reads the database.
                try {
                    val intent = Intent(com.cronicle.app.cronicle.MainActivity.ACTION_LIBRARY_CHANGED)
                        .setPackage(packageName)
                    sendBroadcast(intent)
                } catch (t: Throwable) {
                    Log.w(TAG, "Failed to broadcast library change", t)
                }
            }
        } finally {
            db.close()
        }

        publishSnapshot()
    }

    private fun publishSnapshot() {
        val items = try {
            val db = CronicleLibraryDb.openOrNull(applicationContext)
            if (db == null) {
                Log.w(TAG, "DB unavailable; pushing empty snapshot")
                emptyList()
            } else {
                try { db.queryInProgress() } finally { db.close() }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Snapshot query failed", t)
            emptyList()
        }

        val arr = JSONArray()
        for (row in items) {
            val o = JSONObject()
            for ((k, v) in row) {
                if (v == null) o.put(k, JSONObject.NULL) else o.put(k, v)
            }
            arr.put(o)
        }

        val request = PutDataMapRequest.create(PATH_LIBRARY_ITEMS).apply {
            dataMap.putString(KEY_ITEMS_JSON, arr.toString())
            dataMap.putLong(KEY_TIMESTAMP, System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()

        try {
            Tasks.await(Wearable.getDataClient(applicationContext).putDataItem(request))
            Log.d(TAG, "Snapshot pushed: ${items.size} items")
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to push snapshot", t)
        }
    }

    companion object {
        private const val TAG = "WearLibraryListener"

        // Must mirror the Wear-side `WearProtocol` constants.
        private const val PATH_REQUEST_SYNC = "/library/request_sync"
        private const val PATH_LIBRARY_ITEMS = "/library/items"
        private const val PATH_ACTION = "/library/action"
        private const val KEY_ITEMS_JSON = "items_json"
        private const val KEY_TIMESTAMP = "timestamp"
        private const val ACTION_INCREMENT = "increment"
        private const val ACTION_COMPLETE = "complete"
    }
}
