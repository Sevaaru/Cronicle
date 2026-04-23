package com.cronicle.app.cronicle.widget

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

    fun label(kind: Int, current: Int, total: Int?): String {
        val unit = unitFor(kind)
        return if (total != null && total > 0) {
            "$current / $total $unit"
        } else if (current > 0) {
            "$current $unit"
        } else {
            unit.replaceFirstChar { it.titlecase() }
        }
    }

    private fun unitFor(kind: Int): String = when (kind) {
        KIND_ANIME, KIND_TV -> "ep"
        KIND_MOVIE -> "min"
        KIND_GAME -> "h"
        KIND_MANGA -> "ch"
        KIND_BOOK -> "pg"
        else -> ""
    }

    fun kindLabel(kind: Int): String = when (kind) {
        KIND_ANIME -> "ANI"
        KIND_MOVIE -> "MOV"
        KIND_TV -> "TV"
        KIND_GAME -> "GME"
        KIND_MANGA -> "MNG"
        KIND_BOOK -> "BK"
        else -> "—"
    }
}
