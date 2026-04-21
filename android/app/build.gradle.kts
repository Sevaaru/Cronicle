import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Firma release: carga las credenciales desde android/key.properties.
// Copia android/key.properties.example → android/key.properties y rellena
// con los datos de tu Upload Key (keystore local).
//
// IMPORTANTE — Google Sign-In:
//   Tanto el APK release (firma local con Upload Key) como el AAB en Play
//   (re-firmado por Google con su App Signing Key) deben funcionar.
//   Para ello, registra AMBOS SHA-1 en Google Cloud Console:
//     1. SHA-1 de tu Upload Key   → keytool o .\gradlew.bat signingReport
//     2. SHA-1 de la App Signing  → Play Console > Configuración > Integridad
//   Ver key.properties.example para más detalle.
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Wearable Data Layer — used by `WearLibraryListenerService` to talk to the watch app.
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}

android {
    namespace = "com.cronicle.app.cronicle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.cronicle.app.cronicle"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // -----------------------------------------------------------------------
    // Signing config: usa la Upload Key para firmar TANTO el APK como el AAB.
    // El AAB será re-firmado por Google Play con la App Signing Key al
    // publicar, pero la subida siempre se hace con la Upload Key.
    // -----------------------------------------------------------------------
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Si key.properties existe → firma con la Upload Key (release).
            // Si no existe (CI sin keystore, máquina nueva) → usa debug para
            // que el build no falle; el artefacto NO será válido para Play.
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
        debug {
            // Firmar también debug con la Upload Key cuando esté disponible,
            // para que el módulo Wear OS (que se firma siempre con release)
            // pueda hablar con la app del móvil sin "Mismatched certificate".
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    // Incluir símbolos de depuración nativos (Flutter engine, sqlite3, etc.)
    // en el AAB para que Play Console simbolice ANRs/crashes.
    buildTypes.getByName("release") {
        ndk {
            debugSymbolLevel = "FULL"
        }
    }
}

flutter {
    source = "../.."
}
