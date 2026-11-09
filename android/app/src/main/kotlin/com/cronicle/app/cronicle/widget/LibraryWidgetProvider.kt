package com.cronicle.app.cronicle.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.cronicle.app.cronicle.MainActivity
import com.cronicle.app.cronicle.R
import com.cronicle.app.cronicle.wear.CronicleLibraryDb
import com.cronicle.app.cronicle.wear.WearRemoteSyncService

/**
 * Widget Material 3 de la biblioteca de Cronicle.
 *
 * - Redimensionable a cualquier tamaño estándar de Android (2x2, 3x2, 4x2,
 *   4x3, 4x4...).
 * - En Android 12+ usa la API de [RemoteViews] con mapa de [SizeF] para
 *   conmutar el layout (tarjeta destacada / lista) de forma dinámica
 *   mientras el usuario arrastra el manejador de redimensionado, sin
 *   esperar a [onAppWidgetOptionsChanged].
 * - En versiones más antiguas se usa el ancho reportado por
 *   [AppWidgetManager.getAppWidgetOptions] como umbral.
 *
 * Las subclases [LibraryWidgetProviderSmall] y [LibraryWidgetProviderLarge]
 * existen únicamente para que el selector de widgets de Android muestre 3
 * entradas independientes (con su propia previsualización y tamaño por
 * defecto).
 */
open class LibraryWidgetProvider : AppWidgetProvider() {

    /**
     * Conjunto de variantes de layout que esta instancia del provider
     * puede mostrar. La subclase pequeña fuerza sólo la tarjeta destacada
     * (sin lista) para evitar que el launcher se líe inflando un
     * RemoteViews con `setRemoteAdapter` cuando el widget tiene 2x2 y la
     * lista no cabe.
     */
    protected open val variants: Set<Variant> =
        setOf(Variant.SMALL, Variant.MEDIUM, Variant.LARGE)

