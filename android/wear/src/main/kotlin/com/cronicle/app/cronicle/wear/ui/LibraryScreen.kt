package com.cronicle.app.cronicle.wear.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.Card
import androidx.wear.compose.material.CircularProgressIndicator
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import androidx.wear.compose.material.Vignette
import androidx.wear.compose.material.VignettePosition
import com.cronicle.app.cronicle.wear.LibraryUiState
import com.cronicle.app.cronicle.wear.model.LibraryItem
import com.cronicle.app.cronicle.wear.model.MediaKind

@Composable
fun LibraryScreen(
    state: LibraryUiState,
    onRefresh: () -> Unit,
    onItemClick: (LibraryItem) -> Unit,
    onIncrement: (LibraryItem) -> Unit,
) {
    val listState = rememberScalingLazyListState()
    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) },
    ) {
        when {
            state.loading && state.items.isEmpty() -> CenterMessage {
                CircularProgressIndicator(modifier = Modifier.size(28.dp))
            }
            state.items.isEmpty() && state.error == "no_phone" -> CenterMessage {
                Text(
                    text = "Empareja con tu teléfono y abre Cronicle al menos una vez.",
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.body2,
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
                Spacer(Modifier.height(8.dp))
                RefreshChip(syncing = state.syncing, onClick = onRefresh)
            }
            state.items.isEmpty() -> CenterMessage {
                Text(
                    text = "Nada en curso",
                    style = MaterialTheme.typography.title3,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "Añade algo desde tu teléfono",
                    style = MaterialTheme.typography.caption2,
                    color = MaterialTheme.colors.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 18.dp),
                )
                Spacer(Modifier.height(10.dp))
                RefreshChip(syncing = state.syncing, onClick = onRefresh)
            }
            else -> ScalingLazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    top = 28.dp, bottom = 36.dp, start = 8.dp, end = 8.dp,
                ),
            ) {
                items(state.items, key = { "${it.kind}:${it.externalId}" }) { item ->
                    LibraryItemCard(
                        item = item,
                        onClick = { onItemClick(item) },
                        onIncrement = { onIncrement(item) },
                    )
                }
                item {
                    Spacer(Modifier.height(4.dp))
                    RefreshChip(syncing = state.syncing, onClick = onRefresh)
                }
            }
        }
    }
}

@Composable
private fun LibraryItemCard(
    item: LibraryItem,
    onClick: () -> Unit,
    onIncrement: () -> Unit,
) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
    ) {
        Column(modifier = Modifier.padding(horizontal = 6.dp, vertical = 4.dp)) {
            Text(
                text = item.title,
                style = MaterialTheme.typography.button,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(2.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(
                    text = remember(item) { progressLabel(item) },
                    style = MaterialTheme.typography.caption2,
                    color = MaterialTheme.colors.onSurfaceVariant,
                )
                if (item.supportsIncrement && !item.isAtCap) {
                    Button(
                        onClick = onIncrement,
                        modifier = Modifier.size(32.dp),
                        colors = ButtonDefaults.primaryButtonColors(),
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Add,
                            contentDescription = "+1",
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RefreshChip(syncing: Boolean, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.size(36.dp),
        colors = ButtonDefaults.secondaryButtonColors(),
        enabled = !syncing,
    ) {
        if (syncing) {
            CircularProgressIndicator(
                modifier = Modifier.size(18.dp),
                indicatorColor = MaterialTheme.colors.onSecondary,
                strokeWidth = 2.dp,
            )
        } else {
            Icon(
                imageVector = Icons.Filled.Refresh,
                contentDescription = "Sincronizar",
                modifier = Modifier.size(16.dp),
            )
        }
    }
}

@Composable
private fun CenterMessage(content: @Composable () -> Unit) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) { content() }
    }
}

internal fun progressLabel(item: LibraryItem): String {
    val kind = MediaKind.label(item.kind)
    val total = item.effectiveTotal?.toString() ?: "?"
    return "$kind  ·  ${item.effectiveProgress} / $total"
}
