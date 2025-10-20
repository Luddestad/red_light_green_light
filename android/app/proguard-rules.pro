# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (for app bundles)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# Pose Detection
-keep class com.google.mlkit.vision.pose.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Face Detection  
-keep class com.google.mlkit.vision.face.** { *; }

# Camera
-keep class androidx.camera.** { *; }

# Audio Players
-keep class xyz.luan.audioplayers.** { *; }

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Generic rules for common issues
-dontwarn java.lang.invoke.StringConcatFactory
