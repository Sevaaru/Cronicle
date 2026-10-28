package com.cronicle.app.cronicle.widget

import android.content.Context
import android.content.Intent
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
        return LibraryRemoteViewsFactory(applicationContext, useCardLayout)
    }

    companion object {
        /** Cuando es true se usa widget_library_card (para el StackView 2x2). */
        const val EXTRA_CARD_LAYOUT = "useCardLayout"
    }
}

private class LibraryRemoteViewsFactory(
    private val context: Context,
    private val useCardLayout: Boolean = false,
) : RemoteViewsService.RemoteViewsFactory {

    private var rows: List<Map<String, Any?>> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
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
            buildCardView(kind, title, externalId, posterUrl, current, total)
        } else {
            buildListItemView(kind, title, externalId, posterUrl, current, total)
        }
    }

    /** Layout de tarjeta para el StackView del widget 2x2. */
    private fun buildCardView(
        kind: Int,
        title: String,
        externalId: String,
        posterUrl: String?,
        current: Int,
        total: Int?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library_card)

        views.setTextViewText(R.id.widget_card_kind, LibraryProgress.kindLabel(kind))
        views.setTextViewText(R.id.widget_card_title, title.ifEmpty { "—" })
        views.setTextViewText(
            R.id.widget_card_progress,
            LibraryProgress.label(kind, current, total),
        )

        val poster = LibraryPosterCache.load(posterUrl, 360, 360)
        if (poster != null) {
            views.setImageViewBitmap(R.id.widget_card_poster, poster)
        } else {
            views.setImageViewResource(R.id.widget_card_poster, R.drawable.widget_poster_placeholder)
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

        val incrementExtras = Intent().apply {
            putExtra(LibraryWidgetProvider.EXTRA_OP, LibraryWidgetProvider.OP_INCREMENT)
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        views.setOnClickFillInIntent(R.id.widget_card_plus, incrementExtras)

        return views
    }

    /** Layout de fila para la ListView del widget mediano/grande. */
    private fun buildListItemView(
        kind: Int,
        title: String,
        externalId: String,
        posterUrl: String?,
        current: Int,
        total: Int?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library_item)

        views.setTextViewText(R.id.widget_item_kind, LibraryProgress.kindLabel(kind))
        views.setTextViewText(R.id.widget_item_title, title.ifEmpty { "—" })
        views.setTextViewText(
            R.id.widget_item_progress_text,
            LibraryProgress.label(kind, current, total),
        )
        views.setProgressBar(
            R.id.widget_item_progress, 100,
            LibraryProgress.percent(current, total), false,
        )

        // Portada (descarga + caché en proceso).
        val poster = LibraryPosterCache.load(posterUrl, 144, 192)
        if (poster != null) {
            views.setImageViewBitmap(R.id.widget_item_poster, poster)
        } else {
            views.setImageViewResource(R.id.widget_item_poster, R.drawable.widget_poster_placeholder)
        }

        // FillInIntents: el provider distingue la operación por EXTRA_OP.
        val openExtras = Intent().apply {
            putExtra(LibraryWidgetProvider.EXTRA_OP, LibraryWidgetProvider.OP_OPEN)
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        views.setOnClickFillInIntent(R.id.widget_item_poster, openExtras)
        views.setOnClickFillInIntent(R.id.widget_item_title, openExtras)
        views.setOnClickFillInIntent(R.id.widget_item_progress_text, openExtras)
        views.setOnClickFillInIntent(R.id.widget_item_kind, openExtras)

        val incrementExtras = Intent().apply {
            putExtra(LibraryWidgetProvider.EXTRA_OP, LibraryWidgetProvider.OP_INCREMENT)
            putExtra(LibraryWidgetProvider.EXTRA_KIND, kind)
            putExtra(LibraryWidgetProvider.EXTRA_EXTERNAL_ID, externalId)
        }
        views.setOnClickFillInIntent(R.id.widget_item_plus, incrementExtras)

        return views
    }

    override fun getLoadingView(): RemoteViews = buildLoadingView()

    private fun buildLoadingView(): RemoteViews =
        if (useCardLayout) {
            RemoteViews(context.packageName, R.layout.widget_library_card).apply {
                setTextViewText(R.id.widget_card_kind, "—")
                setTextViewText(R.id.widget_card_title, "…")
                setTextViewText(R.id.widget_card_progress, "")
            }
        } else {
            RemoteViews(context.packageName, R.layout.widget_library_item).apply {
                setTextViewText(R.id.widget_item_kind, "—")
                setTextViewText(R.id.widget_item_title, "…")
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

    companion object {
        private const val TAG = "LibraryWidgetSvc"
    }
}
