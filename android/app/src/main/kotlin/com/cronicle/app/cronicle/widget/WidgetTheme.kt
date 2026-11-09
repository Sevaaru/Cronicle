package com.cronicle.app.cronicle.widget

import android.content.Context
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.cronicle.app.cronicle.R

/**
 * Tema claro/oscuro de cada instancia del widget. Se elige en
 * [LibraryWidgetConfigActivity] y se guarda por appWidgetId; los widgets
 * sin preferencia (los colocados antes de existir la opción) son oscuros.
 */
internal enum class WidgetTheme(
    val key: String,
    val background: Int,
    val itemBackground: Int,
    val navBackground: Int,
    val scrim: Int,
    private val pageRes: Int,
    private val surfaceRes: Int,
    private val textRes: Int,
    private val textDimRes: Int,
) {
    DARK(
        key = "dark",
        background = R.drawable.widget_signal_background,
        itemBackground = R.drawable.widget_signal_item_background,
        navBackground = R.drawable.widget_signal_nav,
        scrim = R.drawable.widget_small_scrim,
        pageRes = R.color.widget_signal_ink,
        surfaceRes = R.color.widget_signal_surface,
        textRes = R.color.widget_signal_text,
        textDimRes = R.color.widget_signal_text_dim,
    ),
    LIGHT(
        key = "light",
        background = R.drawable.widget_signal_background_light,
        itemBackground = R.drawable.widget_signal_item_background_light,
        navBackground = R.drawable.widget_signal_nav_light,
        scrim = R.drawable.widget_small_scrim_light,
        pageRes = R.color.widget_signal_paper,
        surfaceRes = R.color.widget_signal_paper_surface,
        textRes = R.color.widget_signal_ink,
        textDimRes = R.color.widget_signal_text_dim_light,
    );

    /** Widget background colour (row corner cuts are painted with it). */
    fun page(context: Context): Int = ContextCompat.getColor(context, pageRes)

    /** Row plate colour (slanted edges of poster and action are painted with it). */
    fun surface(context: Context): Int = ContextCompat.getColor(context, surfaceRes)

    fun text(context: Context): Int = ContextCompat.getColor(context, textRes)

    fun textDim(context: Context): Int = ContextCompat.getColor(context, textDimRes)

    /** Background plate + icon colour for the 2x2 "next" button. */
    fun applyNavButton(context: Context, views: RemoteViews, viewId: Int) {
        views.setInt(viewId, "setBackgroundResource", navBackground)
        views.setInt(viewId, "setColorFilter", text(context))
    }

    companion object {
        private const val PREFS = "widget_theme"

        fun fromKey(key: String?): WidgetTheme = values().firstOrNull { it.key == key } ?: DARK

        fun of(context: Context, appWidgetId: Int): WidgetTheme = fromKey(
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("theme_$appWidgetId", null),
        )

        fun save(context: Context, appWidgetId: Int, theme: WidgetTheme) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString("theme_$appWidgetId", theme.key).apply()
        }

        fun clear(context: Context, appWidgetId: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().remove("theme_$appWidgetId").apply()
        }
    }
}
