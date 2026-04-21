# Wear OS companion ProGuard rules.
# Compose, AndroidX y Wearable Data Layer ya traen reglas consumer-proguard
# en sus AARs; aquí solo añadimos lo específico del módulo.

# Mantener entry points de Compose (suelen estar cubiertos por consumer rules,
# se incluye por defensa).
-keep class androidx.compose.runtime.** { *; }

# Wearable Data Layer: callbacks invocados por reflexión vía manifest.
-keep class com.cronicle.app.cronicle.wear.** { *; }

# Coil mantiene sus propias reglas; nada extra necesario.
