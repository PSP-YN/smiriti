# ProGuard rules for Smriti — Production Release

# ─── Flutter core ───────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Play Core (used by Flutter deferred components — keep to avoid R8 errors) ─
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ─── ObjectBox ──────────────────────────────────────────────────────────────
-keep class io.objectbox.** { *; }
-keep class io.objectbox.annotation.** { *; }
-keepclassmembers class * {
    @io.objectbox.annotation.* <fields>;
}

# ─── TensorFlow Lite ─────────────────────────────────────────────────────────
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# ─── ML Kit Text Recognition ─────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_release.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ─── Kotlin coroutines ───────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ─── Native methods ──────────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─── Crypto / encryption ─────────────────────────────────────────────────────
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# ─── Disable verbose logging in release ─────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
