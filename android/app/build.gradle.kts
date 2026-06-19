plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase config (processes google-services.json).
    id("com.google.gms.google-services")
}

android {
    namespace = "labs.focuschain.focuschainlabs_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time on older APIs).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "labs.focuschain.focuschainlabs_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 // Firebase Auth requires minSdk 23
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Committed UAT keystore → a STABLE SHA-1 across every machine/Codespace,
        // so Google Sign-In keeps working. NOT a production upload key — generate
        // a separate secret key before Play Store distribution.
        create("uat") {
            storeFile = file("fcl-uat.keystore")
            storePassword = "focuschain"
            keyAlias = "fcl-uat"
            keyPassword = "focuschain"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("uat")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
