plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smriti.app.smriti"
    compileSdk = 34
    buildToolsVersion = "36.0.0"
    ndkVersion = "25.1.8937393"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.smriti.app.smriti"
        minSdk = 24  // Required for native library support
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // Native library configuration
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        
        externalNativeBuild {
            cmake {
                cppFlags += "-O3 -DNDEBUG"
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DANDROID_CPP_FEATURES=exceptions rtti"
                )
            }
        }
    }
    
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Native library optimizations
            packagingOptions {
                jniLibs {
                    useLegacyPackaging = true
                    keepDebugSymbols += listOf("*.so")
                }
            }
        }
        debug {
            isMinifyEnabled = false
            packagingOptions {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
