import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

android {
    namespace = "com.smriti.app.smriti"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.smriti.app.smriti"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

    }

    signingConfigs {
        create("release") {
            val keyPropsFile = rootProject.file("key.properties")
            if (keyPropsFile.exists()) {
                val keyProps = Properties()
                keyProps.load(FileInputStream(keyPropsFile))
                storeFile = rootProject.file(keyProps["storeFile"]!!)
                keyAlias = keyProps["keyAlias"]!!.toString()
                storePassword = keyProps["storePassword"]!!.toString()
                keyPassword = keyProps["keyPassword"]!!.toString()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            packaging {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
        }
        debug {
            isMinifyEnabled = false
            packaging {
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
