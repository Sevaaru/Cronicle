package com.cronicle.app.cronicle.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import com.cronicle.app.cronicle.R

/**
 * Pregunta el tema (oscuro / claro) al colocar el widget. En Android 12+
 * también se abre desde «Personalizar» del widget (`reconfigurable`).
 * Cancelar al colocarlo hace que el launcher no añada el widget.
 */
class LibraryWidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(WidgetLocale.wrap(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_config)

        val current = WidgetTheme.of(this, appWidgetId)
        bindOption(R.id.widget_config_dark, WidgetTheme.DARK, current)
        bindOption(R.id.widget_config_light, WidgetTheme.LIGHT, current)
    }

    private fun bindOption(viewId: Int, theme: WidgetTheme, current: WidgetTheme) {
        val option = findViewById<FrameLayout>(viewId)
        if (theme == current) {
            option.foreground = ContextCompat.getDrawable(this, R.drawable.widget_signal_option_selected)
        }
        option.setOnClickListener { choose(theme) }
    }

    private fun choose(theme: WidgetTheme) {
        WidgetTheme.save(this, appWidgetId, theme)
        LibraryWidgetProvider.refreshWidget(this, appWidgetId)
        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
        )
        finish()
    }
}