    enum class Variant { SMALL, MEDIUM, LARGE }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val nav = context.getSharedPreferences(PREFS_SMALL, Context.MODE_PRIVATE).edit()
        for (id in appWidgetIds) {
            WidgetTheme.clear(context, id)
            nav.remove("idx_$id")
        }
        nav.apply()
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH -> rebuildAll(context)
            ACTION_DATA_CHANGED,
            "com.cronicle.app.cronicle.WEAR_LIBRARY_CHANGED" -> {
                requestRefresh(context)
            }
            ACTION_TEMPLATE -> {
                val kind = intent.getIntExtra(EXTRA_KIND, -1)
                val externalId = intent.getStringExtra(EXTRA_EXTERNAL_ID)
                when (intent.getStringExtra(EXTRA_OP)) {
                    OP_INCREMENT -> if (kind >= 0 && !externalId.isNullOrEmpty()) {
                        handleIncrement(context, kind, externalId)
                    }
                    OP_COMPLETE -> if (kind >= 0 && !externalId.isNullOrEmpty()) {
                        handleComplete(context, kind, externalId)
                    }
                    OP_OPEN -> if (kind >= 0 && !externalId.isNullOrEmpty()) {
                        openLibraryEntry(context, kind, externalId)
                    }
                }
            }
            // Navegación del AdapterViewFlipper del widget 2x2.
            // Usa partiallyUpdateAppWidget para avanzar/retroceder la
            // tarjeta visible sin reconstruir el RemoteViews completo.
            ACTION_PREV_SMALL, ACTION_NEXT_SMALL -> {
                val appWidgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
                // Calcula el nuevo índice usando el total de ítems en progreso.
                // showNext()/showPrevious() de RemoteViews no mueve el flipper
                // cuando tiene setRemoteAdapter; setDisplayedChild sí funciona.
                val total = try {
                    val db = CronicleLibraryDb.openOrNull(context)
                    if (db != null) try { db.queryInProgress().size } finally { db.close() } else 0
                } catch (_: Throwable) { 0 }
                if (total == 0) return
                val prefs = context.getSharedPreferences(PREFS_SMALL, Context.MODE_PRIVATE)
                val key = "idx_$appWidgetId"
                val current = prefs.getInt(key, 0)
                val next = if (intent.action == ACTION_PREV_SMALL) {
                    (current - 1 + total) % total
                } else {
                    (current + 1) % total
                }
                prefs.edit().putInt(key, next).apply()
                val mgr = AppWidgetManager.getInstance(context)
                val views = RemoteViews(context.packageName, R.layout.widget_library_small)
                views.setInt(R.id.widget_small_list, "setDisplayedChild", next)
                mgr.partiallyUpdateAppWidget(appWidgetId, views)
            }
        }
    }

    private fun handleIncrement(context: Context, kind: Int, externalId: String) {
        var applied = false
        try {
            val db = CronicleLibraryDb.openOrNull(context) ?: return
            try {
                applied = db.incrementProgress(kind, externalId)
            } finally {
                db.close()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "increment failed", t)
        }
        if (applied) publishLibraryChange(context, kind, externalId)
        requestRefresh(context)
    }

    private fun handleComplete(context: Context, kind: Int, externalId: String) {
        var applied = false
        try {
            val db = CronicleLibraryDb.openOrNull(context) ?: return
            try {
                applied = db.markCompleted(kind, externalId)
            } finally {
                db.close()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "complete failed", t)
        }
        if (applied) publishLibraryChange(context, kind, externalId)
        requestRefresh(context)
    }

    private fun publishLibraryChange(context: Context, kind: Int, externalId: String) {
        try {
            WearRemoteSyncService.enqueueAndLaunch(context, kind, externalId)
        } catch (t: Throwable) {
            Log.w(TAG, "enqueueAndLaunch failed", t)
        }
        try {
            val broadcast = Intent(MainActivity.ACTION_LIBRARY_CHANGED)
                .setPackage(context.packageName)
            context.sendBroadcast(broadcast)
        } catch (t: Throwable) {
            Log.w(TAG, "broadcast library change failed", t)
        }
    }

    private fun openLibraryEntry(context: Context, kind: Int, externalId: String) {
        try {
            val open = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("cronicle://library/$kind/$externalId")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(open)
        } catch (t: Throwable) {
            Log.w(TAG, "open failed", t)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views: RemoteViews = buildRemoteViewsFor(context, appWidgetManager, appWidgetId)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // El primer aviso llega antes de que el launcher enganche el
        // RemoteViewsService, y la lista se queda vacía hasta que otra
        // cosa (abrir la app) vuelve a pedir datos. Se repite unas veces.
        scheduleCollectionRefresh(context, appWidgetId)
    }

    private fun buildRemoteViewsFor(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ): RemoteViews {
        // Si la variante sólo permite un layout, devolvemos un RemoteViews
        // simple sin mapa de SizeF: algunos launchers no manejan bien el
        // mapa cuando el widget es muy pequeño (2x2) y muestran
        // "Error al cargar el widget".
        if (variants.size == 1) {
            return when (variants.first()) {
                Variant.SMALL -> buildSmallRemoteViews(context, appWidgetId)
                Variant.MEDIUM, Variant.LARGE -> buildMediumRemoteViews(context, appWidgetId)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+: deja que el sistema escoja la mejor variante
            // según el tamaño actual. Cambia al instante mientras se
            // redimensiona el widget, sin nuevos onUpdate.
            val mapping = LinkedHashMap<SizeF, RemoteViews>()
            if (Variant.SMALL in variants) {
                mapping[SizeF(40f, 40f)] = buildSmallRemoteViews(context, appWidgetId)
            }
            if (Variant.MEDIUM in variants) {
                mapping[SizeF(180f, 110f)] = buildMediumRemoteViews(context, appWidgetId)
            }
            if (Variant.LARGE in variants) {
                mapping[SizeF(250f, 250f)] = buildMediumRemoteViews(context, appWidgetId)
            }
            return RemoteViews(mapping)
        }

        // API <31: detecta tamaño manualmente y usa el layout adecuado.
        return if (Variant.SMALL in variants && isCompactSize(appWidgetManager, appWidgetId)) {
            buildSmallRemoteViews(context, appWidgetId)
        } else {
            buildMediumRemoteViews(context, appWidgetId)
        }
    }

    private fun buildMediumRemoteViews(context: Context, appWidgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library)
        val theme = WidgetTheme.of(context, appWidgetId)

        // RemoteAdapter alimenta la ListView vía [LibraryWidgetService].
        // El URI único por id y tema evita que Android reutilice la factory
        // de otro widget o la del tema anterior.
        val serviceIntent = Intent(context, LibraryWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra(LibraryWidgetService.EXTRA_THEME, theme.key)
            data = Uri.parse("cronicle-widget://service/$appWidgetId/medium/${theme.key}")
        }
        views.setRemoteAdapter(R.id.widget_list, serviceIntent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)

        val localized = WidgetLocale.wrap(context)
        views.setInt(R.id.widget_root, "setBackgroundResource", theme.background)
        views.setTextViewText(R.id.widget_title, localized.getString(R.string.widget_library_title))
        views.setTextViewText(R.id.widget_empty, localized.getString(R.string.widget_library_empty))
        views.setTextColor(R.id.widget_title, theme.text(context))
        views.setTextColor(R.id.widget_empty, theme.textDim(context))

        views.setViewVisibility(R.id.widget_title, View.VISIBLE)

        // Cabecera: pulsar el título abre la app. Lanzamos MainActivity
        // sin ACTION_VIEW + data: así Flutter no procesa esto como un deep
        // link (que terminaba llegando a GoRouter como `/?` y rompiendo el
        // routing) y abre directamente en su startPage.
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        views.setOnClickPendingIntent(
            R.id.widget_title,
            PendingIntent.getActivity(context, REQ_OPEN_APP, openAppIntent, piFlags()),
        )

        // Plantilla de PendingIntent compartida por todas las filas. Cada
        // fila adjunta sus extras vía fillInIntent y el receptor decide la
        // operación según EXTRA_OP.
        val templateIntent = Intent(context, this::class.java).apply {
            action = ACTION_TEMPLATE
            data = Uri.parse("cronicle-widget://template/$appWidgetId")
        }
        views.setPendingIntentTemplate(
            R.id.widget_list,
            PendingIntent.getBroadcast(context, REQ_TEMPLATE, templateIntent, piFlags()),
        )

        return views
    }

    private fun buildSmallRemoteViews(context: Context, appWidgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_library_small)
        val theme = WidgetTheme.of(context, appWidgetId)

        // Alimenta el AdapterViewFlipper desde LibraryWidgetService con el
        // layout de tarjeta (descarga de portadas en el hilo del servicio,
        // sin bloquear el main thread del widget provider).
        val serviceIntent = Intent(context, LibraryWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra(LibraryWidgetService.EXTRA_CARD_LAYOUT, true)
            putExtra(LibraryWidgetService.EXTRA_THEME, theme.key)
            data = Uri.parse("cronicle-widget://service/$appWidgetId/small/${theme.key}")
        }
        views.setRemoteAdapter(R.id.widget_small_list, serviceIntent)
        views.setEmptyView(R.id.widget_small_list, R.id.widget_small_empty)

        val localized = WidgetLocale.wrap(context)
        views.setInt(R.id.widget_small_root, "setBackgroundResource", theme.background)
        views.setTextViewText(R.id.widget_small_empty, localized.getString(R.string.widget_library_empty))
        views.setTextColor(R.id.widget_small_empty, theme.textDim(context))
        views.setContentDescription(
            R.id.widget_small_next,
            localized.getString(R.string.widget_next_content_desc),
        )
        theme.applyNavButton(context, views, R.id.widget_small_next)

        // Restaura el índice de navegación guardado para que, al refrescar el
        // widget, el flipper vuelva a mostrar la tarjeta que el usuario dejó.
        val savedIdx = context.getSharedPreferences(PREFS_SMALL, Context.MODE_PRIVATE)
            .getInt("idx_$appWidgetId", 0)
        views.setInt(R.id.widget_small_list, "setDisplayedChild", savedIdx)

        // Plantilla de PendingIntent compartida para toques en las tarjetas.
        val templateIntent = Intent(context, this::class.java).apply {
            action = ACTION_TEMPLATE
            data = Uri.parse("cronicle-widget://template/$appWidgetId/small")
        }
        views.setPendingIntentTemplate(
            R.id.widget_small_list,
            PendingIntent.getBroadcast(context, REQ_TEMPLATE_SMALL + appWidgetId, templateIntent, piFlags()),
        )

        // Botón ▶ siguiente: navegación infinita con un solo botón.
        val nextIntent = Intent(context, this::class.java).apply {
            action = ACTION_NEXT_SMALL
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse("cronicle-widget://next/$appWidgetId")
        }
        views.setOnClickPendingIntent(
            R.id.widget_small_next,
            PendingIntent.getBroadcast(context, REQ_NEXT + appWidgetId, nextIntent, piFlags()),
        )

        return views
    }

    private fun isCompactSize(mgr: AppWidgetManager, id: Int): Boolean {
        val opts = mgr.getAppWidgetOptions(id) ?: return false
        val isLandscape = (Configuration.ORIENTATION_LANDSCAPE ==
            (opts.getInt("appWidgetCategory", 0)))
        val width = if (isLandscape) {
            opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        } else {
            opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        }
        val height = if (isLandscape) {
            opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        } else {
            opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        }
        // Trata como compacto cuando el lado más corto está por debajo de
        // ~3 celdas (~180dp).
        val shortSide = if (width > 0 && height > 0) minOf(width, height) else maxOf(width, height)
        return shortSide in 1..170
    }

    companion object {
        private const val TAG = "LibraryWidget"
        private const val PREFS_SMALL = "widget_small_nav"

        const val ACTION_REFRESH = "com.cronicle.app.cronicle.widget.ACTION_REFRESH"
        const val ACTION_DATA_CHANGED = "com.cronicle.app.cronicle.widget.ACTION_DATA_CHANGED"
        const val ACTION_TEMPLATE = "com.cronicle.app.cronicle.widget.ACTION_TEMPLATE"
        const val ACTION_PREV_SMALL = "com.cronicle.app.cronicle.widget.ACTION_PREV_SMALL"
        const val ACTION_NEXT_SMALL = "com.cronicle.app.cronicle.widget.ACTION_NEXT_SMALL"

        const val EXTRA_KIND = "kind"
        const val EXTRA_EXTERNAL_ID = "externalId"
        const val EXTRA_OP = "op"

        const val OP_OPEN = "open"
        const val OP_INCREMENT = "increment"
        const val OP_COMPLETE = "complete"

        private val mainHandler = Handler(Looper.getMainLooper())
        private val collectionRetries = HashMap<Int, Runnable>()

        private fun scheduleCollectionRefresh(context: Context, appWidgetId: Int) {
            val app = context.applicationContext
            collectionRetries.remove(appWidgetId)?.let { mainHandler.removeCallbacks(it) }
            var attempt = 0
            val task = object : Runnable {
                override fun run() {
                    val mgr = AppWidgetManager.getInstance(app)
                    try {
                        mgr.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
                    } catch (_: Throwable) {}
                    try {
                        mgr.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_small_list)
                    } catch (_: Throwable) {}
                    attempt++
                    if (attempt < 4) {
                        mainHandler.postDelayed(this, if (attempt == 1) 300L else 800L)
                    } else {
                        collectionRetries.remove(appWidgetId)
                    }
                }
            }
            collectionRetries[appWidgetId] = task
            mainHandler.post(task)
        }

        private const val REQ_OPEN_APP = 1001
        private const val REQ_TEMPLATE = 1003
        private const val REQ_TEMPLATE_SMALL = 4000
        private const val REQ_PREV = 5000
        private const val REQ_NEXT = 6000

        private fun piFlags(): Int {
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags = flags or PendingIntent.FLAG_MUTABLE
            }
            return flags
        }

        /**
         * Cambios de datos (+1, completar, cambios desde la app o el reloj):
         * solo pide a las listas que vuelvan a cargar. El launcher mantiene
         * las filas actuales hasta tener las nuevas y las sustituye en su
         * sitio, sin el parpadeo de reconstruir el widget entero.
         */
        fun requestRefresh(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            for (cls in providerClasses) {
                val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
                if (ids.isEmpty()) continue
                if (cls == LibraryWidgetProviderSmall::class.java) {
                    mgr.notifyAppWidgetViewDataChanged(ids, R.id.widget_small_list)
                } else {
                    mgr.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
                }
            }
        }

        /** Full rebuild of every instance (language change, manual refresh). */
        fun rebuildAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            for (cls in providerClasses) {
                val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
                if (ids.isEmpty()) continue
                val instance = try {
                    cls.getDeclaredConstructor().newInstance()
                } catch (_: Throwable) { null } ?: continue
                for (id in ids) instance.updateWidget(context, mgr, id)
            }
            requestRefresh(context)
        }

        /** Rebuilds a single instance (e.g. after choosing its theme). */
        fun refreshWidget(context: Context, appWidgetId: Int) {
            val mgr = AppWidgetManager.getInstance(context)
            val className = mgr.getAppWidgetInfo(appWidgetId)?.provider?.className
            val cls = providerClasses.firstOrNull { it.name == className }
                ?: LibraryWidgetProvider::class.java
            val instance = try {
                cls.getDeclaredConstructor().newInstance()
            } catch (_: Throwable) {
                return
            }
            instance.updateWidget(context, mgr, appWidgetId)
        }

        private val providerClasses: List<Class<out LibraryWidgetProvider>> = listOf(
            LibraryWidgetProvider::class.java,
            LibraryWidgetProviderSmall::class.java,
            LibraryWidgetProviderLarge::class.java,
        )
    }
}
