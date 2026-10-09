# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Native QSP and JNI / FFI bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter InAppWebView
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# MediaKit
-keep class com.alexmercerind.** { *; }

# General keep rules
-dontwarn io.flutter.**
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.**
-dontwarn com.alexmercerind.**
