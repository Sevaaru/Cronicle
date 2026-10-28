package com.cronicle.app.cronicle.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import androidx.wear.compose.material.Vignette
import androidx.wear.compose.material.VignettePosition
import androidx.wear.compose.material.dialog.Alert
import androidx.wear.compose.material.dialog.Dialog
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.cronicle.app.cronicle.wear.model.LibraryItem
import com.cronicle.app.cronicle.wear.model.MediaKind

@Composable
fun DetailScreen(
    item: LibraryItem?,
    onIncrement: (LibraryItem?) -> Unit,
    onComplete: (LibraryItem?) -> Unit,
    onBack: () -> Unit,
) {
    val listState = rememberScalingLazyListState()
    var confirmComplete by remember { mutableStateOf(false) }

    Scaffold(
        timeText = { TimeText() },
        vignette = { Vignette(vignettePosition = VignettePosition.TopAndBottom) },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) },
    ) {
        if (item == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("?", style = MaterialTheme.typography.title2)
            }
            return@Scaffold
        }

        Box(modifier = Modifier.fillMaxSize()) {
            val poster = item.posterUrl
            if (!poster.isNullOrBlank()) {
                AsyncImage(
                    model = ImageRequest.Builder(LocalContext.current)
                        .data(poster)
                        .crossfade(true)
                        .build(),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxSize()
                        .blur(6.dp),
                )
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Black.copy(alpha = 0.30f),
                                    Color.Black.copy(alpha = 0.50f),
                                    Color.Black.copy(alpha = 0.70f),
                                ),
                            ),
                        ),
                )
            }

            ScalingLazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    top = 28.dp, bottom = 36.dp, start = 12.dp, end = 12.dp,
                ),
            ) {
                item {
                    Text(
                        text = MediaKind.label(item.kind),
                        style = MaterialTheme.typography.caption1,
                        color = MaterialTheme.colors.primary,
                    )
                }
                item {
                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.title3,
                        fontWeight = FontWeight.SemiBold,
                        textAlign = TextAlign.Center,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }
                item {
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = progressLabel(item),
                        style = MaterialTheme.typography.body2,
                    )
                }
                item {
                    Spacer(Modifier.height(10.dp))
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        if (item.supportsIncrement) {
                            Button(
                                onClick = { onIncrement(item) },
                                enabled = !item.isAtCap,
                                modifier = Modifier.size(54.dp),
                                colors = ButtonDefaults.primaryButtonColors(),
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Add,
                                    contentDescription = "+1",
                                    modifier = Modifier.size(26.dp),
                                )
                            }
                            Text("+1", style = MaterialTheme.typography.caption2)
                        }
                        Spacer(Modifier.height(4.dp))
                        Button(
                            onClick = { confirmComplete = true },
                            modifier = Modifier.size(48.dp),
                            colors = ButtonDefaults.secondaryButtonColors(),
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Check,
                                contentDescription = "Completar",
                                modifier = Modifier.size(22.dp),
                            )
                        }
                        Text("Completar", style = MaterialTheme.typography.caption2)
                    }
                }
            }
        }
    }

    if (confirmComplete && item != null) {
        Dialog(
            showDialog = true,
            onDismissRequest = { confirmComplete = false },
        ) {
            Alert(
                title = { Text("¿Marcar como completado?", textAlign = TextAlign.Center) },
                negativeButton = {
                    Button(
                        onClick = { confirmComplete = false },
                        colors = ButtonDefaults.secondaryButtonColors(),
                    ) { Text("No") }
                },
                positiveButton = {
                    Button(
                        onClick = {
                            confirmComplete = false
                            onComplete(item)
                            onBack()
                        },
                        colors = ButtonDefaults.primaryButtonColors(),
                    ) { Text("Sí") }
                },
            ) { Text(item.title, textAlign = TextAlign.Center) }
        }
    }
}
