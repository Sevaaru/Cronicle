package com.cronicle.app.cronicle.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.util.Log
import android.util.LruCache
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * Caché de portadas escaladas + recortadas + con esquinas redondeadas para
 * RemoteViews: memoria → disco → red.
 *
 * El disco es lo que evita que desaparezcan: el proceso de la app muere a
 * menudo y en segundo plano Android puede cortar la red, así que una caché
 * solo en memoria acababa mostrando el placeholder.
 */
internal object LibraryPosterCache {
    private const val TAG = "LibraryPosterCache"
    private const val DIR_NAME = "widget_posters"
    private const val MAX_DISK_FILES = 400

    private val memory = object : LruCache<String, Bitmap>(16 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }

    fun load(context: Context, url: String?, targetW: Int, targetH: Int): Bitmap? {
        if (url.isNullOrBlank()) return null
        val key = "$url@${targetW}x$targetH"
        memory.get(key)?.let { return it }

        val file = File(dir(context), sha1(key) + ".png")
        readFromDisk(file)?.let {
            memory.put(key, it)
            return it
        }

        return try {
            val raw = download(url) ?: return null
            val out = scaleAndRoundCorners(raw, targetW, targetH)
            if (out !== raw) raw.recycle()
            memory.put(key, out)
            writeToDisk(context, file, out)
            out
        } catch (t: Throwable) {
            Log.w(TAG, "load failed for $url", t)
            null
        }
    }

    private fun dir(context: Context): File =
        File(context.cacheDir, DIR_NAME).apply { if (!exists()) mkdirs() }

    private fun readFromDisk(file: File): Bitmap? {
        if (!file.isFile) return null
        return try {
            BitmapFactory.decodeFile(file.absolutePath)?.also {
                file.setLastModified(System.currentTimeMillis())
            }
        } catch (t: Throwable) {
            Log.w(TAG, "disk read failed for ${file.name}", t)
            null
        }
    }

    private fun writeToDisk(context: Context, file: File, bitmap: Bitmap) {
        try {
            val tmp = File(file.parentFile, file.name + ".tmp")
            FileOutputStream(tmp).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            if (!tmp.renameTo(file)) tmp.delete()
            prune(dir(context))
        } catch (t: Throwable) {
            Log.w(TAG, "disk write failed for ${file.name}", t)
        }
    }

    // Keeps the most recently used files; older ones are dropped.
    private fun prune(dir: File) {
        val files = dir.listFiles { f -> f.isFile && f.name.endsWith(".png") } ?: return
        if (files.size <= MAX_DISK_FILES) return
        files.sortedBy { it.lastModified() }
            .take(files.size - MAX_DISK_FILES)
            .forEach { it.delete() }
    }

    private fun sha1(value: String): String =
        MessageDigest.getInstance("SHA-1")
            .digest(value.toByteArray())
            .joinToString("") { "%02x".format(it) }

    private fun download(url: String): Bitmap? {
        var conn: HttpURLConnection? = null
        // Cleartext is blocked by default on Android 9+.
        val secureUrl = if (url.startsWith("http://")) "https://" + url.removePrefix("http://") else url
        return try {
            conn = (URL(secureUrl).openConnection() as HttpURLConnection).apply {
                connectTimeout = 8000
                readTimeout = 8000
                instanceFollowRedirects = true
                requestMethod = "GET"
                setRequestProperty("User-Agent", "Cronicle-Android-Widget")
                setRequestProperty("Accept", "image/*")
            }
            val code = conn.responseCode
            if (code !in 200..299) {
                Log.w(TAG, "download HTTP $code for $url")
                return null
            }
            conn.inputStream.use { stream -> BitmapFactory.decodeStream(stream) }
        } catch (t: Throwable) {
            Log.w(TAG, "download failed for $url", t)
            null
        } finally {
            try { conn?.disconnect() } catch (_: Throwable) {}
        }
    }

    private fun scaleAndRoundCorners(src: Bitmap, targetW: Int, targetH: Int): Bitmap {
        val srcRatio = src.width.toFloat() / src.height.toFloat()
        val targetRatio = targetW.toFloat() / targetH.toFloat()
        val cropRect = if (srcRatio > targetRatio) {
            val cropW = (src.height * targetRatio).toInt()
            val left = (src.width - cropW) / 2
            Rect(left, 0, left + cropW, src.height)
        } else {
            val cropH = (src.width / targetRatio).toInt()
            val top = (src.height - cropH) / 2
            Rect(0, top, src.width, top + cropH)
        }
        val out = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rectF = RectF(0f, 0f, targetW.toFloat(), targetH.toFloat())
        val cornerPx = if (targetW > targetH) targetH * 0.10f else targetW * 0.14f
        paint.color = -0x1
        canvas.drawRoundRect(rectF, cornerPx, cornerPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(src, cropRect, rectF, paint)
        paint.xfermode = null
        return out
    }
}
