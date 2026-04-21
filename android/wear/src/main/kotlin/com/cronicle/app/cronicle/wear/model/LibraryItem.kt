package com.cronicle.app.cronicle.wear.model

/**
 * Wear-side mirror of the phone's `LibraryEntry` row, restricted to the fields needed by
 * the watch UI. Identity is the natural key `(kind, externalId)`.
 *
 * The phone publishes one [LibraryItem] per row whose `status == "CURRENT"` to the
 * Wearable Data Layer at path `/library/items`.
 */
data class LibraryItem(
    val id: Long,            // phone-side primary key (used as a fast lookup hint)
    val kind: Int,           // MediaKind.code: 0=anime,1=movie,2=tv,3=game,4=manga,5=book
    val externalId: String,
    val title: String,
    val posterUrl: String?,
    val status: String,      // always "CURRENT" in the in-progress feed
    val progress: Int?,      // episodes watched / pages read / generic counter
    val totalEpisodes: Int?, // for anime/tv: total episodes; for books-pages: total pages
    val releasedEpisodes: Int?, // anime cap (already-aired)
    val currentChapter: Int?,   // books (chapters mode)
    val totalPages: Int?,       // books (pages mode, effective)
    val totalChapters: Int?,    // books (chapters mode, effective)
    val bookTrackingMode: String?, // "pages" | "percentage" | "chapters"
    val updatedAt: Long,
) {
    /** Effective progress shown by the +1 button. */
    val effectiveProgress: Int
        get() = when (kind) {
            MediaKind.BOOK -> when (bookTrackingMode) {
                "chapters" -> currentChapter ?: 0
                "percentage" -> progress ?: 0
                else -> progress ?: 0 // pages
            }
            else -> progress ?: 0
        }

    /** Effective total. `null` means unknown / unbounded. */
    val effectiveTotal: Int?
        get() = when (kind) {
            MediaKind.BOOK -> when (bookTrackingMode) {
                "chapters" -> totalChapters
                "percentage" -> 100
                else -> totalPages ?: totalEpisodes
            }
            MediaKind.ANIME -> {
                val total = totalEpisodes
                val released = releasedEpisodes
                if (total != null && released != null) minOf(total, released)
                else total ?: released
            }
            else -> totalEpisodes
        }

    /** True if [effectiveProgress] has reached [effectiveTotal] (so +1 should be disabled). */
    val isAtCap: Boolean
        get() {
            val total = effectiveTotal ?: return false
            return effectiveProgress >= total
        }

    /**
     * Media types whose +1 affordance makes sense (chaptered/episodic). Movies and games
     * use the "Complete" action exclusively.
     */
    val supportsIncrement: Boolean
        get() = when (kind) {
            MediaKind.ANIME, MediaKind.TV, MediaKind.MANGA, MediaKind.BOOK -> true
            else -> false
        }
}

object MediaKind {
    const val ANIME = 0
    const val MOVIE = 1
    const val TV = 2
    const val GAME = 3
    const val MANGA = 4
    const val BOOK = 5

    fun label(kind: Int): String = when (kind) {
        ANIME -> "Anime"
        MOVIE -> "Película"
        TV -> "Serie"
        GAME -> "Juego"
        MANGA -> "Manga"
        BOOK -> "Libro"
        else -> "?"
    }
}
