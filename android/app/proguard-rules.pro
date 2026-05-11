# Flutter/Dart specific keeps
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keepattributes *Annotation*

# ObjectBox - required for reflection-based DB operations
-keep class io.objectbox.** { *; }
-keep class com.objectbox.** { *; }
-dontwarn io.objectbox.**

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.** { *; }

# Biometric auth
-keep class androidx.biometric.** { *; }

# ML Kit text recognition
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# TFLite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# HTTP / networking
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Syncfusion PDF
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# General Android
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ── Security & Anti-Tampering ─────────────────────────────────────────────────

# Multi-pass optimization (harder to decompile)
-optimizationpasses 7
-allowaccessmodification
-mergeinterfacesaggressively
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# Obfuscate source file names in stack traces
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Prevent reflection-based tampering with core classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}
