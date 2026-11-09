package com.cronicle.app.cronicle.widget

import android.content.Context
import com.cronicle.app.cronicle.R
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Cálculos compartidos de progreso / etiquetas usados tanto por el layout
 * pequeño (renderizado directo desde el provider) como por las filas del
 * layout mediano/grande (renderizado desde [LibraryWidgetService]).
 */
internal object LibraryProgress {
    const val KIND_ANIME = 0
    const val KIND_MOVIE = 1
    const val KIND_TV = 2
    const val KIND_GAME = 3
    const val KIND_MANGA = 4
    const val KIND_BOOK = 5

    fun compute(row: Map<String, Any?>, kind: Int): Pair<Int, Int?> {
        val progress = (row["progress"] as? Number)?.toInt() ?: 0
        val totalEpisodes = (row["totalEpisodes"] as? Number)?.toInt()
        val releasedEpisodes = (row["releasedEpisodes"] as? Number)?.toInt()
        val currentChapter = (row["currentChapter"] as? Number)?.toInt()
        val totalPages = (row["totalPages"] as? Number)?.toInt()
        val totalChapters = (row["totalChapters"] as? Number)?.toInt()
        val mode = row["bookTrackingMode"] as? String

        return when (kind) {
            KIND_BOOK -> when (mode) {
                "chapters" -> (currentChapter ?: 0) to totalChapters
                "percentage" -> progress to 100
                else -> progress to totalPages
            }
            KIND_MOVIE -> {
                val total = if (totalEpisodes != null && totalEpisodes > 0) totalEpisodes else 1
                progress to total
            }
            KIND_ANIME, KIND_TV -> {
                val cap = when {
                    totalEpisodes != null && releasedEpisodes != null ->
                        min(totalEpisodes, releasedEpisodes)
                    totalEpisodes != null -> totalEpisodes
                    releasedEpisodes != null -> releasedEpisodes
                    else -> null
                }
                progress to cap
            }
            else -> progress to totalEpisodes
        }
    }

    fun percent(current: Int, total: Int?): Int {
        return if (total != null && total > 0) {
            ((current.coerceAtLeast(0).toDouble() / total.toDouble()) * 100.0)
                .coerceIn(0.0, 100.0)
                .roundToInt()
        } else if (current > 0) {
            min(100, max(8, current))
        } else {
            0
        }
    }

    /** [context] must be localized with [WidgetLocale.wrap]. */
    fun label(context: Context, kind: Int, current: Int, total: Int?): String {
        val unit = unitFor(context, kind)
        return if (total != null && total > 0) {
            "$current / $total $unit"
        } else if (current > 0) {
            "$current $unit"
        } else {
            unit.replaceFirstChar { it.titlecase() }
        }
    }

    private fun unitFor(context: Context, kind: Int): String = when (kind) {
        KIND_ANIME, KIND_TV -> context.getString(R.string.widget_unit_episode)
        KIND_MOVIE -> context.getString(R.string.widget_unit_minute)
        KIND_GAME -> context.getString(R.string.widget_unit_hour)
        KIND_MANGA -> context.getString(R.string.widget_unit_chapter)
        KIND_BOOK -> context.getString(R.string.widget_unit_page)
        else -> ""
    }

    /** Same accents as `entryKindAccent` in the Flutter app. */
    fun kindAccent(kind: Int): Int = when (kind) {
        KIND_ANIME -> 0xFF7C4DFF
        KIND_MANGA -> 0xFFEC407A
        KIND_MOVIE -> 0xFFFF7043
        KIND_TV -> 0xFF26A69A
        KIND_GAME -> 0xFF42A5F5
        KIND_BOOK -> 0xFFAB47BC
        else -> 0xFFFF3B1F
    }.toInt()

    fun kindLabel(context: Context, kind: Int): String = when (kind) {
        KIND_ANIME -> context.getString(R.string.widget_kind_anime)
        KIND_MOVIE -> context.getString(R.string.widget_kind_movie)
        KIND_TV -> context.getString(R.string.widget_kind_tv)
        KIND_GAME -> context.getString(R.string.widget_kind_game)
        KIND_MANGA -> context.getString(R.string.widget_kind_manga)
        KIND_BOOK -> context.getString(R.string.widget_kind_book)
        else -> "—"
    }
}