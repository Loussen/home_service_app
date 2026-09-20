import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

fun resolveGoogleMapsApiKey(): String {
    // Prefer dart_defines.json (same source as --dart-define-from-file).
    val dartDefines = rootProject.file("../dart_defines.json")
    if (dartDefines.exists()) {
        val match =
            Regex("\"GOOGLE_MAPS_API_KEY\"\\s*:\\s*\"([^\"]*)\"")
                .find(dartDefines.readText())
        val fromFile = match?.groupValues?.getOrNull(1)?.trim().orEmpty()
        if (fromFile.isNotEmpty()) return fromFile
    }
    val localProps = Properties()
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use { stream -> localProps.load(stream) }
        val fromLocal = localProps.getProperty("GOOGLE_MAPS_API_KEY")?.trim().orEmpty()
        if (fromLocal.isNotEmpty()) return fromLocal
    }
    return (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)?.trim().orEmpty()
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "az.homeservice.home_service_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "az.homeservice.home_service_app"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // AndroidManifest ${GOOGLE_MAPS_API_KEY} — dart-define does not fill this.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = resolveGoogleMapsApiKey()
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Local fallback only — Play Store requires upload-keystore + key.properties.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications (heads-up + app icon).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
