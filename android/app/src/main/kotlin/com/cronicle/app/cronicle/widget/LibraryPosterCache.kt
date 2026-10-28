package com.cronicle.app.cronicle.widget

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
import java.net.HttpURLConnection
import java.net.URL

/**
 * Caché en proceso de portadas escaladas + recortadas + con esquinas
 * redondeadas para usar en RemoteViews.
 */
internal object LibraryPosterCache {
    private const val TAG = "LibraryPosterCache"

    // Hasta 8 MB de bitmaps. Suficiente para varias docenas de portadas
    // a tamaño widget sin presionar la GPU del launcher.
    private val cache = object : LruCache<String, Bitmap>(8 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }

    fun load(url: String?, targetW: Int, targetH: Int): Bitmap? {
        if (url.isNullOrBlank()) return null
        val key = "$url@${targetW}x$targetH"
        cache.get(key)?.let { return it }
        return try {
            val raw = download(url) ?: return null
            val out = scaleAndRoundCorners(raw, targetW, targetH)
            if (out !== raw) raw.recycle()
            cache.put(key, out)
            out
        } catch (t: Throwable) {
            Log.w(TAG, "load failed for $url", t)
            null
        }
    }

    private fun download(url: String): Bitmap? {
        var conn: HttpURLConnection? = null
        return try {
            conn = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = 6000
                readTimeout = 6000
                instanceFollowRedirects = true
                requestMethod = "GET"
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
