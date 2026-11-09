package com.cronicle.app.cronicle.widget

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import java.util.Locale

/**
 * Idioma del widget = idioma elegido en la app (`LocaleNotifier`, clave
 * `locale_code` de shared_preferences). Sin preferencia guardada replica la
 * regla de la app: español si alguno de los idiomas del sistema lo es.
 *
 * Los textos del XML los resuelve el launcher con el idioma del sistema, así
 * que todo texto visible del widget se fija en tiempo de ejecución con el
 * contexto que devuelve [wrap].
 */
internal object WidgetLocale {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val KEY = "flutter.locale_code"
    private val supported = setOf("es", "en")

    fun code(context: Context): String {
        val saved = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null)
        if (saved in supported) return saved!!

        val config = context.resources.configuration
        val languages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            (0 until config.locales.size()).map { config.locales[it].language }
        } else {
            @Suppress("DEPRECATION")
            listOf(config.locale.language)
        }
        return if (languages.any { it.equals("es", ignoreCase = true) }) "es" else "en"
    }

    fun wrap(context: Context): Context {
        val config = Configuration(context.resources.configuration)
        config.setLocale(Locale(code(context)))
        return context.createConfigurationContext(config)
    }
}
