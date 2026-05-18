import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun readSigningValue(propertyKey: String, envKey: String): String? {
    return (keystoreProperties.getProperty(propertyKey)
        ?: System.getenv(envKey))
        ?.takeIf { it.isNotBlank() }
}

val signingStoreFile = readSigningValue("storeFile", "ANDROID_KEYSTORE_PATH")
val signingStorePassword = readSigningValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val signingKeyAlias = readSigningValue("keyAlias", "ANDROID_KEY_ALIAS")
val signingKeyPassword = readSigningValue("keyPassword", "ANDROID_KEY_PASSWORD")
val hasReleaseSigning =
    !signingStoreFile.isNullOrBlank() &&
        !signingStorePassword.isNullOrBlank() &&
        !signingKeyAlias.isNullOrBlank() &&
        !signingKeyPassword.isNullOrBlank()

android {
    namespace = "com.example.quranglow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.quranglow"
        minSdk = maxOf(21, flutter.minSdkVersion)   // must be >= 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(signingStoreFile!!)
                storePassword = signingStorePassword
                keyAlias = signingKeyAlias
                keyPassword = signingKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // 🔥 REQUIRED for HomeWidget & Native Kotlin logic
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.10"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}
