import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "company.thecloud.pantry"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "company.thecloud.pantry"
        manifestPlaceholders["msalRedirectHost"] = "company.thecloud.pantry"
        manifestPlaceholders["msalRedirectPath"] =
            "/515a9IhVXCyy57IZeaswJmLBBUA="
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
            )
        }
    }

    buildTypes {
        release {
            // MSAL redirect hash for the Play App Signing certificate.
            manifestPlaceholders["msalRedirectPath"] =
                "/nrvBMaqisWak4u1Jp+p7aT5dDhE="

            // Minification is intentionally OFF. It was enabled in 1f55a6f with a
            // proguard-rules.pro that does not exist and no keep rules, which
            // stripped MSAL (reflection-heavy) and crashed release builds.
            // To re-enable later: create proguard-rules.pro with keep rules for
            // MSAL/msal_auth/Gson/Drift and verify a release build before shipping.
            isMinifyEnabled = false
            isShrinkResources = false

            // Use the production keystore when available, otherwise keep a
            // debug-signed release build working for local verification.
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
