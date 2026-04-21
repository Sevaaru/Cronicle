package com.cronicle.app.cronicle.wear

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.cronicle.app.cronicle.wear.model.LibraryItem
import com.cronicle.app.cronicle.wear.sync.LibraryUpdateBus
import com.cronicle.app.cronicle.wear.sync.PhoneSyncClient
import com.cronicle.app.cronicle.wear.sync.WearProtocol
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LibraryUiState(
    val loading: Boolean = true,
    val items: List<LibraryItem> = emptyList(),
    val error: String? = null,
    val syncing: Boolean = false,
)

/**
 * Single ViewModel that owns the in-progress list shown by the watch. Listens to
 * [LibraryUpdateBus] so a snapshot push from the phone instantly refreshes the UI.
 */
class LibraryViewModel(app: Application) : AndroidViewModel(app) {
    private val client = PhoneSyncClient(app)
    private val _state = MutableStateFlow(LibraryUiState())
    val state: StateFlow<LibraryUiState> = _state.asStateFlow()

    private var refreshJob: Job? = null

    init {
        observePushes()
        refresh(initial = true)
    }

    private fun observePushes() {
        viewModelScope.launch {
            LibraryUpdateBus.updates.collect {
                reloadFromCache()
            }
        }
    }

    fun refresh(initial: Boolean = false) {
        // Don't cancel an in-flight sync just because the activity resumed; let it finish.
        if (refreshJob?.isActive == true) return
        refreshJob = viewModelScope.launch {
            _state.update { it.copy(syncing = true, error = null, loading = initial) }
            val cached = client.loadCachedSnapshot()
            _state.update { it.copy(items = cached, loading = false) }
            val ok = client.requestSync()
            _state.update {
                it.copy(
                    syncing = false,
                    error = if (!ok && cached.isEmpty()) "no_phone" else null,
                )
            }
        }
    }

    private suspend fun reloadFromCache() {
        val cached = client.loadCachedSnapshot()
        _state.update { it.copy(items = cached, loading = false, syncing = false) }
    }

    fun increment(item: LibraryItem) {
        viewModelScope.launch {
            applyOptimistic(item) { it.copy(progress = (it.progress ?: 0) + 1) }
            client.sendAction(item, WearProtocol.ACTION_INCREMENT)
        }
    }

    fun complete(item: LibraryItem) {
        viewModelScope.launch {
            // Optimistically remove from the in-progress list — the next snapshot push
            // confirms the change.
            _state.update { s ->
                s.copy(items = s.items.filterNot { it.kind == item.kind && it.externalId == item.externalId })
            }
            client.sendAction(item, WearProtocol.ACTION_COMPLETE)
        }
    }

    private fun applyOptimistic(item: LibraryItem, transform: (LibraryItem) -> LibraryItem) {
        _state.update { s ->
            val updated = s.items.map {
                if (it.kind == item.kind && it.externalId == item.externalId) transform(it) else it
            }
            s.copy(items = updated)
        }
    }

    class Factory(private val app: Application) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            LibraryViewModel(app) as T
    }
}
