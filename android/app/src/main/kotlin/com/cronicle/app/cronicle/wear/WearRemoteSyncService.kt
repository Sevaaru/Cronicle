package com.cronicle.app.cronicle.wear

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/**
 * Headless foreground service that boots a `FlutterEngine` running the Dart
 * entry-point `wearSyncMain` (see `lib/wear_sync_entry.dart`). The Dart code
 * drains the pending wear-action queue and pushes updates to AniList / Trakt.
 *
 * The service stops itself as soon as Dart calls `cronicle.wear.sync.done`,
 * with a 30s safety timeout to guarantee we never linger.
 *
 * A foreground service is required so Android lets us do network work even when
 * the user has not opened the Cronicle app recently.
 */
class WearRemoteSyncService : Service() {

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        Log.w(TAG, "Engine timeout reached; force-stopping")
        stopAndShutdown()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundCompat()

        if (engine != null) {
            // Already running; new actions are picked up because Dart re-reads
            // the queue file. Nothing else to do.
            return START_NOT_STICKY
        }

        try {
            launchEngine()
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to launch FlutterEngine", t)
            stopAndShutdown()
        }

        // Hard timeout in case Dart never replies.
        handler.postDelayed(timeoutRunnable, TIMEOUT_MS)
        return START_NOT_STICKY
    }

    private fun launchEngine() {
        val loader: FlutterLoader = io.flutter.FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(applicationContext)
        }
        loader.ensureInitializationComplete(applicationContext, null)

        val eng = FlutterEngine(applicationContext)
        engine = eng

        val ch = MethodChannel(eng.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "done" -> {
                    Log.i(TAG, "Dart signalled done")
                    result.success(null)
                    stopAndShutdown()
                }
                else -> result.notImplemented()
            }
        }

        val entrypoint = DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(),
            "package:cronicle/wear_sync_entry.dart",
            "wearSyncMain",
        )
        eng.dartExecutor.executeDartEntrypoint(entrypoint)
    }

    private fun stopAndShutdown() {
        handler.removeCallbacks(timeoutRunnable)
        try { engine?.destroy() } catch (_: Throwable) {}
        engine = null
        channel = null
        try {
            stopForeground(Service.STOP_FOREGROUND_REMOVE)
        } catch (_: Throwable) {}
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeoutRunnable)
        try { engine?.destroy() } catch (_: Throwable) {}
        super.onDestroy()
    }

    private fun startForegroundCompat() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Sincronización con reloj",
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                description = "Envía cambios hechos en el reloj a AniList / Trakt"
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Cronicle")
            .setContentText("Sincronizando cambios del reloj…")
            .setSmallIcon(applicationInfo.icon)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notif,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    companion object {
        private const val TAG = "WearRemoteSyncSvc"
        private const val CHANNEL_NAME = "cronicle.wear.sync"
        private const val CHANNEL_ID = "cronicle_wear_sync"
        private const val NOTIF_ID = 4471
        private const val TIMEOUT_MS = 30_000L

        /**
         * Appends `(kind, externalId)` to the pending JSONL queue and starts the
         * foreground service. Safe to call from any thread.
         */
        fun enqueueAndLaunch(context: Context, kind: Int, externalId: String) {
            try {
                val docs = File(context.dataDir, "app_flutter")
                if (!docs.exists()) docs.mkdirs()
                val queue = File(docs, "wear_pending.jsonl")
                val line = JSONObject().apply {
                    put("kind", kind)
                    put("externalId", externalId)
                    put("ts", System.currentTimeMillis())
                }.toString() + "\n"
                queue.appendText(line)
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to enqueue pending wear action", t)
            }

            val intent = Intent(context, WearRemoteSyncService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to start WearRemoteSyncService", t)
            }
        }
    }
}
