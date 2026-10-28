package com.cronicle.app.cronicle.wear

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.io.File

internal class CronicleLibraryDb private constructor(private val db: SQLiteDatabase) {

    fun close() = db.close()

    fun queryInProgress(): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val cursor = db.rawQuery(
            """
            SELECT id, kind, external_id, title, poster_url, status, progress,
                   total_episodes, released_episodes, current_chapter,
                   total_pages_from_api, user_total_pages_override,
                   total_chapters_from_api, user_total_chapters_override,
                   book_tracking_mode, updated_at
            FROM library_entries
            WHERE UPPER(status) = 'CURRENT'
            ORDER BY updated_at DESC, id DESC
            LIMIT 100
            """.trimIndent(),
            emptyArray(),
        )
        cursor.use { c ->
            while (c.moveToNext()) {
                val totalPages = c.intOrNull("user_total_pages_override")
                    ?: c.intOrNull("total_pages_from_api")
                val totalChapters = c.intOrNull("user_total_chapters_override")
                    ?: c.intOrNull("total_chapters_from_api")
                out.add(
                    mapOf(
                        "id" to c.getLong(c.getColumnIndexOrThrow("id")),
                        "kind" to c.getInt(c.getColumnIndexOrThrow("kind")),
                        "externalId" to c.getString(c.getColumnIndexOrThrow("external_id")),
                        "title" to c.getString(c.getColumnIndexOrThrow("title")),
                        "posterUrl" to c.stringOrNull("poster_url"),
                        "status" to c.getString(c.getColumnIndexOrThrow("status")),
                        "progress" to c.intOrNull("progress"),
                        "totalEpisodes" to c.intOrNull("total_episodes"),
                        "releasedEpisodes" to c.intOrNull("released_episodes"),
                        "currentChapter" to c.intOrNull("current_chapter"),
                        "totalPages" to totalPages,
                        "totalChapters" to totalChapters,
                        "bookTrackingMode" to c.stringOrNull("book_tracking_mode"),
                        "updatedAt" to c.getLong(c.getColumnIndexOrThrow("updated_at")),
                    )
                )
            }
        }
        return out
    }

    private fun findEntry(kind: Int, externalId: String): EntrySnapshot? {
        val cursor = db.rawQuery(
            """
            SELECT id, kind, status, progress, total_episodes, released_episodes,
                   current_chapter, total_pages_from_api, user_total_pages_override,
                   total_chapters_from_api, user_total_chapters_override,
                   book_tracking_mode
            FROM library_entries
            WHERE kind = ? AND external_id = ?
            LIMIT 1
            """.trimIndent(),
            arrayOf(kind.toString(), externalId),
        )
        cursor.use { c ->
            if (!c.moveToFirst()) return null
            return EntrySnapshot(
                id = c.getLong(c.getColumnIndexOrThrow("id")),
                kind = c.getInt(c.getColumnIndexOrThrow("kind")),
                status = c.getString(c.getColumnIndexOrThrow("status")),
                progress = c.intOrNull("progress"),
                totalEpisodes = c.intOrNull("total_episodes"),
                releasedEpisodes = c.intOrNull("released_episodes"),
                currentChapter = c.intOrNull("current_chapter"),
                totalPages = c.intOrNull("user_total_pages_override")
                    ?: c.intOrNull("total_pages_from_api"),
                totalChapters = c.intOrNull("user_total_chapters_override")
                    ?: c.intOrNull("total_chapters_from_api"),
                bookTrackingMode = c.stringOrNull("book_tracking_mode"),
            )
        }
    }

    fun incrementProgress(kind: Int, externalId: String): Boolean {
        val entry = findEntry(kind, externalId) ?: return false
        return if (entry.kind == KIND_BOOK) {
            incrementBook(entry)
        } else {
            incrementGeneric(entry)
        }
    }

    private fun incrementGeneric(entry: EntrySnapshot): Boolean {
        val current = entry.progress ?: 0
        val cap = animeCap(entry) ?: entry.totalEpisodes
        if (cap != null && current >= cap) return false
        val next = current + 1
        val seriesTotal = entry.totalEpisodes
        val newStatus = if (seriesTotal != null && next >= seriesTotal) "COMPLETED" else entry.status
        db.execSQL(
            "UPDATE library_entries SET progress = ?, status = ?, updated_at = ? WHERE id = ?",
            arrayOf<Any?>(next, newStatus, System.currentTimeMillis(), entry.id),
        )
        return true
    }

    private fun incrementBook(entry: EntrySnapshot): Boolean {
        val mode = entry.bookTrackingMode ?: "pages"
        val now = System.currentTimeMillis()
        return when (mode) {
            "chapters" -> {
                val current = entry.currentChapter ?: 0
                val total = entry.totalChapters
                if (total != null && current >= total) return false
                val next = current + 1
                val newStatus = if (total != null && next >= total) "COMPLETED" else entry.status
                db.execSQL(
                    "UPDATE library_entries SET current_chapter = ?, status = ?, updated_at = ? WHERE id = ?",
                    arrayOf<Any?>(next, newStatus, now, entry.id),
                )
                true
            }
            "percentage" -> {
                val current = entry.progress ?: 0
                if (current >= 100) return false
                val next = current + 1
                val newStatus = if (next >= 100) "COMPLETED" else entry.status
                db.execSQL(
                    "UPDATE library_entries SET progress = ?, status = ?, updated_at = ? WHERE id = ?",
                    arrayOf<Any?>(next, newStatus, now, entry.id),
                )
                true
            }
            else -> { // pages
                val current = entry.progress ?: 0
                val total = entry.totalPages ?: entry.totalEpisodes
                if (total != null && current >= total) return false
                val next = current + 1
                val newStatus = if (total != null && next >= total) "COMPLETED" else entry.status
                db.execSQL(
                    "UPDATE library_entries SET progress = ?, status = ?, updated_at = ? WHERE id = ?",
                    arrayOf<Any?>(next, newStatus, now, entry.id),
                )
                true
            }
        }
    }

    fun markCompleted(kind: Int, externalId: String): Boolean {
        val entry = findEntry(kind, externalId) ?: return false
        val now = System.currentTimeMillis()
        val progress = entry.totalEpisodes ?: entry.progress ?: 0
        db.execSQL(
            "UPDATE library_entries SET status = 'COMPLETED', progress = ?, updated_at = ? WHERE id = ?",
            arrayOf<Any?>(progress, now, entry.id),
        )
        return true
    }

    private fun animeCap(entry: EntrySnapshot): Int? {
        if (entry.kind != KIND_ANIME) return null
        val total = entry.totalEpisodes
        val released = entry.releasedEpisodes
        return when {
            total != null && released != null -> minOf(total, released)
            total != null -> total
            released != null -> released
            else -> null
        }
    }

    private data class EntrySnapshot(
        val id: Long,
        val kind: Int,
        val status: String,
        val progress: Int?,
        val totalEpisodes: Int?,
        val releasedEpisodes: Int?,
        val currentChapter: Int?,
        val totalPages: Int?,
        val totalChapters: Int?,
        val bookTrackingMode: String?,
    )

    private fun android.database.Cursor.intOrNull(column: String): Int? {
        val idx = getColumnIndex(column)
        if (idx < 0 || isNull(idx)) return null
        return getInt(idx)
    }

    private fun android.database.Cursor.stringOrNull(column: String): String? {
        val idx = getColumnIndex(column)
        if (idx < 0 || isNull(idx)) return null
        return getString(idx)
    }

    companion object {
        private const val TAG = "CronicleLibraryDb"
        private const val KIND_ANIME = 0
        private const val KIND_BOOK = 5

        fun openOrNull(context: Context): CronicleLibraryDb? {
            val names = listOf("cronicle.db.sqlite", "cronicle.db")
            val dirs = listOf(
                File(context.dataDir, "app_flutter"),
                context.filesDir,
                context.getDatabasePath("cronicle.db").parentFile ?: context.filesDir,
            )
            val candidates = dirs.flatMap { d -> names.map { File(d, it) } }
            val file = candidates.firstOrNull { it.exists() && it.length() > 0 } ?: run {
                Log.w(TAG, "Drift DB not found in any known location: $candidates")
                try {
                    val root = context.dataDir
                    val found = mutableListOf<String>()
                    fun walk(dir: File, depth: Int) {
                        if (depth > 4) return
                        val children = dir.listFiles() ?: return
                        for (c in children) {
                            if (c.isDirectory) walk(c, depth + 1)
                            else if (c.name.endsWith(".db") || c.name.endsWith(".sqlite")) found += c.absolutePath
                        }
                    }
                    walk(root, 0)
                    Log.w(TAG, "Scan of ${root.absolutePath} found db files: $found")
                } catch (t: Throwable) {
                    Log.w(TAG, "Scan failed", t)
                }
                return null
            }
            Log.i(TAG, "Opening Drift DB at ${file.absolutePath}")
            val raw = SQLiteDatabase.openDatabase(
                file.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE,
            )
            return CronicleLibraryDb(raw)
        }
    }
}
