// Remove duplicate ANDROID_PREFS_ROOT environment variable to prevent AGP AndroidLocationsException
try {
    val processEnv = Class.forName("java.lang.ProcessEnvironment")
    try {
        val field = processEnv.getDeclaredField("theCaseInsensitiveEnvironment").apply { isAccessible = true }
        (field.get(null) as? MutableMap<String, String>)?.remove("ANDROID_PREFS_ROOT")
    } catch (_: Exception) {}
    try {
        val field = processEnv.getDeclaredField("theEnvironment").apply { isAccessible = true }
        (field.get(null) as? MutableMap<String, String>)?.remove("ANDROID_PREFS_ROOT")
    } catch (_: Exception) {}
} catch (_: Exception) {}
java.lang.System.clearProperty("ANDROID_PREFS_ROOT")

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
