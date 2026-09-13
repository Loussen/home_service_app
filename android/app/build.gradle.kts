import java.util.Properties

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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "az.homeservice.home_service_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // AndroidManifest ${GOOGLE_MAPS_API_KEY} — dart-define does not fill this.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = resolveGoogleMapsApiKey()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
