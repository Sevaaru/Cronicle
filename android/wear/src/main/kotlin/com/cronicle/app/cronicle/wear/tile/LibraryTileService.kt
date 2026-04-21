package com.cronicle.app.cronicle.wear.tile

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.FONT_WEIGHT_BOLD
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.cronicle.app.cronicle.wear.MainActivity
import com.cronicle.app.cronicle.wear.sync.PhoneSyncClient
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.SettableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Quick-glance tile shown on the watch face. Displays the count of in-progress items
 * cached on the watch and tapping launches [MainActivity].
 */
class LibraryTileService : TileService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val future: SettableFuture<TileBuilders.Tile> = SettableFuture.create()
        scope.launch {
            try {
                val items = PhoneSyncClient(applicationContext).loadCachedSnapshot()
                future.set(buildTile(items.size, items.firstOrNull()?.title))
            } catch (t: Throwable) {
                future.set(buildTile(0, null))
            }
        }
        return future
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = Futures.immediateFuture(
        ResourceBuilders.Resources.Builder()
            .setVersion(RESOURCES_VERSION)
            .build()
    )

    private fun buildTile(count: Int, firstTitle: String?): TileBuilders.Tile {
        val launchAction = ActionBuilders.LaunchAction.Builder()
            .setAndroidActivity(
                ActionBuilders.AndroidActivity.Builder()
                    .setPackageName(applicationContext.packageName)
                    .setClassName(MainActivity::class.java.name)
                    .build()
            )
            .build()

        val clickable = ModifiersBuilders.Clickable.Builder()
            .setId("open_app")
            .setOnClick(launchAction)
            .build()

        val countText = LayoutElementBuilders.Text.Builder()
            .setText("$count")
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(40f))
                    .setWeight(FONT_WEIGHT_BOLD)
                    .setColor(argb(0xFF7DD3FCu.toInt()))
                    .build()
            )
            .build()

        val subtitle = LayoutElementBuilders.Text.Builder()
            .setText("en curso")
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(12f))
                    .setColor(argb(0xFFE5E7EBu.toInt()))
                    .build()
            )
            .build()

        val firstLine = LayoutElementBuilders.Text.Builder()
            .setText(firstTitle?.take(40) ?: "Toca para abrir")
            .setMaxLines(1)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(11f))
                    .setColor(argb(0xFFCBD5E1u.toInt()))
                    .build()
            )
            .build()

        val column = LayoutElementBuilders.Column.Builder()
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .addContent(countText)
            .addContent(subtitle)
            .addContent(LayoutElementBuilders.Spacer.Builder().setHeight(dp(6f)).build())
            .addContent(firstLine)
            .build()

        val root = LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setClickable(clickable)
                    .build()
            )
            .addContent(column)
            .build()

        val layout = LayoutElementBuilders.Layout.Builder().setRoot(root).build()
        val tileTimeline = TimelineBuilders.Timeline.Builder()
            .addTimelineEntry(
                TimelineBuilders.TimelineEntry.Builder().setLayout(layout).build()
            )
            .build()

        return TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(tileTimeline)
            .setFreshnessIntervalMillis(REFRESH_MS)
            .build()
    }

    companion object {
        private const val RESOURCES_VERSION = "1"
        private const val REFRESH_MS = 10 * 60 * 1000L
    }
}
