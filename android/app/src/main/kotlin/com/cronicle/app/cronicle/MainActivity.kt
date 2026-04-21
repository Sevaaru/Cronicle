package com.cronicle.app.cronicle

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var wearChannel: MethodChannel? = null
    private var wearStatusChannel: MethodChannel? = null
    private var wearReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wearChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_WEAR_EVENTS,
        )

        wearStatusChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_WEAR_STATUS,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStatus" -> {
                        Thread {
                            val status = queryWearStatus()
                            runOnUiThread { result.success(status) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
        }

        wearReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != ACTION_LIBRARY_CHANGED) return
                wearChannel?.invokeMethod("libraryChanged", null)
            }
        }
        val filter = IntentFilter(ACTION_LIBRARY_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(wearReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(wearReceiver, filter)
        }
    }

    private fun queryWearStatus(): Map<String, Any> {
        var anyNodeConnected = false
        var companionInstalled = false
        try {
            val nodes = Tasks.await(Wearable.getNodeClient(applicationContext).connectedNodes)
            anyNodeConnected = nodes.isNotEmpty()
        } catch (_: Throwable) {}
        try {
            val info = Tasks.await(
                Wearable.getCapabilityClient(applicationContext)
                    .getCapability(WEAR_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
            )
            companionInstalled = info.nodes.isNotEmpty()
        } catch (_: Throwable) {}
        return mapOf(
            "anyNodeConnected" to anyNodeConnected,
            "companionInstalled" to companionInstalled,
        )
    }

    override fun onDestroy() {
        wearReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Throwable) {}
        }
        wearReceiver = null
        wearChannel = null
        wearStatusChannel?.setMethodCallHandler(null)
        wearStatusChannel = null
        super.onDestroy()
    }

    companion object {
        const val CHANNEL_WEAR_EVENTS = "cronicle.wear.events"
        const val CHANNEL_WEAR_STATUS = "cronicle.wear.status"
        const val ACTION_LIBRARY_CHANGED = "com.cronicle.app.cronicle.WEAR_LIBRARY_CHANGED"
        private const val WEAR_CAPABILITY = "cronicle_wear_companion"
    }
}
