package com.cronicle.app.cronicle.wear.sync

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class WearLibraryListener : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)
        var anyRelevant = false
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            if (event.dataItem.uri.path?.startsWith("/library/") == true) {
                anyRelevant = true
            }
        }
        if (anyRelevant) {
            Log.d(TAG, "Library snapshot updated; broadcasting refresh")
            LibraryUpdateBus.notifyUpdated()
        }
    }

    companion object { private const val TAG = "WearLibraryListener" }
}

object LibraryUpdateBus {
    private val _updates = MutableSharedFlow<Long>(replay = 0, extraBufferCapacity = 4)
    val updates = _updates.asSharedFlow()

    fun notifyUpdated() {
        _updates.tryEmit(System.currentTimeMillis())
    }

    @Suppress("unused")
    fun init(@Suppress("UNUSED_PARAMETER") context: Context) {
    }
}
