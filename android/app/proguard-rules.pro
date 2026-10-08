# Questopia R8 / Proguard Rules for Minimized Release Build

# Keep Flutter Engine & FFI bindings
-keep class io.flutter.** { *; }
-keep class com.questopia.re.** { *; }

# Keep Native JNI and C FFI entry points
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Background Downloader & WorkManager classes
-keep class com.bbflight.background_downloader.** { *; }
-keep class androidx.work.** { *; }

# Keep WebView and InAppWebView classes
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Suppress warnings from unused dependencies
-dontwarn **
