# ProGuard rules for Smriti

# Keep ObjectBox
-keep class io.objectbox.** { *; }
-keep class io.objectbox.annotation.** { *; }
-keepclassmembers class * {
    @io.objectbox.annotation.* <fields>;
}

# Keep TFLite
-keep class org.tensorflow.lite.** { *; }

# Keep Secure Storage
-keep class com.itextpdf.** { *; }

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.mlkit.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Disable logging in release
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
