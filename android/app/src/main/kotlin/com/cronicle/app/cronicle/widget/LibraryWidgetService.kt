package com.cronicle.app.cronicle.widget

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.cronicle.app.cronicle.R
import com.cronicle.app.cronicle.wear.CronicleLibraryDb

/**
 * RemoteViewsService que alimenta la ListView del layout mediano/grande
 * con las entradas en progreso de la base de datos Drift.
 */
class LibraryWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val useCardLayout = intent.getBooleanExtra(EXTRA_CARD_LAYOUT, false)
        val theme = WidgetTheme.fromKey(intent.getStringExtra(EXTRA_THEME))
        return LibraryRemoteViewsFactory(applicationContext, useCardLayout, theme)
    }

    companion object {
        /** Cuando es true se usa widget_library_card (para el StackView 2x2). */
        const val EXTRA_CARD_LAYOUT = "useCardLayout"
        const val EXTRA_THEME = "widgetTheme"
    }
}

private class LibraryRemoteViewsFactory(
    private val context: Context,
    private val useCardLayout: Boolean = false,
    private val theme: WidgetTheme = WidgetTheme.DARK,
) : RemoteViewsService.RemoteViewsFactory {

    private var rows: List<Map<String, Any?>> = emptyList()

    /** Context localized to the app language (see [WidgetLocale]). */
    private var strings: Context = context

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        strings = WidgetLocale.wrap(context)
        rows = try {
            val db = CronicleLibraryDb.openOrNull(context)
            if (db == null) emptyList() else try {
                db.queryInProgress()
            } finally {
                db.close()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "queryInProgress failed", t)
            emptyList()
        }
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val row = rows.getOrNull(position) ?: return buildLoadingView()

        val kind = (row["kind"] as? Number)?.toInt() ?: 0
        val title = (row["title"] as? String).orEmpty()
        val externalId = (row["externalId"] as? String).orEmpty()
        val posterUrl = row["posterUrl"] as? String

        val (current, total) = LibraryProgress.compute(row, kind)

        return if (useCardLayout) {
            buildCardView(position, kind, title, externalId, posterUrl, current, total)
        } else {
            buildListItemView(position, kind, title, externalId, posterUrl, current, total)
        }
    }

    private fun signalIndex(n: Int): String = n.toString().padStart(2, '0')

    /** Layout de tarjeta para el pase de diapositivas del widget 2x2. */
    private fun buildCardView(
        position: Int,
        kind: Int,
        title: String,
        externalId: String,
        posterUrl: String?,
        current: Int,
        total: Int?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library_card)
        val accent = LibraryProgress.kindAccent(kind)

        applyCardTheme(views)
        views.setTextColor(R.id.widget_card_title, theme.text(context))
        views.setTextColor(R.id.widget_card_progress, theme.textDim(context))

        views.setTextViewText(
            R.id.widget_card_index,
            "${signalIndex(position + 1)} / ${signalIndex(rows.size)}",
        )
        views.setTextViewText(R.id.widget_card_kind, LibraryProgress.kindLabel(strings, kind))
        views.setTextColor(R.id.widget_card_kind, accent)
        views.setInt(R.id.widget_card_accent, "setColorFilter", accent)
        views.setTextViewText(R.id.widget_card_title, title.ifEmpty { "—" })
        views.setTextViewText(
            R.id.widget_card_progress,
            LibraryProgress.label(strings, kind, current, total),
        )

        val poster = LibraryPosterCache.load(context, posterUrl, 360, 360)
        if (poster != null) {
            views.setImageViewBitmap(R.id.widget_card_poster, poster)
        } else {
            views.setImageViewResource(R.id.widget_card_poster, R.drawable.widget_signal_poster_placeholder)
        }

        val openExtras = Intent().apply {
            putExtra(LibraryWidgetProvider.EXTRA_OP, LibraryWidgetProvider.OP_OPEN)
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        views.setOnClickFillInIntent(R.id.widget_card_poster, openExtras)
        views.setOnClickFillInIntent(R.id.widget_card_title, openExtras)
        views.setOnClickFillInIntent(R.id.widget_card_progress, openExtras)
        views.setOnClickFillInIntent(R.id.widget_card_kind, openExtras)

        bindProgressAction(views, R.id.widget_card_plus, kind, externalId)

        return views
    }

    /** Layout de fila para la ListView del widget mediano/grande. */
    private fun buildListItemView(
        position: Int,
        kind: Int,
        title: String,
        externalId: String,
        posterUrl: String?,
        current: Int,
        total: Int?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library_item)
        val accent = LibraryProgress.kindAccent(kind)

        applyItemTheme(views)

        views.setTextViewText(R.id.widget_item_index, signalIndex(position + 1))
        views.setTextViewText(R.id.widget_item_kind, LibraryProgress.kindLabel(strings, kind))
        views.setTextColor(R.id.widget_item_kind, accent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorStateList(
                R.id.widget_item_progress,
                "setProgressTintList",
                ColorStateList.valueOf(accent),
            )
        }
        views.setTextViewText(R.id.widget_item_title, title.ifEmpty { "—" })
        views.setTextViewText(
            R.id.widget_item_progress_text,
            LibraryProgress.label(strings, kind, current, total),
        )
        views.setProgressBar(
            R.id.widget_item_progress, 100,
            LibraryProgress.percent(current, total), false,
        )

        // Portada (descarga + caché en proceso).
        val poster = LibraryPosterCache.load(context, posterUrl, 200, 280)
        if (poster != null) {
            views.setImageViewBitmap(R.id.widget_item_poster, poster)
        } else {
            views.setImageViewResource(R.id.widget_item_poster, R.drawable.widget_signal_poster_placeholder)
        }

        // FillInIntents: el provider distingue la operación por EXTRA_OP.
        val openExtras = Intent().apply {
            putExtra(LibraryWidgetProvider.EXTRA_OP, LibraryWidgetProvider.OP_OPEN)
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        // Whole row opens the entry, so its ripple background shows the tap.
        views.setOnClickFillInIntent(R.id.widget_item_card, openExtras)

        bindProgressAction(views, R.id.widget_item_plus, kind, externalId)

        return views
    }

    /** Row plate plus the corner/slant overlays, which must match the theme colours. */
    private fun applyItemTheme(views: RemoteViews) {
        val surface = theme.surface(context)
        val page = theme.page(context)
        views.setInt(R.id.widget_item_card, "setBackgroundResource", theme.itemBackground)
        views.setInt(R.id.widget_item_poster_slant, "setColorFilter", surface)
        views.setInt(R.id.widget_item_action_slant, "setColorFilter", surface)
        for (id in ITEM_CORNERS) views.setInt(id, "setColorFilter", page)
        views.setTextColor(R.id.widget_item_title, theme.text(context))
        views.setTextColor(R.id.widget_item_progress_text, theme.textDim(context))
    }

    /**
     * Games have no episode count: the button finishes them instead of adding
     * hours. Icon and description are always set because the host recycles
     * row views, so a game's tick would otherwise stay on other kinds.
     */
    private fun bindProgressAction(
        views: RemoteViews,
        buttonId: Int,
        kind: Int,
        externalId: String,
    ) {
        val completes = kind == LibraryProgress.KIND_GAME
        views.setImageViewResource(
            buttonId,
            if (completes) R.drawable.widget_ic_check else R.drawable.widget_ic_plus,
        )
        views.setContentDescription(
            buttonId,
            strings.getString(
                if (completes) R.string.widget_library_complete else R.string.widget_library_increment,
            ),
        )
        val extras = Intent().apply {
            putExtra(
                LibraryWidgetProvider.EXTRA_OP,
                if (completes) {
                    LibraryWidgetProvider.OP_COMPLETE
                } else {
                    LibraryWidgetProvider.OP_INCREMENT
                },
            )
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        views.setOnClickFillInIntent(buttonId, extras)
    }

    override fun getLoadingView(): RemoteViews = buildLoadingView()

    private fun buildLoadingView(): RemoteViews =
        if (useCardLayout) {
            RemoteViews(context.packageName, R.layout.widget_library_card).apply {
                applyCardTheme(this)
                setTextViewText(R.id.widget_card_index, "—")
                setTextViewText(R.id.widget_card_kind, "—")
                setTextViewText(R.id.widget_card_title, "…")
                setTextViewText(R.id.widget_card_progress, "")
            }
        } else {
            RemoteViews(context.packageName, R.layout.widget_library_item).apply {
                applyItemTheme(this)
                setImageViewResource(R.id.widget_item_poster, R.drawable.widget_signal_poster_placeholder)
                setTextViewText(R.id.widget_item_index, "")
                setTextViewText(R.id.widget_item_kind, "—")
                setTextViewText(R.id.widget_item_title, "")
                setTextViewText(R.id.widget_item_progress_text, "")
                setProgressBar(R.id.widget_item_progress, 100, 0, false)
            }
        }

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long {
        val id = rows.getOrNull(position)?.get("id")
        return (id as? Number)?.toLong() ?: position.toLong()
    }

    override fun hasStableIds(): Boolean = true

    private fun applyCardTheme(views: RemoteViews) {
        views.setInt(R.id.widget_card_root, "setBackgroundResource", theme.background)
        views.setImageViewResource(R.id.widget_card_scrim, theme.scrim)
        val page = theme.page(context)
        for (id in CARD_CORNERS) views.setInt(id, "setColorFilter", page)
    }

    companion object {
        private const val TAG = "LibraryWidgetSvc"

        private val ITEM_CORNERS = intArrayOf(
            R.id.widget_item_round_top_start,
            R.id.widget_item_round_bottom_start,
            R.id.widget_item_round_top_end,
            R.id.widget_item_round_bottom_end,
        )
        private val CARD_CORNERS = intArrayOf(
            R.id.widget_card_round_top_start,
            R.id.widget_card_round_top_end,
            R.id.widget_card_round_bottom_start,
            R.id.widget_card_round_bottom_end,
        )
    }
}
