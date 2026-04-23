package com.cronicle.app.cronicle.widget

/**
 * Variante del widget de biblioteca pensada para 2x2 (tarjeta destacada).
 * Toda la lógica vive en [LibraryWidgetProvider]; esta subclase solo existe
 * para que el selector de Android muestre una entrada independiente con su
 * propia previsualización.
 */
class LibraryWidgetProviderSmall : LibraryWidgetProvider() {
    override val variants: Set<Variant> = setOf(Variant.SMALL)
}
