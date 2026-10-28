package com.cronicle.app.cronicle.widget

/**
 * Variante del widget de biblioteca pensada para 4x4 (lista grande).
 * Toda la lógica vive en [LibraryWidgetProvider].
 */
class LibraryWidgetProviderLarge : LibraryWidgetProvider() {
    override val variants: Set<Variant> = setOf(Variant.LARGE)
}
