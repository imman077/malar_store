plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.malarstores.malar_stores"
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
        applicationId = "com.malarstores.malar_stores"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // signingConfigs {
    //    create("release") {
    //        // TODO: Replace with your real keystore
    //        storeFile = file("key.jks")
    //        storePassword = "your-password"
    //        keyAlias = "your-alias"
    //        keyPassword = "your-password"
    //    }
    // }

    buildTypes {
        getByName("release") {
            // Enable shrinking + minification (reduces APK size a lot)
            isMinifyEnabled = false
            isShrinkResources = false

            // Set your real signing config
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
