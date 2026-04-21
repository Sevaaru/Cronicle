import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Reuse the same upload key as the phone app so both APKs are paired by signature
// (required by Wear OS Data Layer for inter-device communication).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.cronicle.app.cronicle.wear"
    compileSdk = 35

    defaultConfig {
        // MUST match the phone app's applicationId for Wearable Data Layer pairing.
        applicationId = "com.cronicle.app.cronicle"
        minSdk = 30 // Wear OS 3+
        targetSdk = 35
        // Mantener sincronizado con `pubspec.yaml` (version: x.y.z+versionCode)
        // del módulo móvil para que ambas subidas a Play Console avancen juntas.
        versionCode = 39
        versionName = "1.0.9"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

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
            // R8 desactivado: el módulo Wear es muy pequeño (Kotlin puro) y
            // R8 estaba removiendo clases que Compose / WearableListenerService /
            // Tiles / Coil necesitan por reflexión o por referencia desde el
            // manifest, provocando crash al iniciar la APK release. El warning
            // de Play Console sobre "archivo de desofuscación" es informativo
            // y no bloquea publicación.
            isMinifyEnabled = false
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            applicationIdSuffix = ""
            // Sign debug builds with the same release key as the phone app, so
            // Wearable Data Layer accepts cross-device messages (it requires both
            // sides to be signed with the matching certificate).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
        // Excluir la única .so del AAB (prebuilt y stripped en el AAR de
        // androidx.graphics:graphics-path). Sin código nativo desaparece el
        // aviso "native debug symbols" en Play Console. La librería tiene
        // fallback Kotlin puro, así que Compose sigue funcionando.
        jniLibs.excludes += "**/libandroidx.graphics.path.so"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.10.00")
    implementation(composeBom)

    // Core Android
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")

    // Compose for Wear OS
    implementation("androidx.wear.compose:compose-material:1.4.0")
    implementation("androidx.wear.compose:compose-foundation:1.4.0")
    implementation("androidx.wear.compose:compose-navigation:1.4.0")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material:material-icons-core")

    // Wearable Data Layer
    implementation("com.google.android.gms:play-services-wearable:19.0.0")

    // Tiles
    implementation("androidx.wear.tiles:tiles:1.4.0")
    implementation("androidx.wear.tiles:tiles-material:1.4.0")
    implementation("androidx.wear.protolayout:protolayout:1.2.0")
    implementation("androidx.wear.protolayout:protolayout-material:1.2.0")
    implementation("androidx.wear.protolayout:protolayout-expression:1.2.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

    // Guava (ListenableFuture / SettableFuture used by the Tile service).
    implementation("com.google.guava:guava:33.3.1-android")

    // Coil for async image loading (poster artwork in the detail screen).
    implementation("io.coil-kt:coil-compose:2.7.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
}
